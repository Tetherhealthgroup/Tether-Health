import type { ConfigService } from "@nestjs/config";
import { IS_PUBLIC_KEY } from "../common/public.decorator";
import { environmentSchema } from "../config/environment";
import { AppConfigController } from "./app-config.controller";

const base = {
  NODE_ENV: "production",
  SUPABASE_URL: "https://project.supabase.co",
  SUPABASE_ANON_KEY: "publishable-placeholder-key",
};

describe("minimum app versions", () => {
  it("default to 0.0.0 on both platforms", () => {
    const { error, value } = environmentSchema.validate(base) as {
      error?: Error;
      value: Record<string, unknown>;
    };
    expect(error).toBeUndefined();
    expect(value.MINIMUM_APP_VERSION_IOS).toBe("0.0.0");
    expect(value.MINIMUM_APP_VERSION_ANDROID).toBe("0.0.0");
  });

  it.each(["1.4.0", "10.0.12", "0.0.1"])("accept %s", (version) => {
    const { error } = environmentSchema.validate({
      ...base,
      MINIMUM_APP_VERSION_IOS: version,
      MINIMUM_APP_VERSION_ANDROID: version,
    });
    expect(error).toBeUndefined();
  });

  it.each(["1.4", "v1.4.0", "1.04.0", "1.4.0-beta", "", "1.4.0 "])(
    "refuse %p at start-up without echoing it",
    (version) => {
      for (const name of [
        "MINIMUM_APP_VERSION_IOS",
        "MINIMUM_APP_VERSION_ANDROID",
      ]) {
        const { error } = environmentSchema.validate({
          ...base,
          [name]: version,
        });
        expect(error?.message).toContain(`"${name}"`);
        if (version.trim() !== "") {
          expect(error?.message).not.toContain(version);
        }
      }
    },
  );
});

describe("AppConfigController", () => {
  it("returns only the two minimum versions", () => {
    const values: Record<string, string> = {
      MINIMUM_APP_VERSION_IOS: "2.1.0",
      MINIMUM_APP_VERSION_ANDROID: "2.0.3",
    };
    const controller = new AppConfigController({
      getOrThrow: (key: string) => values[key],
    } as unknown as ConfigService);
    expect(controller.get()).toEqual({
      minimumVersion: { ios: "2.1.0", android: "2.0.3" },
    });
  });

  it("is public", () => {
    const handler = Object.getOwnPropertyDescriptor(
      AppConfigController.prototype,
      "get",
    )?.value as object;
    expect(Reflect.getMetadata(IS_PUBLIC_KEY, handler)).toBe(true);
  });
});
