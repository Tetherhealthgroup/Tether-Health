import 'package:flutter/material.dart';

import '../models/prototype_catalog.dart';
import '../models/screen_spec.dart';
import '../models/tap_target.dart';
import '../theme/app_colors.dart';
import '../unplug/models/unplug_screen_spec.dart';
import '../unplug/screens/unplug_screen_host.dart';
import '../widgets/approved_screen_viewport.dart';

class ApprovedScreenPlayer extends StatefulWidget {
  const ApprovedScreenPlayer({
    required this.currentIndex,
    required this.onSelectScreen,
    required this.onPrevious,
    required this.onNext,
    required this.onTarget,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectScreen;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<AppTapTarget> onTarget;

  @override
  State<ApprovedScreenPlayer> createState() => _ApprovedScreenPlayerState();
}

class _ApprovedScreenPlayerState extends State<ApprovedScreenPlayer> {
  bool _showHotspots = false;

  /// The screen body, whichever module the current entry belongs to.
  Widget _buildScreen(CatalogEntry entry, {required bool showHotspots}) {
    switch (entry) {
      case ApprovedCatalogEntry(:final spec):
        return ApprovedScreenViewport(
          spec: spec,
          showHotspots: showHotspots,
          onPrevious: widget.onPrevious,
          onNext: widget.onNext,
          onTarget: widget.onTarget,
        );
      case UnplugCatalogEntry(:final spec):
        return UnplugScreenHost(
          spec: spec,
          position: widget.currentIndex - unplugCatalogOffset + 1,
          total: unplugScreens.length,
          onPrevious: widget.onPrevious,
          onNext: widget.onNext,
          onSelectLetter: (letter) {
            final index = prototypeIndexOfLetter(letter);
            if (index >= 0) widget.onSelectScreen(index);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = prototypeCatalog[widget.currentIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _DesktopPlayer(
            entry: entry,
            currentIndex: widget.currentIndex,
            showHotspots: _showHotspots,
            onShowHotspotsChanged: (value) {
              setState(() => _showHotspots = value);
            },
            onSelectScreen: widget.onSelectScreen,
            onPrevious: widget.onPrevious,
            onNext: widget.onNext,
            screenBuilder: (showHotspots) =>
                _buildScreen(entry, showHotspots: showHotspots),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: _buildScreen(entry, showHotspots: false),
        );
      },
    );
  }
}

class _DesktopPlayer extends StatelessWidget {
  const _DesktopPlayer({
    required this.entry,
    required this.currentIndex,
    required this.showHotspots,
    required this.onShowHotspotsChanged,
    required this.onSelectScreen,
    required this.onPrevious,
    required this.onNext,
    required this.screenBuilder,
  });

  final CatalogEntry entry;
  final int currentIndex;
  final bool showHotspots;
  final ValueChanged<bool> onShowHotspotsChanged;
  final ValueChanged<int> onSelectScreen;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget Function(bool showHotspots) screenBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2724),
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 300,
              child: _ScreenNavigator(
                currentIndex: currentIndex,
                onSelectScreen: onSelectScreen,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _DesktopToolbar(
                    entry: entry,
                    currentIndex: currentIndex,
                    showHotspots: showHotspots,
                    onShowHotspotsChanged: onShowHotspotsChanged,
                    onPrevious: onPrevious,
                    onNext: onNext,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: AspectRatio(
                          aspectRatio: 1290 / 2796,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(42),
                              border: Border.all(
                                color: const Color(0xFF31534F),
                                width: 9,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x99000000),
                                  blurRadius: 40,
                                  offset: Offset(0, 20),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: screenBuilder(showHotspots),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 300,
              child: _DetailsPanel(
                entry: entry,
                currentIndex: currentIndex,
                onPrevious: onPrevious,
                onNext: onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenNavigator extends StatelessWidget {
  const _ScreenNavigator({
    required this.currentIndex,
    required this.onSelectScreen,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectScreen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.deepTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.air_rounded,
                        color: AppColors.lime,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Text(
                        'BreatheFree',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${approvedScreens.length} approved screens',
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: prototypeCatalog.length,
              itemBuilder: (context, index) {
                final item = prototypeCatalog[index];
                final selected = currentIndex == index;
                final header = index == unplugCatalogOffset
                    ? const _NavigatorHeading('Unplug v2.1 · screens A–L')
                    : null;

                final tile = Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: ListTile(
                    selected: selected,
                    selectedTileColor: AppColors.mint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minLeadingWidth: 30,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          selected ? AppColors.deepTeal : AppColors.cream,
                      foregroundColor:
                          selected ? Colors.white : AppColors.deepTeal,
                      child: Text(
                        item.badge,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item.sectionLabel,
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () => onSelectScreen(index),
                  ),
                );

                if (header == null) return tile;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [header, tile],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigatorHeading extends StatelessWidget {
  const _NavigatorHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.mutedTeal,
          fontSize: 10.5,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.entry,
    required this.currentIndex,
    required this.showHotspots,
    required this.onShowHotspotsChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final CatalogEntry entry;
  final int currentIndex;
  final bool showHotspots;
  final ValueChanged<bool> onShowHotspotsChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final approved = entry is ApprovedCatalogEntry;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Color(0xFF123C37),
        border: Border(bottom: BorderSide(color: Color(0xFF31534F))),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Previous screen',
            onPressed: currentIndex == 0 ? null : onPrevious,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: 'Next screen',
            onPressed: currentIndex == prototypeCatalog.length - 1
                ? null
                : onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              'Screen ${entry.badge} · ${entry.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            approved ? 'Show tap areas' : 'Tap areas are approved-screen only',
            style: const TextStyle(color: Color(0xFFBFD5CD), fontSize: 13),
          ),
          Switch(
            value: showHotspots && approved,
            onChanged: approved ? onShowHotspotsChanged : null,
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.entry,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
  });

  final CatalogEntry entry;
  final int currentIndex;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  String get _description => switch (entry) {
        ApprovedCatalogEntry(:final spec) => spec.description,
        UnplugCatalogEntry(:final spec) => spec.description,
      };

  List<Widget> get _facts => switch (entry) {
        ApprovedCatalogEntry() => const [
            _InfoRow(
              icon: Icons.phone_iphone_rounded,
              title: 'Reference',
              value: '430 × 932 pt',
            ),
            _InfoRow(
              icon: Icons.image_outlined,
              title: 'App Store asset',
              value: '1290 × 2796 px',
            ),
            _InfoRow(
              icon: Icons.devices_rounded,
              title: 'Targets',
              value: 'iOS · Android · Desktop · Web',
            ),
          ],
        UnplugCatalogEntry(:final spec) => [
            _InfoRow(
              icon: Icons.description_outlined,
              title: 'Specified by',
              value: 'Addendum ${spec.addendumRef}',
            ),
            const _InfoRow(
              icon: Icons.widgets_outlined,
              title: 'Rendering',
              value: 'Native widgets · no bitmap',
            ),
            const _InfoRow(
              icon: Icons.devices_rounded,
              title: 'Targets',
              value: 'iOS · Android · Desktop · Web',
            ),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                entry.sectionLabel.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.deepTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              entry.title,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _description,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 18),
            ..._facts,
            const Spacer(),
            const Text(
              'Use ← and →, swipe the phone preview, select a screen, or enable tap areas.',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: currentIndex == 0 ? null : onPrevious,
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: currentIndex == prototypeCatalog.length - 1
                        ? null
                        : onNext,
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: AppColors.deepTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
