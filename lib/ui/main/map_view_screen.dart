// 지도 화면을 위한 플레이스홀더
import 'package:flutter/material.dart';

class MapViewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 약국'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Text('지도는 여기에 표시됩니다.'),
      ),
    );
  }
}