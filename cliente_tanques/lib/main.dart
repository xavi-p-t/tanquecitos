import 'package:flutter/material.dart';
import 'game_service.dart';

void main() {
  runApp(const MaterialApp(home: PantallaPrincipal()));
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
    // Llamamos a la conexión desde el inicio
    gameService.inicializarConexion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tanquecitos Multiplayer")),
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: gameService.statusNotifier,
          builder: (context, estado, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Estado: $estado"),
                if (gameService.miId != null) 
                  Text("Mi ID: ${gameService.miId}"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: gameService.enviarHola,
                  child: const Text("Enviar Hola al Servidor"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}