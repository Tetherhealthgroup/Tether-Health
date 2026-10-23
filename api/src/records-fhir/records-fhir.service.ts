import { Injectable, Logger } from "@nestjs/common";
import type { PostgrestError } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { DatabaseErrorCode } from "../common/database-errors";
import {
  UserSupabaseClientFactory,
  type UserSupabaseClient,
} from "../enrolments/user-supabase-client";
import { readAll } from "../records-events/records-access";
import {
  dedupeKey,
  normaliseManual,
  plausibleRange,
  type ManualItem,
} from "./manual-entry";
import { recordError, recordsUnavailable } from "./records-fhir-errors";
import {
  itemStatuses,
  type AcceptItemsDto,
  type AcceptResponse,
  type ConflictsResponse,
  type ItemStatus,
  type ManualEntryDto,
  type ManualEntryResponse,
  type ProgrammeRouteCount,
  type RecordItemResponse,
  type RecordSourceResponse,
  type RecordsSummaryResponse,
  type ResolveConflictsDto,
} from "./records-fhir.dto";

/** The routes as logged: templates only. */
export const RECORD_ROUTES = {
  manual: "/v1/records/manual",
  accept: "/v1/records/fhir/accept",
  conflicts: "/v1/records/fhir/conflicts",
  sources: "/v1/records/fhir/sources",
  items: "/v1/records/fhir/items",
  summary: "/v1/records/fhir/summary",
} as const;

const {
  uniqueViolation: UNIQUE_VIOLATION,
  checkViolation: CHECK_VIOLATION,
  insufficientPrivilege: INSUFFICIENT_PRIVILEGE,
} = DatabaseErrorCode;

interface ItemRow {
  id: string;
  source_id: string;
  resource_type: RecordItemResponse["resourceType"];
  category: string | null;
  code_system: string;
  code: string;
  display: string;
  value_num: number | string | null;
  value_text: string | null;
  unit_ucum: string | null;
  effective_at: string | null;
  status: ItemStatus;
  dedupe_key: string;
}
interface SourceRow {
  id: string;
  kind: string;
  display_name: string;
  status: RecordSourceResponse["status"];
  last_synced_at: string | null;
  created_at: string;
}

const ITEM_COLUMNS =
  "id,source_id,resource_type,category,code_system,code,display,value_num,value_text,unit_ucum,effective_at,status,dedupe_key";
const SOURCE_COLUMNS = "id,kind,display_name,status,last_synced_at,created_at";
/** Ids per `in` filter, so a request URL stays short. */
const ID_CHUNK = 50;

const chunks = <T>(values: T[], size = ID_CHUNK): T[][] => {
  const out: T[][] = [];
  for (let i = 0; i < values.length; i += size)
    out.push(values.slice(i, i + size));
  return out;
};

/**
 * Health records the member reviews and enters by hand: manual values,
 * accepting imported items, resolving conflicts, and the reads the records
 * screens show. Every query runs as the caller, so row-level security
 * decides what exists; rows are also filtered on the caller's id. An item
 * reaches a programme only through record_routes, whose insert check needs
 * the enrolment's live records_import consent and a category the programme
 * receives; this service routes only where both hold.
 */
@Injectable()
export class RecordsFhirService {
  private readonly logger = new Logger(RecordsFhirService.name);

  constructor(private readonly clients: UserSupabaseClientFactory) {}

  // ---- manual entry ---------------------------------------------------------

  async manual(
    user: AuthUser,
    dto: ManualEntryDto,
    requestId: string,
  ): Promise<ManualEntryResponse> {
    const route = RECORD_ROUTES.manual;
    const result = normaliseManual(dto);
    if (!result.ok) {
      throw recordError(
        result.reason === "out_of_range"
          ? "value_out_of_range"
          : "invalid_request",
      );
    }
    const client = this.clients.forUser(user);
    await this.requireBarrierOpen(client, requestId, route);
    await this.refuseDuplicates(
      client,
      user,
      result.items.map((item) => item.dedupeKey),
      requestId,
      route,
    );
    const source = await this.manualSource(client, user, requestId, route);
    const rows = await this.insertAccepted(
      client,
      user,
      source.id,
      result.items,
      requestId,
      route,
    );
    const routedTo = await this.route(client, user, rows, requestId, route);
    return {
      items: rows.map((row) => toItem(row, new Set([source.id]))),
      routedTo,
    };
  }

