# CMTAT-Canton Specification

Canton/Daml reference implementation of the **mandatory CMTAT token baseline**.

## About CMTA and CMTAT
[CMTA](https://www.cmta.ch/) (Capital Markets and Technology Association) publishes the CMTAT framework as a blockchain-agnostic standard for compliant tokenization of financial instruments.

[CMTAT](https://github.com/CMTA/CMTAT) defines a core set of token capabilities, including supply and balance operations, lifecycle controls (pause/unpause/deactivate), and compliance controls such as account freeze. The framework is designed to be implemented across multiple blockchain ecosystems.

This repository provides the Canton/Daml implementation of the **mandatory CMTAT baseline** and maps those requirements into Daml templates and choices while preserving Canton-native authorization and visibility semantics.

## CMTAT Canton (Core Features)

This package provides a Canton/Daml implementation of the mandatory CMTAT token features.

## 1. Purpose
This project provides an auditable implementation of mandatory CMTAT features on Canton using Daml templates and choices.

It is intended as:
- a functional equivalency reference,
- a technical baseline for reviews and audits,
- a foundation for optional extensions (snapshot, allowlist/rules, debt, enforcement).

It is **not** a full reproduction of all CMTAT Solidity variants.

## 1.1 Introduction
This project provides a clear, auditable, and implementation-focused Canton adaptation of the mandatory CMTAT token baseline.
Its main objective is to demonstrate functional equivalency for required CMTAT capabilities while remaining consistent with Canton and Daml principles, especially explicit party authorization, scoped data visibility, and contract-based state transitions.

This package is intended as a reference implementation of core token behavior, not as a full reproduction of all CMTAT Solidity modules.
The current scope therefore focuses on mandatory features only: token metadata, supply and balance operations, transfer controls, lifecycle controls (pause, unpause, deactivate), and account-level freeze controls.

From a governance and compliance perspective, this repository provides a foundation that can be reviewed against the CMTAT equivalency criteria before introducing optional extensions such as snapshotting, rule engines, allowlist systems, debt-specific modules, or enforcement-specific mechanics.

For readers coming from Ethereum, the business intent remains the same, but the implementation model is different:
- On Ethereum, token logic is usually centralized in a Solidity contract with public state and EVM execution semantics.
- On Canton, logic is expressed through Daml templates and choices, where authorization and visibility are first-class elements of the ledger model.

This README is organized as follows:
1. **Scope** defines what is included and excluded in this version.
2. **Ethereum vs Canton (Platform Differences)** explains infrastructure and ledger-model differences.
3. **Implementation Differences** compares this package with CMTAT Solidity implementation patterns.
4. **CMTAT Requirement Mapping** provides direct traceability from each mandatory requirement to Daml artifacts.

## 2. Scope
### In scope
- Mandatory token attributes and functions (`1.a`-`1.e`, `1.1`-`1.10`)
- Core lifecycle controls: pause, unpause, deactivate
- Account-level freeze / unfreeze

### Out of scope
- Optional modules: snapshot, dividend, debt, rule engine, allowlist, forced transfer/burn, partial freeze
- EVM-specific patterns (proxy upgradeability, ERC-2771 gasless relay model)

## 3. Repository Structure
- `src/`: Daml implementation
- `daml.yaml`: package configuration
- `src/Cmtat/Mandatory/Auth.daml`: authorization helper (`isAuthorized`)
- `src/Cmtat/Mandatory/Holding.daml`: holder state
- `src/Cmtat/Mandatory/TokenConfig.daml`: token metadata + lifecycle state
- `src/Cmtat/Mandatory/TokenAdmin.daml`: operational choices
- `src/Cmtat/Mandatory/Model.daml`: compatibility facade
- `src/Cmtat/Test/Main.daml`: test script
- `submodules/CMTAT`: upstream Solidity reference
- `submodules/CMTAT-Confidential`: Zama FHE confidential variant
- `submodules/CMTAT-equivalency-assessment`: equivalency checklist template

## Package Layout
- `src/Cmtat/Mandatory/Auth.daml`: Authorization helpers (`isAuthorized`).
- `src/Cmtat/Mandatory/Holding.daml`: Holder balance/freeze template.
- `src/Cmtat/Mandatory/TokenConfig.daml`: Token metadata and lifecycle template.
- `src/Cmtat/Mandatory/TokenAdmin.daml`: Operational template (mint/burn/transfer/freeze/unfreeze).
- `src/Cmtat/Mandatory/Model.daml`: Compatibility facade re-exporting the mandatory modules.
- `src/Cmtat/Test/Main.daml`: Script tests for positive and negative flows.
- `daml.yaml`: Package configuration and init script.

## 4. Architecture
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

## 5. Access Control and Visibility Model
Canton separates **visibility** from **authorization**.

- `signatory`: party that authorizes and owns contract obligations
- `observer`: party that can see contract data
- `controller`: party allowed to exercise a specific choice

In this implementation:
- Privileged choices require both:
  - correct controller invocation, and
  - `isAuthorized actor issuer operators` (issuer or listed operator)
- Holder transfer is sender-controlled (`actor` is sender) with policy guards.

Practical implication:
- A party may see data (observer) but still be unable to execute privileged actions.

## 6. Functional Specification Mapping (CMTAT Mandatory)
### 6.1 Mandatory attributes
- `1.a Name` -> `TokenConfig.name`
- `1.b Symbol` -> `TokenConfig.symbol`
- `1.c Token ID` -> `TokenConfig.tokenId`
- `1.d Legal document reference` -> `TokenConfig.termsRef`
- `1.e No fractions` -> `decimals == 0` unless `allowFractional = True`

### 6.2 Mandatory functions
- `1.1 totalSupply` -> `TokenConfig.TotalSupplyOf`
- `1.2 balanceOf` -> `TokenAdmin.BalanceOf`
- `1.3 transfer` -> `TokenAdmin.Transfer`
- `1.4 mint` -> `TokenAdmin.Mint`
- `1.5 burn/cancel` -> `TokenAdmin.Burn`
- `1.6 pause` -> `TokenConfig.Pause`
- `1.7 unpause` -> `TokenConfig.Unpause`
- `1.8 deactivate` -> `TokenConfig.Deactivate` (irreversible)
- `1.9 freeze` -> `TokenAdmin.Freeze`
- `1.10 unfreeze` -> `TokenAdmin.Unfreeze`

## 7. Business Rules and Invariants
- `decimals >= 0`
- `totalSupply >= 0`
- `decimals == 0 || allowFractional`
- `Holding.amount >= 0`
- `Mint` and `Burn` amounts must be positive
- `Transfer` requires:
  - positive amount
  - token not paused
  - token not deactivated
  - sender holding exists and has sufficient balance
  - sender and receiver not frozen
- After deactivation, state-changing token operations are blocked
- `TotalSupplyOf` remains readable after deactivation

## 8. Lifecycle and State Transitions
Daml contracts are immutable. Updates are performed through archive-and-create transitions.

- Pause/unpause/deactivate update `TokenConfig`
- Mint/burn update holder state and total supply
- Transfer atomically debits sender and credits receiver
- Freeze/unfreeze toggles holder-level transfer eligibility

## 9. Upgrade Model (Canton/Daml)
Upgradeability is package evolution (DAR versions), not proxy swapping.

- Keep package `name` stable, bump package `version`
- Use `upgrades:` in `daml.yaml` to enforce compatibility checks
- Uploading a new DAR is non-destructive; old and new versions can coexist
- Existing contracts are not bulk-rewritten on DAR upload
- Mixed-version operation is expected during transition
- For non-compatible shape changes, add explicit migration workflows (archive old + create new)

## 10. Ethereum vs Canton (Platform Differences)

These differences are at blockchain/platform level, independent of CMTAT specifics.

| Topic | Ethereum | Canton |
|---|---|---|
| Data visibility | On public EVM chains, state and transaction data are broadly visible by default. | Party-scoped visibility (only stakeholders/observers can see contract data). |
| State model | Mutable contract storage (for example mappings and variables). | Immutable contracts; updates occur through archive-and-create transitions. |
| Authorization model | Solidity checks (for example `msg.sender`, modifiers, role checks). | Daml controllers/signatories/observers plus explicit assertions. |
| Execution model | EVM execution with global transaction processing. | Participant-driven Canton/Daml execution with privacy-aware workflows. |
| Cost model | Gas metering paid in native token. | No EVM gas model; operational cost is infrastructure/protocol driven. |
| Composition style | Commonly contract-centric (single contract or proxy + modules), though multi-contract systems are also common. | Logic typically distributed across templates with explicit relationships. |

1. Data visibility and privacy
- Ethereum (public-chain context): contract state and transaction data are publicly visible by default.
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
- Ethereum: token logic is commonly contract-centric (single contract or proxy + modules), though multi-contract compositions are also standard.
- Canton: business state is often split across multiple templates with explicit relationships.

## 11. Implementation Differences: CMTAT Solidity vs This Canton Package

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

## 12. Comparison: Canton Core vs CMTAT-Confidential (Zama FHE)

This section compares this repository (`cmtat-canton`) with the `CMTAT-Confidential` implementation available in this workspace (`submodules/CMTAT-Confidential/README.md`), with focus on feature scope and privacy model.

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

## 13. Test Coverage
`Cmtat.Test.Main:setup` covers:
- read checks (`totalSupply`, `balanceOf`)
- unauthorized action failures (`Mint`, `Pause`)
- authorized mint paths
- transfer success and balance updates
- pause/unpause transfer gating
- freeze/unfreeze transfer gating
- burn supply reduction
- deactivation gating for state-changing operations
- total supply readability post-deactivation

## 14. Operational Run
### Dockerized (from repo root)
```bash
make daml-build-docker
make daml-test-docker
```

### Local Daml CLI (from repo root)
```bash
daml build
daml test
```

## 15. FAQ
### 0. How do I become a token holder in Canton? Do I need to run a node?
You do not need to run your own Canton node to be a token holder.

In practice, a holder is an onboarded **Party** on a Canton participant (often operated by your custodian, issuer, or service provider):
- You are provisioned with a Party identity on a participant.
- The issuer/operator can then mint or transfer tokens to your Party (your `Holding.owner`).
- You interact through the application/API connected to that participant to view balances and initiate holder actions (for example `Transfer`).

Compared to Ethereum:
- Ethereum holder model: wallet key + public chain access.
- Canton holder model: Party onboarding + participant connectivity + permissioned visibility.

### 1. As an issuer, can I burn tokens from a token holder without their consent?
Yes, if the actor is authorized (issuer or configured operator).

- `Burn` is an issuer/operator action and does not require the holder (`owner`) to be the choice controller.
- It requires an explicit `owner` target, an existing holding, and sufficient balance.
- This package does not include a dedicated `forcedTransfer`/enforcement module; however, authorized cancellation via `Burn` is available in the current scope.

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

### 7. If we add a new function/choice in v2, do we always need a migration?
No. In Canton/Daml SCU, adding new choices is generally a backward-compatible change and does not by itself require migrating all existing contracts.

Rule of thumb:
- **Migration usually not required**: add new choices, update compatible choice logic, add optional fields in an SCU-compatible way.
- **Migration required**: breaking model changes (for example removing fields/choices/templates, incompatible type changes), or when business/governance policy requires converting all v1 contracts to v2 state.

Even when migration is not required, v1 and v2 may coexist during rollout; migration can still be executed later for operational standardization.

### What happens to a holder with 100 tokens on v1 when v2 is deployed?
The 100 tokens remain on-ledger. Uploading v2 does not delete or rewrite v1 contracts.

### How do balances move from v1 state to v2 state?
- SCU-compatible coexistence: continue operating while v1/v2 coexist.
- Explicit migration: add and execute migration choices to archive v1 holdings and create equivalent v2 holdings.

### Is there a built-in `Upgrade`/`MigrateHolding` choice in this repository?
No. Current scope provides core mandatory token operations only.

### Can this be deployed as an EVM token contract?
No. This is a Canton/Daml implementation, not an EVM contract codebase.

## 16. Current Environment Note
In this execution environment, the Daml CLI may be unavailable; runtime commands/tests depend on a Daml-enabled setup.
