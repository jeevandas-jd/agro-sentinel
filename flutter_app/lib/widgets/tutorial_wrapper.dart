// lib/widgets/tutorial_wrapper.dart
import 'package:flutter/material.dart';
import '../app/app_route_observer.dart';
import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';

class TutorialWrapper extends StatefulWidget {
  final String screenKey;
  final Widget child;

  /// When true, shows a top-right strip: "Tutorial on/off" + switch.
  /// Set false when the host screen places the same control elsewhere (e.g. home app bar).
  final bool showEmbeddedToggle;

  const TutorialWrapper({
    super.key,
    required this.screenKey,
    required this.child,
    this.showEmbeddedToggle = true,
  });

  @override
  State<TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends State<TutorialWrapper> with RouteAware {
  final _svc = TutorialService();
  bool _speaking = false;
  bool _ready = false;
  ModalRoute<dynamic>? _route;
  DateTime? _lastScheduledPlay;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onTutorialChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _svc.init();
    if (mounted) setState(() => _ready = true);
  }

  void _onTutorialChanged() {
    if (!mounted) return;
    setState(() {});
    if (_svc.isEnabled) {
      _scheduleTutorialPlay();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      appRouteObserver.unsubscribe(this);
      appRouteObserver.subscribe(this, route);
      _route = route;
    }
  }

  /// Each time this route becomes the visible top route (including returning
  /// from another screen), play tutorial when enabled.
  void _scheduleTutorialPlay() {
    Future.microtask(() async {
      await _svc.init();
      if (!mounted || !_svc.isEnabled) return;

      final now = DateTime.now();
      if (_lastScheduledPlay != null &&
          now.difference(_lastScheduledPlay!) <
              const Duration(milliseconds: 900)) {
        return;
      }
      _lastScheduledPlay = now;

      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted || !_svc.isEnabled) return;

      await _autoPlay();
    });
  }

  @override
  void didPush() {
    _scheduleTutorialPlay();
  }

  @override
  void didPopNext() {
    _scheduleTutorialPlay();
  }

  Future<void> _autoPlay() async {
    if (!mounted) return;
    setState(() => _speaking = true);
    await _svc.speak(widget.screenKey);
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _replay() async {
    _lastScheduledPlay = null;
    setState(() => _speaking = true);
    await _svc.speak(widget.screenKey);
    if (mounted) setState(() => _speaking = false);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _svc.removeListener(_onTutorialChanged);
    _svc.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (widget.showEmbeddedToggle) ...[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Material(
                    color: AppColors.surface.withValues(alpha: 0.94),
                    elevation: 1,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _svc.isEnabled ? 'Tutorial on' : 'Tutorial off',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _svc.isEnabled
                                  ? AppColors.primaryDark
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Switch.adaptive(
                            value: _svc.isEnabled,
                            onChanged: (v) => _svc.setEnabled(v),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        Positioned(
          bottom: 90,
          left: 16,
          child: IgnorePointer(
            ignoring: !(_ready && _svc.isEnabled),
            child: AnimatedOpacity(
              opacity: (_ready && _svc.isEnabled) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Tooltip(
                message: 'Replay tutorial audio',
                child: FloatingActionButton.small(
                  heroTag: 'tutorial_${widget.screenKey}',
                  onPressed: _speaking || !_svc.isEnabled ? null : _replay,
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: _speaking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.replay, color: Colors.green),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
