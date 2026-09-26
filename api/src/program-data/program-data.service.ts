import {
  BadGatewayException,
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import type {
  ProgramDataResponse,
  ProgramId,
  PutProgramDataDto,
} from "./program-data.dto";

interface ProgramDataRow {
  program_id: ProgramId;
  payload: Record<string, unknown>;
  revision: number;
  updated_at: string;
}

@Injectable()
export class ProgramDataService {
  constructor(private readonly config: ConfigService) {}

  async get(user: AuthUser, programId: ProgramId) {
    const result = await this.client(user)
      .from("program_data")
      .select("program_id,payload,revision,updated_at")
      .eq("user_id", user.id)
      .eq("program_id", programId)
      .maybeSingle<ProgramDataRow>();
    if (result.error)
      throw new BadGatewayException("Program data is unavailable");
    if (!result.data) throw new NotFoundException("Program data not found");
    return this.response(result.data);
  }

  async put(
    user: AuthUser,
    programId: ProgramId,
    dto: PutProgramDataDto,
  ): Promise<ProgramDataResponse> {
    if (Buffer.byteLength(JSON.stringify(dto.payload), "utf8") > 32768) {
      throw new BadRequestException("Program payload is too large");
    }
    const result = await this.client(user)
      .from("program_data")
      .upsert(
        {
          user_id: user.id,
          program_id: programId,
          payload: dto.payload,
          revision: dto.revision,
        },
        { onConflict: "user_id,program_id" },
      )
      .select("program_id,payload,revision,updated_at")
      .single<ProgramDataRow>();
    if (result.error) throw new BadGatewayException("Program data save failed");
    return this.response(result.data);
  }

  async delete(user: AuthUser, programId: ProgramId): Promise<void> {
    const result = await this.client(user)
      .from("program_data")
      .delete()
      .eq("user_id", user.id)
      .eq("program_id", programId);
    if (result.error)
      throw new BadGatewayException("Program data deletion failed");
  }

  private response(row: ProgramDataRow): ProgramDataResponse {
    return {
      programId: row.program_id,
      payload: row.payload,
      revision: row.revision,
      updatedAt: row.updated_at,
    };
  }

  private client(user: AuthUser) {
    return createClient(
      this.config.getOrThrow<string>("SUPABASE_URL"),
      this.config.getOrThrow<string>("SUPABASE_ANON_KEY"),
      {
        global: { headers: { Authorization: `Bearer ${user.accessToken}` } },
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );
  }
}
