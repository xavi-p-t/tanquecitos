import 'dart:async';
import 'package:flutter/foundation.dart';
import 'utils_websockets.dart'; 

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final WebSocketsHandler _socketHandler = WebSocketsHandler();
  
  ValueNotifier<ConnectionStatus> statusNotifier = ValueNotifier(ConnectionStatus.disconnected);

  final StreamController<String> _mensajesController = StreamController<String>.broadcast();
  Stream<String> get streamMensajes => _mensajesController.stream;

  Future<bool> inicializarConexion(String host, int port) async {
    // CAMBIO AQUÍ: Ahora le ponemos 'await' y quitamos el Future.delayed
    await _socketHandler.connectToServer(
      host, 
      port, 
      (message) {
        if (kDebugMode) print("Mensaje recibido: $message");
        _mensajesController.add(message);
      },
      onError: (e) => _actualizarEstado(),
      onDone: () => _actualizarEstado(),
    );
    
    _actualizarEstado();

    return _socketHandler.connectionStatus == ConnectionStatus.connected;
  }

  void _actualizarEstado() {
    statusNotifier.value = _socketHandler.connectionStatus;
  }

  void enviar(String mensaje) {
    _socketHandler.sendMessage(mensaje);
  }

  void desconectar() {
    _socketHandler.disconnectFromServer();
    _actualizarEstado();
  }

  void enviarHola() {
    _socketHandler.sendMessage("hola desde Flutter");
  }

  String? get miId => _socketHandler.socketId;
}