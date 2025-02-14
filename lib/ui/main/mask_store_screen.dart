import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_store/ui/main/mask_store_view_model.dart';
import 'package:provider/provider.dart';
import '../component/store_item.dart';

class MaskStoreScreen extends StatelessWidget {
  const MaskStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maskStoreViewModel = context.watch<MaskStoreViewModel>();
    final isDarkMode = maskStoreViewModel.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          '마스크 재고 있는 약국 ${maskStoreViewModel.state.stores.length}곳',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.map, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => context.push("/mapViewScreen"),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey.shade900]
                : [Colors.teal.shade100, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: maskStoreViewModel.state.isLoading
              ? _buildLoadingIndicator(isDarkMode)
              : Column(
            children: [
              _buildSearchAndFilter(context, maskStoreViewModel),
              const Divider(height: 1, thickness: 1, color: Colors.teal),
              Expanded(
                child: maskStoreViewModel.state.stores.isEmpty
                    ? _buildNoResults(isDarkMode)
                    : _buildStoreList(maskStoreViewModel, isDarkMode),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          maskStoreViewModel.scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        },
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.teal,
        child: Icon(Icons.arrow_upward, color: isDarkMode ? Colors.white : Colors.black),
      ),
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
            '로딩 중 입니다 잠시만 기다려 주세요',
            style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, MaskStoreViewModel viewModel) {
    final isDarkMode = viewModel.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.teal),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.filter_alt, color: isDarkMode ? Colors.white : Colors.teal),
            onPressed: () => _showSortFilterBottomSheet(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(bool isDarkMode) {
    return Center(
      child: Text(
        '검색 결과가 없습니다.',
        style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.grey.shade600),
      ),
    );
  }

  Widget _buildStoreList(MaskStoreViewModel viewModel, bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: viewModel.refreshStores,
      child: ListView.builder(
        controller: viewModel.scrollController,
        itemCount: viewModel.state.stores.length,
        itemBuilder: (context, index) {
          final store = viewModel.state.stores[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              color: isDarkMode ? Colors.grey.shade800.withOpacity(0.9) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.2),
              child: StoreItem(maskStore: store),
            ),
          );
        },
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
                title: Text('거리 순', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  viewModel.sortByDistance();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('재고 순', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                onTap: () {
                  viewModel.sortByStock();
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
