import { IsInt, IsObject, Max, Min } from "class-validator";

export const programIds = ["heartwise", "steady", "clearair"] as const;
export type ProgramId = (typeof programIds)[number];

export class PutProgramDataDto {
  @IsObject()
  payload!: Record<string, unknown>;

  @IsInt()
  @Min(1)
  @Max(2147483647)
  revision!: number;
}

export interface ProgramDataResponse {
  programId: ProgramId;
  payload: Record<string, unknown>;
  revision: number;
  updatedAt: string;
}
