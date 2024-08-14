import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  _ItemsScreenState createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final List<String> _items = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];
  late List<String> _filteredItems;
  late TextEditingController _searchController;
  List<BluetoothDevice> _devicesList = [];
  bool isConnected = false;
  Set<int> selected = {0};
  Map<String, Set<int>> itemSelections = {};

  @override
  void initState() {
    super.initState();
    _filteredItems = _items;
    _searchController = TextEditingController();
    _searchController.addListener(_filterItems);
    Map<String, Set<int>> itemSelections = {};
    // 初期状態でのアイテムの選択状態を設定
    for (var item in _items) {
      itemSelections[item] = {0};
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems =
          _items.where((item) => item.toLowerCase().contains(query)).toList();
    });
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

  void _showDeleteDialog(String item) {
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
              onPressed: () {
                setState(() {
                  _filteredItems.remove(item);
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

  void _onSelectionChanged(String item, Set<int> set) {
    setState(() {
      itemSelections[item] = set;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            title: Text(item),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<int> set) =>
                      _onSelectionChanged(item, set),
                  segments: [
                    ButtonSegment(
                        value: 0,
                        label: Icon(Icons.backpack, color: Colors.grey[700])),
                    ButtonSegment(
                        value: 1,
                        label:
                            Icon(Icons.no_backpack, color: Colors.grey[700])),
                  ],
                  selected: itemSelections[item] ?? {0},
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
                        return AlertDialog(
                          title: const Text('編集'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: TextEditingController(text: item),
                                onChanged: (value) {
                                  setState(() {
                                    _filteredItems[index] = value;
                                  });
                                },
                              ),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('アイテム名'),
                              ),
                              TextField(
                                controller: TextEditingController(text: item),
                                onChanged: (value) {
                                  setState(() {
                                    _filteredItems[index] = value;
                                  });
                                },
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
                              onPressed: () {
                                Navigator.of(context).pop();
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
