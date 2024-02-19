import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class SideswapPeg extends ChangeNotifier {
  late IOWebSocketChannel _channel;
  final _messageController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get messageStream => _messageController.stream;

  void connect({
    required String recv_addr,
    required bool peg_in,
  }) {
    _channel = IOWebSocketChannel.connect('wss://api.sideswap.io/json-rpc-ws');
    peg(method: 'peg', peg_in: peg_in, recv_addr: recv_addr);

    _channel.stream.listen(handleIncomingMessage);
  }

  void peg({
    required String method,
    required bool? peg_in,
    required String? recv_addr,
  }) {
    _channel.sink.add(json.encode({
      'id': 1,
      'method': method,
      'params': {
        'peg_in': peg_in,
        'recv_addr': recv_addr,
      },
    }));
  }

  void handleIncomingMessage(dynamic message) {
    if (message is String) {
      var decodedMessage = json.decode(message);
      _messageController.add(decodedMessage);
      notifyListeners();
    }
  }

  void close() {
    _channel.sink.close();
    _messageController.close();
  }
}

class SideswapPegStatus extends ChangeNotifier {
  late IOWebSocketChannel _channel;
  final _messageController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get messageStream => _messageController.stream;

  void connect({
    required String orderId,
    required bool pegIn,
  }) {
    _channel = IOWebSocketChannel.connect('wss://api.sideswap.io/json-rpc-ws');
    peg(method: 'peg_status', pegIn: pegIn, orderId: orderId);

    _channel.stream.listen(handleIncomingMessage);
  }

  void peg({
    required String method,
    required String orderId,
    required bool? pegIn,
  }) {
    _channel.sink.add(json.encode({
      'id': 1,
      'method': method,
      'params': {
        'peg_in': pegIn,
        'order_id': orderId,
      },
    }));
  }

  void handleIncomingMessage(dynamic message) {
    if (message is String) {
      var decodedMessage = json.decode(message);
      _messageController.add(decodedMessage);
      notifyListeners();
    }
  }

  void close() {
    _channel.sink.close();
    _messageController.close();
  }
}