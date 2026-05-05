import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:cliente_tanques/game_service.dart';
import 'package:cliente_tanques/views/vista_espera.dart';



class PantallaJuego extends StatefulWidget {
  final Map<String, dynamic> estadoInicial;
  const PantallaJuego({super.key, required this.estadoInicial});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  ui.Image? tileSetImage, tankImage, basicBulletImage, specialBulletImage; 
  ui.Image? itemImage, heartFullImage, heartEmptyImage, deadImage; 
  List<List<int>>? tileMap;
  bool isLoaded = false;
  
  late Map<String, dynamic> jugadoresState;
  List<dynamic> balasState = [], powerUpsState = [], efectosState = []; 

  final gameService = GameService();
  late StreamSubscription _suscripcionMensajes;
  Map<String, bool> teclas = {'w': false, 'a': false, 's': false, 'd': false, 'space': false};

  @override
  void initState() {
    super.initState();
    jugadoresState = widget.estadoInicial;
    _cargarAssets();

    _suscripcionMensajes = gameService.streamMensajes.listen((mensaje) {
      try {
        final data = jsonDecode(mensaje);
        if (data['type'] == 'update_state') {
          setState(() {
            jugadoresState = data['estadoPartida'];
            balasState = data['balas'] ?? []; 
            powerUpsState = data['powerUps'] ?? []; 
            efectosState = data['efectos'] ?? []; 
          });
        } 
        // NUEVO: CAPTURAR EL EVENTO DE FIN DE PARTIDA
        else if (data['type'] == 'end_game') {
          _suscripcionMensajes.cancel(); 
          
          String? winnerId = data['winner'];
          bool heGanado = (winnerId == gameService.miId);
          
          // EXTRAEMOS TU NOMBRE DEL ESTADO ANTES DE SALIR
          String miNombre = "Soldado";
          if (jugadoresState.containsKey(gameService.miId)) {
            miNombre = jugadoresState[gameService.miId]['name'];
          }
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaResultados(
                haGanado: heGanado,
                nombreJugador: miNombre, // LE PASAMOS EL NOMBRE
              ),
            ),
          );
        }
      } catch (e) {}
    });
  }

  Future<void> _cargarAssets() async {
    final String mapData = await rootBundle.loadString('assets/levels/tilemaps/level_000_layer_000.json');
    final Map<String, dynamic> jsonMap = jsonDecode(mapData);
    
    Future<ui.Image> cargarImagen(String ruta) async {
      final ByteData data = await rootBundle.load(ruta);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo fi = await codec.getNextFrame();
      return fi.image;
    }

    final imgTiles = await cargarImagen('assets/levels/media/Background_Bleak-Yellow_TileSet.png');
    final imgTank = await cargarImagen('assets/levels/media/tanks.png');
    final imgBasicB = await cargarImagen('assets/levels/media/All_Fire_Bullet_Pixel_16x16_06.png');
    final imgSpecialB = await cargarImagen('assets/levels/media/All_Fire_Bullet_Pixel_16x16_05.png'); 
    final imgItem = await cargarImagen('assets/levels/media/sprite-6-1.png');
    final imgHeartFull = await cargarImagen('assets/levels/media/Heart_Full.png');
    final imgHeartEmpty = await cargarImagen('assets/levels/media/Heart_Empty.png');
    final imgDead = await cargarImagen('assets/levels/media/dead_animation-removebg-preview.png');

    setState(() {
      tileMap = List<List<int>>.from(jsonMap['tileMap'].map((row) => List<int>.from(row)));
      tileSetImage = imgTiles;
      tankImage = imgTank;
      basicBulletImage = imgBasicB;
      specialBulletImage = imgSpecialB;
      itemImage = imgItem;
      heartFullImage = imgHeartFull;
      heartEmptyImage = imgHeartEmpty;
      deadImage = imgDead;
      isLoaded = true;
    });
  }

  @override
  void dispose() {
    _suscripcionMensajes.cancel();
    super.dispose();
  }

  void _teclaPulsada(KeyEvent event) {
    if (event is KeyRepeatEvent) return;
    bool isKeyDown = event is KeyDownEvent;
    bool cambio = false;

    if (event.logicalKey == LogicalKeyboardKey.keyW) { if (teclas['w'] != isKeyDown) { teclas['w'] = isKeyDown; cambio = true; } }
    else if (event.logicalKey == LogicalKeyboardKey.keyS) { if (teclas['s'] != isKeyDown) { teclas['s'] = isKeyDown; cambio = true; } }
    else if (event.logicalKey == LogicalKeyboardKey.keyA) { if (teclas['a'] != isKeyDown) { teclas['a'] = isKeyDown; cambio = true; } }
    else if (event.logicalKey == LogicalKeyboardKey.keyD) { if (teclas['d'] != isKeyDown) { teclas['d'] = isKeyDown; cambio = true; } }
    else if (event.logicalKey == LogicalKeyboardKey.space) { if (teclas['space'] != isKeyDown) { teclas['space'] = isKeyDown; cambio = true; } }

    if (cambio) gameService.enviar(jsonEncode({"type": "input", "keys": teclas}));
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFB87333))));
    final miId = gameService.miId ?? '';

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          _teclaPulsada(event);
          return KeyEventResult.handled;
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: 211 / 121, 
            child: CustomPaint(
              painter: MotorJuegoPainter(
                tileMap!, tileSetImage!, tankImage!, basicBulletImage!, specialBulletImage!, itemImage!, 
                heartFullImage!, heartEmptyImage!, deadImage!, 
                jugadoresState, balasState, powerUpsState, efectosState, miId
              ),
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }
}

