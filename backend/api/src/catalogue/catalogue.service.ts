import { BadGatewayException, Injectable } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { UserSupabaseClientFactory } from "../enrolments/user-supabase-client";

interface ProgrammeRow {
  code: string;
  slug: string;
  name: string;
  area: string;
  archetype: string;
  receives_resources: string[];
}

export interface ProgrammeResponse {
  code: string;
  slug: string;
  name: string;
  area: string;
  archetype: string;
  receivesResources: string[];
}

export interface ProgrammeCatalogueResponse {
  programmes: ProgrammeResponse[];
}

/** Programme reference data (no user data), read as the caller. */
@Injectable()
export class CatalogueService {
  constructor(private readonly clients: UserSupabaseClientFactory) {}

  async programmes(user: AuthUser): Promise<ProgrammeCatalogueResponse> {
    const { data, error } = await this.clients
      .forUser(user)
      .from("programmes")
      .select("code,slug,name,area,archetype,receives_resources")
      .order("code", { ascending: true })
      .returns<ProgrammeRow[]>();
    if (error) throw new BadGatewayException("Catalogue is unavailable");
    return {
      programmes: data.map((row) => ({
        code: row.code,
        slug: row.slug,
        name: row.name,
        area: row.area,
        archetype: row.archetype,
        receivesResources: row.receives_resources,
      })),
    };
  }
}
