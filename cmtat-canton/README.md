# CMTAT Canton (Core Features)

This package provides a Canton/Daml implementation of the mandatory CMTAT token features.

## Introduction

This project is intended to provide a clear, auditable, and implementation-focused Canton adaptation of the CMTAT mandatory token baseline.  
Its primary objective is to demonstrate functional equivalency for the required CMTAT capabilities while respecting Canton and Daml design principles, particularly explicit party authorization, scoped data visibility, and contract-based state transitions.

The package should be read as a reference implementation for core token behavior, rather than a full reproduction of all CMTAT Solidity modules.  
Accordingly, the current scope emphasizes mandatory features only: token metadata, supply and balance operations, transfer controls, lifecycle controls (pause, unpause, deactivate), and account-level freeze controls.

From a governance and compliance perspective, this repository provides a foundation that can be reviewed against the CMTAT equivalency criteria before introducing optional extensions such as snapshotting, rule engines, allowlist systems, debt-specific modules, or enforcement-specific mechanics.

For readers coming from Ethereum, the business intent remains the same, but the implementation model is different:
- On Ethereum, token logic is usually centralized in a Solidity contract with public state and EVM execution semantics.
- On Canton, logic is expressed through Daml templates and choices, where authorization and visibility are first-class elements of the ledger model.

This README is organized as follows:
1. **Scope** defines what is included and excluded in this version.
2. **Ethereum vs Canton (Platform Differences)** explains infrastructure and ledger-model differences.
3. **Implementation Differences** compares this package with CMTAT Solidity implementation patterns.
4. **CMTAT Requirement Mapping** provides direct traceability from each mandatory requirement to Daml artifacts.

## Scope
- Included: Mandatory attributes `1.a`-`1.e` and mandatory functions `1.1`-`1.10`.
- Excluded: Optional modules (snapshot, dividend, debt, enforcement extras, allowlist/rules engine, etc.).

## Package Layout
- `src/Cmtat/Mandatory/Auth.daml`: Authorization helpers (`isAuthorized`).
- `src/Cmtat/Mandatory/Holding.daml`: Holder balance/freeze template.
- `src/Cmtat/Mandatory/TokenConfig.daml`: Token metadata and lifecycle template.
- `src/Cmtat/Mandatory/TokenAdmin.daml`: Operational template (mint/burn/transfer/freeze/unfreeze).
- `src/Cmtat/Mandatory/Model.daml`: Compatibility facade re-exporting the mandatory modules.
- `src/Cmtat/Test/Main.daml`: Script tests for positive and negative flows.
- `daml.yaml`: Package configuration and init script.

## Architecture
The model is split into four mandatory modules:

1. `Auth`
- Shared helper logic for privileged action checks.
- Exposes: `isAuthorized`.

2. `Holding`
- Per-holder balance and freeze state.
- Defines the `Holding` template and holding key.

3. `TokenConfig`
- Global token metadata and lifecycle state.
- Defines the `TokenConfig` template and lifecycle/read choices.

4. `TokenAdmin`
- Operational entrypoint for issuance and balance operations.
- Defines the `TokenAdmin` template and operational choices.

`Model.daml` now re-exports these modules to preserve a stable import path (`Cmtat.Mandatory.Model`).

The functional model still uses three templates:

1. `TokenConfig`
- Global token metadata and lifecycle state.
- Fields: `name`, `symbol`, `tokenId`, `termsRef`, `decimals`, `allowFractional`, `paused`, `deactivated`, `totalSupply`.
- Roles: `issuer` (signatory), `operators` + `readers` (observers).
- Lifecycle choices: `Pause`, `Unpause`, `Deactivate`.
- Read choice: `TotalSupplyOf`.

2. `Holding`
- Per-holder balance and freeze state.
- Fields: `issuer`, `owner`, `tokenId`, `amount`, `frozen`.
- Key: `(issuer, tokenId, owner)` with `issuer` as maintainer.

3. `TokenAdmin`
- Operational entrypoint for issuance and balance operations.
- Roles: `issuer` (signatory), `operators` + `readers` (observers).
- Choices: `BalanceOf`, `Mint`, `Burn`, `Transfer`, `Freeze`, `Unfreeze`.

## Ethereum vs Canton (Platform Differences)

These differences are at blockchain/platform level, independent of CMTAT specifics.

