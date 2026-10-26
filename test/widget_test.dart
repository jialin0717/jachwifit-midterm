// 실제 db.json 형식을 읽되 이미지 URL은 비워 네트워크 없이 UI를 검사한다.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mid_project_template/api.dart';
import 'package:mid_project_template/models.dart';
import 'package:mid_project_template/screens/a_list_screen.dart';
import 'package:mid_project_template/screens/b_detail_screen.dart';
import 'package:mid_project_template/screens/c_result_sheet.dart';

late List<Item> _items;
late List<Note> _notes;

Future<List<Note>> _noNotes(int _) async => const [];

Widget _app(
  ItemsLoader load, {
  NotesLoader loadNotes = _noNotes,
}) =>
    _shell(ListScreen(load: load, loadNotes: loadNotes));

Widget _shell(Widget home) => MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E6B57),
    ),
  ),
  home: home,
);

void _setSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() {
    final db =
        jsonDecode(File('mock_server/db.json').readAsStringSync())
            as Map<String, dynamic>;
    final rows = (db['items'] as List).cast<Map<String, dynamic>>();
    final noteRows =
        (db['notes'] as List).cast<Map<String, dynamic>>();

    expect(rows, isNotEmpty);
    expect(noteRows, isNotEmpty);

    _items = rows.map((row) {
      expect(
        Item.fromJson(row),
        isNotNull,
        reason: 'db.json 상품 형식이 Item 모델과 맞아야 합니다.',
      );
      return Item.fromJson({...row, 'image': ''})!;
    }).toList();

    _notes = noteRows.map((row) {
      final note = Note.fromJson(row);
      expect(
        note,
        isNotNull,
        reason: 'db.json 안내 형식이 Note 모델과 맞아야 합니다.',
      );
      expect(
        _items.any((item) => item.id == note!.itemId),
        isTrue,
      );
      return note!;
    }).toList();
  });

  testWidgets('목록: 로딩 → 오류 → 다시 시도 → 성공', (tester) async {
    _setSize(tester, const Size(400, 800));
    final pending = Completer<List<Item>>();
    var calls = 0;

    await tester.pumpWidget(
      _app(
        () => ++calls == 1
            ? pending.future
            : Future.value(_items),
      ),
    );

    expect(find.text('목록을 불러오는 중…'), findsOneWidget);
    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
    );

    pending.completeError(const ApiException('테스트 연결 오류'));
    await tester.pumpAndSettle();

    expect(
      find.text('목록을 불러오지 못했습니다.'),
      findsOneWidget,
    );
    expect(find.text('테스트 연결 오류'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text(_items.first.title), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('목록: 빈 상태', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(() async => const []));
    await tester.pumpAndSettle();

    expect(
      find.text('아직 등록된 항목이 없습니다.'),
      findsOneWidget,
    );
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('push·모의 관심 상품·추천 modal·tab·pop', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(() async => _items));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_items.first.title));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('상품 정보'), findsOneWidget);

    final favorite = find.widgetWithText(
      OutlinedButton,
      '관심 상품 체험',
    );
    await tester.ensureVisible(favorite);
    await tester.pumpAndSettle();
    await tester.tap(favorite);
    await tester.pumpAndSettle();

    expect(
      find.text('관심 상품 기능 체험입니다. 실제로 저장하지 않습니다.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final recommend = find.widgetWithText(
      FilledButton,
      'AI 추천 예시 보기',
    );
    await tester.ensureVisible(recommend);
    await tester.pumpAndSettle();
    await tester.tap(recommend);
    await tester.pumpAndSettle();

    final sheet = find.byType(ResultSheet);
    expect(sheet, findsOneWidget);

    expect(
      find.descendant(
        of: sheet,
        matching: find.text('선택한 상품: ${_items.first.title}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byType(ListTile),
      ),
      findsNWidgets(3),
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.textContaining(
          '실제 AI 분석이나 추천 계산은 하지 않습니다.',
        ),
      ),
      findsOneWidget,
    );

    final close = find.descendant(
      of: sheet,
      matching: find.text('닫기'),
    );
    await tester.ensureVisible(close);
    await tester.pumpAndSettle();
    await tester.tap(close);
    await tester.pumpAndSettle();

    expect(find.byType(ResultSheet), findsNothing);

    await tester.tap(find.text('사용 안내'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '등록된 사용 안내가 없습니다.\n'
        '상품 정보 탭에서 치수와 용도를 확인하세요.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsNothing);
    expect(find.text('자취핏'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('사용 안내: 로딩 → 오류 → 재시도 → 모의 안내', (tester) async {
    _setSize(tester, const Size(400, 800));

    final item = _items.firstWhere(
      (item) => item.id == _notes.first.itemId,
    );
    final notes = _notes
        .where((note) => note.itemId == item.id)
        .toList();
    final pending = Completer<List<Note>>();
    var calls = 0;

    await tester.pumpWidget(
      _shell(
        DetailScreen(
          item: item,
          loadNotes: (id) {
            expect(id, item.id);
            return ++calls == 1
                ? pending.future
                : Future.value(notes);
          },
        ),
      ),
    );

    await tester.tap(find.text('사용 안내'));

    // 첫 프레임에서 탭/PageView 애니메이션을 시작한다.
    await tester.pump();

    final controller = DefaultTabController.of(
      tester.element(find.byType(TabBar)),
    );

    // 로딩 인디케이터는 계속 회전하므로 pumpAndSettle을 사용하지 않는다.
    for (
      var frame = 0;
      frame < 60 && controller.indexIsChanging;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(controller.index, 1);
    expect(
      controller.indexIsChanging,
      isFalse,
      reason: '사용 안내 탭 전환이 제한된 프레임 안에 끝나야 합니다.',
    );

    // 애니메이션 완료 뒤 페이지와 FutureBuilder의 예약 프레임을 반영한다.
    await tester.pump();
    await tester.pump();

    expect(calls, 1);
    expect(
      find.text('사용 안내를 불러오는 중…'),
      findsOneWidget,
    );
    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
    );

    pending.completeError(const ApiException('테스트 안내 오류'));
    await tester.pumpAndSettle();

    expect(
      find.text('사용 안내를 불러오지 못했습니다.'),
      findsOneWidget,
    );

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text(notes.first.text), findsOneWidget);
    expect(
      find.text('모의 안내 작성일: ${notes.first.date}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [599.0, 600.0, 1024.0]) {
    testWidgets('적응형: 너비 $width dp', (tester) async {
      _setSize(tester, Size(width, 900));
      await tester.pumpWidget(_app(() async => _items));
      await tester.pumpAndSettle();

      expect(
        find.byType(GridView),
        width >= 600 ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(ListView),
        width < 600 ? findsOneWidget : findsNothing,
      );
      expect(find.text(_items.first.title), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}