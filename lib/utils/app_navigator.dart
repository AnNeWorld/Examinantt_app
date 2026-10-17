import 'dart:async';
import 'package:flutter/material.dart';

/// AppNavigationObserver tracks the active route stack and current route name.
class AppNavigationObserver extends NavigatorObserver {
  final List<Route<dynamic>> _routeStack = [];

  String? get currentRouteName {
    if (_routeStack.isEmpty) return null;
    return _routeStack.last.settings.name;
  }

  Route<dynamic>? get currentRoute => _routeStack.isNotEmpty ? _routeStack.last : null;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _routeStack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _routeStack.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routeStack.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      final index = _routeStack.indexOf(oldRoute);
      if (index != -1 && newRoute != null) {
        _routeStack[index] = newRoute;
      } else {
        _routeStack.remove(oldRoute);
        if (newRoute != null) _routeStack.add(newRoute);
      }
    } else if (newRoute != null) {
      _routeStack.add(newRoute);
    }
  }
}

/// Centralized, safe navigation utility to prevent:
/// 1. Duplicate pushes of the same screen onto the navigation stack.
/// 2. Multiple rapid clicks / taps triggering duplicate navigation.
/// 3. In-flight route overlapping.
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final AppNavigationObserver observer = AppNavigationObserver();

  static bool _isNavigating = false;
  static DateTime _lastNavTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  /// Pushes either a [Widget] or a [Route] safely. Returns null if navigation
  /// is currently in flight or if the destination is already the active top route.
  static Future<T?> push<T>(
    BuildContext context,
    dynamic pageOrRoute, {
    String? routeName,
    bool preventDuplicates = true,
  }) async {
    final now = DateTime.now();

    // 1. Guard against rapid multiple taps and in-flight transitions
    if (_isNavigating || now.difference(_lastNavTime) < _debounceDuration) {
      debugPrint('[AppNavigator] Blocked rapid/in-flight navigation');
      return null;
    }

    final Route<T> route;
    String targetName = routeName ?? '';

    if (pageOrRoute is MaterialPageRoute<T>) {
      if (routeName != null) {
        targetName = routeName;
      } else if (pageOrRoute.settings.name != null) {
        targetName = pageOrRoute.settings.name!;
      } else {
        try {
          final dummyWidget = pageOrRoute.builder(context);
          targetName = dummyWidget.runtimeType.toString();
        } catch (_) {
          targetName = pageOrRoute.runtimeType.toString();
        }
      }
      route = MaterialPageRoute<T>(
        builder: pageOrRoute.builder,
        settings: RouteSettings(name: targetName),
      );
    } else if (pageOrRoute is Route<T>) {
      route = pageOrRoute;
      targetName = routeName ?? route.settings.name ?? route.runtimeType.toString();
    } else if (pageOrRoute is Widget) {
      targetName = routeName ?? pageOrRoute.runtimeType.toString();
      route = MaterialPageRoute<T>(
        builder: (_) => pageOrRoute,
        settings: RouteSettings(name: targetName),
      );
    } else {
      throw ArgumentError('pageOrRoute must be a Widget or a Route');
    }

    // 2. Guard against duplicate pushes if destination is already the active route
    if (preventDuplicates && observer.currentRouteName == targetName) {
      debugPrint('[AppNavigator] Blocked duplicate navigation: $targetName is already the active route');
      return null;
    }

    _isNavigating = true;
    _lastNavTime = now;

    try {
      return await Navigator.of(context).push<T>(route);
    } finally {
      // Release lock after screen transition has begun
      Future.delayed(const Duration(milliseconds: 400), () {
        _isNavigating = false;
      });
    }
  }

  /// Pushes [pageOrRoute] as a replacement safely.
  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    dynamic pageOrRoute, {
    String? routeName,
    TO? result,
  }) async {
    final now = DateTime.now();

    if (_isNavigating || now.difference(_lastNavTime) < _debounceDuration) {
      return null;
    }

    final Route<T> route;
    String targetName = routeName ?? '';

    if (pageOrRoute is MaterialPageRoute<T>) {
      if (routeName != null) {
        targetName = routeName;
      } else if (pageOrRoute.settings.name != null) {
        targetName = pageOrRoute.settings.name!;
      } else {
        try {
          final dummyWidget = pageOrRoute.builder(context);
          targetName = dummyWidget.runtimeType.toString();
        } catch (_) {
          targetName = pageOrRoute.runtimeType.toString();
        }
      }
      route = MaterialPageRoute<T>(
        builder: pageOrRoute.builder,
        settings: RouteSettings(name: targetName),
      );
    } else if (pageOrRoute is Route<T>) {
      route = pageOrRoute;
      targetName = routeName ?? route.settings.name ?? route.runtimeType.toString();
    } else if (pageOrRoute is Widget) {
      targetName = routeName ?? pageOrRoute.runtimeType.toString();
      route = MaterialPageRoute<T>(
        builder: (_) => pageOrRoute,
        settings: RouteSettings(name: targetName),
      );
    } else {
      throw ArgumentError('pageOrRoute must be a Widget or a Route');
    }

    _isNavigating = true;
    _lastNavTime = now;

    try {
      return await Navigator.of(context).pushReplacement<T, TO>(route, result: result);
    } finally {
      Future.delayed(const Duration(milliseconds: 400), () {
        _isNavigating = false;
      });
    }
  }

  /// Pushes [pageOrRoute] and removes previous routes until [predicate] returns true.
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    dynamic pageOrRoute,
    RoutePredicate predicate, {
    String? routeName,
  }) async {
    final now = DateTime.now();

    if (_isNavigating || now.difference(_lastNavTime) < _debounceDuration) {
      return null;
    }

    final Route<T> route;
    String targetName = routeName ?? '';

    if (pageOrRoute is MaterialPageRoute<T>) {
      if (routeName != null) {
        targetName = routeName;
      } else if (pageOrRoute.settings.name != null) {
        targetName = pageOrRoute.settings.name!;
      } else {
        try {
          final dummyWidget = pageOrRoute.builder(context);
          targetName = dummyWidget.runtimeType.toString();
        } catch (_) {
          targetName = pageOrRoute.runtimeType.toString();
        }
      }
      route = MaterialPageRoute<T>(
        builder: pageOrRoute.builder,
        settings: RouteSettings(name: targetName),
      );
    } else if (pageOrRoute is Route<T>) {
      route = pageOrRoute;
      targetName = routeName ?? route.settings.name ?? route.runtimeType.toString();
    } else if (pageOrRoute is Widget) {
      targetName = routeName ?? pageOrRoute.runtimeType.toString();
      route = MaterialPageRoute<T>(
        builder: (_) => pageOrRoute,
        settings: RouteSettings(name: targetName),
      );
    } else {
      throw ArgumentError('pageOrRoute must be a Widget or a Route');
    }

    _isNavigating = true;
    _lastNavTime = now;

    try {
      return await Navigator.of(context).pushAndRemoveUntil<T>(route, predicate);
    } finally {
      Future.delayed(const Duration(milliseconds: 400), () {
        _isNavigating = false;
      });
    }
  }

  /// Pops the current route safely.
  static void pop<T>(BuildContext context, [T? result]) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  /// Wraps any callback to debounce rapid repeated clicks.
  static VoidCallback? safeTap(VoidCallback? action, [Duration duration = const Duration(milliseconds: 500)]) {
    if (action == null) return null;
    DateTime lastTap = DateTime.fromMillisecondsSinceEpoch(0);
    return () {
      final now = DateTime.now();
      if (now.difference(lastTap) < duration || _isNavigating) {
        return;
      }
      lastTap = now;
      action();
    };
  }
}

/// Context extension for quick safe navigation syntax
extension SafeNavigationExtension on BuildContext {
  Future<T?> pushSafe<T>(dynamic pageOrRoute, {String? routeName, bool preventDuplicates = true}) {
    return AppNavigator.push<T>(this, pageOrRoute, routeName: routeName, preventDuplicates: preventDuplicates);
  }

  Future<T?> pushReplacementSafe<T, TO>(dynamic pageOrRoute, {String? routeName, TO? result}) {
    return AppNavigator.pushReplacement<T, TO>(this, pageOrRoute, routeName: routeName, result: result);
  }

  void popSafe<T>([T? result]) {
    AppNavigator.pop<T>(this, result);
  }
}