| Topic | Ethereum | Canton |
|---|---|---|
| Data visibility | Public by default (state and transactions are broadly visible). | Party-scoped visibility (only stakeholders/observers can see contract data). |
| State model | Mutable contract storage (for example mappings and variables). | Immutable contracts; updates occur through archive-and-create transitions. |
| Authorization model | Solidity checks (for example `msg.sender`, modifiers, role checks). | Daml controllers/signatories/observers plus explicit assertions. |
| Execution model | EVM execution with global transaction processing. | Participant-driven Canton/Daml execution with privacy-aware workflows. |
| Cost model | Gas metering paid in native token. | No EVM gas model; operational cost is infrastructure/protocol driven. |
| Composition style | Logic often concentrated in one contract (or proxy + modules). | Logic typically distributed across templates with explicit relationships. |

1. Data visibility and privacy
- Ethereum: contract state and transaction data are publicly visible by default.
- Canton: ledger visibility is party-scoped; only stakeholders/observers of a contract can see it.

2. State model
- Ethereum: a contract keeps mutable storage (for example mappings and variables).
- Canton: contracts are immutable; state changes are modeled by archiving old contracts and creating new ones.

3. Authorization model
- Ethereum: access checks are implemented in Solidity logic (`msg.sender`, roles, modifiers).
- Canton: authorization is built from Daml controllers/signatories/observers plus explicit assertions.

4. Execution and fees
- Ethereum: global execution with gas metering paid in native token.
- Canton: no EVM gas model; execution is on participants with Canton/Daml workflow and privacy semantics.

5. Contract composition
- Ethereum: token logic is commonly concentrated in one contract (or proxy + modules).
- Canton: business state is often split across multiple templates with explicit relationships.

## Implementation Differences: CMTAT Solidity vs This Canton Package

This section compares the CMTAT Solidity implementation family and this repository's Canton implementation.

| Topic | CMTAT Solidity | This Canton Package |
|---|---|---|
| Scope | Core plus optional/extended modules depending on variant (allowlist, rule engine, snapshot, debt, enforcement, upgradeability, etc.). | Mandatory core only (`1.a`-`1.e`, `1.1`-`1.10`). |
| Structure | Typically one token contract integrating modules. | Split into `TokenConfig`, `Holding`, and `TokenAdmin` templates. |
| Freeze interface | Often a single boolean-based function (`setAddressFrozen(address, bool)`). | Two explicit choices: `Freeze` and `Unfreeze`. |
| Access control | Role-based permissions (`grantRole`, `revokeRole`, `hasRole`) with module roles. | `isAuthorized actor issuer operators` with Daml choice controllers. |
| Transfer flow | ERC20-style `transfer` with optional module checks. | Holder-initiated transfer with pause/deactivation/freeze guard checks. |
| Lifecycle enforcement | Lifecycle controls implemented in Solidity/module logic. | Lifecycle checks enforced through `TokenConfig`-based choice assertions. |
| Optional compliance features | May include rules/allowlists and enforcement paths (for example forced transfer) by variant. | Optional compliance/enforcement modules intentionally out of scope. |

1. Scope
- CMTAT Solidity: includes core plus several optional/extended modules depending on variant (allowlist, rule engine, snapshot, debt, enforcement, upgradeability, etc.).
- This Canton package: includes only mandatory CMTAT core (`1.a`-`1.e`, `1.1`-`1.10`).

2. Contract structure
- CMTAT Solidity: typically one token contract integrating modules.
- Canton package: split into `TokenConfig`, `Holding`, and `TokenAdmin` templates.

3. Freeze interface
- CMTAT Solidity reference: often one function with a boolean status (`setAddressFrozen(address, bool)`).
- Canton package: two explicit choices, `Freeze` and `Unfreeze`.

4. Access control style
- CMTAT Solidity: role-based permissions (`grantRole`, `revokeRole`, `hasRole`) with module-specific roles.
- Canton package: `isAuthorized actor issuer operators` with Daml controllers on choices.

5. Transfer and holder actions
- CMTAT Solidity: transfer is ERC20-style (`transfer`) with additional module checks where enabled.
- Canton package: transfer is holder-initiated (`actor` is sender) and checked against pause/deactivation/freeze invariants.

6. Lifecycle and deactivation behavior
- Both: support pause/unpause/deactivation semantics.
- Canton package: lifecycle checks are enforced by choice-level assertions against `TokenConfig` fields.

