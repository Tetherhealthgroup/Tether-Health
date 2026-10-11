import Fastify from "fastify";
import { buildFastifyAdapterOptions } from "./fastify-adapter-options";

const baseEnv = {
  NODE_ENV: "production",
  SUPABASE_URL: "https://project.supabase.co",
  SUPABASE_ANON_KEY: "publishable-placeholder-key",
  SUPABASE_SERVICE_ROLE_KEY: "sb_secret_synthetic-server-key",
};

async function clientIp(
  trustProxy: ReturnType<typeof buildFastifyAdapterOptions>["trustProxy"],
  forwardedFor: string,
): Promise<string> {
  const app = Fastify({ trustProxy });
  app.get("/ip", (request) => ({ ip: request.ip }));
  const response = await app.inject({
    method: "GET",
    url: "/ip",
    remoteAddress: "10.0.0.1",
    headers: { "x-forwarded-for": forwardedFor },
  });
  await app.close();
  return response.json<{ ip: string }>().ip;
}

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
    const { trustProxy } = buildFastifyAdapterOptions({
      ...baseEnv,
      TRUST_PROXY: String(n),
    });
    expect(trustProxy).toBeInstanceOf(Function);
    if (typeof trustProxy === "function") {
      expect(trustProxy("10.0.0.1", n - 1)).toBe(true);
      expect(trustProxy("198.51.100.7", n)).toBe(false);
    }
  });

  it("with one hop, request.ip is the entry the proxy appended", async () => {
    const { trustProxy } = buildFastifyAdapterOptions({
      ...baseEnv,
      TRUST_PROXY: "1",
    });
    expect(await clientIp(trustProxy, "203.0.113.9, 198.51.100.7")).toBe(
      "198.51.100.7",
    );
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
        buildFastifyAdapterOptions({ ...baseEnv, TRUST_PROXY: raw }),
      ).toThrow(/TRUST_PROXY/);
    },
  );

  it("throws when the rest of the environment is invalid", () => {
    expect(() =>
      buildFastifyAdapterOptions({ ...baseEnv, SUPABASE_URL: undefined }),
    ).toThrow(/SUPABASE_URL/);
  });
});
