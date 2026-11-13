create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  student_id text not null unique,
  email text,
  phone text,
  department text,
  avatar_url text,
  role text not null default 'student' check (role in ('student', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  category text not null check (category in ('Academic', 'Exam', 'Event', 'General')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.lost_found_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('lost', 'found')),
  title text not null,
  description text,
  category text,
  location text,
  item_date date,
  contact text,
  image_url text,
  status text not null default 'open' check (status in ('open', 'recovered')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  event_date timestamptz not null,
  location text,
  organizer text,
  image_url text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.event_registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (event_id, user_id)
);

create table public.study_resources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  department text,
  semester text,
  category text,
  file_url text not null,
  file_size bigint,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.marketplace_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  price numeric(10,2) not null check (price >= 0),
  category text not null check (category in ('Books', 'Electronics', 'Accessories', 'Stationery', 'Other')),
  condition text,
  image_url text,
  status text not null default 'available' check (status in ('available', 'sold')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.complaints (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null default 'complaint' check (type in ('complaint', 'feedback')),
  category text,
  description text not null,
  image_url text,
  status text not null default 'Pending'
    check (status in ('Pending', 'In Progress', 'Resolved', 'Rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index on public.notices (created_at desc);
create index on public.lost_found_items (user_id);
create index on public.lost_found_items (created_at desc);
create index on public.events (event_date);
create index on public.event_registrations (user_id);
create index on public.study_resources (user_id);
create index on public.marketplace_items (user_id);
create index on public.complaints (user_id);
create index on public.notifications (user_id, created_at desc);

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, student_id, email, phone, department)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'student_id', new.id::text),
    new.email,
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'department'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.notices for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.lost_found_items for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.events for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.study_resources for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.marketplace_items for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.complaints for each row execute function public.set_updated_at();

create or replace function public.protect_role()
returns trigger
language plpgsql
as $$
begin
  if new.role is distinct from old.role and auth.uid() is not null then
    raise exception 'You are not allowed to change the role';
  end if;
  return new;
end;
$$;

create trigger protect_role before update on public.profiles
for each row execute function public.protect_role();

create or replace function public.notify_new_notice()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, title, message)
  select id, 'New notice', new.title from public.profiles;
  return new;
end;
$$;

create trigger on_notice_created after insert on public.notices
for each row execute function public.notify_new_notice();

create or replace function public.notify_new_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, title, message)
  select id, 'New event', new.title from public.profiles;
  return new;
end;
$$;

create trigger on_event_created after insert on public.events
for each row execute function public.notify_new_event();

create or replace function public.notify_complaint_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status then
    insert into public.notifications (user_id, title, message)
    values (new.user_id, 'Complaint update', 'Your complaint is now: ' || new.status);
  end if;
  return new;
end;
$$;

create trigger on_complaint_status after update on public.complaints
for each row execute function public.notify_complaint_status();

alter table public.profiles enable row level security;
alter table public.notices enable row level security;
alter table public.lost_found_items enable row level security;
alter table public.events enable row level security;
alter table public.event_registrations enable row level security;
alter table public.study_resources enable row level security;
alter table public.marketplace_items enable row level security;
alter table public.complaints enable row level security;
alter table public.notifications enable row level security;

create policy "profiles: read" on public.profiles for select to authenticated using (true);
create policy "profiles: update own" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy "notices: read" on public.notices for select to authenticated using (true);
create policy "notices: admin insert" on public.notices for insert to authenticated with check (public.is_admin());
create policy "notices: admin update" on public.notices for update to authenticated using (public.is_admin());
create policy "notices: admin delete" on public.notices for delete to authenticated using (public.is_admin());

create policy "events: read" on public.events for select to authenticated using (true);
create policy "events: admin insert" on public.events for insert to authenticated with check (public.is_admin());
create policy "events: admin update" on public.events for update to authenticated using (public.is_admin());
create policy "events: admin delete" on public.events for delete to authenticated using (public.is_admin());

create policy "registrations: read" on public.event_registrations for select to authenticated using (true);
create policy "registrations: join" on public.event_registrations for insert to authenticated with check (user_id = auth.uid());
create policy "registrations: cancel own" on public.event_registrations for delete to authenticated using (user_id = auth.uid());

create policy "lost: read" on public.lost_found_items for select to authenticated using (true);
create policy "lost: insert own" on public.lost_found_items for insert to authenticated with check (user_id = auth.uid());
create policy "lost: update own" on public.lost_found_items for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "lost: delete own" on public.lost_found_items for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "resources: read" on public.study_resources for select to authenticated using (true);
create policy "resources: insert own" on public.study_resources for insert to authenticated with check (user_id = auth.uid());
create policy "resources: update own" on public.study_resources for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "resources: delete own" on public.study_resources for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "market: read" on public.marketplace_items for select to authenticated using (true);
create policy "market: insert own" on public.marketplace_items for insert to authenticated with check (user_id = auth.uid());
create policy "market: update own" on public.marketplace_items for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "market: delete own" on public.marketplace_items for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "complaints: read own or admin" on public.complaints for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy "complaints: insert own" on public.complaints for insert to authenticated
  with check (user_id = auth.uid() and status = 'Pending');
create policy "complaints: admin update" on public.complaints for update to authenticated
  using (public.is_admin());
create policy "complaints: admin delete" on public.complaints for delete to authenticated
  using (public.is_admin());

create policy "notifications: read own" on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "notifications: update own" on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('campus-files', 'campus-files', true)
on conflict (id) do nothing;

create policy "files: public read" on storage.objects for select
  using (bucket_id = 'campus-files');

create policy "files: upload to own folder" on storage.objects for insert to authenticated
  with check (bucket_id = 'campus-files' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "files: update own" on storage.objects for update to authenticated
  using (bucket_id = 'campus-files' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "files: delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'campus-files' and (storage.foldername(name))[1] = auth.uid()::text);

update public.profiles set role = 'admin' where email = 'jibonlu@gmail.com';