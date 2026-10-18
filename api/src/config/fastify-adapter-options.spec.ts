import Fastify from "fastify";
import { buildFastifyAdapterOptions } from "./fastify-adapter-options";

const baseEnv = {
  NODE_ENV: "production",
  SUPABASE_URL: "https://project.supabase.co",
  SUPABASE_ANON_KEY: "publishable-placeholder-key",
  SUPABASE_SERVICE_ROLE_KEY: "sb_secret_synthetic-server-key",
};

type TrustProxy = ReturnType<typeof buildFastifyAdapterOptions>["trustProxy"];

async function requestSeenBy(
  trustProxy: TrustProxy,
  headers: Record<string, string>,
  remoteAddress = "10.0.0.1",
): Promise<{ ip: string; host: string; protocol: string }> {
  const app = Fastify({ trustProxy });
  app.get("/ip", (request) => ({
    ip: request.ip,
    host: request.host,
    protocol: request.protocol,
  }));
  const response = await app.inject({
    method: "GET",
    url: "/ip",
    remoteAddress,
    headers,
  });
  await app.close();
  return response.json<{ ip: string; host: string; protocol: string }>();
}

async function clientIp(
  trustProxy: TrustProxy,
  forwardedFor: string,
  remoteAddress = "10.0.0.1",
): Promise<string> {
  return (
    await requestSeenBy(
      trustProxy,
      { "x-forwarded-for": forwardedFor },
      remoteAddress,
    )
  ).ip;
}

const proxyEnv = (hops: number, cidrs = "10.0.0.0/24") => ({
  ...baseEnv,
  TRUST_PROXY: String(hops),
  TRUST_PROXY_CIDRS: cidrs,
});

describe("buildFastifyAdapterOptions", () => {
  it("defaults to trusting no proxy, even in production", () => {
    const options = buildFastifyAdapterOptions(baseEnv);
    expect(options.trustProxy).toBe(false);
    expect(options.bodyLimit).toBe(65536);
  });

  it("with the default, X-Forwarded-For does not change request.ip", async () => {
    const { trustProxy } = buildFastifyAdapterOptions(baseEnv);
    expect(await clientIp(trustProxy, "203.0.113.9")).toBe("10.0.0.1");
    expect(await clientIp(trustProxy, "203.0.113.9, 198.51.100.7")).toBe(
      "10.0.0.1",
    );
  });

  it("treats TRUST_PROXY=0 and false as no trust", () => {
    expect(
      buildFastifyAdapterOptions({ ...baseEnv, TRUST_PROXY: "0" }),
    ).toEqual({ bodyLimit: 65536, trustProxy: false });
    expect(
      buildFastifyAdapterOptions({ ...baseEnv, TRUST_PROXY: "false" })
        .trustProxy,
    ).toBe(false);
  });

  it.each([1, 2, 10])("trusts exactly %i hop(s) for TRUST_PROXY=%i", (n) => {
    const { trustProxy } = buildFastifyAdapterOptions(proxyEnv(n));
    expect(trustProxy).toBeInstanceOf(Function);
    if (typeof trustProxy === "function") {
      expect(trustProxy("10.0.0.1", n - 1)).toBe(true);
      expect(trustProxy("10.0.0.1", n)).toBe(false);
      expect(trustProxy("198.51.100.7", n - 1)).toBe(false);
    }
  });

  it("with one hop, request.ip is the entry an allowlisted proxy appended", async () => {
    const { trustProxy } = buildFastifyAdapterOptions(proxyEnv(1));
    expect(await clientIp(trustProxy, "203.0.113.9, 198.51.100.7")).toBe(
      "198.51.100.7",
    );
  });

  it("matches an allowlisted proxy that connects as an IPv4-mapped IPv6 address", async () => {
    const { trustProxy } = buildFastifyAdapterOptions(proxyEnv(1));
    expect(await clientIp(trustProxy, "198.51.100.7", "::ffff:10.0.0.1")).toBe(
      "198.51.100.7",
    );
  });

  it("ignores X-Forwarded-For from a socket peer outside the allowlist", async () => {
    const { trustProxy } = buildFastifyAdapterOptions(proxyEnv(1));
    expect(await clientIp(trustProxy, "198.51.100.7", "203.0.113.50")).toBe(
      "203.0.113.50",
    );
    expect(await clientIp(trustProxy, "198.51.100.7", "2001:db8::50")).toBe(
      "2001:db8::50",
    );
  });

  it("ignores X-Forwarded-Host and X-Forwarded-Proto from a peer outside the allowlist", async () => {
    const { trustProxy } = buildFastifyAdapterOptions(proxyEnv(1));
    const headers = {
      host: "api.example.test",
      "x-forwarded-host": "spoofed.example.test",
      "x-forwarded-proto": "https",
    };
    expect(
      await requestSeenBy(trustProxy, headers, "203.0.113.50"),
    ).toMatchObject({ host: "api.example.test", protocol: "http" });
    expect(await requestSeenBy(trustProxy, headers)).toMatchObject({
      host: "spoofed.example.test",
      protocol: "https",
    });
  });

  it("with two hops, trusts the inner hop only if it is also allowlisted", async () => {
    const { trustProxy } = buildFastifyAdapterOptions(proxyEnv(2));
    // 10.0.0.2 is an allowlisted inner proxy: the client is the entry it added.
    expect(
      await clientIp(trustProxy, "203.0.113.9, 198.51.100.7, 10.0.0.2"),
    ).toBe("198.51.100.7");
    // 198.51.100.8 is not a proxy: the stop is there, the spoof is ignored.
    expect(await clientIp(trustProxy, "203.0.113.9, 198.51.100.8")).toBe(
      "198.51.100.8",
    );
  });

  it("fails closed when TRUST_PROXY is above 0 without TRUST_PROXY_CIDRS", () => {
    expect(() =>
      buildFastifyAdapterOptions({ ...baseEnv, TRUST_PROXY: "1" }),
    ).toThrow(/TRUST_PROXY_CIDRS/);
    expect(() => buildFastifyAdapterOptions(proxyEnv(1, ""))).toThrow(
      /TRUST_PROXY_CIDRS/,
    );
  });

  it("does not echo an invalid TRUST_PROXY_CIDRS value in the startup error", () => {
    const canary = "synthetic-canary-4f1c";
    let message = "";
    try {
      buildFastifyAdapterOptions(proxyEnv(1, canary));
    } catch (error) {
      message = (error as Error).message;
    }
    expect(message).toContain("TRUST_PROXY_CIDRS");
    expect(message).not.toContain(canary);
  });

  it("honours REQUEST_BODY_LIMIT_BYTES", () => {
    expect(
      buildFastifyAdapterOptions({
        ...baseEnv,
        REQUEST_BODY_LIMIT_BYTES: "2048",
      }).bodyLimit,
    ).toBe(2048);
  });

  it.each(["true", "-1", "1.5", "11", "abc", ""])(
    "throws on invalid TRUST_PROXY %p",
    (raw) => {
      expect(() =>
        buildFastifyAdapterOptions({
          ...baseEnv,
          TRUST_PROXY: raw,
          TRUST_PROXY_CIDRS: "10.0.0.0/24",
        }),
      ).toThrow(/"TRUST_PROXY"/);
    },
  );

  it("throws when the rest of the environment is invalid", () => {
    expect(() =>
      buildFastifyAdapterOptions({ ...baseEnv, SUPABASE_URL: undefined }),
    ).toThrow(/SUPABASE_URL/);
  });
});
