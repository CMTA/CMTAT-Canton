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

```
cmtat-canton/
├── daml.yaml                          # Package config, SDK version, init script
├── src/
│   └── Cmtat/
│       ├── Mandatory/                 # Core token implementation
│       └── Test/                      # Daml Script tests
└── submodules/
    ├── CMTAT/                         # Upstream Solidity reference
    ├── CMTAT-Confidential/            # Zama FHE confidential variant
    └── CMTAT-equivalency-assessment/  # Equivalency checklist template
```

## 4. Source File Reference

All source files live under `src/Cmtat/`. Each row describes one `.daml` file: what it defines, what kind of artifact it is, and its role in the system.

| File | Kind | Defines | Role |
|---|---|---|---|
| `Mandatory/Auth.daml` | Helper | `isAuthorized : Party -> Party -> [Party] -> Bool` | Shared authorization predicate. Returns `True` if `actor` is the issuer or a listed operator. Imported by all modules that gate privileged actions. |
| `Mandatory/Holding.daml` | Template | `Holding` | Per-holder balance and freeze state. Keyed by `(issuer, tokenId, owner)` — the ledger enforces at most one active holding per holder. Signatory: `issuer`. Observers: `owner` and `readers`. |
| `Mandatory/TokenConfig.daml` | Template | `TokenConfig`, `TotalSupplyOf` | Token metadata (name, symbol, tokenId, termsRef, decimals) and lifecycle state (paused, deactivated, totalSupply). Holds the `ensure` invariants for the token. Contains only the non-state-changing `TotalSupplyOf` read choice. |
| `Mandatory/TokenAdmin.daml` | Template | `TokenAdmin` and all operational choices | Stable entry point for all issuer, operator, and holder actions. All choices are `nonconsuming` — the contract is never consumed. Each choice body is a one-line delegation to the corresponding module function. |
| `Mandatory/PauseModule.daml` | Module functions | `doPause`, `doUnpause`, `doDeactivate` | Lifecycle control logic. `doPause`/`doUnpause` toggle the `paused` flag on `TokenConfig`. `doDeactivate` sets `deactivated = True` irreversibly. All three guard against deactivated state and no-op transitions. |
| `Mandatory/MintModule.daml` | Module functions | `doMint` | Supply issuance logic. Creates a new `Holding` if the owner has none, or increments an existing one. Guards: authorized actor, positive amount, token not deactivated, target not frozen. Updates `totalSupply` in `TokenConfig`. |
| `Mandatory/BurnModule.daml` | Module functions | `doBurn` | Standard supply reduction logic. Decrements the owner's `Holding` and `totalSupply`. Guards: authorized actor, positive amount, token not deactivated, holder not frozen, sufficient balance. |
| `Mandatory/EnforcementModule.daml` | Module functions | `doForcedBurn`, `doFreeze`, `doUnfreeze` | Enforcement actions that may bypass normal guards. `doForcedBurn` skips both the frozen and deactivated checks. `doFreeze`/`doUnfreeze` toggle the `frozen` flag on a `Holding`, guarding against no-op transitions and deactivated state. |
| `Mandatory/TransferModule.daml` | Module functions | `doTransfer` | Holder-initiated transfer logic. Debits the sender's `Holding` and credits the receiver's (creating it if absent). Guards: positive amount, token not paused or deactivated, sender and receiver not frozen, sufficient balance. Does not check `isAuthorized` — transfer is a holder right, not an operator action. |
| `Mandatory/Model.daml` | Facade | Re-exports `Auth`, `Holding`, `TokenConfig`, `TokenAdmin` | Stable import surface for external consumers. Importing `Cmtat.Mandatory.Model` gives access to all templates and choices without depending on internal module paths. The `*Module` files are not re-exported as they are implementation details. |
| `Test/Main.daml` | Test script | `setup : Script ()` | End-to-end Daml Script covering the full lifecycle: read checks, unauthorized rejections, mint, transfer, pause/unpause gating, freeze/unfreeze gating, standard burn, forced burn on frozen and deactivated accounts, and deactivation gating. |

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
### 6.1 Token attributes
- `1` Name -> `TokenConfig.name`
- `2` Ticker symbol -> `TokenConfig.symbol`
- `3` Legal document reference -> `TokenConfig.termsRef`
- `4` No fractions -> `decimals == 0` unless `allowFractional = True`
- `5` Token ID *(optional, included)* -> `TokenConfig.tokenId`

### 6.2 Token module
- `6` totalSupply -> `TokenConfig.TotalSupplyOf`
- `7` balanceOf -> `TokenAdmin.BalanceOf`
- `8` transfer -> `TokenAdmin.Transfer` (`TransferModule.doTransfer`)
- `9` mint -> `TokenAdmin.Mint` (`MintModule.doMint`)
- `10` burn/cancel -> `TokenAdmin.Burn` (`BurnModule.doBurn`)

### 6.3 Pause module
- `12` pause -> `TokenAdmin.Pause` (`PauseModule.doPause`)
- `13` unpause -> `TokenAdmin.Unpause` (`PauseModule.doUnpause`)
- `14` deactivate -> `TokenAdmin.Deactivate` (`PauseModule.doDeactivate`, irreversible)

