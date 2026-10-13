import 'package:flutter/material.dart';

/// Shown instead of the app when a release build starts without valid service
/// configuration. The message holds only variable names, never values.
class MisconfiguredBuildApp extends StatelessWidget {
  const MisconfiguredBuildApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Semantics(
                  liveRegion: true,
                  child: Text(message, textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ),
      );
}
