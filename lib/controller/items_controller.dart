import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:remind_dev/model/items_model.dart';

class ItemsController extends ChangeNotifier {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  String notifyValue = '';
  String statusMessage = '';

  final String targetDeviceName = "ubuntu";
  final String serviceUuid = "5ccc9918-c8a9-4f09-8c88-671375b3cf75";
  final String characteristicUuid = "c6f6bb69-2b85-47fb-993b-584440b6a785";

  final ItemRepository _itemRepository = ItemRepository();

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  void startScan() async {
    if (isScanning) return;

    isScanning = true;
    notifyListeners();

    scanResults.clear();

    try {
      // スキャン開始前に権限を確認
      if (!(await FlutterBluePlus.isAvailable)) {
        statusMessage = "Bluetooth is not available on this device";
        isScanning = false;
        notifyListeners();
        return;
      }

      await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        scanResults = results;
        notifyListeners();
      });

      await Future.delayed(Duration(seconds: 4));
    } catch (e) {
      statusMessage = "Error scanning: ${e.toString()}";
    } finally {
      await FlutterBluePlus.stopScan();
      isScanning = false;
      notifyListeners();
    }
  }

  void addItem(String tagId, String name) async {
    Item newItem = Item(tagId: tagId, name: name);
    await _itemRepository.addItem(newItem);
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
