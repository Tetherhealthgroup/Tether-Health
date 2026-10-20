import { environmentSchema, fastifyTrustProxy } from "./environment";

const validEnvironment = {
  NODE_ENV: "production",
  SUPABASE_URL: "https://project.supabase.co",
  SUPABASE_ANON_KEY: "publishable-placeholder-key",
};

describe("environmentSchema", () => {
  it("accepts the caller-scoped configuration without a server key", () => {
    const { error } = environmentSchema.validate(validEnvironment);

    expect(error).toBeUndefined();
  });

  it.each([
    ["a secret key", "sb_secret_synthetic-server-key"],
    [
      "a legacy service-role JWT",
      "eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.synthetic-signature",
    ],
    ["a publishable key", "sb_publishable_not-a-server-secret"],
    ["an arbitrary value", "arbitrary-long-value"],
    ["an empty value", ""],
  ])("refuses to start while the server key variable holds %s", (_, value) => {
    const { error } = environmentSchema.validate({
      ...validEnvironment,
      SUPABASE_SERVICE_ROLE_KEY: value,
    });

    expect(error?.message).toContain('"SUPABASE_SERVICE_ROLE_KEY"');
    expect(error?.message).toContain("is not allowed");
    if (value !== "") expect(error?.message).not.toContain(value);
  });

  it("refuses the server key variable the way startup validates the environment", () => {
    // ConfigModule validates process.env with unknown keys allowed and every
    // error reported; buildFastifyAdapterOptions does the same.
    const { error } = environmentSchema.validate(
      { ...validEnvironment, SUPABASE_SERVICE_ROLE_KEY: "" },
      { allowUnknown: true, abortEarly: false },
    );

    expect(error?.message).toContain('"SUPABASE_SERVICE_ROLE_KEY"');
  });

  describe("RECENT_AUTH_MAX_AGE_SECONDS", () => {
    const maxAge = (value?: unknown) =>
      environmentSchema.validate({
        ...validEnvironment,
        ...(value === undefined ? {} : { RECENT_AUTH_MAX_AGE_SECONDS: value }),
      }) as { error?: Error; value: { RECENT_AUTH_MAX_AGE_SECONDS: number } };

    it("defaults to 600 seconds", () => {
      const { error, value } = maxAge();
      expect(error).toBeUndefined();
      expect(value.RECENT_AUTH_MAX_AGE_SECONDS).toBe(600);
    });

    it.each([60, "600", 600])("accepts %p", (raw) => {
      expect(maxAge(raw).error).toBeUndefined();
    });

    it.each([601, "601", 3600, 59])("refuses %p", (raw) => {
      expect(maxAge(raw).error?.message).toContain(
        '"RECENT_AUTH_MAX_AGE_SECONDS"',
      );
    });
  });

  it("rejects a legacy service-role JWT in the anonymous credential slot", () => {
    const { error } = environmentSchema.validate({
      ...validEnvironment,
      SUPABASE_ANON_KEY:
        "eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.synthetic-signature",
    });

    expect(error?.message).toContain("SUPABASE_ANON_KEY");
  });

  it("accepts a legacy anonymous-role JWT in the anonymous credential slot", () => {
    const { error } = environmentSchema.validate({
      ...validEnvironment,
      SUPABASE_ANON_KEY:
        "eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiJ9.synthetic-signature",
    });

    expect(error).toBeUndefined();
  });

  describe("TRUST_PROXY", () => {
    const PROXY_CIDRS = "192.0.2.0/24";
    const hops = (overrides: Record<string, unknown>) => {
      const result = environmentSchema.validate({
        ...validEnvironment,
        ...overrides,
      }) as { error?: Error; value: { TRUST_PROXY: number } };
      expect(result.error).toBeUndefined();
      return result.value.TRUST_PROXY;
    };

    it.each(["production", "development", "test", undefined])(
      "defaults to trusting no proxy hops when NODE_ENV is %s",
      (env) => {
        expect(hops({ NODE_ENV: env })).toBe(0);
      },
    );

    it.each([
      ["false", 0],
      ["0", 0],
      ["1", 1],
      ["2", 2],
      ["10", 10],
    ])("accepts explicit %s as %i hops, overriding the default", (raw, n) => {
      const overrides = { TRUST_PROXY: raw, TRUST_PROXY_CIDRS: PROXY_CIDRS };
      expect(hops(overrides)).toBe(n);
      expect(hops({ ...overrides, NODE_ENV: "test" })).toBe(n);
      expect(hops({ ...overrides, NODE_ENV: "production" })).toBe(n);
    });

    it.each(["true", "True", "-1", "1.5", "01", "11", "abc", "", " 1", "1e0"])(
      "rejects invalid value %p",
      (raw) => {
        const { error } = environmentSchema.validate({
          ...validEnvironment,
          TRUST_PROXY: raw,
          TRUST_PROXY_CIDRS: PROXY_CIDRS,
        });
        expect(error?.message).toContain('"TRUST_PROXY"');
      },
    );

    it("maps zero hops to no trust and ignores every forwarded address", () => {
      expect(fastifyTrustProxy(0)).toBe(false);
      expect(
        fastifyTrustProxy(0, [{ family: "ipv4", address: "192.0.2.1" }]),
      ).toBe(false);
    });

    it("maps hop counts to a trust function limited to the allowlist", () => {
      const trustOne = fastifyTrustProxy(1, [
        { family: "ipv4", address: "192.0.2.0", prefix: 24 },
      ]);
      expect(trustOne).toBeInstanceOf(Function);
      if (typeof trustOne === "function") {
        expect(trustOne("192.0.2.1", 0)).toBe(true);
        expect(trustOne("192.0.2.2", 1)).toBe(false);
        expect(trustOne("198.51.100.7", 0)).toBe(false);
        expect(trustOne("198.51.100.7", 1)).toBe(false);
      }
    });
  });

  describe("TRUST_PROXY_CIDRS", () => {
    const validate = (overrides: Record<string, unknown>) =>
      environmentSchema.validate({ ...validEnvironment, ...overrides }) as {
        error?: Error;
        value: { TRUST_PROXY_CIDRS: unknown };
      };

    it.each([undefined, "0", "false"])(
      "is optional and defaults to an empty list when TRUST_PROXY is %p",
      (trustProxy) => {
        const { error, value } = validate({ TRUST_PROXY: trustProxy });
        expect(error).toBeUndefined();
        expect(value.TRUST_PROXY_CIDRS).toEqual([]);
        expect(
          validate({ TRUST_PROXY: trustProxy, TRUST_PROXY_CIDRS: "" }).error,
        ).toBeUndefined();
      },
    );

    it.each([undefined, "", "  "])(
      "is required when TRUST_PROXY is above 0 (value %p)",
      (cidrs) => {
        const { error } = validate({
          TRUST_PROXY: "1",
          TRUST_PROXY_CIDRS: cidrs,
        });
        expect(error?.message).toContain("TRUST_PROXY_CIDRS");
      },
    );

    it("parses addresses and CIDR ranges of both families", () => {
      const { error, value } = validate({
        TRUST_PROXY: "2",
        TRUST_PROXY_CIDRS: "192.0.2.0/24, 198.51.100.1,2001:db8::/32 ,::1",
      });
      expect(error).toBeUndefined();
      expect(value.TRUST_PROXY_CIDRS).toEqual([
        { family: "ipv4", address: "192.0.2.0", prefix: 24 },
        { family: "ipv4", address: "198.51.100.1" },
        { family: "ipv6", address: "2001:db8::", prefix: 32 },
        { family: "ipv6", address: "::1" },
      ]);
    });

    it.each([
      "192.0.2.0/0",
      "::/0",
      "192.0.2.0/33",
      "2001:db8::/129",
      "192.0.2.0/024",
      "192.0.2.0/",
      "192.0.2.0/24/24",
      "0192.0.2.1",
      "192.0.2",
      "fe80::1%eth0",
      "[::1]",
      "localhost",
      "192.0.2.1,",
      "192.0.2.1,,192.0.2.2",
      "192.0.2.1;192.0.2.2",
    ])("rejects invalid entry %p", (cidrs) => {
      const { error } = validate({
        TRUST_PROXY: "1",
        TRUST_PROXY_CIDRS: cidrs,
      });
      expect(error?.message).toContain("TRUST_PROXY_CIDRS");
    });

    it.each([
      // Broader than the minimum prefix (/8 for IPv4, /32 for IPv6).
      "0.0.0.0/1",
      "128.0.0.0/1",
      "10.0.0.0/7",
      "2001:db8::/31",
      // IPv6 ranges that BlockList would match against IPv4 peers.
      "::/1",
      "::/32",
      "::/80",
      "::ffff:0:0/96",
      "::ffff:0:0/104",
      "::ffff:192.0.2.1",
      "::ffff:c000:200/120",
      // Host bits are masked: these are ::/32 and ::/80.
      "0:0:1::/32",
      "::ffff:0:0/80",
      "::/96",
    ])("rejects over-broad or IPv4-mapped range %p", (cidrs) => {
      const { error } = validate({
        TRUST_PROXY: "1",
        TRUST_PROXY_CIDRS: cidrs,
      });
      expect(error?.message).toContain("TRUST_PROXY_CIDRS");
      expect(error?.message).not.toContain(cidrs);
    });

    it("rejects a list that only covers everything when combined", () => {
      const { error } = validate({
        TRUST_PROXY: "1",
        TRUST_PROXY_CIDRS: "0.0.0.0/1, 128.0.0.0/1",
      });
      expect(error?.message).toContain("TRUST_PROXY_CIDRS");
    });

    it.each([
      "192.0.2.0/24",
      "198.51.100.0/24, 203.0.113.0/24",
      "10.0.0.0/8",
      "2001:db8::/32",
      "2001:db8::/48",
      "2001:db8::1",
      "::1",
      "64:ff9b::/96",
    ])("accepts the narrow range %p", (cidrs) => {
      expect(
        validate({ TRUST_PROXY: "1", TRUST_PROXY_CIDRS: cidrs }).error,
      ).toBeUndefined();
    });

    it("validates the syntax even when TRUST_PROXY is 0", () => {
      const { error } = validate({ TRUST_PROXY_CIDRS: "not-an-address" });
      expect(error?.message).toContain("TRUST_PROXY_CIDRS");
    });

    it("does not echo the rejected value in the error", () => {
      const canary = "synthetic-canary-4f1c";
      const { error } = validate({
        TRUST_PROXY: "1",
        TRUST_PROXY_CIDRS: `192.0.2.1,${canary}`,
      });
      expect(error?.message).toContain("TRUST_PROXY_CIDRS");
      expect(error?.message).not.toContain(canary);
      expect(error?.message).not.toContain("192.0.2.1");
    });
  });
});