  // ---- review ---------------------------------------------------------------

  /** Accepts items waiting for review and gives them to their programmes. */
  async accept(
    user: AuthUser,
    dto: AcceptItemsDto,
    requestId: string,
  ): Promise<AcceptResponse> {
    const route = RECORD_ROUTES.accept;
    const ids = dto.itemIds.map((id) => id.toLowerCase());
    const client = this.clients.forUser(user);
    const items = await this.ownItems(client, user, ids, requestId, route);
    if (items.some((item) => item.status !== "pending_review")) {
      throw recordError("item_not_reviewable");
    }
    await this.requireBarrierOpen(client, requestId, route);
    const accepted = await this.setStatus(
      client,
      user,
      ids,
      "pending_review",
      "accepted",
      requestId,
      route,
    );
    const routedTo = await this.route(client, user, accepted, requestId, route);
    return { accepted: accepted.length, routedTo };
  }

  /**
   * Resolves items in conflict. `use_imported` accepts the imported item
   * and rejects the member's own entry for the same test and day;
   * `keep_both` accepts it and keeps the entry; `keep_mine` and `discard`
   * reject it; `correct` rejects it and stores the corrected value as the
   * member's own entry (checked against the plausibility range).
   */
  async resolveConflicts(
    user: AuthUser,
    dto: ResolveConflictsDto,
    requestId: string,
  ): Promise<ConflictsResponse> {
    const route = RECORD_ROUTES.conflicts;
    const resolutions = dto.resolutions.map((r) => ({
      ...r,
      itemId: r.itemId.toLowerCase(),
    }));
    const ids = resolutions.map((r) => r.itemId);
    if (new Set(ids).size !== ids.length) throw recordError("invalid_request");
    for (const r of resolutions) {
      if ((r.choice === "correct") !== (r.correctedValue !== undefined)) {
        throw recordError("invalid_request");
      }
    }
    const client = this.clients.forUser(user);
    const items = await this.ownItems(client, user, ids, requestId, route);
    if (items.some((item) => item.status !== "conflict")) {
      throw recordError("item_not_reviewable");
    }
    const byId = new Map(items.map((item) => [item.id.toLowerCase(), item]));
    // Every correction is checked before anything is written.
    const corrections: ManualItem[] = [];
    for (const r of resolutions) {
      if (r.choice !== "correct") continue;
      const item = byId.get(r.itemId) as ItemRow;
      const range = plausibleRange(item.code_system, item.code);
      const value = r.correctedValue as number;
      if (range === null || item.resource_type !== "Observation") {
        throw recordError("invalid_request");
      }
      if (value < range[0] || value > range[1]) {
        throw recordError("value_out_of_range");
      }
      const day = (item.effective_at ?? new Date().toISOString()).slice(0, 10);
      corrections.push({
        resourceType: "Observation",
        category: item.category,
        codeSystem: item.code_system,
        code: item.code,
        display: item.display,
        valueNum: value,
        valueText: null,
        unit: item.unit_ucum,
        effectiveAt: item.effective_at ?? new Date().toISOString(),
        dedupeKey: dedupeKey(item.code_system, item.code, day, value),
      });
    }
    await this.requireBarrierOpen(client, requestId, route);
    const toAccept = resolutions
      .filter((r) => r.choice === "use_imported" || r.choice === "keep_both")
      .map((r) => r.itemId);
    const toReject = resolutions
      .filter((r) => !toAccept.includes(r.itemId))
      .map((r) => r.itemId);
    if (corrections.length > 0) {
      await this.refuseDuplicates(
        client,
        user,
        corrections.map((c) => c.dedupeKey),
        requestId,
        route,
      );
    }
    const accepted = await this.setStatus(
      client,
      user,
      toAccept,
      "conflict",
      "accepted",
      requestId,
      route,
    );
    const rejected = await this.setStatus(
      client,
      user,
      toReject,
      "conflict",
      "rejected",
      requestId,
      route,
    );
    // use_imported: the member's own entry for the same test and day goes.
    const replacing = resolutions
      .filter((r) => r.choice === "use_imported")
      .map((r) => byId.get(r.itemId) as ItemRow);
    let created: ItemRow[] = [];
    if (replacing.length > 0 || corrections.length > 0) {
      const source = await this.manualSource(client, user, requestId, route);
      if (replacing.length > 0) {
        await this.rejectOwnEntries(
          client,
          user,
          source.id,
          replacing,
          requestId,
          route,
        );
      }
      if (corrections.length > 0) {
        created = await this.insertAccepted(
          client,
          user,
          source.id,
          corrections,
          requestId,
          route,
        );
      }
    }
    const routedTo = await this.route(
      client,
      user,
      [...accepted, ...created],
      requestId,
      route,
    );
    return {
      accepted: accepted.map((row) => row.id),
      rejected: rejected.map((row) => row.id),
      created: created.map((row) => row.id),
      routedTo,
    };
  }

