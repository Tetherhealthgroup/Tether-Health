# Store description for the multi-program app (not for the current build)

**Status: draft, held back.** Use this text only when a release build ships
all eleven programs. Today's release builds include BreatheFree, Heartwise,
Steady and ClearAir only (see `data-safety.md`, "What build these answers
describe"), and both stores reject listings that describe features the app
does not have. The live drafts are `metadata/android/en-US/` and
`ios/fastlane/metadata/en-US/`.

Program names, areas and purposes come from the design
(`tether_ui/spec/programs.json` and each program's intro screen in
`tether_ui/spec/l10n/en.arb`). Wording that could read as a health outcome
claim was left out (for example Beacon's design tagline "Lower your risk").
Needs clinical and legal review before use.

## The eleven programs

| Program | Area | One-line purpose |
|---|---|---|
| BreatheFree | Tobacco & nicotine | Plan, practice and get through cravings, with no judgment. A slip never erases your wins. |
| ScrollFree | Social media use | Notice what pulls you in, set a goal that feels doable, and pause for 60 seconds when the urge hits. |
| ClearAir | Respiratory health | Check your zone, log symptoms and know what to do, using the plan your clinician gave you. |
| Heartwise | Cardiovascular health | Log blood pressure and cholesterol, see trends and prepare for visits. |
| Steady | Diabetes & metabolic health | Log readings, see patterns around meals and sleep, and follow the low plan your clinician gave you. Steady never counts calories. |
| Renew | Kidney & liver health | Keep track of kidney and liver lab results, with reminders for the checks your clinician asks for. |
| Nourish | Obesity & nutrition | Food without judgment: one weekly habit at a time, adding rather than restricting, with weight off by default. |
| Stride | Healthy aging | Move well, stay well: short sessions, home safety and an optional caregiver. |
| Ease | Mental & behavioral health | Support for how you feel: a 30-second mood check-in, optional private screening, and 988 one tap away. |
| Checkup | Preventive health | What's due for you, in one place, based on USPSTF and CDC guidance. |
| Beacon | Cancer | Everyday steps around smoking, sun, alcohol and activity, screening linked with Checkup, and support with questions during treatment. |

## Full description (draft, under 4000 characters)

```
Care that meets you where you are.

Tether Health offers small steps, practical support and no judgment, for the parts of your health you choose. Pick the programs that fit your life. You can add, pause or leave a program anytime.

PROGRAMS

• BreatheFree (tobacco and nicotine): plan, practice and get through cravings, with no judgment.
• ScrollFree (social media use): notice what pulls you in, set a goal that feels doable, and pause when the urge hits.
• ClearAir (respiratory health): check your zone, log symptoms and follow the plan your clinician gave you.
• Heartwise (heart health): log blood pressure and cholesterol, see trends and prepare for visits.
• Steady (diabetes and metabolic health): log readings and notice patterns, without judgment. Steady never counts calories.
• Renew (kidney and liver health): keep track of lab results, with reminders for the checks your clinician asks for.
• Nourish (nutrition): food without judgment, one habit at a time.
• Stride (healthy aging): move well, stay well, with short sessions and home safety.
• Ease (mental and behavioral health): support for how you feel, with a quick mood check-in and 988 one tap away.
• Checkup (preventive health): what's due for you, in one place.
• Beacon (cancer): everyday steps, screening reminders and support with questions.

YOUR DATA, YOUR CHOICE

• No ads.
• You choose what each program receives.
• Export or delete your account and data at any time in the app.

IMPORTANT

Tether Health supports everyday self-care. It is not medical advice and does not replace care from your clinician. If you think you are having an emergency, call 911 or your local emergency number.
```

Before using it, check every line against the build being submitted (for
example "see trends", "reminders", "you choose what each program receives"
and the Ease screening all depend on features that are design-only today),
and redo `data-safety.md` and `ios/Runner/PrivacyInfo.xcprivacy` for any new
data the build collects.
