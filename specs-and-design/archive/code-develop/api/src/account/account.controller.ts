import { Body, Controller, Delete, Get } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { AccountService } from "./account.service";
import { DeleteAccountDataDto } from "./account.dto";

@Controller("v1/account")
export class AccountController {
  constructor(private readonly accounts: AccountService) {}

  @Get("export")
  export(@RequestUser() user: AuthUser) {
    return this.accounts.export(user);
  }

  @Delete("data")
  deleteData(@RequestUser() user: AuthUser, @Body() dto: DeleteAccountDataDto) {
    return this.accounts.deleteData(user, dto.confirmation);
  }
}
