import * as Joi from "joi";
import { BlockList, isIP } from "node:net";

function decodedSupabaseRole(value: string): string | undefined {
  const segments = value.split(".");
  if (segments.length !== 3) return undefined;
  const payloadSegment = segments[1];
  if (!payloadSegment) return undefined;
  try {
    const payload = JSON.parse(
      Buffer.from(payloadSegment, "base64url").toString("utf8"),
    ) as Record<string, unknown>;
    return typeof payload.role === "string" ? payload.role : undefined;
  } catch {
    return undefined;
  }
}

function isPrivilegedSupabaseKey(value: string): boolean {
  if (value.startsWith("sb_secret_")) return true;
  return decodedSupabaseRole(value) === "service_role";
}

export const MAX_TRUSTED_PROXY_HOPS = 10;

/**
 * Normalises TRUST_PROXY to a trusted-hop count. Accepts "false" (no proxy)
 * or a non-negative integer string up to MAX_TRUSTED_PROXY_HOPS. "true" is
 * rejected on purpose: trusting every hop lets clients spoof X-Forwarded-For.
 */
function trustedProxyHops(
  value: unknown,
  helpers: Joi.CustomHelpers,
): number | Joi.ErrorReport {
  if (typeof value === "number" && Number.isInteger(value) && value >= 0) {
    return value <= MAX_TRUSTED_PROXY_HOPS
      ? value
      : helpers.error("any.invalid");
  }
  if (typeof value !== "string") return helpers.error("any.invalid");
  if (value === "false") return 0;
  if (!/^(0|[1-9][0-9]*)$/.test(value)) return helpers.error("any.invalid");
  const hops = Number(value);
  return hops <= MAX_TRUSTED_PROXY_HOPS ? hops : helpers.error("any.invalid");
}

export interface TrustedProxyRange {
  family: "ipv4" | "ipv6";
  address: string;
  /** Prefix length; undefined for a single address. */
  prefix?: number;
}

const MAX_PREFIX = { ipv4: 32, ipv6: 128 } as const;
// Broadest accepted range per family. Broader ranges are rejected because
// several of them together can cover every address (e.g. two IPv4 /1s).
const MIN_PREFIX = { ipv4: 8, ipv6: 32 } as const;

/** Eight 16-bit groups of an address that isIP() reports as IPv6. */
function ipv6Groups(address: string): number[] {
  let text = address;
  const lastColon = text.lastIndexOf(":");
  const tail = text.slice(lastColon + 1);
  if (tail.includes(".")) {
    const [a = 0, b = 0, c = 0, d = 0] = tail.split(".").map(Number);
    text = `${text.slice(0, lastColon + 1)}${((a << 8) | b).toString(16)}:${((c << 8) | d).toString(16)}`;
  }
  const [head = "", rest] = text.split("::");
  const parse = (part: string) =>
    part === "" ? [] : part.split(":").map((group) => parseInt(group, 16));
  const left = parse(head);
  const right = rest === undefined ? [] : parse(rest);
  const zeros = new Array<number>(8 - left.length - right.length).fill(0);
  return [...left, ...zeros, ...right];
}

/** True if the first `bits` bits of two IPv6 group arrays are equal. */
function sameLeadingBits(a: number[], b: number[], bits: number): boolean {
  for (let i = 0; i < 8 && bits > 0; i += 1, bits -= 16) {
    const mask = bits >= 16 ? 0xffff : (0xffff << (16 - bits)) & 0xffff;
    if (((a[i] ?? 0) & mask) !== ((b[i] ?? 0) & mask)) return false;
  }
  return true;
}

const IPV4_MAPPED = [0, 0, 0, 0, 0, 0xffff, 0, 0]; // ::ffff:0:0/96
const ZERO = [0, 0, 0, 0, 0, 0, 0, 0];

