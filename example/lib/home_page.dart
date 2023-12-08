// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import 'package:serial/serial.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _defaultBaudRate = 9600;

  SerialPort? _port;
  final _received = <Uint8List>[];

  final _controller1 = TextEditingController();

  final _baudController = TextEditingController(text: '9600');

  ReadableStreamReader? _reader;

  Future<void> _openPort() async {
    await _port?.close();

    final port = await window.navigator.serial.requestPort();

    var baudRate = int.tryParse(_baudController.text);

    if (baudRate == null) {
      _logError('Invalid baud rate. Using default: $_defaultBaudRate');
      baudRate = _defaultBaudRate;
    }

    await port.open(baudRate: baudRate);

    _port = port;

    _startReceiving(port);

    final info = port.getInfo();
    _logInfo(
        'Port opened. ProductId: ${info.usbProductId}, VendorId: ${info.usbVendorId}');

    setState(() {});
  }

  Future<void> _writeToPort(Uint8List data) async {
    if (data.isEmpty) {
      return;
    }

    final port = _port;

    if (port == null) {
      return;
    }

    final writer = port.writable.writer;

    await writer.ready;
    await writer.write(data);

    await writer.ready;
    await writer.close();
  }

  Future<void> _startReceiving(SerialPort port) async {
    final reader = port.readable.reader;

    _reader = reader;

    while (_reader != null) {
      try {
        final result = await reader.read();
        _received.add(result.value);

        setState(() {});

        if (result.done) {
          _logInfo('Reader done.');
          break;
        }
      } catch (e) {
        _logError('Error reading from port: $e');
        break;
      }
    }

    _logInfo('Reader cancelled.');

    setState(() {});
  }

  _closePort() async {
    await _reader?.cancel();
    _reader?.releaseLock();
    _reader = null;

    await _port?.close();
    _port = null;

    setState(() {});
  }

  void _log(String message) {
    var bytes = utf8.encode(message);
    _received.add(Uint8List.fromList(bytes));
  }

  void _logInfo(String message) {
    _log('[INFO] $message');
  }

  void _logError(String message) {
    _log('[ERROR] $message');
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serial Port'),
        actions: [
          IconButton(
            onPressed: _openPort,
            icon: Icon(Icons.device_hub),
            tooltip: 'Open Serial Port',
          ),
          IconButton(
            onPressed: _port == null ? null : _closePort,
            icon: Icon(Icons.close),
            tooltip: 'Close Serial Port',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _baudController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Baud Rate',
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _received.isNotEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(4),
                        children: _received.map((e) {
                          final text = utf8.decode(e, allowMalformed: true);

                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(text),
                          );
                        }).toList(),
                      )
                    : Center(
                        child: Text(
                        'No data received yet.',
                        textAlign: TextAlign.center,
                      )),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TextFormField(
                    controller: _controller1,
                  ),
                ),
                Gap(8),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    child: const Text('Send'),
                    onPressed: () {
                      _writeToPort(
                          Uint8List.fromList(_controller1.text.codeUnits));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
