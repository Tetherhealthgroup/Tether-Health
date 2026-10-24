// Platform variants: exactly four routes open as their Android variant, and
// nothing changes on iOS.
import 'dart:convert';
import 'dart:io';

import 'package:breathefree_patient/app/app_owned_routes.dart';
import 'package:breathefree_patient/app/variants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';

void main() {
  final routeOf = {
    for (final (id, _, _, route) in AppRouter.catalog) id: route
  };
  final idOf = {for (final (id, _, _, route) in AppRouter.catalog) route: id};

  test('exactly these four screen pairs are substituted on Android', () {
    expect(
      {
        for (final MapEntry(:key, :value) in androidRouteVariants.entries)
          idOf[key]: idOf[value],
      },
      {
        'sys_update': 'sys_update_android',
        'sf_screentime': 'sf_screentime_android',
        'sf_home_unplug': 'sf_home_unplug_android',
        'sf_unplug_health': 'sf_unplug_health_android',
      },
    );
  });

  test('each pair is an Android variant of its screen in the spec', () {
    final screens = jsonDecode(
      File('specs-and-design/tether_ui/spec/screens.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final MapEntry(:key, :value) in androidRouteVariants.entries) {
      final base = screens[idOf[key]] as Map<String, dynamic>;
      final variant = screens[idOf[value]] as Map<String, dynamic>;
      expect(base['route'], key);
      expect(variant['route'], value);
      expect(variant['state'].toString().toLowerCase(), contains('android'));
      expect(variant['variantOf'], base['variantOf'] ?? idOf[key]);
    }
  });

  for (final platform in TargetPlatform.values) {
    test('${platform.name}: the route settings carry the opened name', () {
      for (final route in AppRouter.screens.keys) {
        final opened = generateAppRoute(
          RouteSettings(name: route),
          platform: platform,
        );
        final expected = platform == TargetPlatform.android
            ? androidRouteVariants[route] ?? route
            : route;
        expect(opened, isNotNull, reason: route);
        expect(opened!.settings.name, expected, reason: route);
      }
    });
  }

  test('other states of a substituted screen are not substituted', () {
    for (final route in [
      Routes.sfUnplugHealthNotifications,
      Routes.sfUnplugHealthStopped,
      Routes.sfScreentimeDenied,
    ]) {
      expect(
        generateAppRoute(RouteSettings(name: route),
                platform: TargetPlatform.android)!
            .settings
            .name,
        route,
      );
    }
    expect(routeOf['sf_unplug_health'], Routes.sfUnplugHealth);
  });

  test('the developer gallery and unknown names are not routable', () {
    for (final name in [null, '/', 'gallery', '/gallery', '/dev/gallery', '']) {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        expect(
          generateAppRoute(RouteSettings(name: name), platform: platform),
          isNull,
          reason: '$name',
        );
      }
    }
  });

  test('app-owned routes never shadow a generated screen', () {
    expect(
      appOwnedRoutes.keys.where(AppRouter.screens.containsKey),
      isEmpty,
    );
  });
}
