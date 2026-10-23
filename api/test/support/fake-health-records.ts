import { randomUUID } from "node:crypto";

/**
 * The health record tables of supabase/migrations/202610180015_records.sql
 * for the fake PostgREST (fake-postgrest.ts owns request handling, state and
 * rollback), as the member's own token sees them:
 *
 * - record_categories: select of every row (the seeded categories); no write.
 * - record_sources: select own; insert (column grants; policy: own user_id
 *   and the deletion barrier; kind, URL-for-kind, display name and status
 *   checks; one manual, apple_health and health_connect source per member,
 *   23505); update of display_name, status and last_synced_at; no delete.
 * - record_items: select own; insert (column grants; policy: own user_id and
 *   the deletion barrier; the composite source key (23503), the category
 *   key (23503), the checks, and the unique dedupe key per member (23505,
 *   also against earlier rows of the same statement)); update of status
 *   only (policy: own row); no delete.
 * - record_routes: select own; insert (column grants; policy: own user_id,
 *   has_consent(enrolment, 'records_import'), an accepted item of the caller
 *   whose category the programme receives, the deletion barrier; the
 *   primary key (23505) and the composite enrolment key (23503)); no update
 *   or delete.
 *
 * Not emulated: record_imports and record_category_codes (no API path writes
 * them yet), delete_record_source_items, the truncate guard and the sync
 * session guard. "Delete now" removes the enrolment's routes and account
 * deletion removes every record row of the member (counts not returned).
 */

type Row = Record<string, unknown>;

export const HEALTH_RECORD_TABLES = [
  "record_categories",
  "record_sources",
  "record_items",
  "record_routes",
] as const;
export type HealthRecordTable = (typeof HEALTH_RECORD_TABLES)[number];

export interface HealthRecordState {
  programmes: Row[];
  enrolments: Row[];
  record_categories: Row[];
  record_sources: Row[];
  record_items: Row[];
  record_routes: Row[];
}

export interface HealthRecordContext {
  state(): HealthRecordState;
  barrierOpen(uid: string): boolean;
  hasConsent(uid: string, enrolmentId: string, purpose: string): boolean;
  now(): string;
  fail(status: number, code: string, message: string): never;
}

/** The distinct values of programmes.receives_resources (the seed). */
export const RECORD_CATEGORIES = [
  "a1c",
  "blood_pressure",
  "egfr",
  "glucose",
  "immunizations",
  "lipids",
  "smoking_status",
];

const INSERT_GRANTS: Record<string, string[]> = {
  record_sources: [
    "user_id",
    "kind",
    "fhir_base_url",
    "display_name",
    "status",
  ],
  record_items: [
    "user_id",
    "source_id",
    "import_id",
    "resource_type",
    "fhir_id",
    "category",
    "code_system",
    "code",
    "display",
    "value_num",
    "value_text",
    "unit_ucum",
    "effective_at",
    "status",
    "dedupe_key",
  ],
  record_routes: [
    "record_item_id",
    "user_id",
    "enrolment_id",
    "programme_code",
  ],
};
const UPDATE_GRANTS: Record<string, string[]> = {
  record_sources: ["display_name", "status", "last_synced_at"],
  record_items: ["status"],
};
const KINDS = [
  "epic",
  "oracle",
  "bluebutton",
  "smart",
  "apple_health",
  "health_connect",
  "manual",
];
const FHIR_KINDS = ["epic", "oracle", "bluebutton", "smart"];
const SINGLE_KINDS = ["manual", "apple_health", "health_connect"];
const RESOURCE_TYPES = [
  "Observation",
  "Condition",
  "MedicationRequest",
  "Immunization",
];
const ITEM_STATUSES = ["pending_review", "accepted", "rejected", "conflict"];

export class FakeHealthRecords {
  constructor(private readonly ctx: HealthRecordContext) {}

  private check(table: string, name: string): never {
    return this.ctx.fail(
      400,
      "23514",
      `new row for relation "${table}" violates check constraint "${name}"`,
    );
  }

  private rls(table: string): never {
    return this.ctx.fail(
      403,
      "42501",
      `new row violates row-level security policy for table "${table}"`,
    );
  }

