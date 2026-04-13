import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class WebSocketService {
  static final WebSocketService _instancia = WebSocketService._interno();
  factory WebSocketService() => _instancia;
  WebSocketService._interno();

  WebSocketChannel? _canal;

  // Intentar conectar al servidor y devolver si tuvo éxito
  Future<bool> conectar(String url) async {
    if (_canal != null) return true; 
    
    try {
      _canal = WebSocketChannel.connect(Uri.parse(url));
      // Esperamos a que el canal esté listo para confirmar la conexión
      await _canal!.ready;
      return true;
    } catch (e) {
      _canal = null;
      return false;
    }
  }

  // Enviar mensajes en formato String (JSON)
  void enviar(String mensaje) {
    if (_canal != null) {
      _canal!.sink.add(mensaje);
    }
  }

  // Stream para que la UI escuche los mensajes del servidor
  Stream<dynamic>? get streamMensajes => _canal?.stream;

  void desconectar() {
    _canal?.sink.close();
    _canal = null;
  }
}
