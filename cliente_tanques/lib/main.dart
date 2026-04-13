import 'package:flutter/material.dart';
import 'game_service.dart';
import 'pantalla_juego.dart'; // Tu nueva clase aparte

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PantallaPrincipal()));
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final gameService = GameService();

  @override
  void initState() {
    super.initState();
    gameService.inicializarConexion();

    // Escuchamos los mensajes. Si el servidor responde al "hola", navegamos.
    gameService.onMessageReceived = (message) {
      if (message.contains("gameplay") || message.contains("welcome")) {
        // Si recibimos datos de juego o confirmación, saltamos al campo de batalla
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PantallaJuego()),
        );
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tanquecitos Wii Style")),
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: gameService.statusNotifier,
          builder: (context, estado, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Conexión: $estado"),
                const SizedBox(height: 20),
                ElevatedButton(
                  // Al pulsar, mandamos el hola para "activar" el cambio de vista
                  onPressed: gameService.enviarHola,
                  child: const Text("Empezar Partida (Enviar Hola)"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}