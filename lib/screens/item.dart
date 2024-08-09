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

  @override
  void initState() {
    super.initState();
    _filteredItems = _items;
    _searchController = TextEditingController();
    _searchController.addListener(_filterItems);
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
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
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
          return ListTile(
            title: Text(_filteredItems[index]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    // 編集アイコンがタップされたときの処理
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () {
                    _showDeleteDialog(_filteredItems[index]);
                  },
                ),
              ],
            ),
            onTap: () {
              // アイテムがタップされたときの処理
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${_filteredItems[index]} tapped')),
              );
            },
          );
        },
      ),
    );
  }
}
