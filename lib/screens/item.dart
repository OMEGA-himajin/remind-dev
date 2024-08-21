import 'package:flutter/material.dart';
import '../model/firestore_items.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});
  @override
  _ItemsScreenState createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Item> _filteredItems = [];
  Map<Item, Set<int>> itemSelections = {};
  List<BluetoothDevice> _devicesList = [];
  bool isConnected = false;
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
        _filteredItems.add(Item(name: 'Unknown', tagId: tagId, inBag: false));
      });
    }
  }

  void _onSelectionChanged(Item item, Set<int> set) {
    if (mounted) {
      setState(() {
        item.inBag = set.contains(1);
      });
      _itemRepository.updateItemDetails(
          'U2m7Wvq2I6MTawagyrUgKlKzWzo1', item.tagId, item.name, item.inBag);
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

  void _startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _devicesList = results.map((r) => r.device).toList();
      });
    });
  }

  void _showBluetoothPopup() async {
    bool isBluetoothOn = await FlutterBluePlus.isOn;
    if (!isBluetoothOn) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bluetoothがオフです'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bluetooth_disabled,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text('Bluetoothをオンにしてください...'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      _startScan();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('リーダーと接続'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: _devicesList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_devicesList[index].name),
                    subtitle: Text(_devicesList[index].id.toString()),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await _devicesList[index].connect();
                        setState(() {
                          isConnected = true;
                        });
                        // サービスとキャラクタリスティックのUUIDを指定
                        final serviceUuid =
                            Guid('5ccc9918-c8a9-4f09-8c88-671375b3cf75');
                        final characteristicUuid =
                            Guid('c6f6bb69-2b85-47fb-993b-584440b6a785');

                        // サービスを取得
                        List<BluetoothService> services =
                            await _devicesList[index].discoverServices();
                        for (BluetoothService service in services) {
                          if (service.uuid == serviceUuid) {
                            for (BluetoothCharacteristic characteristic
                                in service.characteristics) {
                              if (characteristic.uuid == characteristicUuid) {
                                // 通知をオンにする
                                await characteristic.setNotifyValue(true);
                                characteristic.value.listen((value) {
                                  // 通知を受け取ったときの処理
                                  print('Received data: $value');
                                });
                              }
                            }
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('${_devicesList[index].name}に接続しました')),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Connect'),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showDeleteDialog(Item item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: Text('$item を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                await _itemRepository.deleteItem(
                    'U2m7Wvq2I6MTawagyrUgKlKzWzo1', item.tagId);
                setState(() {
                  _filteredItems.remove(item);
                  _items.remove(item);
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('削除'),
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
        title: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 8.0),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.bluetooth,
                color: isConnected ? Colors.green : Colors.grey,
              ),
              onPressed: _showBluetoothPopup,
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index]; // ここで item を定義
          return ListTile(
            title: Text(item.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<int> set) =>
                      _onSelectionChanged(item, set),
                  segments: [
                    ButtonSegment(
                        value: 1,
                        label: Icon(Icons.backpack, color: Colors.grey[700])),
                    ButtonSegment(
                        value: 0,
                        label:
                            Icon(Icons.no_backpack, color: Colors.grey[700])),
                  ],
                  selected: item.inBag ? {1} : {0},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        TextEditingController nameController =
                            TextEditingController(text: item.name);
                        TextEditingController tagIdController =
                            TextEditingController(text: item.tagId);

                        return AlertDialog(
                          title: const Text('編集'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: nameController,
                              ),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('アイテム名'),
                              ),
                              TextField(
                                controller: tagIdController,
                              ),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('タグID'),
                              ),
                              SizedBox(
                                width: 200,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showDeleteDialog(item);
                                  },
                                  child: const Text(
                                    '削除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              )
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
                              onPressed: () async {
                                // Firestoreの値を更新
                                await _itemRepository.updateItemDetails(
                                  'U2m7Wvq2I6MTawagyrUgKlKzWzo1', // UIDを適切に設定
                                  tagIdController.text,
                                  nameController.text,
                                  _filteredItems[index].inBag,
                                );
                                Navigator.of(context).pop();
                                setState(() {
                                  _filteredItems[index] = Item(
                                    tagId: tagIdController.text,
                                    name: nameController.text,
                                    inBag: _filteredItems[index].inBag,
                                  );
                                });
                              },
                              child: const Text('保存'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              // アイテムがタップされたときの処理
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$item tapped')),
              );
            },
          );
        },
      ),
    );
  }
}
