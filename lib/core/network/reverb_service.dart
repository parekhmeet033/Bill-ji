import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';

class ReverbService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  
  String get _url => ApiConstants.webSocketUrl;
  
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  void connect() {
    if (_isConnected) return;
    _shouldReconnect = true;

    debugPrint("Reverb: Connecting to $_url");

    runZonedGuarded(() {
      try {
        _channel = WebSocketChannel.connect(Uri.parse(_url));

        // Handle the ready future — web_socket_channel emits connection errors
        // here as well as on the stream; leaving it unhandled crashes the app.
        _channel!.ready.then(
          (_) {},
          onError: (error) {
            debugPrint("Reverb Connection Failed: $error");
            _handleDisconnection();
          },
        );

        _channel!.stream.listen(
          (message) {
            _isConnected = true;
            _handleMessage(message);
          },
          onError: (error) {
            debugPrint("Reverb Error: $error");
            _handleDisconnection();
          },
          onDone: () {
            debugPrint("Reverb Disconnected");
            _handleDisconnection();
          },
          cancelOnError: true,
        );
      } catch (e) {
        debugPrint("Reverb Connection Exception: $e");
        _handleDisconnection();
      }
    }, (error, stack) {
      debugPrint("Reverb Unhandled Zone Error: $error");
      _handleDisconnection();
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message.toString());
      final event = decoded['event'];
      
      if (event == 'pusher:connection_established') {
        debugPrint("Reverb: Connection Established");
        _subscribe('dashboard');
      } else if (event == 'pusher:error') {
        debugPrint("Reverb Pusher Error: ${decoded['data']}");
      } else if (event == 'pusher:ping') {
        _channel?.sink.add(jsonEncode({'event': 'pusher:pong'}));
      } else {
        // Broadcast other events
        _eventController.add(decoded);
      }
    } catch (e) {
      debugPrint("Reverb: Error decoding message: $e");
    }
  }

  void _subscribe(String channelName) {
    _channel?.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': {'channel': channelName}
    }));
  }

  void _handleDisconnection() {
    _isConnected = false;
    _channel = null;
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint("Reverb: Attempting to reconnect...");
      connect();
    });
  }

  void disconnect() {
    debugPrint("Reverb: Disconnecting manually");
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
