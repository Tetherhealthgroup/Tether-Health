# Approved design registry

The UI must match the owner's approved `tether_ui`. These files record what
the owner approved, and `test/tether_ui/approved_design_parity_test.dart`
(part of the root `flutter test`) fails the build when
`tether_ui/spec/screens` drifts from it.

| File | What it holds |
|---|---|
| `manifest.json` | sha256 of each of the 183 approved `spec/screens/<screen>.json`, from the owner's snapshot (equal to `tether_ui.zip`, 2026-10-17). Never edited; the test pins its digest. |
| `deviations.json` / `deviations.md` | Approved screens allowed to differ, each with the owner decision, the ticket, and the sha256 of the reviewed content. |
| `additions.json` | Screens beyond the 183 that an owner decision added (the TH-953 list in `generator/review_TH-953.md`, plus `sf_home_unplug_android` from TH-971). An optional `status` records what is still open. |

The test fails when an approved screen is missing, when it differs from the
manifest without a deviation entry, when a deviated screen differs from its
pinned sha256, when a screen is neither approved nor a listed addition, or
when an entry has no decision or ticket. Decisions must be decision IDs
(`P-22`, `P-30b`, `N3`, `P-47 decision 3`) and tickets ticket IDs (`TH-942`,
`TH-972a`). Missing or malformed registry files, or a missing
`spec/screens`, also fail, with a message saying what to restore.

Listing a screen here records that an owner decision allows it. It is not
final visual approval: `sf_home_unplug_android` (decision N3) has
`"status": "owner prototype check pending"`, and all new copy still needs
clinical/legal review.

## Changing an approved screen

1. Get an owner decision first. Without one, revert the change.
2. Make the change in `generator/` and regenerate from the repo root with
   `python3 tether_ui/generator/build_all.py`. Generated files are never
   edited by hand.
3. In the same change, add or update the screen's entry in `deviations.json`
   (decision IDs, ticket, and the new sha256 that the test prints) and its row
   in `deviations.md`.
4. The change goes through review like any other.

## Adding a screen

Get an owner decision, add the screen through the generator, then add an
entry to `additions.json` with its decision IDs and ticket.

Removing an approved screen means changing `manifest.json` and, in
`test/tether_ui/approved_design_parity_test.dart`, both
`ownerManifestDigest` and `approvedScreenCount`. A new owner snapshot means
changing the manifest and `ownerManifestDigest`, and `approvedScreenCount`
if the number of screens changes. Only the owner can approve either.

`build_all.py` does not write to `approved/`, so the registry survives
regeneration.
