# Smart Campus (Flutter + Supabase)

All-in-one university student app: Lost & Found, Notice Board, Events, Study Resources,
Marketplace, Complaints & Feedback, Profile, Notifications. Beginner-level code (setState + Navigator).

## 1. Create the Flutter project and copy the files
```bash
flutter create smart_campus
cd smart_campus
```
Then copy from this folder into the new project (replace when asked):
- `lib/`  (whole folder)
- `pubspec.yaml`
- `analysis_options.yaml`
- `sql/`  (optional, for reference)

```bash
flutter pub get
```

## 2. Supabase setup
1. Create a project at https://supabase.com
2. Dashboard -> SQL Editor -> New query -> paste all of `sql/schema.sql` -> Run
   (creates tables, security rules, triggers and the `campus-files` storage bucket)
3. Dashboard -> Authentication -> Providers -> Email -> for easy demo, turn OFF "Confirm email"
4. Dashboard -> Project Settings -> API -> copy the **Project URL** and the **anon / publishable key**
5. Open `lib/core/app_config.dart` and paste them into `supabaseUrl` and `supabaseAnonKey`
   (NEVER use the service_role key in the app)
6. Optional: change `studentIdPattern` and `allowedEmailDomain` in the same file

## 3. Make an admin
Register one account in the app, then run in the SQL Editor:
```sql
update public.profiles set role = 'admin' where email = 'your-email@example.com';
```
Log out and log in again. Admin can: add/edit/delete notices and events, change complaint status,
delete any marketplace listing, resource or lost & found post.

## 4. Platform permissions
- Android: works by default (internet permission is already in the debug/main manifest).
  For `url_launcher` calling/opening links add inside `<manifest>` of `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <queries>
    <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
    <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
  </queries>
  ```
- iOS: add to `ios/Runner/Info.plist`:
  ```xml
  <key>NSPhotoLibraryUsageDescription</key><string>Choose pictures to upload</string>
  <key>LSApplicationQueriesSchemes</key><array><string>https</string><string>tel</string></array>
  ```

## 5. Run
```bash
flutter analyze
flutter run
```

## 6. Testing checklist
| Test | Expected |
|---|---|
| Register with bad email / weak password / wrong confirm | Red validation messages |
| Register with valid data | "Registration successful", then Login works |
| Login with wrong password | Error message |
| Forgot password | Reset email is sent |
| Lost & Found: create, edit, delete, mark recovered, search, filter | All work |
| Marketplace: create, edit, mark sold, delete, contact seller | All work |
| Study Resources: upload PDF, download, edit, delete | All work |
| Events: (admin) create; (student) Join / Cancel | Counter changes |
| Notices: student has no "Add Notice" button | Correct |
| Complaint: submit; admin changes status; student sees new status + notification | Works |
| Student tries to edit another student's post | Blocked by database (RLS) |

## 7. Defense demo guide (suggested order, ~10 minutes)
1. Splash -> Register (show validation) -> Login.
2. Dashboard: modules, events, notices, marketplace.
3. Lost & Found: post an item with a photo, search, mark recovered.
4. Marketplace: list a product, open it with a second account, "Contact Seller".
5. Study Resources: upload and download a PDF.
6. Complaint: submit as student.
7. Log in as admin: add a notice and an event, change the complaint status.
8. Student account: show the notification and the new status.
9. Show Supabase dashboard: tables, RLS policies, storage bucket. Explain that security is enforced in the database.

## Folder structure
```
lib/
  main.dart
  core/        app_config, app_theme, validators, helpers, widgets
  features/
    auth/ home/ lost_found/ notices/ events/
    study_resources/ marketplace/ complaints/ profile/
sql/schema.sql
```
