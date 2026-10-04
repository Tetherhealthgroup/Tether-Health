import { Equals, IsString } from "class-validator";

export class DeleteAccountDataDto {
  @IsString()
  @Equals("DELETE")
  confirmation!: "DELETE";
}

export interface AccountDataExportResponse {
  schemaVersion: "1.0";
  generatedAt: string;
  profile: Record<string, unknown>;
  quitPlan: Record<string, unknown> | null;
  programData: Record<string, unknown>[];
}

export interface AccountDeletionReceipt {
  requestId: string;
  completedAt: string;
  deleted: {
    profiles: number;
    quitPlans: number;
    avatarObjects: number;
    programData: number;
  };
  authIdentityDeleted: true;
  authIdentityStatus: "deleted";
}
