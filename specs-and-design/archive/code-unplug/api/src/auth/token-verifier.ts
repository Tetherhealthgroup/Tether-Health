import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createRemoteJWKSet, jwtVerify } from "jose";

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

  async verify(token: string): Promise<{ sub: string }> {
    const result = await jwtVerify(token, this.jwks, {
      issuer: this.issuer,
      audience: this.audience,
    });
    if (typeof result.payload.sub !== "string")
      throw new Error("Missing subject");
    return { sub: result.payload.sub };
  }
}
