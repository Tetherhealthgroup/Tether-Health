import { randomUUID } from "node:crypto";
import { Logger } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import {
  FastifyAdapter,
  NestFastifyApplication,
} from "@nestjs/platform-fastify";
import { Test } from "@nestjs/testing";
import { AppModule } from "../src/app.module";
import {
  AccountDeletionErrorCode,
  AccountService,
} from "../src/account/account.service";
import { TokenVerifier } from "../src/auth/token-verifier";
import { environmentSchema } from "../src/config/environment";
import { buildFastifyAdapterOptions } from "../src/config/fastify-adapter-options";
import { configureApp } from "../src/configure-app";
import { UserSupabaseClientFactory } from "../src/enrolments/user-supabase-client";
import { ProfileService } from "../src/profile/profile.service";
import { QuitPlanService } from "../src/quit-plan/quit-plan.service";
import { ProgramDataService } from "../src/program-data/program-data.service";
import { DATABASE_ERRORS } from "./support/database-errors";
import { FakePostgrest, registryError } from "./support/fake-postgrest";
import { openApiErrors } from "./support/openapi";

describe("API (e2e)", () => {
  let app: NestFastifyApplication;

  beforeAll(async () => {
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(TokenVerifier)
      .useValue({
        verify: () =>
          Promise.resolve({
            sub: "00000000-0000-4000-8000-000000000001",
            authTime: Math.floor(Date.now() / 1000),
          }),
      })
      .overrideProvider(ProfileService)
      .useValue({
        get: () => Promise.resolve(profileFixture()),
        update: (_user: unknown, update: Record<string, unknown>) => {
          const profile = profileFixture();
          return Promise.resolve({
            ...profile,
            locale:
              (update.locale as "en" | "es" | undefined) ?? profile.locale,
          });
        },
      })
      .overrideProvider(QuitPlanService)
      .useValue({
        get: () => Promise.resolve(quitPlanFixture()),
        put: (_user: unknown, plan: Record<string, unknown>) =>
          Promise.resolve({ ...quitPlanFixture(), ...plan }),
        create: (_user: unknown, plan: Record<string, unknown>) =>
          Promise.resolve({ ...quitPlanFixture(), ...plan }),
      })
      .overrideProvider(AccountService)
      .useValue({
        export: () =>
          Promise.resolve({
            schemaVersion: "1.0",
            generatedAt: "2026-09-20T00:00:00.000Z",
            profile: profileFixture(),
            quitPlan: quitPlanFixture(),
            programData: [],
          }),
        deleteData: () =>
          Promise.resolve({
            requestId: "00000000-0000-4000-8000-000000000001",
            completedAt: "2026-09-20T00:00:00.000Z",
            deleted: {
              profiles: 1,
              quitPlans: 1,
              avatarObjects: 0,
              programData: 0,
            },
            authIdentityDeleted: true,
            authIdentityStatus: "deleted",
          }),
      })
      .overrideProvider(ProgramDataService)
      .useValue({
        get: (_user: unknown, programId: string) =>
          Promise.resolve({
            programId,
            payload: { readings: [] },
            revision: 1,
            updatedAt: "2026-09-26T00:00:00.000Z",
          }),
        put: (
          _user: unknown,
          programId: string,
          dto: Record<string, unknown>,
        ) =>
          Promise.resolve({
            programId,
            ...dto,
            updatedAt: "2026-09-26T00:00:00.000Z",
          }),
        delete: () => Promise.resolve(),
      })
      .compile();
    app = module.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter({ bodyLimit: 65536 }),
    );
    await configureApp(app);
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
  });

  afterAll(async () => app.close());

  it("GET /health is public", async () => {
    const response = await app.inject({ method: "GET", url: "/health" });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({
      status: "ok",
      service: "breathefree-api",
      version: "1.0.0",
    });
    expect(response.headers["x-content-type-options"]).toBe("nosniff");
    expect(response.headers["referrer-policy"]).toBe("no-referrer");
    expect(response.headers["x-ratelimit-limit"]).toBeDefined();
  });

  it.each([
    ["GET", "/v1/profile", undefined],
    ["PATCH", "/v1/profile", { locale: "en" }],
    ["GET", "/v1/quit-plan", undefined],
    ["PUT", "/v1/quit-plan", {}],
    ["POST", "/v1/quit-plan/guest-import", {}],
    ["GET", "/v1/account/export", undefined],
    ["DELETE", "/v1/account/data", { confirmation: "DELETE" }],
    ["GET", "/v1/program-data/steady", undefined],
    ["PUT", "/v1/program-data/steady", { payload: {}, revision: 1 }],
  ])("%s %s requires a token", async (method, url, payload) => {
    const response = await app.inject({
      method: method as "DELETE" | "GET" | "PATCH" | "POST" | "PUT",
      url,
      payload,
    });
    expect(response.statusCode).toBe(401);
  });

  it("GET /v1/profile returns the authenticated caller profile", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/v1/profile",
      headers: { authorization: "Bearer test-token" },
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual(profileFixture());
  });

  it("PATCH /v1/profile validates and updates allowed fields", async () => {
    const response = await app.inject({
      method: "PATCH",
      url: "/v1/profile",
      headers: { authorization: "Bearer test-token" },
      payload: { locale: "es" },
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ ...profileFixture(), locale: "es" });
  });

  it("PATCH /v1/profile rejects fields outside the v1 contract", async () => {
    const response = await app.inject({
      method: "PATCH",
      url: "/v1/profile",
      headers: { authorization: "Bearer test-token" },
      payload: { healthNotes: "must not enter profile storage" },
    });
    expect(response.statusCode).toBe(400);
  });

  it("GET /v1/program-data/:programId returns only the caller module", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/v1/program-data/steady",
      headers: { authorization: "Bearer test-token" },
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      programId: "steady",
      payload: { readings: [] },
      revision: 1,
    });
  });

  it("rejects unsupported program identifiers", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/v1/program-data/breathefree",
      headers: { authorization: "Bearer test-token" },
    });
    expect(response.statusCode).toBe(400);
  });

  it("GET /v1/quit-plan returns the caller's complete plan", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/v1/quit-plan",
      headers: { authorization: "Bearer test-token" },
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual(quitPlanFixture());
  });

  it("PUT /v1/quit-plan validates and replaces the caller's plan", async () => {
    const payload = { ...quitPlanInput(), readinessPath: "explore" };
    const response = await app.inject({
      method: "PUT",
      url: "/v1/quit-plan",
      headers: { authorization: "Bearer test-token" },
      payload,
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ ...quitPlanFixture(), ...payload });
  });

  it("POST /v1/quit-plan/guest-import creates without replacing", async () => {
    const payload = { ...quitPlanInput(), readinessPath: "explore" };
    const response = await app.inject({
      method: "POST",
      url: "/v1/quit-plan/guest-import",
      headers: { authorization: "Bearer test-token" },
      payload,
    });
    expect(response.statusCode).toBe(201);
    expect(response.json()).toEqual({ ...quitPlanFixture(), ...payload });
  });

  it("PUT /v1/quit-plan rejects unknown or invalid fields", async () => {
    const response = await app.inject({
      method: "PUT",
      url: "/v1/quit-plan",
      headers: { authorization: "Bearer test-token" },
      payload: { ...quitPlanInput(), readinessPath: "invalid", notes: "no" },
    });
    expect(response.statusCode).toBe(400);
  });

  it("PUT /v1/quit-plan rejects duplicate support-person IDs", async () => {
    const input = quitPlanInput();
    const response = await app.inject({
      method: "PUT",
      url: "/v1/quit-plan",
      headers: { authorization: "Bearer test-token" },
      payload: {
        ...input,
        supportPeople: [input.supportPeople[0], input.supportPeople[0]],
      },
    });
    expect(response.statusCode).toBe(400);
  });

  it("GET /v1/account/export returns only the bounded account export", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/v1/account/export",
      headers: { authorization: "Bearer test-token" },
    });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      schemaVersion: "1.0",
      profile: { id: profileFixture().id },
      quitPlan: { userId: profileFixture().id },
    });
  });

  it("DELETE /v1/account/data requires exact explicit confirmation", async () => {
    const rejected = await app.inject({
      method: "DELETE",
      url: "/v1/account/data",
      headers: { authorization: "Bearer test-token" },
      payload: { confirmation: "delete" },
    });
    expect(rejected.statusCode).toBe(400);

    const attemptedRetarget = await app.inject({
      method: "DELETE",
      url: "/v1/account/data",
      headers: { authorization: "Bearer test-token" },
      payload: {
        confirmation: "DELETE",
        userId: "00000000-0000-0000-0000-000000000002",
      },
    });
    expect(attemptedRetarget.statusCode).toBe(400);

    const accepted = await app.inject({
      method: "DELETE",
      url: "/v1/account/data",
      headers: { authorization: "Bearer test-token" },
      payload: { confirmation: "DELETE" },
    });
    expect(accepted.statusCode).toBe(200);
    expect(accepted.json()).toMatchObject({
      deleted: { profiles: 1, quitPlans: 1 },
      authIdentityDeleted: true,
      authIdentityStatus: "deleted",
    });
  });

  it("rejects request bodies larger than the privacy boundary", async () => {
    const response = await app.inject({
      method: "PATCH",
      url: "/v1/profile",
      headers: { authorization: "Bearer test-token" },
      payload: { displayName: "x".repeat(70000) },
    });
    expect(response.statusCode).toBe(413);
    expect(response.json()).toEqual(
      expect.objectContaining({ statusCode: 413, error: "Request rejected" }),
    );
  });
});

