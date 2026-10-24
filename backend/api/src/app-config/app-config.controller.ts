import { Controller, Get } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { Public } from "../common/public.decorator";

export interface AppConfig {
  minimumVersion: { ios: string; android: string };
}

/**
 * `GET /v1/app/config`, public: the lowest app version per platform, from
 * MINIMUM_APP_VERSION_IOS and MINIMUM_APP_VERSION_ANDROID (validated at
 * start-up). Nothing else.
 */
@Controller("v1/app/config")
export class AppConfigController {
  constructor(private readonly config: ConfigService) {}

  @Public()
  @Get()
  get(): AppConfig {
    return {
      minimumVersion: {
        ios: this.config.getOrThrow<string>("MINIMUM_APP_VERSION_IOS"),
        android: this.config.getOrThrow<string>("MINIMUM_APP_VERSION_ANDROID"),
      },
    };
  }
}
