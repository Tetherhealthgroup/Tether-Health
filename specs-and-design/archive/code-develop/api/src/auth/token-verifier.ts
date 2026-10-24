import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createRemoteJWKSet, jwtVerify, type JWTPayload } from "jose";

function authenticationMethodTimestamp(entry: unknown): number | null {
  if (typeof entry !== "object" || entry === null) return null;
  const candidate = entry as Record<string, unknown>;
  if (
    typeof candidate.method !== "string" ||
    typeof candidate.timestamp !== "number" ||
    !Number.isFinite(candidate.timestamp)
  ) {
    return null;
  }
  return candidate.timestamp;
}

export function latestAuthenticationTime(payload: JWTPayload): number {
  const methods: unknown = payload.amr;
  if (!Array.isArray(methods))
    throw new Error("Missing authentication methods");
  const timestamps = methods
    .map(authenticationMethodTimestamp)
    .filter((timestamp): timestamp is number => timestamp !== null);
  if (timestamps.length === 0)
    throw new Error("Missing authentication method timestamps");
  return Math.max(...timestamps);
}

@Injectable()
export class TokenVerifier {
  private readonly issuer: string;
  private readonly audience: string;
  private readonly jwks: ReturnType<typeof createRemoteJWKSet>;

  constructor(config: ConfigService) {
    const baseUrl = config
      .getOrThrow<string>("SUPABASE_URL")
      .replace(/\/$/, "");
    this.issuer = `${baseUrl}/auth/v1`;
    this.audience = config.getOrThrow<string>("SUPABASE_JWT_AUDIENCE");
    this.jwks = createRemoteJWKSet(
      new URL(`${this.issuer}/.well-known/jwks.json`),
    );
  }

  async verify(token: string): Promise<{ sub: string; authTime: number }> {
    const result = await jwtVerify(token, this.jwks, {
      issuer: this.issuer,
      audience: this.audience,
    });
    if (typeof result.payload.sub !== "string")
      throw new Error("Missing subject");
    return {
      sub: result.payload.sub,
      authTime: latestAuthenticationTime(result.payload),
    };
  }
}
