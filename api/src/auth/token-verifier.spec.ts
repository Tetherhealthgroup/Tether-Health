import { latestAuthenticationTime } from "./token-verifier";

describe("latestAuthenticationTime", () => {
  it("uses the newest signed Supabase authentication-method timestamp", () => {
    expect(
      latestAuthenticationTime({
        amr: [
          { method: "password", timestamp: 1700000000 },
          { method: "totp", timestamp: 1700000300 },
        ],
      }),
    ).toBe(1700000300);
  });

  it("rejects untimestamped RFC authentication methods for recent-auth checks", () => {
    expect(() => latestAuthenticationTime({ amr: ["password"] })).toThrow(
      "Missing authentication method timestamps",
    );
  });

  it("rejects tokens without authentication methods", () => {
    expect(() => latestAuthenticationTime({})).toThrow(
      "Missing authentication methods",
    );
  });
});
