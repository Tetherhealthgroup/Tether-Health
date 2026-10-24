import { ValidationPipe } from "@nestjs/common";
import {
  FastifyAdapter,
  NestFastifyApplication,
} from "@nestjs/platform-fastify";
import { Test } from "@nestjs/testing";
import { AppModule } from "../src/app.module";
import { TokenVerifier } from "../src/auth/token-verifier";
import { ProfileService } from "../src/profile/profile.service";

describe("API (e2e)", () => {
  let app: NestFastifyApplication;

  beforeAll(async () => {
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(TokenVerifier)
      .useValue({
        verify: () =>
          Promise.resolve({ sub: "00000000-0000-0000-0000-000000000001" }),
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
      .compile();
    app = module.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }),
    );
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
  });

  it.each([
    ["GET", "/v1/profile", undefined],
    ["PATCH", "/v1/profile", { locale: "en" }],
  ])("%s %s requires a token", async (method, url, payload) => {
    const response = await app.inject({
      method: method as "GET" | "PATCH",
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
});

const profileFixture = () => ({
  id: "00000000-0000-0000-0000-000000000001",
  displayName: "Alex",
  locale: "en",
  timeZone: "UTC",
  onboardingCompleted: false,
  avatarPath: null,
  createdAt: "2026-09-11T00:00:00.000Z",
  updatedAt: "2026-09-11T00:00:00.000Z",
});
