import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Animación de marca de la pantalla de bienvenida.
///
/// El vídeo es decorativo: lleva el logotipo y el lema que ya están en texto
/// debajo, así que va sin sonido, sin controles y marcado como decorativo para
/// el lector de pantalla.
///
/// Siempre se pinta antes el póster (el último fotograma). Mientras el vídeo
/// carga evita el hueco en blanco, y si el vídeo no se puede reproducir
/// —códec no soportado, autoplay bloqueado en web, o el usuario pidió menos
/// movimiento en el sistema— la pantalla se queda con esa imagen fija en vez
/// de perder la cabecera.
class WelcomeIntroVideo extends StatefulWidget {
  const WelcomeIntroVideo({super.key, this.height = 280});

  static const asset = 'assets/brand/welcome_intro.mp4';
  static const posterAsset = 'assets/brand/welcome_intro_poster.webp';

  /// Alto del recuadro. El vídeo es vertical y se recorta a lo ancho.
  final double height;

  @override
  State<WelcomeIntroVideo> createState() => _WelcomeIntroVideoState();
}

class _WelcomeIntroVideoState extends State<WelcomeIntroVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La preferencia de movimiento reducido del sistema solo se puede leer con
    // un contexto, por eso el arranque no va en initState.
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _start();
  }

  Future<void> _start() async {
    final controller = VideoPlayerController.asset(WelcomeIntroVideo.asset);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      // Sin vídeo la bienvenida sigue en pie con el póster.
      await controller.dispose();
      if (!mounted) {
        _controller = null;
        return;
      }
      setState(() {
        _controller = null;
        _ready = false;
      });
      return;
    }
    if (!mounted) {
      await controller.dispose();
      _controller = null;
      return;
    }
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                WelcomeIntroVideo.posterAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              if (_ready && controller != null)
                AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 240),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