  /** Superuser seed of an item (an import the API did not make). */
  seedItem(row: Row): Row {
    const full: Row = {
      id: randomUUID(),
      import_id: null,
      fhir_id: null,
      value_num: null,
      value_text: null,
      unit_ucum: null,
      effective_at: null,
      status: "pending_review",
      created_at: this.ctx.now(),
      updated_at: this.ctx.now(),
      ...row,
    };
    this.ctx.state().record_items.push(full);
    return full;
  }

  /** Superuser seed of a source. */
  seedSource(row: Row): Row {
    const full: Row = {
      id: randomUUID(),
      fhir_base_url: null,
      last_synced_at: null,
      created_at: this.ctx.now(),
      updated_at: this.ctx.now(),
      ...row,
    };
    this.ctx.state().record_sources.push(full);
    return full;
  }

  visible(uid: string, table: HealthRecordTable): Row[] {
    const state = this.ctx.state();
    if (table === "record_categories") return state.record_categories;
    return state[table].filter((row) => row.user_id === uid);
  }

  /** One statement: every row checked in order, then all kept or none. */
  insert(uid: string, table: HealthRecordTable, values: Row[]): Row[] {
    const granted = INSERT_GRANTS[table];
    if (
      !granted ||
      values.some((value) =>
        Object.keys(value).some((column) => !granted.includes(column)),
      )
    ) {
      return this.ctx.fail(
        403,
        "42501",
        `permission denied for table ${table}`,
      );
    }
    const state = this.ctx.state();
    const rows: Row[] = [];
    for (const value of values) {
      if (table === "record_sources") {
        const row: Row = {
          id: randomUUID(),
          user_id: value.user_id,
          kind: value.kind,
          fhir_base_url: value.fhir_base_url ?? null,
          display_name: value.display_name,
          status: value.status,
          last_synced_at: null,
          created_at: this.ctx.now(),
          updated_at: this.ctx.now(),
        };
        if (row.user_id !== uid || !this.ctx.barrierOpen(uid)) this.rls(table);
        if (!KINDS.includes(row.kind as string))
          this.check(table, "record_sources_kind_check");
        if (
          FHIR_KINDS.includes(row.kind as string) !==
          (row.fhir_base_url !== null)
        )
          this.check(table, "record_sources_fhir_base_url_kind_check");
        if (
          typeof row.display_name !== "string" ||
          row.display_name !== row.display_name.trim() ||
          row.display_name.length < 1 ||
          row.display_name.length > 80
        )
          this.check(table, "record_sources_display_name_check");
        if (
          !["connected", "needs_reauth", "disconnected"].includes(
            row.status as string,
          )
        )
          this.check(table, "record_sources_status_check");
        if (
          SINGLE_KINDS.includes(row.kind as string) &&
          [...state.record_sources, ...rows].some(
            (other) => other.user_id === row.user_id && other.kind === row.kind,
          )
        ) {
          this.ctx.fail(
            409,
            "23505",
            'duplicate key value violates unique constraint "record_sources_single_kind_key"',
          );
        }
        rows.push(row);
        continue;
      }
      if (table === "record_items") {
        const row: Row = {
          id: randomUUID(),
          user_id: value.user_id,
          source_id: value.source_id,
          import_id: value.import_id ?? null,
          resource_type: value.resource_type,
          fhir_id: value.fhir_id ?? null,
          category: value.category ?? null,
          code_system: value.code_system,
          code: value.code,
          display: value.display,
          value_num: value.value_num ?? null,
          value_text: value.value_text ?? null,
          unit_ucum: value.unit_ucum ?? null,
          effective_at: value.effective_at ?? null,
          status: value.status ?? "pending_review",
          dedupe_key: value.dedupe_key,
          created_at: this.ctx.now(),
          updated_at: this.ctx.now(),
        };
        if (row.user_id !== uid || !this.ctx.barrierOpen(uid)) this.rls(table);
        if (!RESOURCE_TYPES.includes(row.resource_type as string))
          this.check(table, "record_items_resource_type_check");
        if (!ITEM_STATUSES.includes(row.status as string))
          this.check(table, "record_items_status_check");
        if (
          typeof row.display !== "string" ||
          row.display !== row.display.trim() ||
          row.display.length < 1 ||
          row.display.length > 200
        )
          this.check(table, "record_items_display_check");
        if (
          typeof row.dedupe_key !== "string" ||
          row.dedupe_key.length < 1 ||
          row.dedupe_key.length > 300
        )
          this.check(table, "record_items_dedupe_key_check");
        if (
          [...state.record_items, ...rows].some(
            (other) =>
              other.user_id === row.user_id &&
              other.dedupe_key === row.dedupe_key,
          )
        ) {
          this.ctx.fail(
            409,
            "23505",
            'duplicate key value violates unique constraint "record_items_dedupe_key"',
          );
        }
        rows.push(row);
        continue;
      }
      // record_routes
      const row: Row = {
        record_item_id: value.record_item_id,
        user_id: value.user_id,
        enrolment_id: value.enrolment_id,
        programme_code: value.programme_code,
        created_at: this.ctx.now(),
      };
      const item = state.record_items.find((i) => i.id === row.record_item_id);
      const programme = state.programmes.find(
        (p) => p.code === row.programme_code,
      );
      if (
        row.user_id !== uid ||
        !this.ctx.hasConsent(
          uid,
          row.enrolment_id as string,
          "records_import",
        ) ||
        !item ||
        item.user_id !== uid ||
        item.status !== "accepted" ||
        !programme ||
        !(programme.receives_resources as string[]).includes(
          item.category as string,
        ) ||
        !this.ctx.barrierOpen(uid)
      ) {
        this.rls(table);
      }
      if (
        [...state.record_routes, ...rows].some(
          (other) =>
            other.record_item_id === row.record_item_id &&
            other.enrolment_id === row.enrolment_id,
        )
      ) {
        this.ctx.fail(
          409,
          "23505",
          'duplicate key value violates unique constraint "record_routes_pkey"',
        );
      }
      rows.push(row);
    }
    // Foreign keys, at the end of the statement.
    for (const row of rows) {
      if (
        table === "record_items" &&
        (!state.record_sources.some(
          (s) => s.id === row.source_id && s.user_id === row.user_id,
        ) ||
          (row.category !== null &&
            !state.record_categories.some((c) => c.category === row.category)))
      ) {
        this.ctx.fail(
          409,
          "23503",
          'insert or update on table "record_items" violates foreign key constraint',
        );
      }
      if (
        table === "record_routes" &&
        !state.enrolments.some(
          (e) =>
            e.id === row.enrolment_id &&
            e.user_id === row.user_id &&
            e.programme_code === row.programme_code,
        )
      ) {
        this.ctx.fail(
          409,
          "23503",
          'insert or update on table "record_routes" violates foreign key constraint',
        );
      }
    }
    state[table].push(...rows);
    return rows;
  }

