import { environmentSchema, fastifyTrustProxy } from "./environment";

const validEnvironment = {
  NODE_ENV: "production",
  SUPABASE_URL: "https://project.supabase.co",
  SUPABASE_ANON_KEY: "publishable-placeholder-key",
  SUPABASE_SERVICE_ROLE_KEY: "sb_secret_synthetic-server-key",
};

describe("environmentSchema", () => {
  it("requires a server-only credential for privileged Auth deletion", () => {
    const { error } = environmentSchema.validate({
      ...validEnvironment,
      SUPABASE_SERVICE_ROLE_KEY: undefined,
    });

    expect(error?.message).toContain("SUPABASE_SERVICE_ROLE_KEY");
  });

  it("rejects a publishable key in the privileged credential slot", () => {
    const { error } = environmentSchema.validate({
      ...validEnvironment,
      SUPABASE_SERVICE_ROLE_KEY: "sb_publishable_not-a-server-secret",
    });

    expect(error?.message).toContain("SUPABASE_SERVICE_ROLE_KEY");
  });

  it("rejects an arbitrary value in the privileged credential slot", () => {
    const { error } = environmentSchema.validate({
      ...validEnvironment,
      SUPABASE_SERVICE_ROLE_KEY: "arbitrary-long-value-that-is-not-privileged",
    });

    expect(error?.message).toContain("SUPABASE_SERVICE_ROLE_KEY");
  });

  it("accepts separately scoped caller and server credentials", () => {
    const { error } = environmentSchema.validate(validEnvironment);

    expect(error).toBeUndefined();
  });

  it("accepts a legacy JWT only when its payload has the service_role", () => {
    const { error } = environmentSchema.validate({
      ...validEnvironment,
      SUPABASE_SERVICE_ROLE_KEY:
        "eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.synthetic-signature",
    });

    expect(error).toBeUndefined();
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
    const PROXY_CIDRS = "10.0.0.0/8";
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
        fastifyTrustProxy(0, [{ family: "ipv4", address: "10.0.0.1" }]),
      ).toBe(false);
    });

    it("maps hop counts to a trust function limited to the allowlist", () => {
      const trustOne = fastifyTrustProxy(1, [
        { family: "ipv4", address: "10.0.0.0", prefix: 8 },
      ]);
      expect(trustOne).toBeInstanceOf(Function);
      if (typeof trustOne === "function") {
        expect(trustOne("10.0.0.1", 0)).toBe(true);
        expect(trustOne("10.0.0.2", 1)).toBe(false);
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
        TRUST_PROXY_CIDRS: "10.0.0.0/8, 192.0.2.1,2001:db8::/32 ,::1",
      });
      expect(error).toBeUndefined();
      expect(value.TRUST_PROXY_CIDRS).toEqual([
        { family: "ipv4", address: "10.0.0.0", prefix: 8 },
        { family: "ipv4", address: "192.0.2.1" },
        { family: "ipv6", address: "2001:db8::", prefix: 32 },
        { family: "ipv6", address: "::1" },
      ]);
    });

    it.each([
      "10.0.0.0/0",
      "::/0",
      "10.0.0.0/33",
      "2001:db8::/129",
      "10.0.0.0/08",
      "10.0.0.0/",
      "10.0.0.0/8/8",
      "010.0.0.1",
      "10.0.0",
      "fe80::1%eth0",
      "[::1]",
      "localhost",
      "10.0.0.1,",
      "10.0.0.1,,10.0.0.2",
      "10.0.0.1;10.0.0.2",
    ])("rejects invalid entry %p", (cidrs) => {
      const { error } = validate({
        TRUST_PROXY: "1",
        TRUST_PROXY_CIDRS: cidrs,
      });
      expect(error?.message).toContain("TRUST_PROXY_CIDRS");
    });

    it("validates the syntax even when TRUST_PROXY is 0", () => {
      const { error } = validate({ TRUST_PROXY_CIDRS: "not-an-address" });
      expect(error?.message).toContain("TRUST_PROXY_CIDRS");
    });

    it("does not echo the rejected value in the error", () => {
      const canary = "synthetic-canary-4f1c";
      const { error } = validate({
        TRUST_PROXY: "1",
        TRUST_PROXY_CIDRS: `10.0.0.1,${canary}`,
      });
      expect(error?.message).toContain("TRUST_PROXY_CIDRS");
      expect(error?.message).not.toContain(canary);
      expect(error?.message).not.toContain("10.0.0.1");
    });
  });
});
