import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class PantallaJuego extends StatefulWidget {
  const PantallaJuego({super.key});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  ui.Image? tileSetImage;
  List<List<int>>? tileMap;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _cargarAssets();
  }

  // Cargamos los JSONs y la imagen del TileSet
  Future<void> _cargarAssets() async {
    // 1. Cargar el mapa de tiles
    final String mapData = await rootBundle.loadString('assets/levels/tilemaps/level_000_layer_000.json');
    final Map<String, dynamic> jsonMap = jsonDecode(mapData);
    
    // 2. Cargar la imagen (usa el nombre del archivo del JSON)
    final ByteData data = await rootBundle.load('assets/levels/media/Background_Bleak-Yellow_TileSet.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();

    setState(() {
      tileMap = List<List<int>>.from(
        jsonMap['tileMap'].map((row) => List<int>.from(row))
      );
      tileSetImage = fi.image;
      isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 320 / 180, // Relación de aspecto del JSON
          child: CustomPaint(
            painter: MotorJuegoPainter(tileMap!, tileSetImage!),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class MotorJuegoPainter extends CustomPainter {
  final List<List<int>> map;
  final ui.Image tileSet;
  
  // Tamaño de cada tile según el JSON
  final int tileW = 16; 
  final int tileH = 16;

  MotorJuegoPainter(this.map, this.tileSet);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculamos la escala para ajustar los 320x180 a la pantalla
    double scaleX = size.width / 320;
    double scaleY = size.height / 180;

    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        int tileId = map[y][x];
        if (tileId == -1) continue; // Tile vacío

        // Calcular posición del tile en la imagen (TileSet)
        // Suponiendo un TileSet de 20 columnas (esto varía según la imagen)
        int colsInTileSet = tileSet.width ~/ tileW;
        double srcX = (tileId % colsInTileSet) * tileW.toDouble();
        double srcY = (tileId ~/ colsInTileSet) * tileH.toDouble();

        // Dibujar el tile escalado
        canvas.drawImageRect(
          tileSet,
          Rect.fromLTWH(srcX, srcY, tileW.toDouble(), tileH.toDouble()),
          Rect.fromLTWH(x * tileW * scaleX, y * tileH * scaleY, tileW * scaleX, tileH * scaleY),
          Paint(),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}