  // ---- reads ----------------------------------------------------------------

  async sources(
    user: AuthUser,
    requestId: string,
  ): Promise<{ sources: RecordSourceResponse[] }> {
    const rows = await this.ownSources(
      this.clients.forUser(user),
      user,
      requestId,
      RECORD_ROUTES.sources,
    );
    return {
      sources: rows.map((row) => ({
        id: row.id,
        kind: row.kind,
        displayName: row.display_name,
        status: row.status,
        lastSyncedAt: row.last_synced_at,
        createdAt: row.created_at,
      })),
    };
  }

  /**
   * The caller's items in `status` (one of the item statuses), or by
   * default the ones waiting for review (pending_review and conflict).
   * Only `status` is accepted in the query.
   */
  async items(
    user: AuthUser,
    query: unknown,
    requestId: string,
  ): Promise<{ items: RecordItemResponse[] }> {
    const route = RECORD_ROUTES.items;
    const statuses = parseItemsQuery(query);
    const client = this.clients.forUser(user);
    const result = await readAll<ItemRow>((from, to) =>
      client
        .from("record_items")
        .select(ITEM_COLUMNS, { count: "exact" })
        .eq("user_id", user.id)
        .in("status", statuses)
        .order("effective_at", { ascending: false })
        .range(from, to)
        .returns<ItemRow[]>(),
    );
    if ("error" in result) {
      return recordsUnavailable(this.logger, requestId, route, result.error);
    }
    const manual = await this.manualSourceIds(client, user, requestId, route);
    return { items: result.rows.map((row) => toItem(row, manual)) };
  }

