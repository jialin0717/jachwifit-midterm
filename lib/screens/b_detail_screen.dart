// 화면 B — 수납용품 상세.
// 번호 | Flutter 위젯명 | 비즈니스 명칭 | 원칙
// B-1 | AppBar + BackButton | 상품 상세 제목줄 | P03
// B-2 | TabBar + TabBarView | 상품 정보·사용 안내 탭 | P06
// B-3 | NetImage + Text | 상품 이미지·기본 정보 | P02
// B-4 | Wrap + Chip | 상품 조건 태그 | P06
// B-5 | OutlinedButton + SnackBar | 관심 상품 체험 버튼 | P01
// B-6 | FilledButton | AI 추천 예시 열기 | P07
// B-7 | FutureBuilder + 상태 위젯 + ListView | 사용 안내 목록 | P01·P05·P09
// A → B: push. B 내부: tab. B → C: modal.
// B-3은 URL이 비어 있으면 NetImage를 만들지 않고 자리표시자를 표시한다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'c_result_sheet.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.item,
    this.loadNotes = fetchNotes,
  });

  final Item item;
  final NotesLoader loadNotes;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(item.title), // B-1 P03
          bottom: const TabBar(
            tabs: [
              Tab(text: '상품 정보'),
              Tab(text: '사용 안내'),
            ],
          ), // B-2 P06
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _ProductInfo(item: item),
              _UsageNotes(itemId: item.id, load: loadNotes),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            const Text('상품 이미지 준비 중'),
          ],
        ),
      ),
    );

    // STATE: 관심 상품 여부 → B-5 버튼, A-2·A-3 카드 (현재 저장하지 않음)
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            child: item.image.trim().isEmpty
                ? placeholder
                : NetImage(item.image),
          ),
        ), // B-3 P02
        const SizedBox(height: 20),
        Text(
          item.title,
          style: theme.textTheme.headlineSmall,
        ), // B-3 P02
        const SizedBox(height: 12),
        Text(
          item.subtitle.replaceAll(' · ', '\n'),
          style: theme.textTheme.bodyLarge,
        ), // B-3 P02
        const SizedBox(height: 16),
        if (item.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final tag in item.tags) Chip(label: Text(tag)),
            ],
          ), // B-4 P06
        const SizedBox(height: 16),
        const Text(
          '가격과 치수는 UI 시연용 가상 값입니다. '
          'IKEA 실제 상품 정보가 아니며 구매 기능은 없습니다.',
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '관심 상품 기능 체험입니다. 실제로 저장하지 않습니다.',
                ),
              ),
            );
          },
          icon: const Icon(Icons.bookmark_border),
          label: const Text('관심 상품 체험'),
        ), // B-5 P01
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => ResultSheet.show(context, item),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('AI 추천 예시 보기'),
        ), // B-6 P07
      ],
    );
  }
}

class _UsageNotes extends StatefulWidget {
  const _UsageNotes({
    required this.itemId,
    required this.load,
  });

  final int itemId;
  final NotesLoader load;

  @override
  State<_UsageNotes> createState() => _UsageNotesState();
}

class _UsageNotesState extends State<_UsageNotes> {
  late Future<List<Note>> _future = widget.load(widget.itemId);

  void _retry() {
    setState(() {
      _future = widget.load(widget.itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Note>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(
            label: '사용 안내를 불러오는 중…',
          ); // B-7 P01
        }
        if (snap.hasError) {
          return ErrorView(
            title: '사용 안내를 불러오지 못했습니다.',
            message: '${snap.error}',
            onRetry: _retry,
          ); // B-7 P09
        }

        final notes = snap.data ?? const <Note>[];
        if (notes.isEmpty) {
          return const EmptyView(
            message: '등록된 사용 안내가 없습니다.\n'
                '상품 정보 탭에서 치수와 용도를 확인하세요.',
          ); // B-7 P01
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notes[i].text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '모의 안내 작성일: ${notes[i].date}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ); // B-7 P01 P05
      },
    );
  }
}