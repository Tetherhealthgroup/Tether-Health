import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/screen_spec.dart';
import '../models/tap_target.dart';

class ApprovedScreenViewport extends StatelessWidget {
  const ApprovedScreenViewport({
    required this.spec,
    required this.onPrevious,
    required this.onNext,
    required this.onTarget,
    this.showHotspots = false,
    super.key,
  });

  static const _referenceSize = Size(1290, 2796);

  final ScreenSpec spec;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<AppTapTarget> onTarget;
  final bool showHotspots;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): onPrevious,
        const SingleActivator(LogicalKeyboardKey.arrowRight): onNext,
        const SingleActivator(LogicalKeyboardKey.pageUp): onPrevious,
        const SingleActivator(LogicalKeyboardKey.pageDown): onNext,
      },
      child: Focus(
        autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -250) onNext();
            if (velocity > 250) onPrevious();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fitted = _contain(_referenceSize, constraints.biggest);
              final left = (constraints.maxWidth - fitted.width) / 2;
              final top = (constraints.maxHeight - fitted.height) / 2;

              return Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
                  Positioned(
                    left: left,
                    top: top,
                    width: fitted.width,
                    height: fitted.height,
                    child: Semantics(
                      label:
                          'Screen ${spec.number} of ${approvedScreens.length}: ${spec.title}',
                      image: true,
                      child: Image.asset(
                        spec.assetPath,
                        key: ValueKey('screen-image-${spec.number}'),
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  for (final target in tapTargetsFor(spec.number - 1))
                    _PositionedTarget(
                      target: target,
                      fittedSize: fitted,
                      leftOffset: left,
                      topOffset: top,
                      showHotspot: showHotspots,
                      onTap: () => onTarget(target),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Size _contain(Size source, Size destination) {
    if (destination.width <= 0 || destination.height <= 0) return Size.zero;
    final sourceAspect = source.width / source.height;
    final destinationAspect = destination.width / destination.height;

    if (destinationAspect > sourceAspect) {
      return Size(destination.height * sourceAspect, destination.height);
    }
    return Size(destination.width, destination.width / sourceAspect);
  }
}

class _PositionedTarget extends StatelessWidget {
  const _PositionedTarget({
    required this.target,
    required this.fittedSize,
    required this.leftOffset,
    required this.topOffset,
    required this.showHotspot,
    required this.onTap,
  });

  final AppTapTarget target;
  final Size fittedSize;
  final double leftOffset;
  final double topOffset;
  final bool showHotspot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rect = target.normalizedRect;
    final button = Material(
      color: showHotspot ? const Color(0x5538A878) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: showHotspot
            ? Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xDD123C37),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    target.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );

    return Positioned(
      left: leftOffset + (rect.left * fittedSize.width),
      top: topOffset + (rect.top * fittedSize.height),
      width: rect.width * fittedSize.width,
      height: rect.height * fittedSize.height,
      child: Semantics(
        label: target.label,
        button: true,
        child: showHotspot
            ? Tooltip(message: target.label, child: button)
            : button,
      ),
    );
  }
}