  update(
    uid: string,
    table: HealthRecordTable,
    targets: Row[],
    change: Row,
  ): Row[] {
    const granted = UPDATE_GRANTS[table];
    if (
      !granted ||
      Object.keys(change).some((column) => !granted.includes(column))
    ) {
      return this.ctx.fail(
        403,
        "42501",
        `permission denied for table ${table}`,
      );
    }
    for (const row of targets) {
      Object.assign(row, change);
      row.updated_at = this.ctx.now();
      if (row.user_id !== uid) this.rls(table);
      if (
        table === "record_items" &&
        !ITEM_STATUSES.includes(row.status as string)
      )
        this.check(table, "record_items_status_check");
    }
    return targets;
  }

  remove(table: HealthRecordTable): Row[] {
    return this.ctx.fail(403, "42501", `permission denied for table ${table}`);
  }

  dropEnrolment(enrolmentId: string): void {
    const state = this.ctx.state();
    state.record_routes = state.record_routes.filter(
      (r) => r.enrolment_id !== enrolmentId,
    );
  }

  dropMember(uid: string): void {
    const state = this.ctx.state();
    for (const table of [
      "record_routes",
      "record_items",
      "record_sources",
    ] as const) {
      state[table] = state[table].filter((row) => row.user_id !== uid);
    }
  }
}
