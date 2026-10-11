# Unplug v2.1 — Integration Addendum
### Flutter architecture · under-13 stack · mixed-delivery roles

Read alongside the v2 spec. This supersedes v2 §5.3 (data), §5.5 (compliance), and §7 (scope).

---

## 1. The constraint that reshapes the product

Before the architecture: **on iOS you cannot learn which apps a user is using.**

Apple's `FamilyControls` framework returns `ApplicationToken` objects that are opaque and device-local. You can shield them, you can render them with Apple's own `Label(token)` view inside your app, and that's it. You cannot resolve a token to "Instagram", you cannot transmit it, and the `DeviceActivityReport` extension that computes usage detail **has no network access by design**.

What you can actually get out of iOS:
- Threshold callbacks — "user crossed 30 min on the selected set" — via `DeviceActivityMonitor`
- Shield events — how often the intercept fired, how often it was dismissed vs overridden
- Anything the user tells you directly

Android is the opposite: `UsageStatsManager` gives you real package names and real durations.

**Consequences you must design for now, not later:**

| v2 said | Reality |
|---|---|
| Per-app named minutes in the clinician dashboard | iOS: not available. Show "Selected apps" as an aggregate, plus user-labelled groups ("Video apps", "Messaging") |
| Baseline report with per-app split | iOS: aggregate + opens + time-of-day only. Android: full split |
| Open-count budget (M3) | iOS: approximate via shield-event counts, not true launch counts |

**Design the dashboard to the iOS floor and treat Android's extra detail as a bonus, or your two platforms will tell clinicians different stories about the same patient.** Set that expectation with the care team in writing during Phase 1 — a clinician who thinks they're seeing per-app data on iOS will make decisions on numbers that don't exist.

---

## 2. Flutter architecture

Flutter is fine for everything except the part that does the actual work. Roughly 80% of this module is Dart; the 20% that isn't is the hard 20%.

```
┌─────────────────────────────────────────────────┐
│  FLUTTER (Dart)                                 │
│  All screens A–L · tier logic · module config   │
│  local DB (Drift/SQLite) · sync · Tether SSO    │
└───────────────────┬─────────────────────────────┘
                    │  Pigeon-generated channel
        ┌───────────┴────────────┐
        ▼                        ▼
┌──────────────────┐    ┌──────────────────────┐
│ iOS (Swift)      │    │ Android (Kotlin)     │
│ FamilyControls   │    │ UsageStatsManager    │
│ ManagedSettings  │    │ Foreground service   │
│ DeviceActivity   │    │ Overlay intercept    │
│ + 3 EXTENSIONS ◄─┼─── these cannot run      │
└──────────────────┘    │ Flutter              │
                        └──────────────────────┘
```

### 2.1 iOS — three app extensions, all pure Swift

| Extension | Job | Hard limit |
|---|---|---|
| `DeviceActivityMonitor` | Fires on schedule start/end and usage thresholds; applies and lifts shields | Separate process, very tight memory budget, no Flutter |
| `ShieldConfiguration` | Draws the intercept screen (screen C) | **Must be UIKit/SwiftUI. Your Flutter intercept UI cannot be reused — it has to be rebuilt natively, twice** |
| `ShieldAction` | Handles the intercept buttons | Limited execution window |

Practical implications:
- **Screen C gets built three times** — once in Dart (for in-app previews and settings), once in SwiftUI, once as an Android overlay. Budget for it, and keep the design system values (colours, copy strings) in a shared JSON the three read, or they will drift apart within two sprints.
- Extensions share state with the main app only through an **App Group** container. Tier state, module config, and override counts live there.
- Effort gates (M5) run inside `ShieldAction` — so a camera-based pushup counter is not realistic on iOS. Keep iOS effort gates to breathing, typed commitment, and simple puzzles.

### 2.2 Android — the policy choice

Two ways to detect and intercept a foreground app:

| Approach | Latency | Play Store risk |
|---|---|---|
| `AccessibilityService` | Instant | **High.** Google requires a declaration justifying accessibility use; blockers are routinely rejected or removed |
| Foreground service polling `UsageStatsManager` + `SYSTEM_ALERT_WINDOW` overlay | 0.5–1.5s | Low |

**Recommendation: ship the polling approach.** A one-second delay before the shield appears is a minor UX cost; a removed app is a dead program. Also budget for OEM battery-management testing — Xiaomi, Samsung, Oppo and OnePlus all kill foreground services differently, and this is the single most common source of "the blocker just stopped working" support tickets.

### 2.3 The channel interface

Use **Pigeon**, not raw `MethodChannel` — you'll have three implementations of the same contract and type-safety is worth the setup. Keep the surface small:

```
applyShield(moduleConfig, appSelection)     liftShield(reason)
startSession(duration, scope, strict)       endSession(overrideReason?)
setThresholds(minutes[], opens[])           requestAuthorization(mode)
onThresholdCrossed →                        onShieldShown →
onShieldDismissed →                         onOverrideUsed →
```

Everything above that line is Dart. Resist letting tier logic leak into native code.

---

## 3. Under-13 — what it actually costs

This is the most expensive answer you gave, and it's worth confirming it's really in scope.

### 3.1 The iOS blocker for minors

To shield a child's device on iOS you need `requestAuthorization(for: .child)`, which requires:
- the child's device signed into an **iCloud Family**, with the child under 18 in that family
- the **parent's Apple ID and Screen Time passcode** entered on the child's device during setup

