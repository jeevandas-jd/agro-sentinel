import 'package:flutter/widgets.dart';

/// Used with [TutorialWrapper] so tutorial audio can run on every visit,
/// including when returning from a pushed route (see [RouteAware.didPopNext]).
final RouteObserver<ModalRoute<dynamic>> appRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();