### 6.4 Enforcement module
- `15` freeze -> `TokenAdmin.Freeze` (`EnforcementModule.doFreeze`)
- `16` unfreeze -> `TokenAdmin.Unfreeze` (`EnforcementModule.doUnfreeze`)

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
| Numeric range for amounts | `uint256` (0 to ~1.16 × 10⁷⁷). Supports 18 decimals with supply in the billions without overflow. | `Int` (64-bit signed, max 2⁶³ − 1 ≈ 9.2 × 10¹⁸). With 18 decimals, usable supply in human units is capped at ~9.2 tokens — impractical for real issuances. Smaller decimal values (0–8) are recommended. |

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

8. Numeric range for amounts
- CMTAT Solidity: balances and supply are `uint256`, supporting values from 0 to ~1.16 × 10⁷⁷. A token with 18 decimals and a supply of billions of units fits comfortably within this range.
- Canton package: `Holding.amount` and `TokenConfig.totalSupply` are Daml `Int`, a 64-bit signed integer with a maximum value of 2⁶³ − 1 = 9,223,372,036,854,775,807. With 18 decimals, the entire 64-bit range represents only ~9.2 human-unit tokens, making high-decimal configurations impractical. Recommended practice is to keep `decimals` between 0 and 8, where the integer range remains operationally meaningful.

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

### 8. What are `cfg0`, `cfg1`, `cfg5`… in the test script?
Each name tracks the **current live `ContractId TokenConfig`** after a state-changing operation.

In Daml, contracts are immutable. Every choice that mutates `TokenConfig` (Mint, Burn, Pause, Unpause, Deactivate, ForcedBurn) archives the old contract and creates a new one, which returns a brand-new `ContractId`. The old ID is permanently dead — exercising it aborts with "contract consumed".

The test script must thread the latest ID forward through every call:

```
cfg0  ← created initially (totalSupply=0, paused=False, deactivated=False)
cfg1  ← after Mint alice 100       (totalSupply=100)
cfg2  ← after Mint bob 10          (totalSupply=110)
cfg4  ← after Pause                (paused=True)
cfg5  ← after Unpause              (paused=False)
cfg6  ← after ForcedBurn alice 5   (totalSupply=105)
cfg7  ← after Burn bob 5           (totalSupply=100)
cfg8  ← after Deactivate           (deactivated=True)
cfg9  ← after ForcedBurn bob 1     (totalSupply=99)
```

Numbering gaps (`cfg3` missing, no binding between `cfg5` and `cfg6`) reflect operations that do not mutate `TokenConfig` — `Transfer`, `Freeze`, `Unfreeze` — so no new ID is produced.

In a production application, the caller is responsible for keeping track of the latest `ContractId`, typically by querying the active contract set rather than threading IDs manually.

### 9. What happens to a holder with 100 tokens on v1 when v2 is deployed?
The 100 tokens remain on-ledger. Uploading v2 does not delete or rewrite v1 contracts.

### 10. How do balances move from v1 state to v2 state?
- SCU-compatible coexistence: continue operating while v1/v2 coexist.
- Explicit migration: add and execute migration choices to archive v1 holdings and create equivalent v2 holdings.

### 11. Is there a built-in `Upgrade`/`MigrateHolding` choice in this repository?
No. Current scope provides core mandatory token operations only.

### 12. Can this be deployed as an EVM token contract?
No. This is a Canton/Daml implementation, not an EVM contract codebase.

## 16. Current Environment Note
In this execution environment, the Daml CLI may be unavailable; runtime commands/tests depend on a Daml-enabled setup.

## 17. Glossary

Key terms for understanding Canton and Daml, ordered from foundational to operational.

### Ledger model

| Term | Definition |
|---|---|
| **Ledger** | The distributed, append-only record of all contract events (creates and archives). There is no mutable state — only active (non-archived) contracts at any point in time. |
| **Canton** | The enterprise distributed ledger platform by Digital Asset. Runs Daml smart contracts with privacy-aware, participant-driven execution. Not a public blockchain. |
| **Daml** | The smart contract language and SDK by Digital Asset. Contracts are expressed as typed templates with explicit authorization and visibility rules. |
| **DAR** | Daml Archive. The compiled, deployable artifact for a Daml package (analogous to a JAR or Wasm module). Uploaded to a Canton participant to activate contract logic. |
| **Package** | A versioned unit of Daml code identified by a package hash. Multiple versions can coexist on the same ledger. |

### Parties and roles

| Term | Definition |
|---|---|
| **Party** | A named principal with a cryptographic identity on the Canton network. Authorization and visibility are always expressed in terms of parties. Analogous to an Ethereum address, but scoped to a Canton deployment. |
| **Participant** | A Canton node that hosts one or more parties, manages their private contract data, and submits/validates transactions on their behalf. |
| **Signatory** | A party whose authorization is required to create (or archive) a contract. Signatories are bound by the contract's obligations. Every contract must have at least one signatory. |
| **Observer** | A party that can see a contract's data but is not bound by it and does not authorize its creation. Observers have read-only visibility. |
| **Controller** | The party (or set of parties) authorized to exercise a specific choice on a contract. Declared per choice, not at the template level. |
| **Stakeholder** | Any party that is either a signatory or an observer of a contract. Stakeholders are the only parties who can see that contract on the ledger. |
| **Maintainer** | The signatory responsible for enforcing uniqueness of a contract key. Must be a subset of the signatories. |