class MotorJuegoPainter extends CustomPainter {
  final List<List<int>> map;
  final ui.Image tileSet, tankImage, basicBImage, specialBImage, itemImage, heartFull, heartEmpty, deadImage;
  final Map<String, dynamic> jugadores;
  final List<dynamic> balas, powerUps, efectos;
  final String miId; 
  
  final int tileW = 16, tileH = 16;
  final double viewportW = 211.0, viewportH = 121.0;

  MotorJuegoPainter(this.map, this.tileSet, this.tankImage, this.basicBImage, this.specialBImage, this.itemImage, this.heartFull, this.heartEmpty, this.deadImage, this.jugadores, this.balas, this.powerUps, this.efectos, this.miId);

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / viewportW, scaleY = size.height / viewportH;
    canvas.save(); 
    canvas.scale(scaleX, scaleY); 

    double camX = viewportW / 2, camY = viewportH / 2;
    if (jugadores.containsKey(miId)) { camX = jugadores[miId]['x'].toDouble(); camY = jugadores[miId]['y'].toDouble(); }

    double offsetX = (viewportW / 2) - camX, offsetY = (viewportH / 2) - camY;
    double mapPixelW = map[0].length * tileW.toDouble(), mapPixelH = map.length * tileH.toDouble();

    if (mapPixelW > viewportW) offsetX = offsetX.clamp(viewportW - mapPixelW, 0.0); else offsetX = (viewportW - mapPixelW) / 2;
    if (mapPixelH > viewportH) offsetY = offsetY.clamp(viewportH - mapPixelH, 0.0); else offsetY = (viewportH - mapPixelH) / 2;
    canvas.translate(offsetX, offsetY);

    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        int tileId = map[y][x];
        if (tileId == -1) continue; 
        int colsInTileSet = tileSet.width ~/ tileW;
        double srcX = (tileId % colsInTileSet) * tileW.toDouble(), srcY = (tileId ~/ colsInTileSet) * tileH.toDouble();
        canvas.drawImageRect(tileSet, Rect.fromLTWH(srcX, srcY, tileW.toDouble(), tileH.toDouble()), Rect.fromLTWH(x * tileW.toDouble(), y * tileH.toDouble(), tileW.toDouble(), tileH.toDouble()), Paint());
      }
    }

    const double iW = 81.0, iH = 81.0, iAnchorX = 0.5595, iAnchorY = 0.4948, escalaCaja = 0.15; 
    for (var pu in powerUps) {
      double px = pu['x'].toDouble(), py = pu['y'].toDouble();
      canvas.save(); canvas.translate(px, py); canvas.scale(escalaCaja, escalaCaja);
      canvas.drawImageRect(itemImage, const Rect.fromLTWH(0, 0, iW, iH), const Rect.fromLTWH(-iW * iAnchorX, -iH * iAnchorY, iW, iH), Paint());
      canvas.restore();
    }

    int colsBasic = basicBImage.width ~/ 16;
    int colsSpecial = specialBImage.width ~/ 16;
    const double bAnchorX = 0.538, bAnchorY = 0.531, escalaBala = 1.0; 

    for (var b in balas) {
      double bx = b['x'].toDouble(), by = b['y'].toDouble(), anguloBala = math.atan2(b['vy'].toDouble(), b['vx'].toDouble());
      String type = b['type'];
      ui.Image currentImg = basicBImage;
      int frame = 61; 
      if (type == 'heavy') { currentImg = specialBImage; frame = 600; } 
      else if (type == 'ricochet') { currentImg = specialBImage; frame = 146; }

      int cols = (currentImg == basicBImage) ? colsBasic : colsSpecial;
      double bSrcX = (frame % cols) * 16.0, bSrcY = (frame ~/ cols) * 16.0;

      canvas.save(); canvas.translate(bx, by); canvas.rotate(anguloBala); canvas.scale(escalaBala, escalaBala);
      canvas.drawImageRect(currentImg, Rect.fromLTWH(bSrcX, bSrcY, 16.0, 16.0), Rect.fromLTWH(-16.0 * bAnchorX, -16.0 * bAnchorY, 16.0, 16.0), Paint());
      canvas.restore();
    }

    int colsDead = deadImage.width ~/ 67; 
    for (var fx in efectos) {
      double fxX = fx['x'].toDouble(), fxY = fx['y'].toDouble();
      String tipo = fx['type'];
      int timer = fx['timer'] as int;
      
      canvas.save();
      canvas.translate(fxX, fxY);
      
      if (tipo == 'health') {
        canvas.drawImageRect(heartFull, const Rect.fromLTWH(0, 0, 13.0, 12.0), const Rect.fromLTWH(-6.5, -6.0, 13.0, 12.0), Paint());
      } else if (tipo == 'heavy') {
        double eSrcX = (600 % colsSpecial) * 16.0, eSrcY = (600 ~/ colsSpecial) * 16.0;
        canvas.drawImageRect(specialBImage, Rect.fromLTWH(eSrcX, eSrcY, 16.0, 16.0), const Rect.fromLTWH(-8.0, -8.0, 16.0, 16.0), Paint());
      } else if (tipo == 'ricochet') {
        double eSrcX = (146 % colsSpecial) * 16.0, eSrcY = (146 ~/ colsSpecial) * 16.0;
        canvas.drawImageRect(specialBImage, Rect.fromLTWH(eSrcX, eSrcY, 16.0, 16.0), const Rect.fromLTWH(-8.0, -8.0, 16.0, 16.0), Paint());
      } else if (tipo == 'dead') {
        int step = (timer - 1) ~/ 5; 
        int currentFrame = (5 - step).clamp(0, 5); 
        double dSrcX = (currentFrame % colsDead) * 67.0, dSrcY = (currentFrame ~/ colsDead) * 82.0;
        const double dAnchorX = 0.507, dAnchorY = 0.518, dScale = 0.25; 

        canvas.scale(dScale, dScale);
        canvas.drawImageRect(deadImage, Rect.fromLTWH(dSrcX, dSrcY, 67.0, 82.0), Rect.fromLTWH(-67.0 * dAnchorX, -82.0 * dAnchorY, 67.0, 82.0), Paint());
      }
      canvas.restore();
    }

    const double spriteW = 150.0, spriteH = 200.0, anchorX = 0.5027, anchorY = 0.3348, escalaTanque = 0.075; 
    
    for (var jugador in jugadores.values) {
      int hp = jugador['hp'] ?? 3;
      if (hp <= 0) continue; 

      double tankX = jugador['x'].toDouble(), tankY = jugador['y'].toDouble(), anguloTanque = jugador['angulo']?.toDouble() ?? 0.0;
      
      canvas.save(); canvas.translate(tankX, tankY); canvas.rotate(anguloTanque); canvas.scale(escalaTanque, escalaTanque); 
      canvas.drawImageRect(tankImage, const Rect.fromLTWH(0, 0, spriteW, spriteH), const Rect.fromLTWH(-spriteW * anchorX, -spriteH * anchorY, spriteW, spriteH), Paint());
      canvas.restore();

      const double heartScale = 0.5; 
      const double wCorazon = 13.0 * heartScale, hCorazon = 12.0 * heartScale, gap = 2.0; 
      double totalWidth = (wCorazon * 3) + (gap * 2);
      double startX = tankX - (totalWidth / 2);
      double heartY = tankY - 14.0; 

      for (int i = 0; i < 3; i++) {
        ui.Image img = i < hp ? heartFull : heartEmpty;
        canvas.drawImageRect(img, const Rect.fromLTWH(0, 0, 13.0, 12.0), Rect.fromLTWH(startX + (i * (wCorazon + gap)), heartY, wCorazon, hCorazon), Paint());
      }
    }
    canvas.restore(); 
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true; 
}


// --- LA PANTALLA DE RESULTADOS CORREGIDA ---
class PantallaResultados extends StatefulWidget {
  final bool haGanado;
  final String nombreJugador; // Añadimos la variable para el nombre

  const PantallaResultados({super.key, required this.haGanado, required this.nombreJugador});

  @override
  State<PantallaResultados> createState() => _PantallaResultadosState();
}

class _PantallaResultadosState extends State<PantallaResultados> {
  int _contador = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarContador();
  }

  void _iniciarContador() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_contador > 0) {
        setState(() {
          _contador--;
        });
      } else {
        _volverAlLobby();
      }
    });
  }

  void _volverAlLobby() {
    _timer?.cancel();
    
    if (!mounted) return;

    // Limpiamos el historial y vamos a la Sala de Espera con tu nombre
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => VistaEspera(nombre: widget.nombreJugador)),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.haGanado ? "¡HAS GANADO!" : "HAS PERDIDO...",
              style: TextStyle(
                color: widget.haGanado ? Colors.amber : Colors.red,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 10)
                ]
              ),
            ),
            const SizedBox(height: 50),
            Text(
              "Volviendo a la sala en: $_contador",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: _volverAlLobby,
              child: const Text(
                "Aceptar",
                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}