import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cliente_tanques/game_service.dart';
import 'package:cliente_tanques/views/vista_inicio.dart';
import 'package:cliente_tanques/pantalla_juego.dart'; 

class VistaEspera extends StatefulWidget {
  final String nombre;
  const VistaEspera({super.key, required this.nombre});

  @override
  State<VistaEspera> createState() => _VistaEsperaState();
}

class _VistaEsperaState extends State<VistaEspera> {
  final gameService = GameService();
  late StreamSubscription _suscripcionMensajes;
  
  List<String> _jugadores = [];
  String _estado = "Interceptando transmisiones...";
  int? _cuentaAtras; // Almacena los segundos restantes

  @override
  void initState() {
    super.initState();
    
    // 1. PRIMERO NOS PONEMOS A ESCUCHAR AL SERVIDOR
    _suscripcionMensajes = gameService.streamMensajes.listen((mensaje) {
      try {
        final data = jsonDecode(mensaje);
        
        if (data['type'] == 'player_list' && data['players'] != null) {
          if (mounted) {
            setState(() {
              _jugadores = List<String>.from(data['players']);
              if (_cuentaAtras == null) {
                _estado = "Pelotón actual: ${_jugadores.length} soldados.";
              }
            });
          }
        } 
        // RECIBIMOS LA CUENTA ATRÁS
        else if (data['type'] == 'countdown') {
          if (mounted) {
            setState(() {
              _cuentaAtras = data['value'];
              _estado = "¡PREPÁRATE PARA EL DESPLIEGUE!";
            });
          }
        }
        // SI ALGUIEN SE DESCONECTA DURANTE LA CUENTA ATRÁS
        else if (data['type'] == 'countdown_cancelled') {
          if (mounted) {
            setState(() {
              _cuentaAtras = null;
              _estado = "Despliegue abortado. Esperando refuerzos...";
            });
          }
        }
        else if (data['type'] == 'start_game') {
          print("¡Luz verde! Iniciando partida...");
          _suscripcionMensajes.cancel();
          
          // PASAMOS EL DICCIONARIO DE JUGADORES A LA PANTALLA
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaJuego(
                estadoInicial: data['estadoPartida'], // Pasamos las posiciones
              ),
            ),
          );
        }
      } catch (e) {
        // Ignoramos mensajes no JSON
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _estado = "Interferencia en las comunicaciones.";
        });
      }
    });

    // 2. UNA VEZ QUE ESCUCHAMOS, ENVIAMOS EL REGISTRO
    // Esto asegura que el broadcast del servidor no se pierda.
    gameService.enviar(jsonEncode({
      "type": "register",
      "playerName": widget.nombre
    }));
  }

  @override
  void dispose() {
    _suscripcionMensajes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A5D23),
      appBar: AppBar(
        title: const Text('Cuartel General', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D3816),
        foregroundColor: const Color(0xFFD98A3C),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Column(
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
                  'Soldado: ${widget.nombre}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _estado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFD98A3C), fontSize: 16, fontFamily: 'Courier'),
                ),
              ],
            ),
          ),
          
          // MOSTRAR LA CUENTA ATRÁS GIGANTE SI EXISTE
          if (_cuentaAtras != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                '$_cuentaAtras',
                style: const TextStyle(
                  fontSize: 80, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFFD98A3C),
                  fontFamily: 'Courier',
                ),
              ),
            ),

          const SizedBox(height: 10),
          
          Expanded(
            child: _jugadores.isEmpty 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFB87333)))
              : ListView.builder(
                  itemCount: _jugadores.length,
                  itemBuilder: (context, index) {
                    bool soyYo = _jugadores[index] == widget.nombre;
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
                          _jugadores[index],
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
      ),
    );
  }
}