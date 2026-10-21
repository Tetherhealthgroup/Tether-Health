import { randomUUID } from "node:crypto";
import { databaseError, type DatabaseErrorHint } from "./database-errors";

/**
 * In-memory stand-in for PostgREST over the TH-913 schema
 * (supabase/migrations/202610170002_enrolments.sql) and its TH-972b
 * follow-ups (supabase/migrations/202610180003_enrolment_consent_followups.sql),
 * used as the `fetch` of the real supabase-js client in e2e tests.
 *
 * What it emulates, per request (one request = one transaction):
 * - identity from the request's own bearer token only (like auth.uid());
 * - the RLS policies of profiles (read own row), programmes, enrolments and programme_consents
 *   (select/insert/update), including the insert checks (deletion barrier,
 *   enrolment not left, live core consent) and the deletion barrier in the
 *   enrolment update check
 *   (supabase/migrations/202610180012_enrolment_delete_now.sql);
 * - the column grants (insert/update column lists; no delete on any table,
 *   so a member's direct delete is refused with 42501; consent_text is not
 *   insertable, so sending it is refused with 42501);
 * - consent documents: a seeded table, read-only to members
 *   (CONSENT_DOCUMENTS; a test may retire documents with
 *   retireConsentDocuments and restore the seed afterwards); a
 *   consent insert takes its text from the grantable document for its
 *   purpose, version and locale, or fails with TH011 (consent_fill_text);
 * - check, foreign-key and unique constraints, including the live-row unique
 *   index on consents;
 * - the triggers: left_at management, revoke-only consents, core revocation
 *   cascade, revoke-on-leave and the deferred focus cap of two;
 * - the RPCs deletion_barrier_open(), current_consent_documents(),
 *   swap_focus() (focus cap checked inside the call, TH001; its updates
 *   refused with 42501 once account deletion has started) and
 *   supersede_core_consent() (TH004/5/6/11/12/14, superseded_by set, the
 *   optional consents left live). The supersession's optional-consent
 *   cascade is not emulated: no seeded document sets cascades_optional;
 * - a concurrent transaction committing just before a request
 *   (interleave), e.g. a first tap's supersession;
 * - account deletion (supabase/migrations/202610180008_delete_my_account.sql
 *   and the functions it calls): begin_account_deletion() sets the deletion
 *   barrier; delete_my_account() refuses, in the function's order, a
 *   confirmation other than DELETE (23514), a sign-in that is not recent
 *   (TH017, see setSignInAge), a function owner that does not bypass
 *   row-level security (TH020, see functionOwnerBypassesRls) and an avatar
 *   object left under the caller's folder (TH016); then, as
 *   delete_my_app_data(), refuses a profile without the barrier (23514) and
 *   deletes the caller's consents, enrolments, program data, quit plan and
 *   profile, deletes the caller's identity and returns the ten counts. A
 *   refusal deletes nothing; a repeat returns zero counts. The sync session
 *   refusals (TH009, TH010) and the identity re-check (TH018) are not
 *   emulated: the API sees them only as other errors;
 * - "Delete now" (202610180012): delete_enrolment_now() refuses, in the
 *   function's order, a confirmation other than DELETE (23514), a sign-in
 *   that is not recent (TH017, see setSignInAge), a function owner that does
 *   not bypass row-level security (TH020, see functionOwnerBypassesRls) and
 *   an enrolment that is missing or not the caller's (TH012); it does not
 *   check the deletion barrier. It then deletes the enrolment's consents,
 *   the caller's quit plan (BreatheFree only), the caller's program data
 *   whose program_id is the programme's slug, and the enrolment, and
 *   returns the twelve counts (the sync and care tables are not held here,
 *   so theirs are 0). A refusal deletes nothing. The sync session refusal
 *   (TH010) is not emulated;
 * - the Storage API for the avatars bucket (/storage/v1): list-v2 and
 *   remove, limited to objects in the caller's own folder like the avatar
 *   select and delete policies; an object outside it is neither listed nor
 *   removed (a short batch). failNextStorage makes the next call fail;
 * - error bodies: standard SQLSTATEs for constraints and RLS, and the
 *   database's own `TH` codes with the registry's exact message and hint
 *   (test/support/database-errors.ts), answered as HTTP 400 the way
 *   PostgREST answers SQLSTATEs it does not know.
 *
 * It is not Postgres: it implements only the filters and headers the API
 * sends (eq, is.null, in, order, limit, select, Prefer return=representation,
 * single-object Accept). There are no snapshots or lock waits; a request
 * that Postgres would refuse after a lock wait is emulated with interleave
 * plus failNext. The real RLS is tested in SQL by TH-913 and TH-972b.
 */

type Row = Record<string, unknown>;

interface State {
  profiles: Row[];
  programmes: Row[];
  enrolments: Row[];
  programme_consents: Row[];
  consent_documents: Row[];
  /** Not exposed through the REST tables; written by account deletion. */
  quit_plans: Row[];
  program_data: Row[];
  /** Stand-in for auth.users (id only). */
  auth_users: Row[];
  /** Stand-in for storage.objects (bucket_id, name). */
  storage_objects: Row[];
}

export interface ConsentDocument {
  purpose: string;
  version: string;
  locale: "en" | "es";
  body: string;
  effective_from: string;
  retired_at: string | null;
  cascades_optional: boolean;
}

export interface PgError {
  status: number;
  code: string;
  message: string;
  hint: string | null;
}

export interface RecordedRequest {
  method: string;
  path: string;
  token: string | null;
  /** The query string as sent (filters, select), e.g. "?id=eq.…". */
  search: string;
  /** The parsed JSON body as sent, if any. */
  body: unknown;
}

/**
 * Marker the fake puts into the `details` of every constraint error (23503,
 * 23505, 23514), next to the submitted values, the way real PostgREST
 * returns "Failing row contains (...)" / "Key (...)=(...)". It must never
 * reach an API response or log line.
 */
