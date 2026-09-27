import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Put,
} from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import {
  programIds,
  type ProgramId,
  PutProgramDataDto,
} from "./program-data.dto";
import { ProgramDataService } from "./program-data.service";

@Controller("v1/program-data")
export class ProgramDataController {
  constructor(private readonly data: ProgramDataService) {}

  @Get(":programId")
  get(@RequestUser() user: AuthUser, @Param("programId") value: string) {
    return this.data.get(user, this.programId(value));
  }

  @Put(":programId")
  put(
    @RequestUser() user: AuthUser,
    @Param("programId") value: string,
    @Body() dto: PutProgramDataDto,
  ) {
    return this.data.put(user, this.programId(value), dto);
  }

  @Delete(":programId")
  @HttpCode(204)
  async delete(
    @RequestUser() user: AuthUser,
    @Param("programId") value: string,
  ) {
    await this.data.delete(user, this.programId(value));
  }

  private programId(value: string): ProgramId {
    if (!(programIds as readonly string[]).includes(value)) {
      throw new BadRequestException("Unsupported program id");
    }
    return value as ProgramId;
  }
}
