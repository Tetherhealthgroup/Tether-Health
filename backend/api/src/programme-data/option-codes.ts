/**
 * Option codes of the programme event screens. A code is `slug(label)` of
 * the option label in specs-and-design/tether_ui/spec/screens.json; the parity test derives
 * every list from the spec, so a label change there fails the test until
 * the list here follows it.
 */

/** Longest code the database accepts (`^[a-z0-9_]{1,40}$`). */
const MAX_CODE_LENGTH = 40;

/**
 * Lowercase; typographic apostrophes and every other non-alphanumeric
 * character become `_`; runs collapse to one `_`; leading and trailing `_`
 * are trimmed; at most 40 characters.
 */
export function slug(label: string): string {
  return label
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, MAX_CODE_LENGTH)
    .replace(/_+$/g, "");
}

/** The database's code pattern. */
export const CODE_PATTERN = /^[a-z0-9_]{1,40}$/;

const caSymptoms = [
  "coughing",
  "wheezing",
  "short_of_breath",
  "chest_tightness",
  "woke_at_night",
] as const;

/** Every option list, in spec order. */
export const OPTION_CODES = {
  glucoseTiming: [
    "fasting",
    "before_meal",
    "2_h_after_meal",
    "bedtime",
    "other",
  ],
  glucoseFeelings: ["fine", "shaky", "sweaty", "tired", "thirsty"],
  zoneSymptoms: [...caSymptoms, "can_t_speak_in_full_sentences"],
  caSymptoms: [...caSymptoms],
  caSeverity: ["mild", "moderate", "severe"],
  caTriggers: ["cold_air", "smoke", "pollen", "exercise", "not_sure"],
  mood: ["very_low", "low", "okay", "good", "great"],
  moodTopics: [
    "work",
    "money",
    "family",
    "health",
    "lonely",
    "sleep",
    "thoughts_of_harming_myself",
    "not_sure",
  ],
  checkBackChange: ["worse", "same", "better"],
  reachedOut: ["yes_i_have_an_appointment", "not_yet", "i_don_t_want_to"],
  sessionSettings: ["audio_on", "large_text", "captions"],
  pauseReason: [
    "message_someone",
    "bored",
    "avoiding_something",
    "can_t_sleep",
  ],
  diarySymptoms: ["nausea", "pain", "mouth_sores", "numbness", "low_mood"],
  survivorshipFeeling: ["hard", "mixed", "good"],
} as const satisfies Record<string, readonly string[]>;

/**
 * The zone a zone check reports. It is decided on the device from the
 * member's own plan (no spec option list); the API never computes it.
 */
export const ZONES = ["green", "yellow", "red"] as const;