  /** Counts for the records hub: sources, items to review, accepted by category. */
  async summary(
    user: AuthUser,
    requestId: string,
  ): Promise<RecordsSummaryResponse> {
    const route = RECORD_ROUTES.summary;
    const client = this.clients.forUser(user);
    const sources = await this.ownSources(client, user, requestId, route);
    const items = await readAll<Pick<ItemRow, "id" | "category" | "status">>(
      (from, to) =>
        client
          .from("record_items")
          .select("id,category,status", { count: "exact" })
          .eq("user_id", user.id)
          .order("id", { ascending: true })
          .range(from, to)
          .returns<Pick<ItemRow, "id" | "category" | "status">[]>(),
    );
    if ("error" in items) {
      return recordsUnavailable(this.logger, requestId, route, items.error);
    }
    const routes = await readAll<{
      record_item_id: string;
      programme_code: string;
    }>((from, to) =>
      client
        .from("record_routes")
        .select("record_item_id,programme_code", { count: "exact" })
        .eq("user_id", user.id)
        .order("record_item_id", { ascending: true })
        .range(from, to)
        .returns<{ record_item_id: string; programme_code: string }[]>(),
    );
    if ("error" in routes) {
      return recordsUnavailable(this.logger, requestId, route, routes.error);
    }
    const accepted = items.rows.filter(
      (row) => row.status === "accepted" && row.category !== null,
    );
    const categories = new Map<
      string,
      { items: number; programmes: Set<string> }
    >();
    const categoryOf = new Map(
      accepted.map((row) => [row.id, row.category as string]),
    );
    for (const row of accepted) {
      const entry = categories.get(row.category as string) ?? {
        items: 0,
        programmes: new Set<string>(),
      };
      entry.items += 1;
      categories.set(row.category as string, entry);
    }
    for (const r of routes.rows) {
      const category = categoryOf.get(r.record_item_id);
      if (category !== undefined)
        categories.get(category)?.programmes.add(r.programme_code);
    }
    return {
      sources: sources.filter((s) => s.status !== "disconnected").length,
      needsReview: items.rows.filter(
        (row) => row.status === "pending_review" || row.status === "conflict",
      ).length,
      categories: [...categories.entries()]
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([category, entry]) => ({
          category,
          items: entry.items,
          programmes: [...entry.programmes].sort(),
        })),
    };
  }

  // ---- helpers --------------------------------------------------------------

  private async requireBarrierOpen(
    client: UserSupabaseClient,
    requestId: string,
    route: string,
  ): Promise<void> {
    if (!(await this.barrierOpen(client, requestId, route))) {
      throw recordError("account_deletion_in_progress");
    }
  }

  private async barrierOpen(
    client: UserSupabaseClient,
    requestId: string,
    route: string,
  ): Promise<boolean> {
    const { data, error } = (await client.rpc("deletion_barrier_open")) as {
      data: unknown;
      error: PostgrestError | null;
    };
    if (error)
      return recordsUnavailable(this.logger, requestId, route, error.code);
    return data === true;
  }

  /** The caller's items with these ids; any id not found → item_not_found. */
  private async ownItems(
    client: UserSupabaseClient,
    user: AuthUser,
    ids: string[],
    requestId: string,
    route: string,
  ): Promise<ItemRow[]> {
    const rows: ItemRow[] = [];
    for (const part of chunks(ids)) {
      const { data, error } = await client
        .from("record_items")
        .select(ITEM_COLUMNS)
        .eq("user_id", user.id)
        .in("id", part)
        .returns<ItemRow[]>();
      if (error)
        return recordsUnavailable(this.logger, requestId, route, error.code);
      rows.push(...data);
    }
    if (rows.length !== ids.length) throw recordError("item_not_found");
    return rows;
  }

  /** Any stored item of the caller with one of these keys → record_duplicate. */
  private async refuseDuplicates(
    client: UserSupabaseClient,
    user: AuthUser,
    keys: string[],
    requestId: string,
    route: string,
  ): Promise<void> {
    for (const part of chunks(keys)) {
      const { data, error } = await client
        .from("record_items")
        .select("id")
        .eq("user_id", user.id)
        .in("dedupe_key", part)
        .returns<{ id: string }[]>();
      if (error)
        return recordsUnavailable(this.logger, requestId, route, error.code);
      if (data.length > 0) throw recordError("record_duplicate");
    }
  }

  private async ownSources(
    client: UserSupabaseClient,
    user: AuthUser,
    requestId: string,
    route: string,
  ): Promise<SourceRow[]> {
    const { data, error } = await client
      .from("record_sources")
      .select(SOURCE_COLUMNS)
      .eq("user_id", user.id)
      .order("created_at", { ascending: true })
      .returns<SourceRow[]>();
    if (error)
      return recordsUnavailable(this.logger, requestId, route, error.code);
    return data;
  }

  private async manualSourceIds(
    client: UserSupabaseClient,
    user: AuthUser,
    requestId: string,
    route: string,
  ): Promise<Set<string>> {
    const sources = await this.ownSources(client, user, requestId, route);
    return new Set(sources.filter((s) => s.kind === "manual").map((s) => s.id));
  }

  /** The caller's one manual source, created on first use. */
  private async manualSource(
    client: UserSupabaseClient,
    user: AuthUser,
    requestId: string,
    route: string,
  ): Promise<SourceRow> {
    const find = async () => {
      const { data, error } = await client
        .from("record_sources")
        .select(SOURCE_COLUMNS)
        .eq("user_id", user.id)
        .eq("kind", "manual")
        .maybeSingle<SourceRow>();
      if (error)
        return recordsUnavailable(this.logger, requestId, route, error.code);
      return data;
    };
    const existing = await find();
    if (existing) return existing;
    const { data, error } = await client
      .from("record_sources")
      .insert({
        user_id: user.id,
        kind: "manual",
        display_name: "Entered by you",
        status: "connected",
      })
      .select(SOURCE_COLUMNS)
      .single<SourceRow>();
    if (!error) return data;
    // A concurrent first entry created it.
    if (error.code === UNIQUE_VIOLATION) {
      const created = await find();
      if (created) return created;
    }
    throw await this.writeRefusal(client, error, requestId, route);
  }

  private async insertAccepted(
    client: UserSupabaseClient,
    user: AuthUser,
    sourceId: string,
    items: ManualItem[],
    requestId: string,
    route: string,
  ): Promise<ItemRow[]> {
    const { data, error } = await client
      .from("record_items")
      .insert(
        items.map((item) => ({
          user_id: user.id,
          source_id: sourceId,
          resource_type: item.resourceType,
          category: item.category,
          code_system: item.codeSystem,
          code: item.code,
          display: item.display,
          value_num: item.valueNum,
          value_text: item.valueText,
          unit_ucum: item.unit,
          effective_at: item.effectiveAt,
          status: "accepted",
          dedupe_key: item.dedupeKey,
        })),
      )
      .select(ITEM_COLUMNS)
      .returns<ItemRow[]>();
    if (error) {
      // Stored meanwhile by a concurrent request.
      if (error.code === UNIQUE_VIOLATION)
        throw recordError("record_duplicate");
      throw await this.writeRefusal(client, error, requestId, route);
    }
    return data;
  }

  /** Moves the caller's items with these ids from `from` to `to`. */
  private async setStatus(
    client: UserSupabaseClient,
    user: AuthUser,
    ids: string[],
    from: ItemStatus,
    to: ItemStatus,
    requestId: string,
    route: string,
  ): Promise<ItemRow[]> {
    const rows: ItemRow[] = [];
    for (const part of chunks(ids)) {
      const { data, error } = await client
        .from("record_items")
        .update({ status: to })
        .eq("user_id", user.id)
        .eq("status", from)
        .in("id", part)
        .select(ITEM_COLUMNS)
        .returns<ItemRow[]>();
      if (error) throw await this.writeRefusal(client, error, requestId, route);
      rows.push(...data);
    }
    // Another request changed one of them meanwhile.
    if (rows.length !== ids.length) throw recordError("item_not_reviewable");
    return rows;
  }

  /** Rejects the member's accepted entries for the same test and day. */
  private async rejectOwnEntries(
    client: UserSupabaseClient,
    user: AuthUser,
    manualSourceId: string,
    imported: ItemRow[],
    requestId: string,
    route: string,
  ): Promise<void> {
    for (const item of imported) {
      if (item.effective_at === null) continue;
      const day = item.effective_at.slice(0, 10);
      const { error } = await client
        .from("record_items")
        .update({ status: "rejected" })
        .eq("user_id", user.id)
        .eq("source_id", manualSourceId)
        .eq("code_system", item.code_system)
        .eq("code", item.code)
        .eq("status", "accepted")
        .gte("effective_at", `${day}T00:00:00.000Z`)
        .lt("effective_at", nextDay(day));
      if (error) throw await this.writeRefusal(client, error, requestId, route);
    }
  }

  /**
   * Gives accepted items with a category to every enrolment of the caller
   * that is not left, receives that category and holds a live
   * records_import consent. Routes that already exist are skipped. A
   * programme whose consent went away meanwhile (42501 with the barrier
   * open) is skipped too: its items stay accepted and unrouted.
   */
  private async route(
    client: UserSupabaseClient,
    user: AuthUser,
    items: ItemRow[],
    requestId: string,
    route: string,
  ): Promise<ProgrammeRouteCount[]> {
    const routable = items.filter(
      (item) => item.status === "accepted" && item.category !== null,
    );
    if (routable.length === 0) return [];
    const { data: enrolments, error: enrolmentError } = await client
      .from("enrolments")
      .select("id,programme_code,status")
      .eq("user_id", user.id)
      .returns<{ id: string; programme_code: string; status: string }[]>();
    if (enrolmentError) {
      return recordsUnavailable(
        this.logger,
        requestId,
        route,
        enrolmentError.code,
      );
    }
    const live = enrolments.filter((e) => e.status !== "left");
    if (live.length === 0) return [];
    const [
      { data: programmes, error: programmeError },
      { data: consents, error: consentError },
    ] = await Promise.all([
      client
        .from("programmes")
        .select("code,receives_resources")
        .in(
          "code",
          live.map((e) => e.programme_code),
        )
        .returns<{ code: string; receives_resources: string[] }[]>(),
      client
        .from("programme_consents")
        .select("enrolment_id")
        .in(
          "enrolment_id",
          live.map((e) => e.id),
        )
        .eq("purpose", "records_import")
        .is("revoked_at", null)
        .returns<{ enrolment_id: string }[]>(),
    ]);
    if (programmeError || consentError) {
      return recordsUnavailable(
        this.logger,
        requestId,
        route,
        (programmeError ?? consentError)?.code,
      );
    }
    const consented = new Set(consents.map((c) => c.enrolment_id));
    const receives = new Map(
      programmes.map((p) => [p.code, p.receives_resources]),
    );
    const counts: ProgrammeRouteCount[] = [];
    for (const enrolment of live) {
      if (!consented.has(enrolment.id)) continue;
      const wanted = routable.filter((item) =>
        (receives.get(enrolment.programme_code) ?? []).includes(
          item.category as string,
        ),
      );
      if (wanted.length === 0) continue;
      const { data: existing, error: existingError } = await client
        .from("record_routes")
        .select("record_item_id")
        .eq("user_id", user.id)
        .eq("enrolment_id", enrolment.id)
        .in(
          "record_item_id",
          wanted.map((item) => item.id),
        )
        .returns<{ record_item_id: string }[]>();
      if (existingError) {
        return recordsUnavailable(
          this.logger,
          requestId,
          route,
          existingError.code,
        );
      }
      const already = new Set(existing.map((r) => r.record_item_id));
      const fresh = wanted.filter((item) => !already.has(item.id));
      if (fresh.length > 0) {
        const { error } = await client.from("record_routes").insert(
          fresh.map((item) => ({
            record_item_id: item.id,
            user_id: user.id,
            enrolment_id: enrolment.id,
            programme_code: enrolment.programme_code,
          })),
        );
        if (error) {
          if (
            error.code === INSUFFICIENT_PRIVILEGE &&
            (await this.barrierOpen(client, requestId, route))
          ) {
            continue;
          }
          throw await this.writeRefusal(client, error, requestId, route);
        }
      }
      counts.push({
        programmeCode: enrolment.programme_code,
        items: wanted.length,
      });
    }
    return counts.sort((a, b) =>
      a.programmeCode.localeCompare(b.programmeCode),
    );
  }

  /**
   * A refused write, matched by code only: a row-level security refusal
   * with the deletion barrier closed is account_deletion_in_progress; a
   * check violation is invalid input; anything else fails closed as a 502.
   */
  private async writeRefusal(
    client: UserSupabaseClient,
    error: PostgrestError,
    requestId: string,
    route: string,
  ): Promise<Error> {
    if (error.code === CHECK_VIOLATION) return recordError("invalid_request");
    if (
      error.code === INSUFFICIENT_PRIVILEGE &&
      !(await this.barrierOpen(client, requestId, route))
    ) {
      return recordError("account_deletion_in_progress");
    }
    return recordsUnavailable(this.logger, requestId, route, error.code);
  }
}

