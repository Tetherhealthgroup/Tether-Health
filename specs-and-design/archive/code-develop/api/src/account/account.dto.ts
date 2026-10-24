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
}

export interface AccountDeletionReceipt {
  requestId: string;
  completedAt: string;
  deleted: {
    profiles: number;
    quitPlans: number;
    avatarObjects: number;
  };
  authIdentityDeleted: false;
  authIdentityStatus: "external-action-required";
}
