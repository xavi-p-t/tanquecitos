import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cliente_tanques/game_service.dart';
import 'package:cliente_tanques/views/vista_inicio.dart';

class VistaEspera extends StatelessWidget {
  final String nombre;
  const VistaEspera({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final gameService = GameService(); // Obtenemos el Singleton

    return Scaffold(
      backgroundColor: const Color(0xFF4A5D23), // Verde moho principal
      appBar: AppBar(
        title: const Text('Cuartel General', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D3816), // Verde moho oscuro
        foregroundColor: const Color(0xFFD98A3C), // Texto cobre brillante
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: StreamBuilder<String>(
        stream: gameService.streamMensajes,
        builder: (context, snapshot) {
          List<String> jugadores = [];
          String estado = "Interceptando transmisiones...";

          if (snapshot.hasError) {
            estado = "Interferencia en las comunicaciones.";
          } else if (snapshot.hasData) {
            try {
              final data = jsonDecode(snapshot.data.toString());
              if (data['type'] == 'player_list' && data['players'] != null) {
                jugadores = List<String>.from(data['players']);
                estado = "Pelotón actual: ${jugadores.length} soldados.";
              } else {
                estado = "Recibiendo datos encriptados...";
              }
            } catch (e) {
              estado = "Mensaje del servidor recibido.";
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D3816),
                  border: Border(bottom: BorderSide(color: Color(0xFFB87333), width: 3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Soldado: $nombre',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      estado,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFD98A3C), fontSize: 14, fontFamily: 'Courier'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // LISTA DE JUGADORES
              Expanded(
                child: jugadores.isEmpty 
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFB87333))
                    )
                  : ListView.builder(
                      itemCount: jugadores.length,
                      itemBuilder: (context, index) {
                        bool soyYo = jugadores[index] == nombre;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3816),
                            border: Border.all(
                              color: soyYo ? const Color(0xFFD98A3C) : Colors.black45,
                              width: soyYo ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.precision_manufacturing, 
                              color: soyYo ? const Color(0xFFD98A3C) : Colors.white54,
                            ),
                            title: Text(
                              jugadores[index],
                              style: TextStyle(
                                color: soyYo ? const Color(0xFFD98A3C) : Colors.white, 
                                fontWeight: soyYo ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: soyYo 
                              ? const Text('[TÚ]', style: TextStyle(color: Color(0xFFB87333), fontWeight: FontWeight.bold)) 
                              : null,
                          ),
                        );
                      },
                    ),
              ),
              
              // BOTÓN PARA ABANDONAR
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      gameService.desconectar();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const VistaInicio()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('DESERTAR (SALIR)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB87333),
                      side: const BorderSide(color: Color(0xFFB87333), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