7. Optional compliance features
- CMTAT Solidity: can integrate rules/allowlists and enforcement functions such as forced transfer paths depending on variant.
- Canton package: these optional compliance/enforcement modules are intentionally out of scope in the current version.

## Comparison: Canton Core vs CMTAT-Confidential (Zama FHE)

This section compares this repository (`cmtat-canton`) with the `CMTAT-Confidential` implementation available in this workspace (`CMTAT-Confidential/README.md`), with focus on feature scope and privacy model.

### Summary Table (Features + Privacy)

| Topic | Canton Core (`cmtat-canton`) | CMTAT-Confidential (Zama FHE) |
|---|---|---|
| Primary objective | Mandatory CMTAT baseline equivalency (`1.a`-`1.e`, `1.1`-`1.10`). | Confidential token operations with CMTAT compliance modules on ERC-7984/FHE. |
| Runtime model | Daml templates/choices on Canton. | Solidity contracts on EVM with Zama FHE tooling. |
| Balance representation | Plain integer balances in `Holding.amount` (party-visible by ledger visibility rules). | Encrypted balances (`euint64`) with ACL-gated decryption. |
| Transfer amount confidentiality | Not ciphertext-based; privacy comes from Canton party-scoped visibility. | Encrypted transfer amounts with ZK proof input flow. |
| Total supply visibility | Stored as integer in `TokenConfig.totalSupply`; visible to parties that can see `TokenConfig`. | Encrypted total supply (`euint64`) with observer/public-disclosure mechanisms. |
| Mandatory core functions | Implemented (`totalSupply`, `balanceOf`, `transfer`, `mint`, `burn`, `pause`, `unpause`, `deactivate`, `freeze`, `unfreeze`). | Implemented via confidential equivalents and inherited CMTAT lifecycle/compliance controls. |
| Forced operations | Not included in current Canton scope. | Includes `forcedTransfer` and `forcedBurn` modules. |
| Optional modules (snapshot/rules/allowlist/debt) | Not included in current Canton scope. | Some optional features included (forced ops, disclosure, operator model); others documented as not implemented (for example snapshot/rule engine/allowlist). |
| Numeric range | Standard integer range used in Daml model design. | `euint64` encrypted range (smaller than `uint256`), with practical supply/decimals constraints. |
| Privacy model | Privacy by participant/party visibility boundaries. | Privacy by cryptography (FHE encryption + ACL-based decryption permissions). |

### Privacy Interpretation

- Canton version:
  - Privacy is achieved by *who can see a contract* (stakeholder/observer model).
  - Data is not modeled as FHE ciphertext in this package.
  - Appropriate when business privacy is primarily based on permissioned ledger visibility.

- CMTAT-Confidential version:
  - Privacy is achieved by *encrypted state and encrypted transaction values*.
  - Decryption requires explicit ACL permission and FHE decryption workflow.
  - Appropriate when confidentiality must remain cryptographic even within shared execution infrastructure.

### Feature Scope Interpretation

- Canton core implementation is deliberately minimal and audit-friendly for mandatory equivalency.
- CMTAT-Confidential is broader on confidentiality mechanics and enforcement extensions, but also has its own documented constraints (for example `euint64` limits and selective optional-module coverage).

## CMTAT Requirement Mapping

### Mandatory Attributes
- `1.a Name`: `TokenConfig.name`
- `1.b Symbol`: `TokenConfig.symbol`
- `1.c Token ID`: `TokenConfig.tokenId`
- `1.d Legal document ref`: `TokenConfig.termsRef`
- `1.e No fractions`: `TokenConfig.decimals` with policy `decimals == 0` unless `allowFractional = True`

### Mandatory Functions
- `1.1 totalSupply`: `TokenConfig.TotalSupplyOf`
- `1.2 balanceOf`: `TokenAdmin.BalanceOf`
- `1.3 transfer`: `TokenAdmin.Transfer`
- `1.4 mint`: `TokenAdmin.Mint`
- `1.5 burn/cancel`: `TokenAdmin.Burn`
- `1.6 pause`: `TokenConfig.Pause`
- `1.7 unpause`: `TokenConfig.Unpause`
- `1.8 deactivate`: `TokenConfig.Deactivate` (irreversible)
- `1.9 freeze`: `TokenAdmin.Freeze`
- `1.10 unfreeze`: `TokenAdmin.Unfreeze`

