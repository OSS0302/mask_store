import 'package:flutter/material.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('다크 모드'),
            trailing: Switch(
              value: maskStoreViewModel.isDarkMode,
              onChanged: (value) {
                maskStoreViewModel.toggleDarkMode(); // 다크 모드 전환
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('알림 설정'),
            trailing: Switch(
              value: maskStoreViewModel.state.isNotificationsEnabled,
              onChanged: (value) {
                maskStoreViewModel.toggleNotifications(); // 알림 설정 토글
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('언어 설정'),
            subtitle: Text(maskStoreViewModel.state.currentLanguage),
            onTap: () {
              _showLanguageDialog(context, maskStoreViewModel);
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  // 언어 선택 다이얼로그
  void _showLanguageDialog(BuildContext context, MaskStoreViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('언어 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('한국어'),
                value: '한국어',
                groupValue: viewModel.state.currentLanguage,
                onChanged: (value) {
                  viewModel.changeLanguage(value!); // 언어 변경
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: viewModel.state.currentLanguage,
                onChanged: (value) {
                  viewModel.changeLanguage(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