/**
 * BlockList matches IPv4 peers against IPv6 ranges that cover the
 * IPv4-mapped space, so an IPv6 range overlapping it could trust every IPv4
 * address. Rejects any range overlapping ::ffff:0:0/96 (IPv4 proxies must be
 * written in IPv4 form) and any range in ::/80 broader than /104. Host bits
 * are masked first, as BlockList does.
 */
function overlapsIpv4Space(address: string, prefix: number): boolean {
  const groups = ipv6Groups(address);
  if (sameLeadingBits(groups, IPV4_MAPPED, Math.min(prefix, 96))) return true;
  return prefix < 104 && sameLeadingBits(groups, ZERO, Math.min(prefix, 80));
}

function trustedProxyRange(entry: string): TrustedProxyRange | undefined {
  const parts = entry.split("/");
  if (parts.length > 2) return undefined;
  const [address = "", prefixText] = parts;
  // isIP accepts IPv6 zone IDs (fe80::1%eth0); a socket peer never has one.
  if (address.includes("%")) return undefined;
  const version = isIP(address);
  if (version === 0) return undefined;
  const family = version === 4 ? "ipv4" : "ipv6";
  // Decimal prefix without leading zeros.
  if (prefixText !== undefined && !/^[1-9][0-9]{0,2}$/.test(prefixText)) {
    return undefined;
  }
  const prefix =
    prefixText === undefined ? MAX_PREFIX[family] : Number(prefixText);
  if (prefix < MIN_PREFIX[family] || prefix > MAX_PREFIX[family]) {
    return undefined;
  }
  if (family === "ipv6" && overlapsIpv4Space(address, prefix)) {
    return undefined;
  }
  return prefixText === undefined
    ? { family, address }
    : { family, address, prefix };
}

/**
 * Parses TRUST_PROXY_CIDRS: a comma-separated list of IPv4/IPv6 addresses or
 * CIDR ranges (e.g. "10.0.0.0/8, 2001:db8::/32"). An empty value is an empty
 * list. Errors never include the offending value.
 */
function trustedProxyRanges(
  value: unknown,
  helpers: Joi.CustomHelpers,
): TrustedProxyRange[] | Joi.ErrorReport {
  if (typeof value !== "string") return helpers.error("any.invalid");
  if (value.trim() === "") return [];
  const ranges: TrustedProxyRange[] = [];
  for (const entry of value.split(",")) {
    const range = trustedProxyRange(entry.trim());
    if (!range) return helpers.error("any.invalid");
    ranges.push(range);
  }
  return ranges;
}

function nonEmptyRanges(
  value: TrustedProxyRange[],
  helpers: Joi.CustomHelpers,
): TrustedProxyRange[] | Joi.ErrorReport {
  return value.length > 0 ? value : helpers.error("any.required");
}

/**
 * Fastify `trustProxy` option for a validated hop count and proxy allowlist
 * (a hop count of 0 disables it).
 *
 * Fastify 5.12 deliberately ignores a bare numeric `trustProxy` (it fails
 * closed and trusts nothing), so the hop count is expressed as a trust
 * function. Hop 0 is the socket peer and hop N is the Nth X-Forwarded-For
 * entry counting from the right. A hop is trusted only if it is below `hops`
 * AND its address is in `ranges`, so a peer outside the allowlist (including
 * a direct client at hop 0) is never trusted and its forwarded headers are
 * ignored. The client IP is the first untrusted address.
 */
export function fastifyTrustProxy(
  hops: number,
  ranges: readonly TrustedProxyRange[] = [],
): false | ((address: string, hop: number) => boolean) {
  if (hops <= 0 || ranges.length === 0) return false;
  const allowlist = new BlockList();
  for (const { family, address, prefix } of ranges) {
    if (prefix === undefined) allowlist.addAddress(address, family);
    else allowlist.addSubnet(address, prefix, family);
  }
  return (address, hop) => {
    if (hop >= hops) return false;
    const version = isIP(address);
    if (version === 0) return false;
    // BlockList also matches IPv4-mapped IPv6 peers (::ffff:a.b.c.d).
    return allowlist.check(address, version === 4 ? "ipv4" : "ipv6");
  };
}

