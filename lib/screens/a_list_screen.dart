// 화면 A — 수납용품 목록. GET /items만 사용한다.
// 번호 | Flutter 위젯명 | 비즈니스 명칭 | 원칙
// A-1 | AppBar | 자취핏 제목줄 | P04
// A-2 | ListView + Card + InkWell | 수납용품 카드 목록 | P02·P08
// A-3 | GridView + Card | 수납용품 카드 격자 | P04·P08
// A-4 | LoadingView | 상품 불러오는 중 표시 | P01
// A-5 | ErrorView + FilledButton | 상품 오류 안내·다시 시도 | P09
// A-6 | EmptyView | 빈 상품 목록 안내 | P01
// A → B: Navigator.push. 가용 너비 600dp 이상: 격자.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';

const wideBreakpoint = 600.0;

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    this.load = fetchItems,
    this.loadNotes = fetchNotes,
  });

  final ItemsLoader load;
  final NotesLoader loadNotes;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late Future<List<Item>> _future = widget.load();

  // STATE: 공간·예산 조건 → A-2·A-3 상품 목록, C-3 추천 목록 (현재 미구현)
  // STATE: 관심 상품 여부 → A-2·A-3 카드 (현재 저장하지 않음)

  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  void _open(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(
          item: item,
          loadNotes: widget.loadNotes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자취핏')), // A-1 P04
      body: SafeArea(
        child: FutureBuilder<List<Item>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingView(
                label: '목록을 불러오는 중…',
              ); // A-4 P01
            }
            if (snap.hasError) {
              return ErrorView(
                title: '목록을 불러오지 못했습니다.',
                message: '${snap.error}',
                onRetry: _retry,
              ); // A-5 P09
            }

            final items = snap.data ?? const <Item>[];
            if (items.isEmpty) {
              return const EmptyView(
                message: '아직 등록된 항목이 없습니다.',
              ); // A-6 P01
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= wideBreakpoint) {
                  // 실제 글 높이를 측정해 긴 상품 정보도 모두 표시한다.
                  final columns = (constraints.maxWidth / 360).ceil();
                  final cardWidth =
                      (constraints.maxWidth - 32 - 16 * (columns - 1)) /
                      columns;
                  final text = Theme.of(context).textTheme;
                  var contentHeight = 0.0;

                  for (final item in items) {
                    final height =
                        _textHeight(
                          context,
                          item.title,
                          text.titleMedium!,
                          cardWidth - 32,
                        ) +
                        _textHeight(
                          context,
                          _description(item),
                          text.bodyMedium!,
                          cardWidth - 32,
                        );
                    if (height > contentHeight) {
                      contentHeight = height;
                    }
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 120 + 32 + 8 + contentHeight + 16,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, i) => StorageProductCard(
                      items[i],
                      onTap: () => _open(items[i]),
                    ),
                  ); // A-3 P04 P08
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => StorageProductCard(
                    items[i],
                    onTap: () => _open(items[i]),
                  ),
                ); // A-2 P02 P08
              },
            );
          },
        ),
      ),
    );
  }
}

String _description(Item item) =>
    item.subtitle.replaceAll(' · ', '\n');

double _textHeight(
  BuildContext context,
  String value,
  TextStyle style,
  double width,
) {
  final painter = TextPainter(
    text: TextSpan(text: value, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: width);
  final height = painter.height.ceilToDouble();
  painter.dispose();
  return height;
}

class StorageProductCard extends StatelessWidget {
  const StorageProductCard(
    this.item, {
    super.key,
    required this.onTap,
  });

  final Item item;
  final VoidCallback onTap;

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
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            const Text('상품 이미지 준비 중'),
          ],
        ),
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 120,
              child: item.image.trim().isEmpty
                  ? placeholder
                  : Image.network(
                      item.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => placeholder,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _description(item),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}