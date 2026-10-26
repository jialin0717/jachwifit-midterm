// 데이터 모양 — db.json의 한 항목을 화면이 쓰기 좋은 객체로 바꾼다.
// 형식이 틀린 항목은 null을 돌려준다 → 목록에서 빠질 뿐 앱이 멈추지 않는다 (Dart 3 패턴 매칭).
//
// TODO: Item / Note를 내 앱의 비즈니스 명칭으로 바꾼다 (예: Item → Product, Note → Review).
//           필드 이름은 db.json의 키와 같아야 한다.

class Item {
  const Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    this.tags = const [],
  });

  final int id;
  final String title;
  final String subtitle;
  final String image;
  final List<String> tags;

  /// Dart 3 패턴 예: 맵 모양이 맞으면 꺼내고(구조 분해), 아니면 null.
  static Item? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'title': String title,
        'subtitle': String subtitle,
        'image': String image,
      } =>
        Item(
          id: id,
          title: title,
          subtitle: subtitle,
          image: image,
          // 있어도 되고 없어도 되는 필드: 모양이 다르면 빈 목록
          tags: switch (json['tags']) {
            List<Object?> t => t.whereType<String>().toList(),
            _ => const [],
          },
        ),
      _ => null,
    };
  }
}

class Note {
  const Note({
    required this.id,
    required this.itemId,
    required this.text,
    required this.date,
  });

  final int id;
  final int itemId;
  final String text;
  final String date;

  static Note? fromJson(Object? json) {
    return switch (json) {
      {
        'id': int id,
        'itemId': int itemId,
        'text': String text,
        'date': String date,
      } =>
        Note(id: id, itemId: itemId, text: text, date: date),
      _ => null,
    };
  }
}
