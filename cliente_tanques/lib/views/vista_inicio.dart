import 'package:flutter/material.dart';
import 'package:cliente_tanques/game_service.dart';
import 'package:cliente_tanques/views/vista_carga.dart';

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

    final gameService = GameService();
    
    // CAMBIO AQUÍ: Apuntamos a tu dominio y al puerto 443
    bool conectado = await gameService.inicializarConexion('xpalmatalan.ieti.site', 443);
    
    if (!mounted) return;

    if (conectado) {
      gameService.enviar('{"type": "register", "playerName": "$nombre"}');
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VistaCarga(nombre: nombre),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comunicaciones caídas. No hay respuesta del servidor.'),
          backgroundColor: Color(0xFFB87333), 
        ),
      );
    }

    setState(() => _estaConectando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A5D23), 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 100, color: Color(0xFFB87333)), 
              const SizedBox(height: 20),
              const Text(
                'TANQUECITOS 3',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD98A3C), 
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3816), 
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFB87333), width: 2), 
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      enabled: !_estaConectando,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tu nombre de soldado',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.person, color: Color(0xFFB87333)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFB87333)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD98A3C)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _estaConectando ? null : _iniciarProceso,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB87333), 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _estaConectando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('ENTRAR A LA BATALLA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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