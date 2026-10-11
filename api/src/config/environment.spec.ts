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
    const hops = (overrides: Record<string, unknown>) => {
      const result = environmentSchema.validate({
        ...validEnvironment,
        ...overrides,
      }) as { error?: Error; value: { TRUST_PROXY: number } };
      expect(result.error).toBeUndefined();
      return result.value.TRUST_PROXY;
    };

    it("defaults to exactly one trusted hop in production", () => {
      expect(hops({})).toBe(1);
    });

    it.each(["development", "test"])("defaults to no proxy in %s", (env) => {
      expect(hops({ NODE_ENV: env })).toBe(0);
    });

    it("defaults to no proxy when NODE_ENV is unset", () => {
      expect(hops({ NODE_ENV: undefined })).toBe(0);
    });

    it.each([
      ["false", 0],
      ["0", 0],
      ["1", 1],
      ["2", 2],
      ["10", 10],
    ])("accepts explicit %s as %i hops, overriding the default", (raw, n) => {
      expect(hops({ TRUST_PROXY: raw })).toBe(n);
      expect(hops({ NODE_ENV: "test", TRUST_PROXY: raw })).toBe(n);
    });

    it.each(["true", "True", "-1", "1.5", "01", "11", "abc", "", " 1", "1e0"])(
      "rejects invalid value %p",
      (raw) => {
        const { error } = environmentSchema.validate({
          ...validEnvironment,
          TRUST_PROXY: raw,
        });
        expect(error?.message).toContain("TRUST_PROXY");
      },
    );

    it("maps hop counts to the Fastify trustProxy option", () => {
      expect(fastifyTrustProxy(0)).toBe(false);
      const trustOne = fastifyTrustProxy(1);
      expect(trustOne).toBeInstanceOf(Function);
      if (typeof trustOne === "function") {
        expect(trustOne("10.0.0.1", 0)).toBe(true);
        expect(trustOne("198.51.100.7", 1)).toBe(false);
      }
    });
  });
});
