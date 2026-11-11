import 'package:flutter/material.dart';

import '../../core/helpers.dart';
import '../home/home_screen.dart';
import '../profile/edit_profile_screen.dart';

Widget homeOrCompleteProfile() {
  if (AppState.profileIncomplete) {
    return const EditProfileScreen(forceComplete: true);
  }
  return const HomeScreen();
}