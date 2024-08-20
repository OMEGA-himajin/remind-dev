import 'package:flutter/material.dart';
import '../model/firestore_items.dart';

class Item {
  String name;
  String tagID;
  bool inBag;

  Item({required this.name, required this.tagID, required this.inBag});
  factory Item.fromMap(Map<String, dynamic> data) {
    return Item(
      name: data['name'] ?? 'Unknown',
      tagID: data['tagID'] ?? '',
      inBag: data['inBag'] ?? false, // デフォルト値を設定
    );
  }
}

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({Key? key}) : super(key: key);
  @override
  _ItemsScreenState createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Item> _filteredItems = [];
  Map<Item, Set<int>> itemSelections = {};
  final List<Item> _items = []; // 全アイテムのリスト
  final ItemRepository _itemRepository = ItemRepository(); // アイテムリポジトリのインスタンス

  @override
  void dispose() {
    _searchController.removeListener(_filterItems);
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        return item.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterItems);
    _filteredItems = List.from(_items); // 初期状態では全アイテムを表示
    _getItems(); // アイテムを取得するメソッドを呼び出す
  }

  void _addItem(String tagId) {
    if (mounted) {
      setState(() {
        _filteredItems.add(Item(name: 'Unknown', tagID: tagId, inBag: false));
      });
    }
  }

  void _onSelectionChanged(Item item, Set<int> set) {
    if (mounted) {
      setState(() {
        item.inBag = set.contains(1);
      });
    }
  }

  Future<void> _getItems() async {
    List<Item> items =
        (await _itemRepository.getAllItems('U2m7Wvq2I6MTawagyrUgKlKzWzo1'))
            .cast<Item>(); // UIDを適切に設定してください
    if (mounted) {
      setState(() {
        _items.addAll(items);
        _filteredItems = List.from(_items);
      });
    }
    print(items);
  }

  void _showEditDialog(Item item, int index) {
    TextEditingController _nameController =
        TextEditingController(text: item.name);
    TextEditingController _tagIDController =
        TextEditingController(text: item.tagID);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('アイテム名'),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter item name',
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('タグID'),
              ),
              TextField(
                controller: _tagIDController,
                decoration: const InputDecoration(
                  hintText: 'Enter tag ID',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filteredItems.removeAt(index);
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '削除',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filteredItems[index] = Item(
                    tagID: _tagIDController.text,
                    name: _nameController.text,
                    inBag: item.inBag,
                  );
                });
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Tag ID: ${item.tagID}'),
                  trailing: Icon(
                    item.inBag
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: TextField(
//           controller: _searchController,
//           decoration: const InputDecoration(
//             hintText: 'Search...',
//             border: InputBorder.none,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               Icons.bluetooth,
//               color: Colors.green,
//             ),
//             onPressed: () {
//               String tagId = "hello";
//               setState(() {
//                 _addItem(tagId);
//               });
//             },
//           ),
//         ],
//       ),
//       body: ListView.builder(
//         itemCount: _filteredItems.length,
//         itemBuilder: (context, index) {
//           final item = _filteredItems[index];
//           return ListTile(
//             title: Text(item.name),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 SegmentedButton<int>(
//                   showSelectedIcon: false,
//                   onSelectionChanged: (Set<int> set) =>
//                       _onSelectionChanged(item, set),
//                   segments: [
//                     ButtonSegment(
//                         value: 0,
//                         label: Icon(Icons.backpack, color: Colors.grey[700])),
//                     ButtonSegment(
//                         value: 1,
//                         label:
//                             Icon(Icons.no_backpack, color: Colors.grey[700])),
//                   ],
//                   selected: itemSelections[item] ?? {item.inBag ? 1 : 0},
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.edit),
//                   onPressed: () {
//                     _showEditDialog(item, index);
//                   },
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