export const DB_CANARY = "synthetic-db-detail-canary-5b2d";
const LEAKY_CODES = ["23503", "23505", "23514"];
const STATUSES = ["focus", "learn_only", "paused", "left"];
const PURPOSES = [
  "core",
  "reminders",
  "records_import",
  "share_care_team",
  "share_caregiver",
  "research",
  "screen_time",
];
const SHARE = ["share_care_team", "share_caregiver"];
const VERSION = /^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$/;
const LOCALES = ["en", "es"];
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** The fake's clock starts here (see `now()`). */
const START = "2026-10-18T09:00:00.000Z";
const document = (
  purpose: string,
  version: string,
  locale: "en" | "es",
  effectiveFrom: string,
  retiredAt: string | null = null,
): ConsentDocument => ({
  purpose,
  version,
  locale,
  body: `Synthetic ${purpose} ${version} ${locale} document`,
  effective_from: effectiveFrom,
  retired_at: retiredAt,
  cascades_optional: false,
});

/**
 * The seeded consent documents, relative to START: `v1-draft` for every
 * programme purpose in en and es (as the migration seeds), a later core
 * `v2-synthetic` in both locales, a still later core `v3-synthetic` in es
 * only (so the current core version is v2-synthetic in en and v3-synthetic
 * in es, and a locale mix-up shows), a retired core `v0-retired` and a
 * not-yet-effective core `v9-future` (both en; neither is grantable or
 * current).
 */
export const CONSENT_DOCUMENTS: readonly ConsentDocument[] = [
  ...PURPOSES.flatMap((purpose) =>
    (["en", "es"] as const).map((locale) =>
      document(purpose, "v1-draft", locale, "2026-10-18T00:00:00.000Z"),
    ),
  ),
  document("core", "v2-synthetic", "en", "2026-10-18T06:00:00.000Z"),
  document("core", "v2-synthetic", "es", "2026-10-18T06:00:00.000Z"),
  document("core", "v3-synthetic", "es", "2026-10-18T07:00:00.000Z"),
  document(
    "core",
    "v0-retired",
    "en",
    "2026-10-17T00:00:00.000Z",
    "2026-10-18T00:00:00.000Z",
  ),
  document("core", "v9-future", "en", "2027-01-01T00:00:00.000Z"),
];

const INSERT_GRANTS: Record<string, string[]> = {
  enrolments: ["user_id", "programme_code", "status", "mode"],
  programme_consents: [
    "enrolment_id",
    "purpose",
    "recipient_ref",
    "consent_version",
    "locale",
  ],
};
const UPDATE_GRANTS: Record<string, string[]> = {
  enrolments: ["status", "mode"],
  programme_consents: ["revoked_at", "superseded_by"],
};
/**
 * No table: members lost DELETE on enrolments in 202610180012 (consents never
 * had it); "Delete now" goes through delete_enrolment_now().
 */
const DELETE_GRANTS: string[] = [];

const PROGRAMMES: [string, string, string, string, string, string[]][] = [
  [
    "bf",
    "breathefree",
    "BreatheFree",
    "Tobacco & nicotine",
    "Quit / Reduce",
    ["smoking_status"],
  ],
  ["sf", "scrollfree", "ScrollFree", "Social media use", "Quit / Reduce", []],
  ["ca", "clearair", "ClearAir", "Respiratory health", "Manage", []],
  [
    "hw",
    "heartwise",
    "Heartwise",
    "Cardiovascular health",
    "Manage",
    ["blood_pressure", "lipids"],
  ],
  [
    "st",
    "steady",
    "Steady",
    "Diabetes & metabolic health",
    "Manage",
    ["a1c", "glucose"],
  ],
  ["re", "renew", "Renew", "Kidney & liver health", "Manage", ["egfr"]],
  ["nu", "nourish", "Nourish", "Obesity & nutrition", "Build habits", []],
  ["sd", "stride", "Stride", "Healthy aging", "Build habits", []],
  ["ea", "ease", "Ease", "Mental & behavioral health", "Support", []],
  [
    "ck",
    "checkup",
    "Checkup",
    "Preventive health",
    "Prevent",
    ["immunizations"],
  ],
  ["be", "beacon", "Beacon", "Cancer", "Prevent", []],
];

const text = (value: unknown): string =>
  typeof value === "string" ? value : JSON.stringify(value);

class PgFailure extends Error {
  constructor(readonly pg: PgError) {
    super(pg.message);
  }
}

const fail = (status: number, code: string, message: string): never => {
  throw new PgFailure({ status, code, message, hint: null });
};

/**
 * The error body PostgREST returns when a migration raises a registry code:
 * `raise exception using errcode = 'TH0nn', message = …, hint = …`.
 * `messageIndex` picks one of the code's messages (TH003 has two).
 */
export const registryError = (
  hint: DatabaseErrorHint,
  messageIndex = 0,
): PgError => {
  const entry = databaseError(hint);
  const message = entry.messages[messageIndex];
  if (message === undefined) throw new Error(`${hint} has no such message`);
  return { status: 400, code: entry.code, message, hint: entry.hint };
};
const raise = (hint: DatabaseErrorHint, messageIndex = 0): never => {
  throw new PgFailure(registryError(hint, messageIndex));
};
const checkViolation = (name: string) => {
  const table = /^(enrolments|programme_consents)_\w+_check$/.exec(name)?.[1];
  return fail(
    400,
    "23514",
    table
      ? `new row for relation "${table}" violates check constraint "${name}"`
      : name,
  );
};
const rlsViolation = (table: string) =>
  fail(
    403,
    "42501",
    `new row violates row-level security policy for table "${table}"`,
  );

