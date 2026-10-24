import {
  IsBoolean,
  IsIn,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from "class-validator";

export class UpdateProfileDto {
  @IsOptional()
  @ValidateIf((_object, value) => value !== null)
  @IsString()
  @MaxLength(80)
  @Matches(/^\S(?:.*\S)?$/, {
    message: "displayName must not have surrounding whitespace",
  })
  displayName?: string | null;

  @IsOptional()
  @IsIn(["en", "es"])
  locale?: "en" | "es";

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  @Matches(/^[A-Za-z_+-]+(?:\/[A-Za-z0-9_+.-]+)*$/)
  timeZone?: string;

  @IsOptional()
  @IsBoolean()
  onboardingCompleted?: boolean;

  @IsOptional()
  @ValidateIf((_object, value) => value !== null)
  @IsString()
  @MaxLength(512)
  avatarPath?: string | null;
}

export interface ProfileResponse {
  id: string;
  displayName: string | null;
  locale: "en" | "es";
  timeZone: string;
  onboardingCompleted: boolean;
  avatarPath: string | null;
  createdAt: string;
  updatedAt: string;
}
