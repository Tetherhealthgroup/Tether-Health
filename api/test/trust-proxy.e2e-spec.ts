import "./trust-proxy-env";
import {
  FastifyAdapter,
  NestFastifyApplication,
} from "@nestjs/platform-fastify";
import { Test } from "@nestjs/testing";
import { AppModule } from "../src/app.module";
import { configureApp } from "../src/configure-app";
import { buildFastifyAdapterOptions } from "../src/config/fastify-adapter-options";

const LIMIT = 10; // matches RATE_LIMIT_MAX in ./trust-proxy-env
const PROXY_ADDRESS = "10.0.0.1"; // socket peer: the single trusted proxy
const PROXY_CIDRS = "10.0.0.0/24"; // allowlist containing PROXY_ADDRESS
const DIRECT_ADDRESS = "203.0.113.50"; // socket peer outside the allowlist

// Uses the same builder as main.ts, so the e2e wiring cannot drift from it.
async function createApp(
  hops?: number,
  cidrs?: string,
): Promise<NestFastifyApplication> {
  const env = { ...process.env };
  delete env.TRUST_PROXY;
  delete env.TRUST_PROXY_CIDRS;
  if (hops !== undefined) env.TRUST_PROXY = String(hops);
  if (cidrs !== undefined) env.TRUST_PROXY_CIDRS = cidrs;
  const module = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();
  const app = module.createNestApplication<NestFastifyApplication>(
    new FastifyAdapter(buildFastifyAdapterOptions(env)),
  );
  await configureApp(app);
  await app.init();
  await app.getHttpAdapter().getInstance().ready();
  return app;
}

function hit(
  app: NestFastifyApplication,
  forwardedFor?: string,
  remoteAddress = PROXY_ADDRESS,
) {
  return app.inject({
    method: "GET",
    url: "/health",
    remoteAddress,
    headers: forwardedFor ? { "x-forwarded-for": forwardedFor } : {},
  });
}

async function exhaust(
  app: NestFastifyApplication,
  forwardedFor: () => string,
  remoteAddress = PROXY_ADDRESS,
): Promise<void> {
  for (let i = 0; i < LIMIT; i += 1) {
    expect((await hit(app, forwardedFor(), remoteAddress)).statusCode).toBe(
      200,
    );
  }
}

describe("rate limiting behind one trusted proxy hop (e2e)", () => {
  let app: NestFastifyApplication;

  beforeEach(async () => {
    app = await createApp(1, PROXY_CIDRS);
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

describe("rate limiting for a socket peer outside the proxy allowlist (e2e)", () => {
  let app: NestFastifyApplication;

  beforeEach(async () => {
    app = await createApp(1, PROXY_CIDRS);
  });

  afterEach(async () => {
    await app.close();
  });

  it("keys a direct peer on its socket IP, whatever X-Forwarded-For it sends", async () => {
    let n = 0;
    await exhaust(app, () => `198.51.100.${(n += 1)}`, DIRECT_ADDRESS);
    expect((await hit(app, "198.51.100.99", DIRECT_ADDRESS)).statusCode).toBe(
      429,
    );
    expect((await hit(app, undefined, DIRECT_ADDRESS)).statusCode).toBe(429);
  });

  it("cannot exhaust another client's bucket by forging its address", async () => {
    await exhaust(app, () => "198.51.100.1", DIRECT_ADDRESS);
    expect((await hit(app, "198.51.100.1", DIRECT_ADDRESS)).statusCode).toBe(
      429,
    );
    // The real client, arriving through the allowlisted proxy, is unaffected.
    expect((await hit(app, "198.51.100.1")).statusCode).toBe(200);
  });
});

describe("startup with a trusted proxy hop but no allowlist (e2e)", () => {
  it.each([undefined, ""])(
    "fails closed when TRUST_PROXY_CIDRS is %p",
    async (cidrs) => {
      await expect(createApp(1, cidrs)).rejects.toThrow(/TRUST_PROXY_CIDRS/);
    },
  );
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

describe("rate limiting with the default TRUST_PROXY (e2e)", () => {
  let app: NestFastifyApplication;

  beforeEach(async () => {
    app = await createApp();
  });

  afterEach(async () => {
    await app.close();
  });

  it("does not let X-Forwarded-For change the rate-limit key", async () => {
    let n = 0;
    await exhaust(app, () => `198.51.100.${(n += 1)}`);
    expect((await hit(app, "198.51.100.99")).statusCode).toBe(429);
    expect((await hit(app, "203.0.113.5, 198.51.100.200")).statusCode).toBe(
      429,
    );
  });
});
