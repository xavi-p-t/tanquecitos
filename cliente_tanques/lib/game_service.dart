import 'package:flutter/foundation.dart';
import 'utils_websockets.dart'; // Tu archivo original

class GameService {
  // Instancia única (Singleton) para acceder desde cualquier parte
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final WebSocketsHandler _socketHandler = WebSocketsHandler();
  
  // Notificador para que la UI se entere de los cambios de estado
  ValueNotifier<ConnectionStatus> statusNotifier = ValueNotifier(ConnectionStatus.disconnected);

  void inicializarConexion() {
    // Configuramos los parámetros del servidor según tu app.js
    _socketHandler.connectToServer(
      'localhost', // O 10.0.2.2 para emulador
      3000, 
      (message) {
        if (kDebugMode) print("Mensaje recibido: $message");
        // Aquí procesarás los estados del juego más adelante
      },
      onError: (e) => _actualizarEstado(),
      onDone: () => _actualizarEstado(),
    );
    _actualizarEstado();
  }

  void _actualizarEstado() {
    statusNotifier.value = _socketHandler.connectionStatus;
  }

  void enviarHola() {
    _socketHandler.sendMessage("hola desde Flutter");
  }

  String? get miId => _socketHandler.socketId;
}