export class FakePostgrest {
  readonly requests: RecordedRequest[] = [];
  /** Emulates PostgREST db-max-rows for reads; null means no limit. */
  maxRows: number | null = null;
  private readonly tokens = new Map<string, string>();
  private injected: { method: string; table: string; error: PgError }[] = [];
  private interleaved: { method: string; path: string; action: () => void }[] =
    [];
  private clock = Date.parse(START);
  private state: State = {
    profiles: [],
    programmes: PROGRAMMES.map(
      ([code, slug, name, area, archetype, resources]) => ({
        code,
        slug,
        name,
        area,
        archetype,
        receives_resources: resources,
      }),
    ),
    enrolments: [],
    programme_consents: [],
    consent_documents: CONSENT_DOCUMENTS.map((row) => ({ ...row })),
    quit_plans: [],
    program_data: [],
    auth_users: [],
    storage_objects: [],
  };
  /**
   * Seconds since the sign-in recorded in each token's amr claim (0 unless
   * set); null means the token has no usable amr entry.
   */
  private readonly signInAges = new Map<string, number | null>();
  private storageFailures: { operation: "list" | "remove"; status: number }[] =
    [];
  /**
   * Whether the owner of delete_my_account and delete_enrolment_now is a
   * superuser or bypasses row-level security; false makes both refuse with
   * TH020.
   */
  functionOwnerBypassesRls = true;

  /**
   * Registers a synthetic user whose JWT is `token`, with an identity and a
   * profile row.
   */
  addUser(token: string, userId: string): void {
    this.tokens.set(token, userId);
    this.state.auth_users.push({ id: userId });
    this.state.profiles.push({
      id: userId,
      locale: "en",
      account_deletion_started_at: null,
    });
  }

  /** Sets how long ago `token`'s sign-in was (null: no usable amr). */
  setSignInAge(token: string, seconds: number | null): void {
    this.signInAges.set(token, seconds);
  }

  /** Superuser insert of a quit plan for `userId`. */
  addQuitPlan(userId: string): void {
    this.state.quit_plans.push({ user_id: userId });
  }

  /** Superuser insert of program data for `userId`. */
  addProgramData(userId: string, programId: string): void {
    this.state.program_data.push({ user_id: userId, program_id: programId });
  }

  /** Superuser insert of an object named `name` in the avatars bucket. */
  addAvatarObject(name: string): void {
    this.state.storage_objects.push({ bucket_id: "avatars", name });
  }

  /** Makes the next Storage `operation` fail with HTTP `status`. */
  failNextStorage(operation: "list" | "remove", status = 500): void {
    this.storageFailures.push({ operation, status });
  }

  /** Superuser write of a profile's locale (profiles.locale, en or es). */
  setProfileLocale(userId: string, locale: "en" | "es"): void {
    const profile = this.state.profiles.find((row) => row.id === userId);
    if (profile) profile.locale = locale;
  }

  startAccountDeletion(userId: string): void {
    const profile = this.state.profiles.find((row) => row.id === userId);
    if (profile) profile.account_deletion_started_at = this.now();
  }

  /**
   * Superuser write: retires every live `purpose` document in `locale` now,
   * so none is current or grantable there (a publishing state the seed does
   * not have, for the test that needs it). resetConsentDocuments() restores
   * the seed.
   */
  retireConsentDocuments(purpose: string, locale: "en" | "es"): void {
    const at = this.now();
    for (const doc of this.state.consent_documents) {
      if (
        doc.purpose === purpose &&
        doc.locale === locale &&
        doc.retired_at === null
      ) {
        doc.retired_at = at;
      }
    }
  }

  /** Restores the seeded consent documents (CONSENT_DOCUMENTS). */
  resetConsentDocuments(): void {
    this.state.consent_documents = CONSENT_DOCUMENTS.map((row) => ({ ...row }));
  }

  /**
   * Makes the next `method` request on `table` fail with `error` (rolled
   * back like any failure), for errors the API cannot provoke on its own,
   * such as one caused by a concurrent transaction.
   */
  failNext(method: string, table: string, error: PgError): void {
    this.injected.push({ method, table, error });
  }

  /**
   * Runs `action` just before the next `method` request on `path` (a table,
   * or `rpc/<function>`), as a concurrent transaction that has already
   * committed: its changes stay even if that request fails.
   */
  interleave(method: string, path: string, action: () => void): void {
    this.interleaved.push({ method, path, action });
  }

  /** Injected failures and interleaved actions not yet consumed. */
  get pendingFailures(): number {
    return (
      this.injected.length +
      this.interleaved.length +
      this.storageFailures.length
    );
  }

  /** Drops injected failures and interleaved actions not consumed. */
  clearFailures(): void {
    this.injected = [];
    this.interleaved = [];
    this.storageFailures = [];
  }

  /**
   * Superuser insert of a live core consent stored before consent documents
   * existed (null locale, its own text).
   */
  addLegacyCoreConsent(enrolmentId: string, version: string): string {
    const id = randomUUID();
    this.state.programme_consents.push({
      id,
      enrolment_id: enrolmentId,
      purpose: "core",
      recipient_ref: null,
      consent_version: version,
      locale: null,
      consent_text: "Synthetic legacy core wording",
      granted_at: this.now(),
      revoked_at: null,
      superseded_by: null,
    });
    return id;
  }

  /** Superuser write of an enrolment's status: no RLS, triggers or cap. */
  forceEnrolmentStatus(enrolmentId: string, status: string): void {
    const row = this.state.enrolments.find((r) => r.id === enrolmentId);
    if (row) row.status = status;
  }

  /**
   * public.supersede_core_consent() as `userId`, outside any request (for
   * a concurrent transaction in interleave). Throws on refusal.
   */
  supersedeCoreConsent(
    userId: string,
    enrolmentId: string,
    version: string,
    locale: string,
  ): Row[] {
    return structuredClone(
      this.supersede(userId, {
        p_enrolment: enrolmentId,
        p_version: version,
        p_locale: locale,
      }),
    );
  }

  /** Superuser view for assertions (bypasses RLS). */
  table(name: keyof State): Row[] {
    return structuredClone(this.state[name]);
  }

  readonly fetch: typeof fetch = (input, init) =>
    Promise.resolve(this.dispatch(input, init));

