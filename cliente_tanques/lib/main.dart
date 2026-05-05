/*import 'package:flutter/material.dart';
import 'package:cliente_tanques/views/vista_inicio.dart';

void main() {
  runApp(const MiJuegoApp());
}

class MiJuegoApp extends StatelessWidget {
  const MiJuegoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanques Multiplayer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Courier', // Una fuente monoespaciada le da un toque más retro
      ),
      home: const VistaInicio(),
    );
  }
}
*/
// vista juego
import 'package:flutter/material.dart';
import 'package:cliente_tanques/views/vista_inicio.dart'; // Comentamos la vista original
import 'package:cliente_tanques/views/vista_juego.dart'; // Importamos la vista del juego

void main() {
  runApp(const MiJuegoApp());
}

class MiJuegoApp extends StatelessWidget {
  const MiJuegoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanques Multiplayer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Courier', 
      ),
      // CAMBIO AQUÍ: Ponemos VistaJuego como pantalla principal temporalmente
      home: const VistaJuego(miNombre: 'SoldadoPrueba'), 
    );
  }
}