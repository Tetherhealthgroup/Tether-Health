import 'package:flutter/material.dart';

import '../router/app_router.dart';
import '../ui/ui.dart';

/// Developer gallery: every screen and state from the spec, grouped by flow.
/// Tap to open it with real navigation, so every button can be followed.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final byFlow = <String, List<(String, String, String, String)>>{};
    for (final e in AppRouter.catalog) {
      byFlow.putIfAbsent(e.$3, () => []).add(e);
    }
    return Scaffold(
      backgroundColor: TColors.cream,
      appBar: AppBar(title: Text('Tether Health · ${AppRouter.catalog.length} screens'), backgroundColor: TColors.cream),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final flow in byFlow.entries) ...[
            Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 6), child: TEyebrow(flow.key)),
            Card(
              color: TColors.paper,
              child: Column(children: [
                for (final s in flow.value)
                  ListTile(
                    title: Text(s.$2),
                    subtitle: Text(s.$4),
                    trailing: AppRouter.sheets.contains(s.$4) ? const TPill('sheet') : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pushNamed(s.$4),
                  ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
