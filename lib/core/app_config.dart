import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static const String supabaseUrl = 'https://svbcuvxvkhtbycynzahc.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_W7pmki4FNKbCLeJtPU2tTg_rsYAbIOT';

  static const String universityName = 'Leading University';

  static const String studentIdPattern = r'^[0-9A-Za-z\-]{5,20}$';
  static const String studentIdHint = '5-20 letters, numbers or dashes';

  static const String allowedEmailDomain = '';

  static const String storageBucket = 'campus-files';

  static const List<String> departments = ['CSE', 'EEE', 'BBA', 'English', 'Law', 'Civil', 'Other'];

  static const Map<String, String> departmentNames = {
    'CSE': 'Computer Science & Engineering',
    'EEE': 'Electrical & Electronic Engineering',
    'BBA': 'Business Administration',
    'English': 'English',
    'Law': 'Law',
    'Civil': 'Civil Engineering',
    'Other': 'Other',
  };

  static String departmentName(String? code) {
    if (code == null || code.isEmpty) return '';
    return departmentNames[code] ?? code;
  }

  static const List<String> semesters = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];
  static const List<String> noticeCategories = ['Academic', 'Exam', 'Event', 'General'];
  static const List<String> lostCategories = ['Wallet', 'ID Card', 'Electronics', 'Bag', 'Other'];
  static const List<String> resourceCategories = ['Notes', 'Books', 'Previous Q', 'Other'];
  static const List<String> marketCategories = ['Books', 'Electronics', 'Accessories', 'Stationery', 'Other'];
  static const List<String> complaintCategories = ['Facilities', 'Academic', 'Administration', 'Transport', 'Other'];
  static const List<String> complaintStatuses = ['Pending', 'In Progress', 'Resolved', 'Rejected'];
}

final supabase = Supabase.instance.client;