import { Body, Controller, Delete, Get, HttpCode, Post } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { AccountService } from "./account.service";
import { DeleteAccountDataDto } from "./account.dto";

@Controller("v1/account")
export class AccountController {
  constructor(private readonly accounts: AccountService) {}

  /** Kept for app versions that read the export with GET. */
  @Get("export")
  export(@RequestUser() user: AuthUser) {
    return this.accounts.export(user);
  }

  /** The app's form: the same export and response as GET. */
  @Post("export")
  @HttpCode(200)
  exportPost(@RequestUser() user: AuthUser) {
    return this.accounts.export(user);
  }

  @Delete("data")
  deleteData(@RequestUser() user: AuthUser, @Body() dto: DeleteAccountDataDto) {
    return this.accounts.deleteData(user, dto.confirmation);
  }
}
