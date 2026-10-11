import "./trust-proxy-env";
import {
  FastifyAdapter,
  NestFastifyApplication,
} from "@nestjs/platform-fastify";
import { Test } from "@nestjs/testing";
import { AppModule } from "../src/app.module";
import { configureApp } from "../src/configure-app";
import { fastifyTrustProxy } from "../src/config/environment";

const LIMIT = 10; // matches RATE_LIMIT_MAX in ./trust-proxy-env
const PROXY_ADDRESS = "10.0.0.1"; // socket peer: the single trusted proxy

async function createApp(hops: number): Promise<NestFastifyApplication> {
  const module = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();
  const app = module.createNestApplication<NestFastifyApplication>(
    new FastifyAdapter({ trustProxy: fastifyTrustProxy(hops) }),
  );
  await configureApp(app);
  await app.init();
  await app.getHttpAdapter().getInstance().ready();
  return app;
}

function hit(app: NestFastifyApplication, forwardedFor?: string) {
  return app.inject({
    method: "GET",
    url: "/health",
    remoteAddress: PROXY_ADDRESS,
    headers: forwardedFor ? { "x-forwarded-for": forwardedFor } : {},
  });
}

async function exhaust(
  app: NestFastifyApplication,
  forwardedFor: () => string,
): Promise<void> {
  for (let i = 0; i < LIMIT; i += 1) {
    expect((await hit(app, forwardedFor())).statusCode).toBe(200);
  }
}

describe("rate limiting behind one trusted proxy hop (e2e)", () => {
  let app: NestFastifyApplication;

  beforeEach(async () => {
    app = await createApp(1);
  });

  afterEach(async () => {
    await app.close();
  });

  it("gives clients with different X-Forwarded-For addresses separate buckets", async () => {
    await exhaust(app, () => "198.51.100.1");
    expect((await hit(app, "198.51.100.1")).statusCode).toBe(429);

    const other = await hit(app, "198.51.100.2");
    expect(other.statusCode).toBe(200);
  });

  it("cannot be bypassed by rotating the spoofed leftmost X-Forwarded-For entry", async () => {
    let n = 0;
    // The proxy appends the real client address; the attacker controls the left.
    await exhaust(app, () => `203.0.113.${(n += 1)}, 198.51.100.7`);

    const rotated = await hit(app, "203.0.113.200, 198.51.100.7");
    expect(rotated.statusCode).toBe(429);

    const otherClient = await hit(app, "203.0.113.200, 198.51.100.8");
    expect(otherClient.statusCode).toBe(200);
  });

  it("keeps the per-client bucket independent of a spoofed single-entry header from another real client", async () => {
    await exhaust(app, () => "198.51.100.1");
    // A different real client claiming nothing special still has its own bucket.
    expect((await hit(app, "198.51.100.3")).statusCode).toBe(200);
  });
});

describe("rate limiting without a trusted proxy (e2e)", () => {
  let app: NestFastifyApplication;

  beforeEach(async () => {
    app = await createApp(0);
  });

  afterEach(async () => {
    await app.close();
  });

  it("ignores X-Forwarded-For entirely and shares the socket-address bucket", async () => {
    let n = 0;
    await exhaust(app, () => `198.51.100.${(n += 1)}`);
    expect((await hit(app, "198.51.100.99")).statusCode).toBe(429);
  });
});
