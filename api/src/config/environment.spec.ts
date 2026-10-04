import { environmentSchema } from "./environment";

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
});
