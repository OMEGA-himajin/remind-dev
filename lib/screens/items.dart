import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remind_dev/controller/items_controller.dart';

class ItemsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ItemsController(),
      child: _ItemsScreenContent(),
    );
  }
}

class _ItemsScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ItemsController>(context);

    return Scaffold(
      appBar: AppBar(title: Text('BLE Scanner')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text(controller.isScanning ? 'Scanning...' : 'Start Scan'),
              onPressed: controller.isScanning ? null : controller.startScan,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: controller.scanResults.length,
                itemBuilder: (context, index) {
                  final result = controller.scanResults[index];
                  return ListTile(
                    title: Text(result.device.name.isNotEmpty
                        ? result.device.name
                        : 'Unknown Device'),
                    subtitle: Text(result.device.id.toString()),
                    trailing: ElevatedButton(
                      child: Text('Connect'),
                      onPressed: () =>
                          controller.connectToDevice(result.device),
                    ),
                  );
                },
              ),
            ),
            if (controller.connectedDevice != null)
              Text('Connected to: ${controller.connectedDevice!.name}'),
            if (controller.notifyValue.isNotEmpty)
              Text('Notify Value: ${controller.notifyValue}'),
            if (controller.statusMessage.isNotEmpty)
              Text(controller.statusMessage),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPopup(context),
        child: Icon(Icons.add),
        tooltip: 'Add Item',
      ),
    );
  }

  void _showAddPopup(BuildContext context) {
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
                    Provider.of<ItemsController>(context, listen: false)
                        .addItem(tagId, name);
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
