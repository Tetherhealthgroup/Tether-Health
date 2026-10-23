# Unplug v2.1 — platform submissions

Addendum §5 puts two items before any code, because both take weeks and neither
outcome is guaranteed:

1. Apple's `FamilyControls` distribution entitlement
2. Google Play's declaration for the chosen intercept method

The drafts below are ready to submit. **Neither has been submitted.** Submission
needs the Tether Apple Developer account and the Play Console account, and is a
decision about what the company is asking for, not an engineering step.

Until the Apple entitlement is granted, the iOS module builds and runs but
`requestAuthorization` fails on a real device — which is exactly what screen I
reports, and the §5 risk register's only **Critical** row.

---

## 1. Apple — Family Controls (Distribution) entitlement

Submit at <https://developer.apple.com/contact/request/family-controls-distribution>
with the Tether Apple Developer account.

**App name:** Tether Health
**Bundle identifier:** `com.TetherHealthLLC.tetherhealth`. The three extensions
are suffixed `.unplugmonitor`, `.unplugshield` and `.unplugshieldaction`.

**What the app does**

> Tether Health is a digital health application whose BreatheFree programme supports
> people trying to stop smoking,
> delivered through healthcare providers and through self-guided programmes. Its
> Unplug module supports the screen habits that sit alongside a quit attempt: the
> person chooses which apps to slow down, and the app interrupts those apps with
> a pause rather than blocking them outright.

**Why Family Controls is needed**

> Two reasons.
>
> First, the intervention is the intercept. Advice about screen time that cannot
> place anything between a person and the app they reach for reflexively does not
> work; `ManagedSettings` shielding is the only supported way to do that on iOS.
>
> Second, some programmes are delivered to under-13s with a guardian. That path
> requires `requestAuthorization(for: .child)`, an iCloud Family, and the
> guardian's Screen Time passcode on the child's device. The app will not attempt
> to shield a minor's device by any other route.

**How the entitlement is used**

> - `FamilyActivityPicker` for selection. The app never resolves, stores or
>   transmits an `ApplicationToken`; they stay on device, opaque.
> - `ManagedSettingsStore` to shield the selected set, at tier 2 and above of a
>   ladder the person or their clinician sets.
> - `DeviceActivityCenter` for one daily schedule with a usage threshold.
> - Three extensions: `DeviceActivityMonitor`, `ShieldConfiguration`,
>   `ShieldAction`, sharing state through one App Group.

**What is not done with it**

> No app identity leaves the device. No data collected through Family Controls is
> sold, shared with third parties or used for advertising. The app ships no
> analytics SDK, no crash reporter that collects identifiers and no session
> replay, on any profile — this is enforced by a test in the repository
> (`test/no_third_party_sdks_test.dart`). Child profiles retain nothing on device
> beyond 30 days, and only aggregate adherence is synced.

**Category positioning**

> The app is not submitted to the Kids Category. It is a health app a guardian
> installs, which carries a child profile — not an app children discover and
> install themselves.

---

## 2. Google Play — permissions declaration

Two declarations are needed in the Play Console, both under
**Policy → App content → Sensitive app permissions**.

### 2.1 `SYSTEM_ALERT_WINDOW` (Display over other apps)

**Core functionality that requires it**

> The intercept. When a person opens an app they asked the module to slow down,
> an overlay presents a pause, the reason they gave for choosing that app, and a
> way through it. There is no alternative API that can draw over an arbitrary
> foreground app.

**Why an alternative is not workable**

> A notification cannot interrupt a reflex that has already opened the app, and a
> full-screen intent is not deliverable for this case.

### 2.2 Foreground service — `specialUse`

**Declared type:** `specialUse`, not `dataSync` and not `mediaPlayback`.
Mislabelling a foreground service is itself a policy problem.

**Subtype description** (as declared in `AndroidManifest.xml`):

> Watches for the apps the person asked this app to shield, so the intercept can
> be drawn over them. Runs only while screen-time support is switched on.

**Why a foreground service is required**

> Detecting that a shielded app has come to the front requires polling
> `UsageStatsManager` continuously while protection is on. A background job
> cannot poll at a one-second cadence, and the person has explicitly asked for
> this protection.

### 2.3 The declaration we are deliberately **not** making

`AccessibilityService` would detect a foreground app instantly instead of within
about a second. Addendum §2.2 rejects it: Google requires a declaration
justifying accessibility use, and blockers using it are routinely rejected or
removed. A second of delay is a minor cost. A removed app is a dead programme.

`QUERY_ALL_PACKAGES` is also not requested. The manifest declares a `<queries>`
entry for launcher activities instead, which is what the picker and the usage
report actually need.

### 2.4 Data safety form

| Question | Answer |
|---|---|
| Does the app collect or share user data? | Screen-time data is processed **on device only** |
| Is data transmitted off device? | Only aggregate adherence, and only where a programme includes a care team the person has consented to |
| Is data sold or shared with third parties? | No |
| Is data used for advertising? | No |
| Can a user request deletion? | Yes — `purgeLocalData` wipes everything the module holds on the device |
| Is the data encrypted in transit? | Yes, where anything is transmitted at all |

---

## 3. Order of operations

1. Submit the Apple request. It is the long pole and the only Critical risk.
2. Prepare the Play declarations now; they are only submitted at release.
3. While waiting on Apple: the Android side can be finished and tested, and the
   iOS side builds and runs against the simulator without the entitlement. What
   cannot be tested until it is granted is `requestAuthorization` on a device.
4. If Apple declines, §5's fallback applies: a coach-mode-only iOS build that
   tracks and nudges without shielding. That is a smaller product, and the
   decision to ship it belongs to the programme, not to engineering.
