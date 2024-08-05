import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:image/image.dart' as IMG;
import 'apputil/util.dart';
import 'dart:convert'show utf8;
import 'dart:typed_data';


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
  TextEditingController _textController = TextEditingController();

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
        // _serialData.add(Text(line));
        // if (_serialData.length > 20) {
        //   _serialData.removeAt(0);
        // }
      });
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  void _getPorts() async {
    print("_getPorts called");

    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    print("devices id : ${devices.first.deviceId}");
    print("devices name: ${devices.first.deviceName}");
    print("devices port: ${devices.first.port}");
    print("devices vid: ${devices.first.vid}");
    print("devices pid: ${devices.first.pid}");

    // if (!devices.contains(_device)) {
    //   print("in iffffffffff");
    //
    //   _connectTo(null);
    // }
    print("device all details $devices");

    devices.forEach((device) {
      _ports.add(ListTile(
          leading: Icon(Icons.usb),
          title: Text(device.deviceName!),
          subtitle: Text(device.deviceName!),
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
            ElevatedButton(
              child: Text('Show QR'),
              onPressed: () {
                onShowQR();
              },
            ),
            ElevatedButton(
              child: Text('Success'),
              onPressed: () {
                onSuccess();
              },
            ),
            ElevatedButton(
              child: Text('Fail'),
              onPressed: () {
                onFail();
              },
            ),
            ElevatedButton(
              child: Text('Pending'),
              onPressed: () {
                onPending();
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
      if (_port == null) {
        print('Port is not initialized');
      }else{
        print('Port is  initialized');
      }
      try {
        Uint8List data = stringToUint8ListUtf8('WelcomeScreen**\n');
        print('Data to be sent: $data');
        _port!.write(data);
        print('data sent.');
      } on Exception catch (e) {
        print('Exception: $e');
      }
    } else {
      showToast('Device not connected');
    }
  }
  Future<void> onShowQR() async {
    print("status:  $_status");
    if (_status == 'Connected') {
      if (_port == null) {
        print('Port is not initialized');
      }else{
        print('Port is  initialized');
      }
      try {
        Uint8List data = stringToUint8ListUtf8('DisplayQRCodeScreen**upi://pay?pa=abc@icici&pn=testuser&cu=INR&am=10&pn=3323231**10**abc@icici\n');
        print('Data to be sent: $data');
        _port!.write(data);
        print('data sent.');
      } on Exception catch (e) {
        print('Exception: $e');
      }
    } else {
      showToast('Device not connected');
    }
  }
  Future<void> onSuccess() async {
    print("status:  $_status");
    if (_status == 'Connected') {
      if (_port == null) {
        print('Port is not initialized');
      }else{
        print('Port is  initialized');
      }
      try {
        Uint8List data = stringToUint8ListUtf8('DisplaySuccessQRCodeScreen**21312fdfsd**dfsfadsfads**01-08-2024\n');
        print('Data to be sent: $data');
        _port!.write(data);
        print('data sent.');
      } on Exception catch (e) {
        print('Exception: $e');
      }
    } else {
      showToast('Device not connected');
    }
  }
  Future<void> onFail() async {
    print("status:  $_status");
    if (_status == 'Connected') {
      if (_port == null) {
        print('Port is not initialized');
      }else{
        print('Port is  initialized');
      }
      try {
        Uint8List data = stringToUint8ListUtf8('DisplayFailQRCodeScreen**21312fdfsd**dfsfadsfads**01-08-2024\n');
        print('Data to be sent: $data');
        _port!.write(data);
        print('data sent.');
      } on Exception catch (e) {
        print('Exception: $e');
      }
    } else {
      showToast('Device not connected');
    }
  }
  Future<void> onPending() async {
    print("status:  $_status");
    if (_status == 'Connected') {
      if (_port == null) {
        print('Port is not initialized');
      }else{
        print('Port is  initialized');
      }
      try {
        Uint8List data = stringToUint8ListUtf8('DisplayCancelQRCodeScreen**21312fdfsd**dfsfadsfads**01-08-2024\n');
        print('Data to be sent: $data');
        _port!.write(data);
        print('data sent.');
      } on Exception catch (e) {
        print('Exception: $e');
      }
    } else {
      showToast('Device not connected');
    }
  }



  Uint8List stringToUint8ListUtf8(String str) {
    return Uint8List.fromList(utf8.encode(str));
  }




}
