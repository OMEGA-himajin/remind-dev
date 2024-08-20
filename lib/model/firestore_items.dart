import 'package:cloud_firestore/cloud_firestore.dart';

/// アイテムを表現するクラス。
class Item {
  final String tagId;
  final String name;
  bool inBag;

  Item({required this.tagId, required this.name, this.inBag = false});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inbag': inBag,
    };
  }

  static Item fromMap(String tagId, Map<String, dynamic> map) {
    return Item(
      tagId: tagId,
      name: map['name'],
      inBag: map['inbag'],
    );
  }
}

/// Firestoreを利用してアイテムを管理するリポジトリクラス。
class ItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// `uid`に基づいてすべてのアイテムを取得するメソッド。
  Future<List<Item>> getAllItems(String uid) async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(uid).doc('items').get();
    List<Item> items = [];
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      data.forEach((tagId, itemData) {
        items.add(Item.fromMap(tagId, itemData as Map<String, dynamic>));
      });
    }
    return items;
  }

  /// `uid`と`tagId`に基づいてアイテムの`inBag`ステータスを更新するメソッド。
  Future<void> updateItemInBagStatus(
      String uid, String tagId, bool inBag) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('items');
    await documentReference.set({
      tagId: {'inBag': inBag}
    }, SetOptions(merge: true));
  }

  /// 新しいアイテムを追加するメソッド。
  Future<void> addItem(String uid, Item item) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('items');
    await documentReference.set({
      item.tagId: {'name': item.name, 'inBag': item.inBag}
    }, SetOptions(merge: true));
  }
}