### Contracts and templates

| Term | Definition |
|---|---|
| **Template** | The blueprint for a contract. Defines typed fields, signatories, observers, contract key (optional), and choices. Equivalent to a class definition. |
| **Contract** | A live instance of a template on the ledger. Identified by a `ContractId`. Once archived, it can never be reactivated — a new contract must be created instead. |
| **ContractId** | A globally unique, opaque identifier for a specific contract instance. Becomes stale (unusable) as soon as the contract is archived. |
| **Contract Key** | An optional, user-defined unique identifier derived from a contract's fields (e.g. `(issuer, tokenId, owner)` for `Holding`). Enables `lookupByKey` without knowing the `ContractId`. |
| **Archive** | The operation that permanently retires a contract from the active ledger. Equivalent to deletion, but the historical record is preserved. State changes in Daml are always expressed as archive-and-create pairs. |
| **Active Contract Set (ACS)** | The set of all contracts that have been created but not yet archived. Querying the ACS is how applications discover the current live `ContractId` for a given contract. |

### Choices and execution

| Term | Definition |
|---|---|
| **Choice** | An action that can be exercised on a contract by its controller. The body is an `Update` computation that may fetch, create, and archive contracts. |
| **Consuming choice** | A choice that archives its own contract when exercised. The default in Daml. The contract cannot be used again after the choice runs. |
| **Nonconsuming choice** | A choice that leaves its own contract active after execution. Used when the same contract must be exercisable multiple times (e.g. `TokenAdmin`). Declared with the `nonconsuming` keyword. |
| **`Update`** | The monad type for all ledger operations in Daml. A value of type `Update a` represents a ledger action that produces a result of type `a`. Choices return `Update a`. |
| **`fetch`** | An `Update` operation that reads a contract's fields by `ContractId`. Does not consume the contract. The `actAs` parties of the submitting transaction must be stakeholders of the fetched contract. |
| **`lookupByKey`** | An `Update` operation that resolves a contract key to a `ContractId` (returning `Optional (ContractId t)`). Requires the key maintainer to be visible to the submitting transaction — in practice, the submitting party must be an observer or signatory of contracts sharing that maintainer. |
| **`create`** | An `Update` operation that creates a new contract instance on the ledger and returns its `ContractId`. |
| **`archive`** | An `Update` operation that archives a contract by `ContractId`. Equivalent to exercising the built-in `Archive` choice. |
| **`abort`** | Terminates the current `Update` computation with an error, rolling back all ledger changes in the transaction. |
| **`assertMsg`** | Aborts with a given message if a boolean condition is false. Used for precondition checks inside choice bodies. Available from the Daml Prelude without an explicit import. |
| **`ensure`** | A contract-level invariant declared in the template body. If `ensure` evaluates to `False`, the `create` operation aborts. Enforces structural validity on every contract instance. |

### Daml Script

| Term | Definition |
|---|---|
| **Daml Script** | The testing and automation framework for Daml. Replaces the deprecated Scenario API. Scripts run against a simulated or real ledger and are the standard way to write integration tests. |
| **`submit`** | Executes a ledger command as a specific party. Fails the script if the command is rejected. |
| **`submitMustFail`** | Asserts that a ledger command is rejected. Fails the script if the command unexpectedly succeeds. Used to verify negative cases (unauthorized access, violated invariants). |
| **`allocateParty`** | Creates a fresh party in a Script run. Each call returns a distinct `Party` value. |
| **`exerciseCmd`** | Constructs a command to exercise a choice on a contract, for use inside `submit` or `submitMustFail`. |
| **`createCmd`** | Constructs a command to create a contract, for use inside `submit`. |

### This package

| Term | Definition |
|---|---|
| **`TokenConfig`** | Template holding token metadata (name, symbol, tokenId, termsRef, decimals) and lifecycle state (paused, deactivated, totalSupply). Has no contract key — uniqueness (one active instance per token) is a design convention maintained by the `TokenAdmin` choices, not enforced by the ledger. |
| **`Holding`** | Template representing one token holder's balance and freeze state. Keyed by `(issuer, tokenId, owner)` — the ledger enforces that at most one active `Holding` exists per (token, holder) pair. |
| **`TokenAdmin`** | Operational template. Holds no mutable state itself; all choices are `nonconsuming` and delegate to module functions. The stable entry point for all issuer/operator/holder actions. |
| **`isAuthorized`** | Helper function (`Auth.daml`) returning `True` if `actor == issuer` or `actor ∈ operators`. Used as a precondition in all privileged choices. |
| **Module function** | A standalone `Update`-returning function in a `*Module.daml` file (e.g. `doMint`, `doBurn`). Contains the business logic; called by the corresponding `TokenAdmin` choice. Mirrors the CMTAT Solidity module pattern. |
