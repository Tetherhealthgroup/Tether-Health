// Native views drawn inside the tether_ui screens.
import 'package:flutter/widgets.dart';
import 'package:tether_ui/ui/ui.dart';

/// The native slot ids on screens a member can reach, with the builder that
/// draws each one. A null builder means none is registered yet, and the
/// screen shows the kit's placeholder; every id needs a builder before the
/// tether_ui screens ship.
const Map<String, WidgetBuilder?> nativeSlotBuilders = {
  // Today's Screen Time minutes (sf_home_unplug).
  'ios.deviceActivityReport.today': null,
  // This week's Screen Time minutes (sf_week_unplug).
  'ios.deviceActivityReport.week': null,
  // Apple's app picker (sf_unplug_picker_ios).
  'ios.familyActivityPicker': null,
};

/// Registers every builder in [nativeSlotBuilders]. Registers none today.
void registerNativeSlots() {
  for (final MapEntry(:key, :value) in nativeSlotBuilders.entries) {
    if (value != null) TNativeSlot.register(key, value);
  }
}
