import 'package:cloud_firestore/cloud_firestore.dart';

/// アイテムを表現するクラス。
class Item {
  String tagId;
  String name;
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
      inBag: map['inbag'] ?? false,
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

  /// `uid`と`tagId`に基づいてアイテムの情報を更新するメソッド。
  Future<void> updateItemDetails(
      String uid, String tagId, String name, bool inBag) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('items');
    await documentReference.update({
      '$tagId.name': name,
      '$tagId.inBag': inBag,
    });
  }

  /// 新しいアイテムを追加するメソッド。
  Future<void> addItem(String uid, Item item) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('items');
    await documentReference.set({
      item.tagId: {'name': item.name, 'inBag': item.inBag}
    }, SetOptions(merge: true));
  }

  /// `uid`と`tagId`に基づいてアイテムを削除するメソッド。
  Future<void> deleteItem(String uid, String tagId) async {
    DocumentReference documentReference =
        _firestore.collection(uid).doc('items');
    await documentReference.update({tagId: FieldValue.delete()});
  }
}
