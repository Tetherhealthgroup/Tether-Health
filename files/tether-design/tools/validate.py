#!/usr/bin/env python3
"""Validates the Tether design data. Run before every commit.

Checks:
  1. Every product references a real area and real service lines
  2. Every product screen references a real archetype (or declares it as proposed)
  3. Every safeguard named by an area exists in the registry
  4. Every archetype 'requires' entry resolves to a safeguard or a known capability
  5. Areas marked in_development have a product; planned areas may not
  6. Reuse links between areas point at real service lines
"""
import json, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
load = lambda p: json.loads((ROOT / p).read_text())

CAPABILITIES = {
    "product_disclaimer", "self_report_disclaimer", "score_disclaimer",
    "offline_capable", "reduced_motion_fallback", "no_data_sent",
    "crisis_card", "crisis_card_pinned_first", "clinician_routing",
    "threshold_routing", "escalation_policy_ref", "generic_notification_copy",
    "export_action", "hard_delete_action", "share_preview", "review_date",
    "screening_prompt",
}

def main() -> int:
    areas = load("data/areas.json")["areas"]
    archetypes = load("data/archetypes.json")["archetypes"]
    safeguards = load("data/safeguards.json")["safeguards"]
    products = [load(p) for p in sorted(pathlib.Path(ROOT / "data/products").glob("*.json"))]

    area_ids = {a["id"] for a in areas}
    line_ids = {l["id"] for a in areas for l in a["serviceLines"]}
    arch_ids = {a["id"] for a in archetypes}
    guard_ids = {s["id"] for s in safeguards}
    errors, warnings = [], []

    for a in areas:
        for g in a.get("safeguards", []):
            if g not in guard_ids:
                errors.append(f"area {a['id']}: unknown safeguard '{g}'")
        for r in a.get("reuses", []):
            if r not in line_ids:
                errors.append(f"area {a['id']}: reuses unknown service line '{r}'")
        if a["status"] == "in_development" and not a.get("productId"):
            errors.append(f"area {a['id']}: in_development but no productId")

    for ar in archetypes:
        for req in ar.get("requires", []):
            if req not in guard_ids and req not in CAPABILITIES:
                errors.append(f"archetype {ar['id']}: unresolved requirement '{req}'")

    for p in products:
        if p["areaId"] not in area_ids:
            errors.append(f"product {p['id']}: unknown areaId '{p['areaId']}'")
        for l in p.get("serviceLines", []):
            if l not in line_ids:
                errors.append(f"product {p['id']}: unknown service line '{l}'")
        proposed = {x["id"] for x in p.get("proposedArchetypes", [])}
        for s in p["screens"]:
            if s["archetype"] in arch_ids:
                continue
            if s["archetype"] in proposed:
                warnings.append(
                    f"product {p['id']} screen {s['id']}: archetype '{s['archetype']}' is proposed, "
                    f"not yet in the shared library")
            else:
                errors.append(f"product {p['id']} screen {s['id']}: unknown archetype '{s['archetype']}'")

    shared = {}
    for p in products:
        for s in p["screens"]:
            shared.setdefault(s["archetype"], set()).add(p["id"])
    reused = sum(1 for v in shared.values() if len(v) > 1)

    print(f"{len(areas)} areas · {len(line_ids)} service lines · {len(archetypes)} archetypes "
          f"· {len(safeguards)} safeguards · {len(products)} products")
    print(f"{reused} of {len(shared)} archetypes are shared by more than one product")
    for w in warnings:
        print(f"  warn  {w}")
    for e in errors:
        print(f"  ERROR {e}")
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main())
