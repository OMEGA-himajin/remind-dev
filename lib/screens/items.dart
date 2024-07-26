import 'package:flutter/material.dart';
import 'package:remind_dev/controller/items_controller.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({Key? key}) : super(key: key);

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final ItemsController _controller = ItemsController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BLE Scanner')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Start Scan'),
              onPressed: _controller.startScan,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _controller.scanResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_controller.scanResults[index].device.name),
                    subtitle: Text(
                        _controller.scanResults[index].device.id.toString()),
                    trailing: ElevatedButton(
                      child: Text('Connect'),
                      onPressed: () => _controller.connectToDevice(
                          _controller.scanResults[index].device),
                    ),
                  );
                },
              ),
            ),
            if (_controller.connectedDevice != null)
              Text('Connected to: ${_controller.connectedDevice!.name}'),
            if (_controller.notifyValue.isNotEmpty)
              Text('Notify Value: ${_controller.notifyValue}'),
            if (_controller.statusMessage.isNotEmpty)
              Text(_controller.statusMessage),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPopup,
        child: Icon(Icons.add),
        tooltip: 'Add Item',
      ),
    );
  }

  void _showAddPopup() {
    String tagId = '';
    String name = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('持ち物追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'タグID'),
                onChanged: (value) {
                  tagId = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: '名前'),
                onChanged: (value) {
                  name = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  child: Text('追加'),
                  onPressed: () {
                    _controller.addItem(tagId, name);
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('閉じる'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
          ],
        );
      },
    );
  }
}
