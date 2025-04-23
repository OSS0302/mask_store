import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../component/store_item.dart';

class MaskStoreScreen extends StatefulWidget {
  const MaskStoreScreen({super.key});

  @override
  State<MaskStoreScreen> createState() => _MaskStoreScreenState();
}

class _MaskStoreScreenState extends State<MaskStoreScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _fabExpanded = false;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakStoreCount(int count) async {
    await _tts.setLanguage("ko-KR");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak("현재 ${count}개의 약국이 검색되었습니다.");
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MaskStoreViewModel>();
    final isDarkMode = viewModel.isDarkMode;
    final storeCount = viewModel.state.stores.length;

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        title: Text(
          '마스크 재고 약국 ($storeCount곳)',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, color: isDarkMode ? Colors.redAccent : Colors.red),
            onPressed: () => context.push("/favorites"),
          ),
          IconButton(
            icon: Icon(Icons.map, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => context.push("/mapViewScreen"),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => context.push("/settings"),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: viewModel.refreshStores,
            child: Column(
              children: [
                _buildSearchAndFilter(context, viewModel),
                const Divider(height: 1, thickness: 1, color: Colors.teal),
                Expanded(
                  child: viewModel.state.isLoading
                      ? _buildLoadingIndicator(isDarkMode)
                      : viewModel.state.stores.isEmpty
                      ? _buildNoResults(isDarkMode)
                      : _buildStoreList(viewModel, isDarkMode),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_fabExpanded) ...[
                  _fabMiniButton(
                    icon: Icons.refresh,
                    label: "새로고침",
                    onPressed: () => viewModel.refreshStores(),
                  ),
                  const SizedBox(height: 10),
                  _fabMiniButton(
                    icon: Icons.arrow_upward,
                    label: "맨 위로",
                    onPressed: () {
                      viewModel.scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _fabMiniButton(
                    icon: Icons.volume_up,
                    label: "음성 안내",
                    onPressed: () => _speakStoreCount(storeCount),
                  ),
                  const SizedBox(height: 10),
                  _fabMiniButton(
                    icon: Icons.map,
                    label: "지도 보기",
                    onPressed: () => context.push("/mapViewScreen"),
                  ),
                  const SizedBox(height: 10),
                ],
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _fabExpanded = !_fabExpanded;
                    });
                  },
                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.teal,
                  child: Icon(_fabExpanded ? Icons.close : Icons.menu),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fabMiniButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.extended(
      heroTag: label,
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: Colors.teal,
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, MaskStoreViewModel viewModel) {
    final isDarkMode = viewModel.isDarkMode;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: viewModel.filterStores,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade800.withOpacity(0.9) : Colors.white,
                    hintText: '약국 이름 검색',
                    hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.teal),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.filter_list, color: isDarkMode ? Colors.white : Colors.teal),
                onPressed: () => _showSortFilterBottomSheet(context, viewModel),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: isDarkMode ? Colors.white : Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    '지금 영업 중만 보기',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 16),
                  ),
                ],
              ),
              Switch(
                value: viewModel.showOpenNowOnly,
                onChanged: (value) => viewModel.toggleOpenNowOnly(),
                activeColor: Colors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreList(MaskStoreViewModel viewModel, bool isDarkMode) {
    return ListView.builder(
      controller: viewModel.scrollController,
      itemCount: viewModel.state.stores.length,
      itemBuilder: (context, index) {
        final store = viewModel.state.stores[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Card(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 12,
            shadowColor: Colors.black.withOpacity(0.4),
            child: StoreItem(maskStore: store),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: isDarkMode ? Colors.white : Colors.teal),
          const SizedBox(height: 16),
          Text(
            '데이터를 불러오는 중...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.teal.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(bool isDarkMode) {
    return Center(
      child: Text(
        '검색 결과가 없습니다.',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.grey.shade600),
      ),
    );
  }

  void _showSortFilterBottomSheet(BuildContext context, MaskStoreViewModel viewModel) {
    final isDarkMode = viewModel.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('거리 순', style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  viewModel.sortByDistance();
                  context.pop();
                },
              ),
              ListTile(
                title: Text('재고 순', style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  viewModel.sortByStock();
                  context.pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
