import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cliente_tanques/views/vista_espera.dart';

class VistaCarga extends StatefulWidget {
  final String nombre;
  const VistaCarga({super.key, required this.nombre});

  @override
  State<VistaCarga> createState() => _VistaCargaState();
}

class _VistaCargaState extends State<VistaCarga> {
  double _progreso = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarCargaSimulada();
  }

  void _iniciarCargaSimulada() {
    const int duracionTotalMs = 2500;
    const int intervaloMs = 50;
    final int pasosTotales = duracionTotalMs ~/ intervaloMs;
    int pasoActual = 0;

    _timer = Timer.periodic(const Duration(milliseconds: intervaloMs), (timer) {
      pasoActual++;
      setState(() {
        _progreso = pasoActual / pasosTotales;
      });

      if (pasoActual >= pasosTotales) {
        timer.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VistaEspera(nombre: widget.nombre),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D3816), // Verde moho oscuro
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.memory, size: 80, color: Color(0xFFB87333)), // Icono de hardware retro en cobre
              const SizedBox(height: 30),
              const Text(
                'PREPARANDO SISTEMAS...',
                style: TextStyle(
                  color: Color(0xFFD98A3C), // Cobre brillante
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progreso,
                minHeight: 15,
                backgroundColor: Colors.black45,
                color: const Color(0xFFB87333), // Barra de progreso color cobre
                borderRadius: BorderRadius.circular(4), // Bordes estilo años 90
              ),
              const SizedBox(height: 15),
              Text(
                '${(_progreso * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Courier', 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