  private dispatch(
    input: Parameters<typeof fetch>[0],
    init: Parameters<typeof fetch>[1],
  ): Response {
    const url = new URL(
      typeof input === "string"
        ? input
        : input instanceof URL
          ? input.href
          : input.url,
    );
    const headers = new Headers(init?.headers);
    const method = (init?.method ?? "GET").toUpperCase();
    const auth = headers.get("authorization");
    const token = auth?.startsWith("Bearer ") ? auth.slice(7) : null;
    this.requests.push({
      method,
      path: url.pathname,
      token,
      search: url.search,
      body:
        typeof init?.body === "string"
          ? (JSON.parse(init.body) as unknown)
          : undefined,
    });

    const uid = token ? this.tokens.get(token) : undefined;
    const countExact = (headers.get("prefer") ?? "").includes("count=exact");
    if (!uid)
      return this.respond(401, { code: "PGRST301", message: "JWT invalid" });
    if (url.pathname.startsWith("/storage/v1/")) {
      return this.storage(uid, method, url.pathname.slice(12), init?.body);
    }

    // A concurrent transaction commits first, outside this request's.
    const path = url.pathname.replace(/^\/rest\/v1\//, "");
    const concurrent = this.interleaved.find(
      (entry) => entry.method === method && entry.path === path,
    );
    if (concurrent) {
      this.interleaved = this.interleaved.filter(
        (entry) => entry !== concurrent,
      );
      concurrent.action();
    }

    const snapshot = structuredClone(this.state);
    try {
      const body =
        typeof init?.body === "string"
          ? (JSON.parse(init.body) as unknown)
          : undefined;
      const result = this.handle(uid, token, method, url, headers, body);
      return this.respond(
        result.status,
        result.body,
        countExact ? result.total : undefined,
      );
    } catch (error) {
      this.state = snapshot; // roll back the request's transaction
      if (error instanceof PgFailure) {
        const leaky = LEAKY_CODES.includes(error.pg.code);
        const submitted =
          typeof init?.body === "string"
            ? Object.values(JSON.parse(init.body) as Row)
                .map(text)
                .join(", ")
            : "";
        return this.respond(error.pg.status, {
          code: error.pg.code,
          message: error.pg.message,
          details: leaky
            ? `Failing row contains (${submitted}). ${DB_CANARY}`
            : null,
          hint: error.pg.hint,
        });
      }
      throw error;
    }
  }

  private handle(
    uid: string,
    token: string | null,
    method: string,
    url: URL,
    headers: Headers,
    body: unknown,
  ): { status: number; body: unknown; total?: number } {
    const path = url.pathname.replace(/^\/rest\/v1\//, "");
    const injected = this.injected.find(
      (entry) => entry.method === method && entry.table === path,
    );
    if (injected) {
      this.injected = this.injected.filter((entry) => entry !== injected);
      throw new PgFailure(injected.error);
    }
    if (path.startsWith("rpc/")) {
      return this.rpc(uid, token, method, path.slice(4), url, body);
    }
    if (
      ![
        "profiles",
        "programmes",
        "enrolments",
        "programme_consents",
        "consent_documents",
      ].includes(path)
    ) {
      return fail(404, "PGRST205", "Table not found");
    }
    const table = path as keyof State;
    let rows: Row[];
    let status = 200;
    if (method === "GET") {
      rows = this.filter(this.visible(uid, table), url);
    } else if (method === "POST") {
      const values = Array.isArray(body) ? (body as Row[]) : [body as Row];
      rows = values.map((value) => this.insert(uid, table, value));
      status = 201;
    } else if (method === "PATCH") {
      rows = this.update(uid, table, url, body as Row);
    } else if (method === "DELETE") {
      rows = this.remove(uid, table, url);
    } else {
      return fail(405, "PGRST117", "Unsupported method");
    }
    if (method !== "GET") this.deferredChecks(uid);

    const representation =
      method === "GET" ||
      (headers.get("prefer") ?? "").includes("return=representation");
    if (!representation)
      return { status: method === "POST" ? 201 : 204, body: null };
    const ordered = this.order(rows, url);
    const total = ordered.length;
    // PostgREST's server-side row limit (db-max-rows) truncates reads; the
    // exact count still reports the full total.
    const limited =
      method === "GET" && this.maxRows !== null
        ? ordered.slice(0, this.maxRows)
        : ordered;
    const projected = limited.map((row) => this.project(row, url));
    if (
      (headers.get("accept") ?? "").includes(
        "application/vnd.pgrst.object+json",
      )
    ) {
      if (projected.length !== 1) {
        fail(
          406,
          "PGRST116",
          "JSON object requested, multiple (or no) rows returned",
        );
      }
      return { status, body: projected[0], total };
    }
    return { status, body: projected, total };
  }

  // ---- RPCs ---------------------------------------------------------------

  private rpc(
    uid: string,
    token: string | null,
    method: string,
    name: string,
    url: URL,
    body: unknown,
  ): { status: number; body: unknown } {
    // Arguments typed uuid compare case-insensitively in Postgres and come
    // back in lower case; the fake stores ids in lower case.
    const args = Object.fromEntries(
      Object.entries((body ?? {}) as Row).map(([name, value]) => [
        name,
        typeof value === "string" && UUID.test(value)
          ? value.toLowerCase()
          : value,
      ]),
    );
    const answer = (rows: Row[]) => ({
      status: 200,
      body: rows.map((row) => this.project(row, url)),
    });
    if (name === "deletion_barrier_open" && method === "POST") {
      return { status: 200, body: this.barrierOpen(uid) };
    }
    // stable: callable with GET (filters in the query string) or POST.
    if (name === "current_consent_documents" && method !== "DELETE") {
      return answer(this.filter(this.currentDocuments(), url));
    }
    if (name === "swap_focus" && method === "POST") {
      const rows = this.swap(uid, args);
      this.deferredChecks(uid);
      return answer(rows);
    }
    if (name === "supersede_core_consent" && method === "POST") {
      const rows = this.supersede(uid, args);
      this.deferredChecks(uid);
      return answer(rows);
    }
    if (name === "begin_account_deletion" && method === "POST") {
      return { status: 200, body: this.beginDeletion(uid, args) };
    }
    if (name === "delete_my_account" && method === "POST") {
      return { status: 200, body: this.deleteAccount(uid, token, args) };
    }
    if (name === "delete_enrolment_now" && method === "POST") {
      return { status: 200, body: this.deleteEnrolmentNow(uid, token, args) };
    }
    return fail(404, "PGRST202", "Could not find the function");
  }

  /** public.begin_account_deletion(p_confirmation). */
  private beginDeletion(uid: string, args: Row): boolean {
    if (args.p_confirmation !== "DELETE") {
      fail(400, "23514", "Explicit confirmation required");
    }
    const profile = this.state.profiles.find((row) => row.id === uid);
    if (profile && profile.account_deletion_started_at === null) {
      profile.account_deletion_started_at = this.now();
    }
    return true;
  }

  /** public.delete_my_account(p_confirmation), in the function's order. */
  private deleteAccount(
    uid: string,
    token: string | null,
    args: Row,
  ): Record<string, number> {
    if (args.p_confirmation !== "DELETE") {
      fail(400, "23514", "Explicit confirmation required");
    }
    const age = token === null ? null : (this.signInAges.get(token) ?? 0);
    if (age === null || age > 600 || age < -60) {
      raise("recent_authentication_required");
    }
    if (!this.functionOwnerBypassesRls) raise("rls_bypass_required");
    if (
      this.state.storage_objects.some(
        (row) =>
          row.bucket_id === "avatars" && text(row.name).split("/")[0] === uid,
      )
    ) {
      raise("avatar_objects_remain");
    }
    // delete_my_app_data(p_confirmation), unchanged.
    const profile = this.state.profiles.find((row) => row.id === uid);
    if (profile && profile.account_deletion_started_at === null) {
      fail(400, "23514", "Account deletion was not started");
    }
    const enrolmentIds = new Set(
      this.state.enrolments
        .filter((row) => row.user_id === uid)
        .map((row) => row.id),
    );
    const removeWhere = (table: keyof State, match: (row: Row) => boolean) => {
      const before = this.state[table].length;
      this.state[table] = this.state[table].filter((row) => !match(row));
      return before - this.state[table].length;
    };
    const counts = {
      sync_lapses: 0,
      sync_answers: 0,
      sync_areas: 0,
      sync_accounts: 0,
      programme_consents: removeWhere("programme_consents", (row) =>
        enrolmentIds.has(row.enrolment_id),
      ),
      enrolments: removeWhere("enrolments", (row) => row.user_id === uid),
      account_consents: 0,
      program_data: removeWhere("program_data", (row) => row.user_id === uid),
      quit_plans: removeWhere("quit_plans", (row) => row.user_id === uid),
      profiles: removeWhere("profiles", (row) => row.id === uid),
    };
    removeWhere("auth_users", (row) => row.id === uid);
    return counts;
  }

  /**
   * public.delete_enrolment_now(p_enrolment_id, p_confirmation), in the
   * function's order. No deletion-barrier check.
   */
  private deleteEnrolmentNow(
    uid: string,
    token: string | null,
    args: Row,
  ): Record<string, number> {
    if (args.p_confirmation !== "DELETE") {
      fail(400, "23514", "Explicit confirmation required");
    }
    const age = token === null ? null : (this.signInAges.get(token) ?? 0);
    if (age === null || age > 600 || age < -60) {
      raise("recent_authentication_required");
    }
    if (!this.functionOwnerBypassesRls) raise("rls_bypass_required");
    // uuid compares case-insensitively in Postgres.
    const wanted =
      typeof args.p_enrolment_id === "string"
        ? args.p_enrolment_id.toLowerCase()
        : null;
    const enrolment = this.state.enrolments.find(
      (row) => text(row.id).toLowerCase() === wanted && row.user_id === uid,
    );
    if (!enrolment) return raise("enrolment_not_found");
    const code = enrolment.programme_code;
    const slug = this.state.programmes.find((row) => row.code === code)?.slug;
    const removeWhere = (table: keyof State, match: (row: Row) => boolean) => {
      const before = this.state[table].length;
      this.state[table] = this.state[table].filter((row) => !match(row));
      return before - this.state[table].length;
    };
    const counts = {
      programme_consents: removeWhere(
        "programme_consents",
        (row) => row.enrolment_id === enrolment.id,
      ),
      quit_plans:
        code === "bf"
          ? removeWhere("quit_plans", (row) => row.user_id === uid)
          : 0,
      program_data: removeWhere(
        "program_data",
        (row) => row.user_id === uid && row.program_id === slug,
      ),
      enrolments: removeWhere(
        "enrolments",
        (row) => row.id === enrolment.id && row.user_id === uid,
      ),
    };
    return {
      quit_plans: counts.quit_plans,
      program_data: counts.program_data,
      enrolments: counts.enrolments,
      programme_consents: counts.programme_consents,
      sync_answers: 0,
      sync_lapses: 0,
      sync_areas: 0,
      care_share_access: 0,
      care_messages: 0,
      care_shares: 0,
      caregiver_events: 0,
      caregivers: 0,
    };
  }

  // ---- Storage ------------------------------------------------------------

  /**
   * The Storage API for the avatars bucket: POST object/list-v2/avatars and
   * DELETE object/avatars. Only objects in the caller's own folder are
   * listed or removed. Answers with the fields the API reads.
   */
  private storage(
    uid: string,
    method: string,
    path: string,
    rawBody: unknown,
  ): Response {
    const body = (
      typeof rawBody === "string" ? JSON.parse(rawBody) : {}
    ) as Row;
    const own = (row: Row) =>
      row.bucket_id === "avatars" && text(row.name).split("/")[0] === uid;
    const operation =
      method === "POST" && path === "object/list-v2/avatars"
        ? "list"
        : method === "DELETE" && path === "object/avatars"
          ? "remove"
          : null;
    if (operation === null) {
      return this.respond(400, {
        statusCode: "400",
        error: "InvalidRequest",
        message: "Unsupported storage request",
      });
    }
    const failure = this.storageFailures.find(
      (entry) => entry.operation === operation,
    );
    if (failure) {
      this.storageFailures = this.storageFailures.filter(
        (entry) => entry !== failure,
      );
      return this.respond(failure.status, {
        statusCode: String(failure.status),
        error: "InternalError",
        message: "Synthetic storage failure",
      });
    }
    if (operation === "list") {
      const prefix = text(body.prefix ?? "");
      const cursor = typeof body.cursor === "string" ? body.cursor : null;
      const limit = typeof body.limit === "number" ? body.limit : 1000;
      const names = this.state.storage_objects
        .filter((row) => own(row) && text(row.name).startsWith(prefix))
        .map((row) => text(row.name))
        .filter((name) => cursor === null || name > cursor)
        .sort();
      const page = names.slice(0, limit);
      const hasNext = names.length > limit;
      return this.respond(200, {
        hasNext,
        ...(hasNext ? { nextCursor: page[page.length - 1] } : {}),
        folders: [],
        objects: page.map((name) => ({ id: randomUUID(), name })),
      });
    }
    const prefixes = Array.isArray(body.prefixes)
      ? body.prefixes.map(text)
      : [];
    const removed = this.state.storage_objects.filter(
      (row) => own(row) && prefixes.includes(text(row.name)),
    );
    this.state.storage_objects = this.state.storage_objects.filter(
      (row) => !removed.includes(row),
    );
    return this.respond(
      200,
      removed.map((row) => ({ bucket_id: "avatars", name: row.name })),
    );
  }

  /** The grantable document: effective and not retired. */
  private grantable(purpose: unknown, version: unknown, locale: unknown) {
    const at = this.clock;
    return this.state.consent_documents.find(
      (doc) =>
        doc.purpose === purpose &&
        doc.version === version &&
        doc.locale === locale &&
        Date.parse(doc.effective_from as string) <= at &&
        (doc.retired_at === null || Date.parse(doc.retired_at as string) > at),
    );
  }

  /** current_consent_documents(): latest grantable per purpose and locale. */
  private currentDocuments(): Row[] {
    const current = new Map<string, Row>();
    for (const doc of this.state.consent_documents) {
      if (!this.grantable(doc.purpose, doc.version, doc.locale)) continue;
      const key = `${text(doc.purpose)}/${text(doc.locale)}`;
      const best = current.get(key);
      const later =
        !best ||
        Date.parse(doc.effective_from as string) >
          Date.parse(best.effective_from as string) ||
        (doc.effective_from === best.effective_from &&
          text(doc.version) > text(best.version));
      if (later) current.set(key, doc);
    }
    return [...current.values()];
  }

  /** public.swap_focus(p_demote, p_promote). */
  private swap(uid: string, args: Row): Row[] {
    const { p_demote: demoteId, p_promote: promoteId } = args;
    if (!demoteId || !promoteId || demoteId === promoteId) {
      raise("focus_swap_invalid");
    }
    const own = (id: unknown) =>
      this.state.enrolments.find((row) => row.id === id && row.user_id === uid);
    const demote = own(demoteId);
    const promote = own(promoteId);
    if (!demote || !promote) return raise("enrolment_not_found");
    if (promote.status === "left") raise("enrolment_left");
    if (demote.status !== "focus" || promote.status === "focus") {
      raise("focus_swap_invalid");
    }
    // The function is security invoker: its updates meet the update policy,
    // whose check includes the deletion barrier.
    if (!this.barrierOpen(uid)) rlsViolation("enrolments");
    demote.status = "paused";
    demote.updated_at = this.now();
    promote.status = "focus";
    promote.updated_at = this.now();
    // The function checks the focus cap before it returns.
    this.deferredChecks(uid);
    return [demote, promote];
  }

  /** public.supersede_core_consent(p_enrolment, p_version, p_locale). */
  private supersede(uid: string, args: Row): Row[] {
    const { p_enrolment: enrolmentId, p_version, p_locale } = args;
    const enrolment = this.state.enrolments.find(
      (row) => row.id === enrolmentId && row.user_id === uid,
    );
    if (!enrolment) return raise("enrolment_not_found");
    if (enrolment.status === "left") raise("enrolment_left");
    if (!this.barrierOpen(uid)) raise("deletion_in_progress");
    const old = this.state.programme_consents.find(
      (row) =>
        row.enrolment_id === enrolmentId &&
        row.purpose === "core" &&
        row.revoked_at === null,
    );
    if (!old) return raise("consent_requires_core");
    if (!this.grantable("core", p_version, p_locale)) {
      raise("consent_document_unavailable");
    }
    // The one-live-core key is deferred inside the function.
    const replacement = this.insert(
      uid,
      "programme_consents",
      {
        enrolment_id: enrolmentId,
        purpose: "core",
        consent_version: p_version,
        locale: p_locale,
      },
      { deferLiveCore: true },
    );
    this.checkSupersede(old, replacement);
    old.revoked_at = this.now();
    old.superseded_by = replacement.id;
    return [old, replacement];
  }

  /** programme_consents_check_supersede: later version, or other locale. */
  private checkSupersede(old: Row, replacement: Row): void {
    const unchanged = () => raise("consent_version_unchanged");
    if (
      old.locale !== null &&
      replacement.consent_version === old.consent_version
    ) {
      if (replacement.locale === old.locale) unchanged();
      return;
    }
    const effective = (row: Row) =>
      this.state.consent_documents.find(
        (doc) =>
          doc.purpose === "core" &&
          doc.version === row.consent_version &&
          doc.locale === row.locale,
      )?.effective_from as string | undefined;
    const oldEffective =
      old.locale === null ? -Infinity : Date.parse(effective(old) ?? "");
    const newEffective = Date.parse(effective(replacement) ?? "");
    if (
      Number.isNaN(oldEffective) ||
      Number.isNaN(newEffective) ||
      newEffective <= oldEffective
    ) {
      unchanged();
    }
  }

  // ---- RLS: USING clauses -------------------------------------------------

  private visible(uid: string, table: keyof State): Row[] {
    if (table === "programmes") return this.state.programmes;
    // Documents already in effect (consent_documents_select); no writes.
    if (table === "consent_documents") {
      return this.state.consent_documents.filter(
        (doc) => Date.parse(doc.effective_from as string) <= this.clock,
      );
    }
    // Own row only; the API reads it, never writes it (no grants here).
    if (table === "profiles") {
      return this.state.profiles.filter((row) => row.id === uid);
    }
    if (table === "enrolments") {
      return this.state.enrolments.filter((row) => row.user_id === uid);
    }
    if (table === "programme_consents") {
      return this.state.programme_consents.filter((row) =>
        this.state.enrolments.some(
          (enrolment) =>
            enrolment.id === row.enrolment_id && enrolment.user_id === uid,
        ),
      );
    }
    return [];
  }

  // ---- writes -------------------------------------------------------------

  private insert(
    uid: string,
    table: keyof State,
    value: Row,
    { deferLiveCore = false } = {},
  ): Row {
    const granted = INSERT_GRANTS[table];
    if (
      !granted ||
      Object.keys(value).some((column) => !granted.includes(column))
    ) {
      return fail(403, "42501", `permission denied for table ${table}`);
    }
    if (table === "enrolments") {
      const row: Row = {
        id: randomUUID(),
        user_id: value.user_id,
        programme_code: value.programme_code,
        status: value.status ?? "focus",
        mode: value.mode ?? null,
        joined_at: this.now(),
        left_at: null,
        created_at: this.now(),
        updated_at: this.now(),
      };
      // Postgres executor order: RLS WITH CHECK, then CHECK constraints,
      // then unique indexes (on insertion), then foreign keys (an after
      // trigger at the end of the statement).
      if (row.user_id !== uid || !this.barrierOpen(uid)) rlsViolation(table);
      this.checkEnrolment(row);
      if (
        this.state.enrolments.some(
          (other) =>
            other.user_id === row.user_id &&
            other.programme_code === row.programme_code,
        )
      ) {
        fail(
          409,
          "23505",
          'duplicate key value violates unique constraint "enrolments_user_programme_key"',
        );
      }
      if (
        !this.state.programmes.some(
          (programme) => programme.code === row.programme_code,
        )
      ) {
        fail(
          409,
          "23503",
          'insert or update on table "enrolments" violates foreign key constraint',
        );
      }
      this.state.enrolments.push(row);
      return row;
    }
    // consent_fill_text (before insert): the text comes from the document.
    const doc = this.grantable(
      value.purpose,
      value.consent_version,
      value.locale ?? null,
    );
    if (!doc) raise("consent_document_unavailable");
    const row: Row = {
      id: randomUUID(),
      enrolment_id: value.enrolment_id,
      purpose: value.purpose,
      recipient_ref: value.recipient_ref ?? null,
      consent_version: value.consent_version,
      locale: value.locale ?? null,
      consent_text: doc?.body,
      granted_at: this.now(),
      revoked_at: null,
      superseded_by: null,
    };
    const purpose = row.purpose as string;
    const recipient = row.recipient_ref as string | null;
    // After the before-insert trigger: RLS WITH CHECK, then CHECK
    // constraints, then the unique keys, as Postgres runs them.
    const enrolment = this.state.enrolments.find(
      (other) => other.id === row.enrolment_id,
    );
    if (
      !enrolment ||
      enrolment.user_id !== uid ||
      enrolment.status === "left" ||
      !this.barrierOpen(uid) ||
      (purpose !== "core" &&
        !this.hasConsent(uid, enrolment.id as string, "core"))
    ) {
      rlsViolation(table);
    }
    if (!PURPOSES.includes(purpose))
      checkViolation("programme_consents_purpose_check");
    if (SHARE.includes(purpose) !== (recipient !== null)) {
      checkViolation("programme_consents_recipient_check");
    }
    if (
      recipient !== null &&
      (recipient.length < 1 || recipient.length > 200)
    ) {
      checkViolation("programme_consents_recipient_ref_check");
    }
    if (
      typeof row.consent_version !== "string" ||
      !VERSION.test(row.consent_version)
    ) {
      checkViolation("programme_consents_version_check");
    }
    if (row.locale !== null && !LOCALES.includes(row.locale as string)) {
      checkViolation("programme_consents_locale_check");
    }
    if (
      !(deferLiveCore && purpose === "core") &&
      this.state.programme_consents.some(
        (other) =>
          other.revoked_at === null &&
          other.enrolment_id === row.enrolment_id &&
          other.purpose === row.purpose &&
          (other.recipient_ref ?? "") === (recipient ?? ""),
      )
    ) {
      fail(
        409,
        "23505",
        purpose === "core"
          ? 'duplicate key value violates unique constraint "programme_consents_live_core_key"'
          : 'duplicate key value violates unique constraint "programme_consents_live_key"',
      );
    }
    this.state.programme_consents.push(row);
    return row;
  }

  private update(
    uid: string,
    table: keyof State,
    url: URL,
    change: Row,
  ): Row[] {
    const granted = UPDATE_GRANTS[table];
    if (
      !granted ||
      Object.keys(change).some((column) => !granted.includes(column))
    ) {
      return fail(403, "42501", `permission denied for table ${table}`);
    }
    const targets = this.filter(this.visible(uid, table), url);
    for (const row of targets) {
      if (table === "enrolments") {
        const old = { ...row };
        Object.assign(row, change);
        // enrolments_manage_leaving
        if (row.status === "left" && old.status !== "left")
          row.left_at = this.now();
        else if (row.status !== "left") row.left_at = null;
        else row.left_at = old.left_at;
        row.updated_at = this.now();
        // RLS WITH CHECK (own row, deletion barrier open) before CHECK
        // constraints, as Postgres runs them.
        if (row.user_id !== uid || !this.barrierOpen(uid)) rlsViolation(table);
        this.checkEnrolment(row);
        // enrolments_revoke_on_leave
        if (row.status === "left" && old.status !== "left") {
          const at = this.now();
          for (const consent of this.state.programme_consents) {
            if (
              consent.enrolment_id === row.id &&
              consent.purpose !== "core" &&
              consent.revoked_at === null
            ) {
              consent.revoked_at = at;
            }
          }
        }
      } else {
        // Only supersede_core_consent sets superseded_by here (the API never
        // writes it directly); a direct write is refused as the
        // programme_consents_check_supersede trigger refuses a row that does
        // not name its live replacement.
        if (change.superseded_by !== undefined) raise("consent_immutable", 1);
        // consent_revoke_only
        if (row.revoked_at !== null) raise("consent_already_revoked");
        if (change.revoked_at === null || change.revoked_at === undefined) {
          raise("consent_immutable", 0);
        }
        const at = this.now();
        row.revoked_at = at;
        // programme_consents_revoke_with_core
        if (row.purpose === "core") {
          for (const consent of this.state.programme_consents) {
            if (
              consent.enrolment_id === row.enrolment_id &&
              consent.revoked_at === null
            ) {
              consent.revoked_at = at;
            }
          }
        }
      }
    }
    return targets;
  }

  /** A direct delete: refused for every table (DELETE_GRANTS). */
  private remove(uid: string, table: keyof State, url: URL): Row[] {
    if (!DELETE_GRANTS.includes(table)) {
      return fail(403, "42501", `permission denied for table ${table}`);
    }
    const targets = this.filter(this.visible(uid, table), url);
    const ids = new Set(targets.map((row) => row.id));
    this.state.enrolments = this.state.enrolments.filter(
      (row) => !ids.has(row.id),
    );
    this.state.programme_consents = this.state.programme_consents.filter(
      (row) => !ids.has(row.enrolment_id),
    );
    return targets;
  }

  private checkEnrolment(row: Row): void {
    if (!STATUSES.includes(row.status as string))
      checkViolation("enrolments_status_check");
    if (
      row.mode !== null &&
      !(
        ["bf", "sf"].includes(row.programme_code as string) &&
        ["quit", "reduce"].includes(row.mode as string)
      )
    ) {
      checkViolation("enrolments_mode_check");
    }
    if ((row.status === "left") !== (row.left_at !== null)) {
      checkViolation("enrolments_left_state_check");
    }
  }

  /**
   * enrolments_focus_cap: deferred, so checked when the request commits, for
   * the user whose rows the request wrote (the trigger counts that user's).
   */
  private deferredChecks(uid: string): void {
    const focus = this.state.enrolments.filter(
      (row) => row.user_id === uid && row.status === "focus",
    );
    if (focus.length > 2) raise("focus_cap_reached");
  }

  private barrierOpen(uid: string): boolean {
    const profile = this.state.profiles.find((row) => row.id === uid);
    return (
      profile !== undefined && profile.account_deletion_started_at === null
    );
  }

  private hasConsent(
    uid: string,
    enrolmentId: string,
    purpose: string,
  ): boolean {
    const enrolment = this.state.enrolments.find(
      (row) => row.id === enrolmentId,
    );
    return (
      enrolment !== undefined &&
      enrolment.user_id === uid &&
      enrolment.status !== "left" &&
      this.barrierOpen(uid) &&
      this.state.programme_consents.some(
        (row) =>
          row.enrolment_id === enrolmentId &&
          row.purpose === purpose &&
          row.recipient_ref === null &&
          row.revoked_at === null,
      )
    );
  }

  // ---- query string -------------------------------------------------------

  private filter(rows: Row[], url: URL): Row[] {
    const reserved = [
      "select",
      "order",
      "limit",
      "offset",
      "columns",
      "on_conflict",
    ];
    let result = rows;
    for (const [column, expression] of url.searchParams) {
      if (reserved.includes(column)) continue;
      const dot = expression.indexOf(".");
      const operator = expression.slice(0, dot);
      const operand = expression.slice(dot + 1);
      if (operator === "eq") {
        result = result.filter(
          (row) => row[column] !== null && text(row[column]) === operand,
        );
      } else if (operator === "is" && operand === "null") {
        result = result.filter((row) => row[column] === null);
      } else if (operator === "in") {
        const values = operand
          .replace(/^\(|\)$/g, "")
          .split(",")
          .map((value) => value.replace(/^"|"$/g, ""));
        result = result.filter((row) => values.includes(text(row[column])));
      } else {
        fail(400, "PGRST100", "Unsupported filter");
      }
    }
    const limit = url.searchParams.get("limit");
    return limit === null ? result : result.slice(0, Number(limit));
  }

  private order(rows: Row[], url: URL): Row[] {
    const order = url.searchParams.get("order");
    if (!order) return rows;
    const [column, direction] = order.split(".");
    const sign = direction === "desc" ? -1 : 1;
    return [...rows].sort(
      (a, b) =>
        sign *
        text(a[column as string]).localeCompare(text(b[column as string])),
    );
  }

  private project(row: Row, url: URL): Row {
    const select = url.searchParams.get("select");
    if (!select || select === "*") return structuredClone(row);
    const projected: Row = {};
    for (const column of select.split(",")) {
      projected[column] = structuredClone(row[column]);
    }
    return projected;
  }

  private now(): string {
    this.clock += 1;
    return new Date(this.clock).toISOString();
  }

  private respond(status: number, body: unknown, total?: number): Response {
    const headers: Record<string, string> = {
      "content-type": "application/json",
    };
    if (total !== undefined && Array.isArray(body)) {
      headers["content-range"] =
        body.length === 0 ? `*/${total}` : `0-${body.length - 1}/${total}`;
    }
    return new Response(body === null ? null : JSON.stringify(body), {
      status,
      headers,
    });
  }
}
