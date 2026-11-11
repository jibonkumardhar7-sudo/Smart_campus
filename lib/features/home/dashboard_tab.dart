import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/helpers.dart';
import '../../core/widgets.dart';
import '../complaints/complaints_screen.dart';
import '../events/event_detail_screen.dart';
import '../events/events_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../marketplace/marketplace_detail_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../notices/notice_detail_screen.dart';
import '../notices/notices_screen.dart';
import '../profile/notifications_screen.dart';
import '../study_resources/resources_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notices = await supabase.from('notices').select().order('created_at', ascending: false).limit(3);
      final events = await supabase
          .from('events')
          .select()
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date', ascending: true)
          .limit(3);
      final items = await supabase
          .from('marketplace_items')
          .select('*, profiles(full_name, phone, email)')
          .eq('status', 'available')
          .order('created_at', ascending: false)
          .limit(3);
      _notices = List<Map<String, dynamic>>.from(notices);
      _events = List<Map<String, dynamic>>.from(events);
      _items = List<Map<String, dynamic>>.from(items);
    } catch (e) {
      _error = 'Could not load data. Check your internet.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _universityCard() {
    final dept = AppConfig.departmentName(AppState.profile?['department']?.toString());
    final subtitle = AppState.isAdmin ? 'Administration Office' : (dept.isEmpty ? 'Student' : dept);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.universityName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (AppState.profile?['full_name'] ?? 'Student').toString();
    final avatar = AppState.profile?['avatar_url'] as String?;

    final modules = [
      _Module('Notice Board', Icons.campaign, Colors.purple, const NoticesScreen()),
      _Module('Lost & Found', Icons.inventory_2, Colors.orange, const LostFoundScreen()),
      _Module('Events', Icons.event, Colors.red, const EventsScreen()),
      _Module('Study Resources', Icons.menu_book, Colors.teal, const ResourcesScreen()),
      _Module('Marketplace', Icons.shopping_cart, Colors.green, const MarketplaceScreen()),
      _Module('Complaints', Icons.feedback, Colors.deepOrange, const ComplaintsScreen()),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                child: (avatar == null || avatar.isEmpty) ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, $name', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('ID: ${AppState.profile?['student_id'] ?? ''}',
                        style: const TextStyle(color: AppColors.textLight)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => openPage(context, const NotificationsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _universityCard(),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: modules.map((m) {
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => openPage(context, m.page, onBack: _load),
                child: Container(
                  decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.icon, color: m.color, size: 34),
                      const SizedBox(height: 8),
                      Text(m.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: LoadingView()),
          if (_error != null) EmptyView(message: _error!, onRetry: _load),
          if (!_loading && _error == null) ...[
            _sectionTitle('Upcoming Events'),
            if (_events.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('No upcoming events')),
            ..._events.map((e) => _card(
                  leading: NetworkThumb(url: e['image_url'], icon: Icons.event),
                  title: e['title'],
                  subtitle: '${formatDateTime(e['event_date'])}\n${e['location'] ?? ''}',
                  onTap: () => openPage(context, EventDetailScreen(event: e), onBack: _load),
                )),
            _sectionTitle('Latest Notices'),
            if (_notices.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('No notices yet')),
            ..._notices.map((n) => _card(
                  leading: const CircleAvatar(child: Icon(Icons.campaign)),
                  title: n['title'],
                  subtitle: '${n['category']} • ${formatDate(n['created_at'])}',
                  onTap: () => openPage(context, NoticeDetailScreen(notice: n), onBack: _load),
                )),
            _sectionTitle('Recent Marketplace Items'),
            if (_items.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('No items yet')),
            ..._items.map((i) => _card(
                  leading: NetworkThumb(url: i['image_url'], icon: Icons.shopping_bag),
                  title: i['title'],
                  subtitle: '৳ ${i['price']} • ${i['category']}',
                  onTap: () => openPage(context, MarketplaceDetailScreen(item: i), onBack: _load),
                )),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _card({required Widget leading, required String title, required String subtitle, required VoidCallback onTap}) {
    return ItemCard(
      margin: const EdgeInsets.symmetric(vertical: 5),
      leading: leading,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class _Module {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  _Module(this.title, this.icon, this.color, this.page);
}