If a family isn't set up in Apple Family Sharing, this path simply does not work, and no amount of engineering fixes it. Your onboarding for under-13 must therefore include a **"Set up Family Sharing first"** branch with step-by-step guidance and a realistic failure state. Expect this to be your largest onboarding drop-off on iOS.

### 3.2 Account model

**The child does not get an account.** Provision as: guardian's Tether account → child profile → child device paired via code.

- Guardian completes COPPA verifiable parental consent through Tether's existing minor-enrollment flow — don't build a second consent mechanism
- Child-facing UI: no free-text fields anywhere (no journal, no custom intentions, no names), pick-from-list only
- No streaks, no comparisons, no shareable anything
- Retention: 30 days, on-device; only aggregate adherence syncs
- No third-party SDKs on child profiles — no analytics, no crash reporters that collect identifiers, no session replay. Audit your Flutter package tree for this; it's easy to violate accidentally through a transitive dependency

### 3.3 Store positioning

Do **not** submit to Apple's Kids Category or Google's Designed for Families programme. Those bring their own rule sets and are meant for apps children discover and install themselves. This is a health app installed by a guardian that happens to have a child profile — position it that way and the review path is much simpler.

---

## 4. Mixed delivery — the role matrix

"Mix of these" means permissions can't be hardcoded to a tier. Every program instance declares a delivery track, and that track determines who holds which capability.

| Capability | Clinician track | Coach track | Self-guided |
|---|---|---|---|
| View derived metrics | Yes | Yes | Self only |
| View journal / mood tags | With consent | **No** | Self only |
| Set tier ceiling | Yes | Yes | Self |
| Approve escalation | Yes | Yes | Automatic on evidence |
| Approve limit *increase* | Yes | Yes | 24h cool-off |
| Receive engagement flags | Yes | Yes | In-app only |
| Receive **distress** flags | Yes | **Route to clinician** | **Resource card + documented triage** |
| Override guardian settings | Case-by-case, logged | No | n/a |

### 4.1 The one thing to get right

**A distress signal must never terminate at a non-clinical coach.** If a user repeatedly tags urges as `Anxious` or `Lonely`, or writes something concerning, the coach track and the self-guided track both need a defined route to a licensed person. Build this as a configurable escalation policy per program, owned by Tether's clinical leadership, not as app logic you decide.

For self-guided users specifically: the app is not treatment and must say so at enrollment. The distress path there is an in-app resource card plus, if Tether offers it, a one-tap route into a clinician-led program.

### 4.2 Program templates, per track

```
Template: "Family Reset — under 13"     track: coach
  tiers 1–2 only · M1 M2 M8 M9 · guardian sets all · no journal · 6 weeks

Template: "Teen Digital Health"          track: clinician
  tiers 1–4 · M1 M2 M3 M5 M8 M9 M12 · guardian ceiling + teen self-set
  journal opt-in · BSMAS at 0/4/8 · 8 weeks

Template: "Adult Self-Guided"            track: self
  tiers 0–5 · all modules · automatic escalation · 12 weeks, no human review
```

---

## 5. Revised phasing and risk

**Start the two long-lead items on day one, before any code:**
1. Apple `FamilyControls` distribution entitlement application — weeks, outcome not guaranteed
2. Google Play declaration for whichever intercept approach you choose

**Phase 1 (8–10 wks) — Instrument.** Flutter shell + SSO into Tether, Pigeon contract, Android `UsageStatsManager` read, iOS threshold monitoring, Observe Week, baseline report, read-only care-team dashboard. *Ships before blocking exists, and validates the iOS data ceiling with real clinicians early.*

**Phase 2 (10–12 wks) — Intervene.** Three implementations of the intercept, M1/M2/M3/M4/M8, tiers 0–2, Urge SOS. Longer than v2 estimated because of the triple UI build.

**Phase 3 (8 wks) — Escalate & minors.** M5/M6/M12, tiers 3–4, role matrix, guardian zone, Family Sharing onboarding branch, COPPA flow, child profile lockdown.

**Phase 4** — M7 physical key, M11 cross-device, template authoring.

### Risk register

| Risk | Severity | Mitigation |
|---|---|---|
| Apple entitlement denied or delayed | **Critical — no iOS product** | Apply now; have a Coach-mode-only iOS fallback that tracks and nudges without shielding |
| Family Sharing not set up in household | High, under-13 only | Guided branch in onboarding; honest failure state |
| iOS/Android data asymmetry misleads clinicians | High | Design dashboard to iOS floor; label platform on every patient record |
| OEM kills the Android foreground service | High | Device test matrix; in-app health check that warns the user when tracking has stopped |
| Intercept UI drift across three codebases | Medium | Shared design-token and copy JSON; one visual regression suite |
| Play Store rejection of blocking method | Medium | Polling over AccessibilityService; declaration prepared in advance |

---

## 6. What I'd want to confirm next

1. Is under-13 genuinely required for v1, or could it follow? It adds roughly 8 weeks and the entire COPPA and Family Sharing surface.
2. Does Tether have an existing clinical escalation protocol for distress signals? §4.1 should point at it rather than invent one.
3. Do any programs cover substance use? If so, 42 CFR Part 2 changes the consent architecture, not just the paperwork.
4. Is there an existing Tether design system in Flutter? The intercept screens need its tokens exported in a platform-neutral format.