/**
 * Account deletion end to end through the real Nest app, guard, validation,
 * filters, AccountService and supabase-js client. Mocked: TokenVerifier and
 * the network below supabase-js, a fake PostgREST and Storage API
 * (test/support/fake-postgrest.ts) that takes the caller from each
 * request's own bearer token and emulates begin_account_deletion,
 * delete_my_account and the avatar bucket.
 */
describe("Account deletion (e2e)", () => {
  const TOKEN_PREFIX = "synthetic-deletion-token";
  let app: NestFastifyApplication;
  let fake: FakePostgrest;
  const users = new Map<string, { sub: string; authTime: number }>();
  const logged: string[] = [];
  let counter = 0;

  interface Member {
    token: string;
    id: string;
    address: string;
  }

  beforeAll(async () => {
    fake = new FakePostgrest();
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(TokenVerifier)
      .useValue({
        verify: (token: string) => {
          const user = users.get(token);
          return user
            ? Promise.resolve(user)
            : Promise.reject(new Error("invalid token"));
        },
      })
      .overrideProvider(UserSupabaseClientFactory)
      .useFactory({
        factory: (config: ConfigService) =>
          new UserSupabaseClientFactory(config, fake.fetch),
        inject: [ConfigService],
      })
      .compile();
    app = module.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter({ bodyLimit: 65536 }),
    );
    await configureApp(app);
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
    for (const level of ["log", "warn", "error", "debug", "verbose"] as const) {
      jest
        .spyOn(Logger.prototype, level)
        .mockImplementation((...args: unknown[]) => {
          logged.push(JSON.stringify(args));
        });
    }
  });

  beforeEach(() => {
    logged.length = 0;
    fake.functionOwnerBypassesRls = true;
  });

  afterEach(() => {
    const pending = fake.pendingFailures;
    fake.clearFailures();
    expect(pending).toBe(0);
  });

  afterAll(async () => {
    jest.restoreAllMocks();
    await app.close();
  });

  /** A member with a profile, a quit plan, two program snapshots and avatars. */
  const newMember = (avatars = 2): Member => {
    counter += 1;
    const member = {
      token: `${TOKEN_PREFIX}-${counter}`,
      id: randomUUID(),
      address: `198.51.100.${counter}`,
    };
    users.set(member.token, {
      sub: member.id,
      authTime: Math.floor(Date.now() / 1000),
    });
    fake.addUser(member.token, member.id);
    fake.addQuitPlan(member.id);
    fake.addProgramData(member.id, "steady");
    fake.addProgramData(member.id, "heartwise");
    for (let index = 0; index < avatars; index += 1) {
      fake.addAvatarObject(`${member.id}/avatar-${index}.webp`);
    }
    return member;
  };

  const requestsOf = (member: Member) =>
    fake.requests.filter((request) => request.token === member.token);

  const deleteAccount = async (member: Member) => {
    const before = fake.requests.length;
    const response = await app.inject({
      method: "DELETE",
      url: "/v1/account/data",
      remoteAddress: member.address,
      headers: { authorization: `Bearer ${member.token}` },
      payload: { confirmation: "DELETE" },
    });
    const sent = fake.requests.slice(before);
    // Every call below the API carries the member's own token.
    expect(sent.map((request) => request.token)).toEqual(
      sent.map(() => member.token),
    );
    expect(response.body).not.toContain(member.token);
    expect(response.body).not.toContain(member.id);
    expect(response.body).not.toMatch(/TH0\d\d|Synthetic storage failure/);
    return { response, sent: sent.map((request) => request.path) };
  };

  const rowsOf = (member: Member) => ({
    identity: fake.table("auth_users").filter((row) => row.id === member.id)
      .length,
    profiles: fake.table("profiles").filter((row) => row.id === member.id)
      .length,
    quitPlans: fake
      .table("quit_plans")
      .filter((row) => row.user_id === member.id).length,
    programData: fake
      .table("program_data")
      .filter((row) => row.user_id === member.id).length,
    avatars: fake
      .table("storage_objects")
      .filter((row) => String(row.name).startsWith(`${member.id}/`)).length,
  });
  const barrierSet = (member: Member) =>
    fake.table("profiles").find((row) => row.id === member.id)
      ?.account_deletion_started_at !== null;

  const BEGIN = "/rest/v1/rpc/begin_account_deletion";
  const DELETE_ACCOUNT = "/rest/v1/rpc/delete_my_account";
  const LIST = "/storage/v1/object/list-v2/avatars";
  const REMOVE = "/storage/v1/object/avatars";

  it("deletes data, avatars and identity with the member's token and returns the contract receipt", async () => {
    const member = newMember();
    const bystander = newMember(1);

    const { response, sent } = await deleteAccount(member);

    expect(response.statusCode).toBe(200);
    const receipt: unknown = response.json();
    expect(openApiErrors("AccountDeletionReceipt", receipt)).toEqual([]);
    expect(receipt).toMatchObject({
      deleted: { profiles: 1, quitPlans: 1, avatarObjects: 2, programData: 2 },
      authIdentityDeleted: true,
      authIdentityStatus: "deleted",
    });
    expect(sent).toEqual([BEGIN, LIST, REMOVE, DELETE_ACCOUNT]);
    expect(rowsOf(member)).toEqual({
      identity: 0,
      profiles: 0,
      quitPlans: 0,
      programData: 0,
      avatars: 0,
    });
    expect(rowsOf(bystander)).toEqual({
      identity: 1,
      profiles: 1,
      quitPlans: 1,
      programData: 2,
      avatars: 1,
    });
    expect(logged).toEqual([
      JSON.stringify([
        `account_deleted requestId=${(receipt as { requestId: string }).requestId} status=completed`,
      ]),
    ]);
  });

  it("calls no other deletion function and no Auth admin endpoint", async () => {
    const member = newMember(0);

    const { response } = await deleteAccount(member);

    expect(response.statusCode).toBe(200);
    const paths = requestsOf(member).map((request) => request.path);
    expect(paths.filter((path) => path.startsWith("/rest/v1/rpc/"))).toEqual([
      BEGIN,
      DELETE_ACCOUNT,
    ]);
    expect(paths.filter((path) => path.startsWith("/auth/"))).toEqual([]);
    expect(
      fake.requests.some((request) => request.path.includes("admin")),
    ).toBe(false);
  });

  it("answers a retry after a lost response with a zero-count receipt", async () => {
    const member = newMember();
    expect((await deleteAccount(member)).response.statusCode).toBe(200);

    const { response, sent } = await deleteAccount(member);

    expect(response.statusCode).toBe(200);
    const receipt: unknown = response.json();
    expect(openApiErrors("AccountDeletionReceipt", receipt)).toEqual([]);
    expect(receipt).toMatchObject({
      deleted: { profiles: 0, quitPlans: 0, avatarObjects: 0, programData: 0 },
      authIdentityDeleted: true,
    });
    expect(sent).toEqual([BEGIN, LIST, DELETE_ACCOUNT]);
  });

  it("maps TH017 from delete_my_account to 401 and deletes no data", async () => {
    const member = newMember();
    fake.setSignInAge(member.token, 601);

    const { response, sent } = await deleteAccount(member);

    expect(response.statusCode).toBe(401);
    expect(sent).toEqual([BEGIN, LIST, REMOVE, DELETE_ACCOUNT]);
    expect(rowsOf(member)).toEqual({
      identity: 1,
      profiles: 1,
      quitPlans: 1,
      programData: 2,
      avatars: 0,
    });
    expect(logged).toEqual([]);
  });

  it("maps TH017 from begin_account_deletion to 401 before touching storage", async () => {
    const member = newMember();
    fake.failNext(
      "POST",
      "rpc/begin_account_deletion",
      registryError("recent_authentication_required"),
    );

    const { response, sent } = await deleteAccount(member);

    expect(response.statusCode).toBe(401);
    expect(sent).toEqual([BEGIN]);
    expect(barrierSet(member)).toBe(false);
    expect(rowsOf(member).avatars).toBe(2);
  });

  it("maps TH016 to 502 and logs only the status and code", async () => {
    const member = newMember();
    // An avatar object appears after the cleanup, before the function runs.
    fake.interleave("POST", "rpc/delete_my_account", () =>
      fake.addAvatarObject(`${member.id}/late.webp`),
    );

    const { response, sent } = await deleteAccount(member);

    expect(response.statusCode).toBe(502);
    expect(sent).toEqual([BEGIN, LIST, REMOVE, DELETE_ACCOUNT]);
    expect(rowsOf(member)).toMatchObject({ identity: 1, profiles: 1 });
    const failures = logged.filter((line) =>
      line.includes("account_deletion_failed"),
    );
    expect(failures).toHaveLength(1);
    expect(failures[0]).toMatch(
      /^\["account_deletion_failed requestId=[0-9a-f-]{36} status=avatar_objects_remain code=TH016"\]$/,
    );
  });

  it("maps TH020 to 502 with only the code in the log", async () => {
    const member = newMember();
    fake.functionOwnerBypassesRls = false;

    const { response } = await deleteAccount(member);

    expect(response.statusCode).toBe(502);
    expect(rowsOf(member)).toMatchObject({ identity: 1, profiles: 1 });
    const failures = logged.filter((line) =>
      line.includes("account_deletion_failed"),
    );
    expect(failures).toHaveLength(1);
    expect(failures[0]).toMatch(
      /^\["account_deletion_failed requestId=[0-9a-f-]{36} status=account_delete_failed code=TH020"\]$/,
    );
    const joined = logged.join("\n");
    expect(joined).not.toContain("rls_bypass_required");
    expect(joined).not.toContain("row-level security");
    expect(joined).not.toContain(member.id);
  });

  it("fails with 502 and never calls delete_my_account when avatar cleanup fails", async () => {
    const member = newMember();
    fake.failNextStorage("remove");

    const { response, sent } = await deleteAccount(member);

    expect(response.statusCode).toBe(502);
    expect(sent).toEqual([BEGIN, LIST, REMOVE]);
    expect(barrierSet(member)).toBe(true);
    expect(rowsOf(member)).toMatchObject({ identity: 1, profiles: 1 });
    expect(
      logged.filter((line) => line.includes("account_deletion_failed")),
    ).toEqual([expect.stringMatching(/status=avatar_cleanup_failed"\]$/)]);
  });

  it("every registry code the deletion maps is in the registry under the same name", () => {
    const snakeCase = (name: string) =>
      name.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);
    for (const [name, code] of Object.entries(AccountDeletionErrorCode)) {
      expect(DATABASE_ERRORS.find((entry) => entry.code === code)?.hint).toBe(
        snakeCase(name),
      );
    }
  });
});

describe("startup without the Supabase service key", () => {
  const KEY_NAME = "SUPABASE_SERVICE_ROLE_KEY";

  it.each([
    ["a secret key", "sb_secret_synthetic-server-key"],
    ["an empty value", ""],
  ])("refuses to start while the variable holds %s", async (_, value) => {
    expect(process.env[KEY_NAME]).toBeUndefined();
    const env = { ...process.env, [KEY_NAME]: value };
    expect(() => buildFastifyAdapterOptions(env)).toThrow(KEY_NAME);

    process.env[KEY_NAME] = value;
    try {
      await expect(
        ConfigModule.forRoot({
          ignoreEnvFile: true,
          validationSchema: environmentSchema,
        }),
      ).rejects.toThrow(`"${KEY_NAME}" is not allowed`);
    } finally {
      delete process.env[KEY_NAME];
    }
  });

  it("starts without it", () => {
    expect(() => buildFastifyAdapterOptions(process.env)).not.toThrow();
  });
});

const profileFixture = () => ({
  id: "00000000-0000-0000-0000-000000000001",
  displayName: "Alex",
  locale: "en",
  timeZone: "UTC",
  onboardingCompleted: false,
  avatarPath: null,
  avatarUrl: null,
  avatarUrlExpiresAt: null,
  createdAt: "2026-09-11T00:00:00.000Z",
  updatedAt: "2026-09-11T00:00:00.000Z",
});

const quitPlanInput = () => ({
  dailyCigaretteUse: "tenOrFewer",
  smokingTriggers: ["stress", "afterMeals"],
  customSmokingTrigger: null,
  readinessPath: "prepare",
  quitPlanPath: "setQuitDate",
  quitDate: "2026-10-01",
  quitDayCheckIn: true,
  quitReasons: ["family", "breatheEasier"],
  customQuitReason: null,
  topQuitReason: "family",
  supportPeople: [
    {
      id: "test-friend",
      name: "Test Friend",
      relationship: "Friend",
      channel: "text",
      checkIn: "Check in the evening before my quit date",
      enabled: true,
    },
  ],
  preparationTasks: ["removeSupplies"],
  treatmentSupport: true,
  careTeamReminder: true,
});

const quitPlanFixture = () => ({
  userId: "00000000-0000-0000-0000-000000000001",
  ...quitPlanInput(),
  createdAt: "2026-09-15T00:00:00.000Z",
  updatedAt: "2026-09-15T00:00:00.000Z",
});