## Authorization Model
`isAuthorized actor issuer operators = actor == issuer || elem actor operators`

Privileged actions requiring issuer/operator authorization:
- `Mint`, `Burn`, `Freeze`, `Unfreeze`
- `Pause`, `Unpause`, `Deactivate`

Transfer is holder-initiated:
- `Transfer` controller is `actor` (the sender), subject to policy checks.

## Business Rules and Invariants
- `decimals >= 0`
- `totalSupply >= 0`
- `decimals == 0` unless `allowFractional = True`
- `Holding.amount >= 0`
- Transfer requires:
  - `transferAmount > 0`
  - not paused
  - not deactivated
  - sender holding exists and has sufficient balance
  - sender and receiver are not frozen
- Mint/Burn require positive amounts.
- State-changing token operations are blocked after deactivation.
- Read path (`TotalSupplyOf`) remains available after deactivation.

## Visibility Model
To support holder/operator exercise and read flows, `TokenConfig` and `TokenAdmin` include:
- `observer (operators ++ readers)`

This ensures non-issuer actors that must invoke choices (operator, holders, read users) have contract visibility.

## Test Coverage (`Cmtat.Test.Main:setup`)
The script covers:
- Initial read checks for `totalSupply` and `balanceOf`
- Unauthorized action failures:
  - unauthorized `Mint`
  - unauthorized `Pause`
- Authorized mint by issuer and operator
- Transfer success and balance updates
- Pause blocks transfer
- Unpause restores transfer capability
- Freeze blocks transfer
- Unfreeze restores transfer ability
- Burn reduces holder balance and total supply
- Deactivation blocks `Mint`, `Burn`, `Freeze`, `Unpause`
- Post-deactivation `totalSupply` remains readable

## FAQ

### 1. As an issuer, can I burn tokens from a token holder without their consent?

Not in the current Canton core package.

- `Burn` is an issuer/operator action, but it requires an explicit `owner` target and an existing holding.
- This package does not include a dedicated "forced burn" or "forced transfer" enforcement module.
- If forced enforcement is required by your legal process, it must be added as an extension module beyond the current mandatory scope.

### 2. As a token holder, how do I transfer tokens to another party?

Transfers are holder-initiated through `TokenAdmin.Transfer`.

Requirements checked by the model:
- transfer amount must be positive
- token must not be paused
- token must not be deactivated
- sender must have sufficient balance
- sender and recipient must not be frozen

If all checks pass, sender and recipient holdings are updated atomically.

### 3. Is this implementation intended for public-chain deployment like Ethereum mainnet?

No. This implementation targets Canton/Daml deployments, not EVM deployment.

- Smart contract logic is written as Daml templates and choices.
- Execution, authorization, and visibility follow Canton participant/party semantics.
- If you need Ethereum deployment, use a Solidity implementation family (for example CMTAT Solidity or CMTAT-Confidential).

### 4. Does this version encrypt balances and transfer amounts like CMTAT-Confidential?

No. This package does not use FHE ciphertext balances.

- Privacy in Canton comes from ledger visibility rules (stakeholders/observers), not encrypted arithmetic types.
- In contrast, CMTAT-Confidential uses encrypted values (`euint64`) and ACL-based decryption controls.

### 5. Can third parties read balances and total supply?

It depends on contract visibility and granted roles.

- `BalanceOf` and `TotalSupplyOf` are read choices, but callers must have visibility on the corresponding contracts.
- Visibility is controlled by Daml signatory/observer relationships (`issuer`, `operators`, `readers`, and holder-specific visibility on `Holding`).
- There is no public "read everything" endpoint equivalent to a fully public EVM state view.

### 6. What happens after deactivation?

Deactivation is irreversible in this model.

- State-changing token operations are blocked (`Mint`, `Burn`, `Freeze`, `Unfreeze`, and other guarded actions).
- The read path for total supply remains available (`TotalSupplyOf`), which supports audit/reporting needs after shutdown.

## Run
From `cmtat-canton/`:
- `daml build`
- `daml test`

From repository root (Dockerized toolchain):
- `make daml-build-docker`
- `make daml-test-docker`

## Current Environment Note
In this execution environment, `daml` CLI is not installed, so tests could not be executed here. The implementation is ready to run in a Daml-enabled setup.
