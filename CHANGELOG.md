# Changelog

## Semantic Version 2.0.0

Given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when the new version makes:
   -  Incompatible proxy **storage** change internally or through the upgrade of an external library (OpenZeppelin)
   -  A significant change in external APIs (public/external functions) or in the internal architecture
2. MINOR version when the new version adds functionality in a backward compatible manner
3. PATCH version when the new version makes backward compatible bug fixes

See [https://semver.org](https://semver.org)

## Type of changes

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.

Reference: [keepachangelog.com/en/1.1.0/](https://keepachangelog.com/en/1.1.0/)

Custom changelog tag: `Dependencies`, `Documentation`, `Testing`

-----

## [0.1.0] - 2026-05-23

First release of the Canton/Daml mandatory CMTAT baseline.

### Added

**Templates**

- `Holding` — per-holder balance and freeze state, keyed by `(issuer, tokenId, owner)`. The contract key enforces at most one active holding per (token, holder) pair. Fields: `issuer`, `owner`, `readers`, `tokenId`, `amount`, `frozen`. Invariant: `amount >= 0`.
- `TokenConfig` — token metadata (`name`, `symbol`, `tokenId`, `termsRef`, `decimals`, `allowFractional`) and lifecycle state (`paused`, `deactivated`, `totalSupply`). Invariants: `decimals >= 0`, `totalSupply >= 0`, `decimals == 0 || allowFractional`. Exposes the `TotalSupplyOf` read choice.
- `TokenAdmin` — stable operational entry point. All choices are `nonconsuming`; the contract is never consumed. Delegates all business logic to the corresponding module function.

**Choices on `TokenAdmin`**

| Choice | Returns | Description |
|---|---|---|
| `Pause` | `ContractId TokenConfig` | Sets `paused = True`. Guards: authorized, not deactivated, not already paused. |
| `Unpause` | `ContractId TokenConfig` | Sets `paused = False`. Guards: authorized, not deactivated, currently paused. |
| `Deactivate` | `ContractId TokenConfig` | Sets `deactivated = True` irreversibly. Guards: authorized, not already deactivated. |
| `BalanceOf` | `Int` | Returns the holder's current balance, or 0 if no holding exists. |
| `Mint` | `ContractId TokenConfig` | Issues tokens to an owner. Creates a new `Holding` or increments an existing one. Guards: authorized, positive amount, not deactivated, target not frozen. |
| `Burn` | `ContractId TokenConfig` | Reduces an owner's balance. Guards: authorized, positive amount, not deactivated, not frozen, sufficient balance. |
| `ForcedBurn` | `ContractId TokenConfig` | Reduces an owner's balance, bypassing frozen and deactivated checks. Guards: authorized, positive amount, sufficient balance. |
| `Freeze` | `ContractId Holding` | Sets `frozen = True` on a holder's `Holding`. Guards: authorized, not deactivated, not already frozen. |
| `Unfreeze` | `ContractId Holding` | Sets `frozen = False` on a holder's `Holding`. Guards: authorized, not deactivated, currently frozen. |
| `Transfer` | `()` | Holder-initiated transfer. Debits sender, credits receiver (creating receiver's `Holding` if absent). Guards: positive amount, not paused, not deactivated, sender and receiver not frozen, sufficient balance. No operator authorization required. |

**Module functions**

Business logic is separated from choice declarations following the CMTAT Solidity module pattern. Each module is an independent `.daml` file containing `Update`-returning functions called by the corresponding `TokenAdmin` choice.

- `Auth.daml` — `isAuthorized : Party -> Party -> [Party] -> Bool`. Returns `True` if actor is issuer or a listed operator.
- `PauseModule.daml` — `doPause`, `doUnpause`, `doDeactivate`.
- `MintModule.daml` — `doMint`.
- `BurnModule.daml` — `doBurn`.
- `EnforcementModule.daml` — `doForcedBurn`, `doFreeze`, `doUnfreeze`.
- `TransferModule.daml` — `doTransfer`.
- `Model.daml` — re-export facade exposing `Auth`, `Holding`, `TokenConfig`, `TokenAdmin` under the stable path `Cmtat.Mandatory.Model`.

### Testing

- `Cmtat.Test.Main:setup` — end-to-end Daml Script covering: read checks (`totalSupply`, `balanceOf`), unauthorized rejection (`Mint`, `Pause`), authorized mint to new and existing holders, transfer with balance verification, pause/unpause transfer gating, freeze/unfreeze transfer gating, frozen-address rejection for standard `Burn` and `Mint`, `ForcedBurn` on frozen address, standard `Burn`, deactivation gating for `Mint`/`Burn`/`Freeze`/`Unpause`, `ForcedBurn` on deactivated token, and post-deactivation `TotalSupplyOf` readability.

### Documentation

- `README.md` — architecture overview, repository structure, source file reference table (all 11 `.daml` files), access control model, CMTAT mandatory requirement mapping, business rules, lifecycle model, upgrade model, Ethereum vs Canton comparison, CMTAT Solidity vs Canton comparison, Canton Core vs CMTAT-Confidential comparison, test coverage summary, operational run instructions, FAQ (13 entries), and glossary (40+ terms).
- `CMTAT-equivalency-assessment-canton.md` — equivalency assessment updated to template v0.2.0, covering all 54 mandatory CMTAT requirements with Canton-specific implementation notes.

### Dependencies

- `Makefile` — Dockerized build and test targets (`daml-build-docker`, `daml-test-docker`) using `digitalasset/daml-sdk:2.9.5` as the runner and installing Daml SDK `2.10.4` at runtime.
- `submodules/CMTAT` — upstream Solidity reference (CMTA).
- `submodules/CMTAT-Confidential` — Zama FHE confidential variant.
- `submodules/CMTAT-equivalency-assessment` — equivalency checklist template, pinned to v0.2.0.
