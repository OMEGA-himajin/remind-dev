import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  String notifyValue = '';

  final String targetDeviceName = "ubuntu"; // 探したいデバイスの名前
  final String serviceUuid =
      "5ccc9918-c8a9-4f09-8c88-671375b3cf75"; // 対象のサービスUUID
  final String characteristicUuid =
      "c6f6bb69-2b85-47fb-993b-584440b6a785"; // 対象のcharacteristicUUID

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() async {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults =
              results.where((r) => r.device.name == targetDeviceName).toList();
        });
      });
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
      });

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          var characteristics = service.characteristics;
          for (BluetoothCharacteristic c in characteristics) {
            if (c.uuid.toString() == characteristicUuid) {
              targetCharacteristic = c;
              setNotifyValue(true);
            }
          }
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void setNotifyValue(bool value) async {
    if (targetCharacteristic != null) {
      await targetCharacteristic!.setNotifyValue(value);
      targetCharacteristic!.value.listen((value) {
        setState(() {
          final asciiValue = ascii.decode(value);
          notifyValue = asciiValue;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isScanning
                ? CircularProgressIndicator()
                : ElevatedButton(
                    child: Text('Start Scan'),
                    onPressed: startScan,
                  ),
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(scanResults[index].device.name),
                    subtitle: Text(scanResults[index].device.id.toString()),
                    trailing: ElevatedButton(
                      child: Text('Connect'),
                      onPressed: () =>
                          connectToDevice(scanResults[index].device),
                    ),
                  );
                },
              ),
            ),
            if (connectedDevice != null)
              Text('Connected to: ${connectedDevice!.name}'),
            if (notifyValue.isNotEmpty) Text('Notify Value: $notifyValue'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
