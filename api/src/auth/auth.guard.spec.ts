import { ExecutionContext, UnauthorizedException } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { AuthGuard, AuthenticatedRequest } from "./auth.guard";
import { TokenVerifier } from "./token-verifier";

class TestController {}
const testHandler = () => undefined;

describe("AuthGuard", () => {
  it("attaches a verified caller without trusting a client user id", async () => {
    const verifier = {
      verify: jest
        .fn()
        .mockResolvedValue({ sub: "user-123", authTime: 1700000000 }),
    } as unknown as TokenVerifier;
    const request = {
      headers: { authorization: "Bearer signed-token" },
    } as AuthenticatedRequest;
    const context = {
      switchToHttp: () => ({ getRequest: () => request }),
      getHandler: () => testHandler,
      getClass: () => TestController,
    } as unknown as ExecutionContext;
    const guard = new AuthGuard(new Reflector(), verifier);
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.user).toEqual({
      id: "user-123",
      accessToken: "signed-token",
      authenticatedAt: 1700000000,
    });
  });

  it("rejects missing bearer tokens", async () => {
    const request = { headers: {} } as AuthenticatedRequest;
    const context = {
      switchToHttp: () => ({ getRequest: () => request }),
      getHandler: () => testHandler,
      getClass: () => TestController,
    } as unknown as ExecutionContext;
    const guard = new AuthGuard(new Reflector(), {} as TokenVerifier);
    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
