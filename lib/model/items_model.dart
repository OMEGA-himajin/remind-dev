import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String tagId;
  final String name;
  bool inBag;

  Item({required this.tagId, required this.name, this.inBag = false});

  Map<String, dynamic> toMap() {
    return {
      'tag_id': tagId,
      'name': name,
      'inbag': inBag,
    };
  }

  static Item fromMap(Map<String, dynamic> map) {
    return Item(
      tagId: map['tag_id'],
      name: map['name'],
      inBag: map['inbag'],
    );
  }
}

class ItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Item?> getItemByTagId(String tagId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('items')
        .where('tag_id', isEqualTo: tagId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Item.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateItemInBagStatus(String tagId, bool inBag) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('items')
        .where('tag_id', isEqualTo: tagId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String docId = querySnapshot.docs.first.id;
      await _firestore.collection('items').doc(docId).update({'inbag': inBag});
    }
  }

  Future<void> addItem(Item item) async {
    await _firestore.collection('items').add(item.toMap());
  }
}