/** A minimum app version: MAJOR.MINOR.PATCH, no leading zeros. */
export const MINIMUM_APP_VERSION =
  /^(0|[1-9][0-9]{0,3})\.(0|[1-9][0-9]{0,3})\.(0|[1-9][0-9]{0,3})$/;

/** Errors name the variable, never the value. */
const minimumAppVersion = Joi.custom(
  (value: unknown, helpers: Joi.CustomHelpers) =>
    typeof value === "string" && MINIMUM_APP_VERSION.test(value)
      ? value
      : helpers.error("any.invalid"),
  "minimum app version",
);

const trustedProxyList = Joi.custom(
  trustedProxyRanges,
  "trusted proxy address list",
);

export const environmentSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid("development", "test", "production")
    .default("development"),
  PORT: Joi.number().port().default(3000),
  SUPABASE_URL: Joi.when("NODE_ENV", {
    is: "production",
    then: Joi.string()
      .uri({ scheme: ["https"] })
      .required(),
    otherwise: Joi.string()
      .uri({ scheme: ["https", "http"] })
      .required(),
  }),
  SUPABASE_ANON_KEY: Joi.string()
    .min(20)
    .custom((value: string, helpers) => {
      if (isPrivilegedSupabaseKey(value)) {
        return helpers.error("any.invalid");
      }
      return value;
    })
    .required(),
  // The API never holds the Supabase service key: account deletion runs with
  // the member's own token. Startup fails while this variable is set to any
  // value, including an empty one, so the key cannot linger in the process
  // environment.
  SUPABASE_SERVICE_ROLE_KEY: Joi.any().forbidden(),
  SUPABASE_JWT_AUDIENCE: Joi.string().default("authenticated"),
  // At most the database's own recent sign-in window for account deletion
  // (600 seconds), so the API is never looser than the database.
  RECENT_AUTH_MAX_AGE_SECONDS: Joi.number()
    .integer()
    .min(60)
    .max(600)
    .default(600),
  REQUEST_BODY_LIMIT_BYTES: Joi.number()
    .integer()
    .min(1024)
    .max(1048576)
    .default(65536),
  RATE_LIMIT_MAX: Joi.number().integer().min(10).max(10000).default(120),
  RATE_LIMIT_WINDOW_MS: Joi.number()
    .integer()
    .min(1000)
    .max(3600000)
    .default(60000),
  // Number of reverse-proxy hops whose X-Forwarded-For entry is trusted when
  // deriving the client IP (used by rate limiting). Defaults to 0 (trust no
  // proxy; forwarded headers are ignored) in EVERY environment, including
  // production. The owner will set the real hop count after confirming
  // Render's proxy topology. Setting it higher than the real number of
  // proxies lets clients spoof their IP and evade or weaponise rate limits.
  TRUST_PROXY: Joi.custom(trustedProxyHops, "trusted proxy hop count").default(
    0,
  ),
  // Addresses or CIDR ranges of the reverse proxies allowed to set
  // X-Forwarded-For. Required when TRUST_PROXY is above 0: a hop is trusted
  // only if its address is in this list, so a client connecting directly
  // cannot forge its IP. Not used when TRUST_PROXY is 0, but must still be
  // empty or valid.
  TRUST_PROXY_CIDRS: Joi.when("TRUST_PROXY", {
    is: 0,
    then: trustedProxyList.default([]),
    otherwise: trustedProxyList.required().custom(nonEmptyRanges),
  }),
  CORS_ALLOWED_ORIGINS: Joi.string().allow("").default(""),
  // Lowest app version the API still serves, per platform, shown by
  // GET /v1/app/config. Not secret. MAJOR.MINOR.PATCH; the default 0.0.0
  // asks no installed version to update.
  MINIMUM_APP_VERSION_IOS: minimumAppVersion.default("0.0.0"),
  MINIMUM_APP_VERSION_ANDROID: minimumAppVersion.default("0.0.0"),
});
