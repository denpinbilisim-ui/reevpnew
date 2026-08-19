import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Sessiz ve döngüsel şekilde oynatılan tam ekran video arka planı.
/// Video bulunamazsa veya yüklenemezse [fallback] widget'ı gösterilir,
/// böylece uygulama asla çökmez.
class VideoBackground extends StatefulWidget {
  final String assetPath;
  final Widget child;
  final Widget fallback;
  final Color overlayColor;

  const VideoBackground({
    super.key,
    required this.assetPath,
    required this.child,
    required this.fallback,
    this.overlayColor = const Color(0x99000000),
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(widget.assetPath);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (e) {
      debugPrint('Video arka plan yüklenemedi: $e');
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showVideo = _ready && !_failed && _controller != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video hazır değilken / başarısız olduğunda gösterilecek arka plan
        Positioned.fill(child: widget.fallback),

        if (showVideo)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

        if (showVideo)
          Positioned.fill(
            child: Container(color: widget.overlayColor),
          ),

        widget.child,
      ],
    );
  }
}
