import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main/mask_store_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 다크 모드 설정
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.dark_mode, color: Colors.teal),
                title: const Text('다크 모드', style: TextStyle(fontSize: 18)),
                trailing: Switch(
                  value: maskStoreViewModel.isDarkMode,
                  activeColor: Colors.teal,
                  onChanged: (value) {
                    maskStoreViewModel.toggleDarkMode();
                  },
                ),
              ),
            ),

            // 알림 설정
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.notifications, color: Colors.teal),
                title: const Text('알림 설정', style: TextStyle(fontSize: 18)),
                trailing: Switch(
                  value: maskStoreViewModel.isNotificationsEnabled,
                  activeColor: Colors.teal,
                  onChanged: (value) {
                    maskStoreViewModel.toggleNotifications();
                  },
                ),
              ),
            ),

            // 언어 설정
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.language, color: Colors.teal),
                title: const Text('언어 설정', style: TextStyle(fontSize: 18)),
                subtitle: Text(maskStoreViewModel.currentLanguage),
                onTap: () {
                  _showLanguageDialog(context, maskStoreViewModel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, MaskStoreViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('언어 선택', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                RadioListTile<String>(
                  title: const Text('한국어'),
                  value: '한국어',
                  groupValue: viewModel.currentLanguage,
                  onChanged: (value) {
                    viewModel.changeLanguage(value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'English',
                  groupValue: viewModel.currentLanguage,
                  onChanged: (value) {
                    viewModel.changeLanguage(value!);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('닫기', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
