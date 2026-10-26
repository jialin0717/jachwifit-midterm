// 화면 C — AI 추천 예시. 실제 AI·추천 계산·네트워크 요청 없음.
// 번호 | Flutter 위젯명 | 비즈니스 명칭 | 원칙
// C-1 | showModalBottomSheet + TextButton | AI 추천 예시 시트·닫기 | P03
// C-2 | Text | 추천 예시 안내 | P01
// C-3 | ListTile × 3 | 미리 작성한 추천 목록 | P06
// C-4 | Text | 예시 결과 고지 | P10
// B → C: 덮기(modal). 닫기: Navigator.pop.
import 'package:flutter/material.dart';

import '../models.dart';

// STATE: 개인화 추천 결과 → C-3 추천 목록 (현재 고정 예시만 표시)
const _presetResults = [
  (
    title: '슬림 틈새 선반 (모의 상품)',
    details: '12,000원 · 가로 20 × 깊이 30 × 높이 70cm',
    reason: '좁은 틈새 수납을 설명하는 예시입니다.',
  ),
  (
    title: '책상 아래 수납함 (모의 상품)',
    details: '8,000원 · 가로 28 × 깊이 35 × 높이 18cm',
    reason: '적은 예산으로 작은 물건을 정리하는 상황의 예시입니다.',
  ),
  (
    title: '이동식 수납 카트 (모의 상품)',
    details: '29,000원 · 가로 35 × 깊이 40 × 높이 75cm',
    reason: '생활용품을 옮기며 사용하는 수납을 설명하는 예시입니다.',
  ),
];

class ResultSheet extends StatelessWidget {
  const ResultSheet({super.key, required this.baseItem});

  final Item baseItem;

  static Future<void> show(BuildContext context, Item item) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ResultSheet(baseItem: item),
    ); // C-1 P03
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'AI 추천 예시',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '선택한 상품: ${baseItem.title}',
              style: theme.textTheme.titleMedium,
            ), // C-2 P01
            const SizedBox(height: 8),
            const Text(
              '어떤 상품에서 열어도 아래의 같은 세 예시를 보여 줍니다. '
              '선택 상품이나 사용자 조건을 분석한 결과가 아닙니다.',
            ), // C-2 P01
            const SizedBox(height: 16),
            for (final result in _presetResults) ...[
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(result.title),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${result.details}\n${result.reason}',
                    ),
                  ),
                ),
              ), // C-3 P06
              const SizedBox(height: 12),
            ],
            Text(
              '미리 작성한 예시입니다. 실제 AI 분석이나 추천 계산은 하지 않습니다. '
              '가격과 치수는 UI 시연용 가상 값이며 IKEA 실제 상품 정보가 아닙니다.',
              style: theme.textTheme.bodyMedium,
            ), // C-4 P10
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ), // C-1 P03
          ],
        ),
      ),
    );
  }
}