const nextDay = (day: string): string => {
  const at = new Date(`${day}T00:00:00.000Z`);
  at.setUTCDate(at.getUTCDate() + 1);
  return at.toISOString();
};

/** `status` (one item status) only; none → the review statuses. */
export function parseItemsQuery(query: unknown): ItemStatus[] {
  if (query === null || typeof query !== "object")
    throw recordError("invalid_request");
  const values = query as Record<string, unknown>;
  if (Reflect.ownKeys(values).some((key) => key !== "status")) {
    throw recordError("invalid_request");
  }
  const { status } = values;
  if (status === undefined) return ["pending_review", "conflict"];
  const found = itemStatuses.find((known) => known === status);
  if (found === undefined) throw recordError("invalid_request");
  return [found];
}

function toItem(row: ItemRow, manualSources: Set<string>): RecordItemResponse {
  return {
    id: row.id,
    sourceId: row.source_id,
    enteredByYou: manualSources.has(row.source_id),
    resourceType: row.resource_type,
    category: row.category,
    codeSystem: row.code_system,
    code: row.code,
    display: row.display,
    value: row.value_num === null ? null : Number(row.value_num),
    valueText: row.value_text,
    unit: row.unit_ucum,
    effectiveAt: row.effective_at,
    status: row.status,
  };
}
