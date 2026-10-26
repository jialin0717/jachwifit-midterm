// 자취핏 — GAI3008 중간고사 UI 프로토타입.
// S-1 MaterialApp: 자취핏 앱 이름.
// S-2 ThemeData: 공통 색상과 스타일 — P04 일관성과 표준.
// 화면 흐름: A 수납용품 목록 → B 수납용품 상세 → C AI 추천 예시.
// B 탭: 상품 정보 | 사용 안내. C는 미리 작성한 고정 예시만 표시한다.
import 'package:flutter/material.dart';

import 'screens/a_list_screen.dart';

void main() => runApp(const MidProjectApp());

class MidProjectApp extends StatelessWidget {
  const MidProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E6B57),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: '자취핏', // S-1
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF8FAF7),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          centerTitle: false,
        ),
      ), // S-2 P04
      home: const ListScreen(),
    );
  }
}