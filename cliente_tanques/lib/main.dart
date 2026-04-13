import 'package:flutter/material.dart';
import 'package:cliente_tanques/service/websocket_service.dart';

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
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const VistaInicio(),
    );
  }
}

// --- PANTALLA DE INICIO ---
class VistaInicio extends StatefulWidget {
  const VistaInicio({super.key});

  @override
  State<VistaInicio> createState() => _VistaInicioState();
}

class _VistaInicioState extends State<VistaInicio> {
  final TextEditingController _inputController = TextEditingController();
  bool _estaConectando = false;

  Future<void> _iniciarProceso() async {
    final String nombre = _inputController.text.trim();
    if (nombre.isEmpty) return;

    setState(() => _estaConectando = true);

    final wsService = WebSocketService();
    // Intentamos la conexión al servidor
    bool conectado = await wsService.conectar('ws://localhost:8080');

    if (!mounted) return;

    if (conectado) {
      // Enviamos el registro tal como en tu ejemplo profesional
      wsService.enviar('{"type": "register", "playerName": "$nombre"}');

      // Navegamos a la sala de espera
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VistaEspera(nombre: nombre),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo establecer conexión con el servidor'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => _estaConectando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8A9A5B), // Color militar
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TANQUECITOS 3',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      enabled: !_estaConectando,
                      decoration: const InputDecoration(
                        labelText: 'Tu nombre de soldado',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _estaConectando ? null : _iniciarProceso,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5D23),
                          foregroundColor: Colors.white,
                        ),
                        child: _estaConectando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('ENTRAR A LA BATALLA'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA DE ESPERA (SALA) ---
class VistaEspera extends StatelessWidget {
  final String nombre;
  const VistaEspera({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final wsService = WebSocketService();

    return Scaffold(
      backgroundColor: const Color(0xFF4A5D23),
      body: StreamBuilder(
        stream: wsService.streamMensajes,
        builder: (context, snapshot) {
          // Aquí manejamos lo que el servidor nos diga mientras esperamos
          String estado = "Esperando a otros jugadores...";
          
          if (snapshot.hasError) estado = "Error en la comunicación";
          if (snapshot.hasData) {
            // Aquí podrías procesar el JSON para ver cuántos jugadores hay
            estado = "Servidor dice: ${snapshot.data}";
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 40),
                Text(
                  'Soldado: $nombre',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    estado,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 60),
                TextButton(
                  onPressed: () {
                    wsService.desconectar();
                    Navigator.pop(context);
                  },
                  child: const Text('ABANDONAR SALA', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}