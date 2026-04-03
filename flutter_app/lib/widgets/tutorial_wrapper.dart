// lib/widgets/tutorial_wrapper.dart
import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';

class TutorialWrapper extends StatefulWidget {
  final String screenKey;   // must match kTutorialScripts key
  final Widget child;

  const TutorialWrapper({
    super.key,
    required this.screenKey,
    required this.child,
  });

  @override
  State<TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends State<TutorialWrapper> {
  final _svc = TutorialService();
  bool _speaking = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initAndMaybeAutoPlay();
  }

  Future<void> _initAndMaybeAutoPlay() async {
    await _svc.init(); // pulls tutorial_enabled + tutorial_lang from local storage
    if (!mounted) return;
    setState(() => _ready = true);
    if (!_svc.isEnabled) return;
    // slight delay so the screen has rendered before audio starts
    Future.delayed(const Duration(milliseconds: 600), _autoPlay);
  }

  Future<void> _autoPlay() async {
    if (!mounted) return;
    setState(() => _speaking = true);
    await _svc.speak(widget.screenKey);
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _replay() async {
    setState(() => _speaking = true);
    await _svc.speak(widget.screenKey, force: true);
    if (mounted) setState(() => _speaking = false);
  }

  @override
  void dispose() {
    _svc.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Floating replay button — bottom left, out of the way
        Positioned(
          bottom: 90,
          left: 16,
          child: AnimatedOpacity(
            opacity: (_ready && _svc.isEnabled) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: FloatingActionButton.small(
              heroTag: 'tutorial_${widget.screenKey}',
              onPressed: _speaking ? null : _replay,
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: _speaking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.volume_up, color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }
}
