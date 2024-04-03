import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:image/image.dart' as IMG;
import 'apputil/util.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UsbPort? _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  List<Widget> _serialData = [];

  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;
  UsbDevice? _device;

  Future<bool> _connectTo(device) async {
    _serialData.clear();

    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction!.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port!.close();
      _port = null;
    }

    if (device == null) {
      _device = null;
      setState(() {
        _status = "Disconnected";
      });
      return true;
    }

    _port = await device.create();
    if (await (_port!.open()) != true) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }
    _device = device;

    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Transaction.stringTerminated(
        _port!.inputStream as Stream<Uint8List>, Uint8List.fromList([13, 10]));

    _subscription = _transaction!.stream.listen((String line) {
      setState(() {
        _serialData.add(Text(line));
        if (_serialData.length > 20) {
          _serialData.removeAt(0);
        }
      });
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  void _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (!devices.contains(_device)) {
      _connectTo(null);
    }
    print(devices);

    devices.forEach((device) {
      _ports.add(ListTile(
          leading: Icon(Icons.usb),
          title: Text(device.productName!),
          subtitle: Text(device.manufacturerName!),
          trailing: ElevatedButton(
            child: Text(_device == device ? "Disconnect" : "Connect"),
            onPressed: () {
              _connectTo(_device == device ? null : device).then((res) {
                _getPorts();
              });
            },
          )));
    });

    setState(() {
      print(_ports);
    });
  }

  @override
  void initState() {
    super.initState();

    UsbSerial.usbEventStream!.listen((UsbEvent event) {
      _getPorts();
    });

    _getPorts();
  }

  @override
  void dispose() {
    super.dispose();
    _connectTo(null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('3.5 inch QR Display'),
          ),
          body: Center(
              child: Column(children: <Widget>[
            Text(
                _ports.length > 0
                    ? "Available Serial Ports"
                    : "No serial devices available",
                style: Theme.of(context).textTheme.titleLarge),
            ..._ports,
            Text('Status: $_status\n'),
            Text('info: ${_port.toString()}\n'),
            ElevatedButton(
              child: Text('Welcome'),
              onPressed: () {
                onWelcome();
              },
            ),
            // Image.memory(widget.imageData),
            Text("Result Data", style: Theme.of(context).textTheme.titleLarge),
            ..._serialData,
          ])),
        ));
  }

  Future<void> onWelcome() async {
    print("status:  $_status");
    if (_status == 'Connected') {
      try {
        // Load image
        Uint8List imageData =
            await loadAsset(context, 'assets/images/home.bmp');
        IMG.Image? img = IMG.decodeBmp(imageData);
        IMG.Image resized = IMG.copyResize(img!, width: 320, height: 480);
        // Uint8List resizedImg = Uint8List.fromList(IMG.encodeBmp(resized));
        _port!.write(toBmp16(resized));
      } on Exception catch (e) {
        print('Exception: $e');
      }
    } else {
      showToast('Device not connected');
    }
  }

  Uint8List toBmp16(IMG.Image image) {
    Uint8List numArray = Uint8List(0);
    try {
      int width = image.width;
      int height = image.height;
      numArray = Uint8List(width * height * 2);
      int num2 = 0;
      for (int i = height - 1; i >= 0; i--) {
        for (int j = 0; j < width; j++) {
          int pixel = image.getPixel(j, i); // Note: Flipped 'i'
          int r = (IMG.getRed(pixel) >> 3) & 31;
          int g = (IMG.getGreen(pixel) >> 2) & 63;
          int b = (IMG.getBlue(pixel) >> 3) & 31;
          int num3 = (r << 11);
          int num1 = (g << 5);
          int num = (num3 | num1 | b);
          numArray[num2] = (num >> 8) & 0xFF;
          numArray[num2 + 1] = num & 0xFF;
          num2 += 2;
        }
      }
    } catch (e) {
      print('Exception: $e');
    }
    print('numArray: ${numArray.length}');
    return numArray;
  }

  Future<Uint8List> loadAsset(BuildContext context, String assetName) async {
    ByteData data = await DefaultAssetBundle.of(context).load(assetName);
    return data.buffer.asUint8List();
  }
}
