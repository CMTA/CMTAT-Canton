# CMTAT Equivalency Assessment Criteria (Canton Implementation)

Source template: `submodules/CMTAT-equivalency-assessment/README.md` (v0.2.0).

## Table of Contents

- [Document Version](#document-version)
- [How to Use This Document](#how-to-use-this-document)
- [General Note](#general-note)
- [Warning](#warning)
- [CMTAT Function Equivalency Table](#cmtat-function-equivalency-table)
  - [Metadata](#metadata)
  - [Token Attributes](#token-attributes)
    - [Token module](#token-module)
  - [Pause module (mandatory)](#pause-module-mandatory)
    - [Enforcement](#enforcement)
    - [Transfer restriction (optional)](#transfer-restriction-optional)
    - [Access Control](#access-control)
    - [Snapshot (optional)](#snapshot-optional)
    - [Dividend (optional)](#dividend-optional)
    - [Credit Events (optional)](#credit-events-optional)
  - [Debt (optional)](#debt-optional)
- [Guideline for New Blockchain Implementations](#guideline-for-new-blockchain-implementations)
  - [Freeze](#freeze)
  - [CMTAT Extended](#cmtat-extended)
  - [Forced Burn and Forced Transfer](#forced-burn-and-forced-transfer)
  - [Implementation Details](#implementation-details)
  - [Self-Burn](#self-burn)
- [Supplementary features](#supplementary-features)
- [Reference](#reference)

## Document Version
`v0.2.0`

Note:

- versions with the `rc` suffix are draft versions.
- version before `1.0` are also draft versions

## How to Use This Document
- Use the **CMTAT Function Equivalency Table** as the filled assessment checklist for this repository.
- Use **Guideline for New Blockchain Implementations** as reference guidance.

## General Note
- The listed functionalities are the **minimal set** required for each module.
- The key words "MUST", "MUST NOT", "REQUIRED", "SHOULD", and "MAY" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/info/rfc2119) and [RFC 8174](https://www.rfc-editor.org/info/rfc8174).

## Warning
An implementation MAY satisfy the CMTAT standard while still failing to meet the criteria required for tokenized shares under Swiss law at the underlying-ledger level. In particular, compliance with CMTAT does not, by itself, demonstrate that decentralization-related legal criteria are satisfied.

## CMTAT Function Equivalency Table

### Metadata
- Implementation language: `Daml (Canton)`
- Implementation version: `Repository state as of 2026-05-12`

### Token Attributes
#### Mandatory
| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 1 | Name attribute | ERC20 `name` | Public (`view`) |  | y | `TokenConfig` visibility (stakeholders/observers) | `TokenConfig.name` in `src/Cmtat/Mandatory/TokenConfig.daml`. |
| 2 | Ticker symbol attribute | ERC20 `symbol` | Public (`view`) |  | y | `TokenConfig` visibility (stakeholders/observers) | `TokenConfig.symbol` in `src/Cmtat/Mandatory/TokenConfig.daml`. |
| 3 | Reference to legally required documentation | `terms` | Public (`view`) |  | y | `TokenConfig` visibility (stakeholders/observers) | `TokenConfig.termsRef` in `src/Cmtat/Mandatory/TokenConfig.daml`. |
| 4 | No fractions | ERC20 `decimals` | Public (`view`) | - Decimals must be set to zero unless governing law permits fractions.<br />- CMTAT Solidity allows configurable decimals at deployment | y | Enforced at template `ensure` constraints | `decimals == 0 \|\| allowFractional` enforced in `TokenConfig` ensure clause. |

For CMTAT reference implementations, decimals SHOULD be configurable rather than defaulting to zero, to support use cases beyond tokenized shares in Switzerland.

##### Note

> This subsection can be used to detail how mandatory token attributes are implemented and to document specific legal, business, or chain-specific cases.

#### Optional
| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 5 | Token ID attribute | `tokenId` | Public (`view`) | Optional parameter. | y | `TokenConfig`/`TokenAdmin` visibility | `tokenId` exists in `TokenConfig`, `TokenAdmin`, and `Holding` keying. |

For CMTAT reference implementations, `tokenId` SHOULD be included.

##### Note

> This subsection can be used to detail optional token attributes implemented by the target system and to explain specific cases where an optional field is omitted or represented differently.

#### Token module

##### Mandatory

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 6 | Know total supply | ERC20 `totalSupply` | Public (`view`) |  | y | Choice controller `actor` with contract visibility | `TokenConfig.TotalSupplyOf` returns `totalSupply`. |
| 7 | Know balance | ERC20 `balanceOf` | Public (`view`) |  | y | Choice controller `actor` with contract visibility | `TokenAdmin.BalanceOf` returns holder balance (or `0` if absent). |
| 8 | Transfer tokens | ERC20 `transfer` | Token holder (`msg.sender`) |  | y | Holder-initiated (`controller actor`) | `TokenAdmin.Transfer` debits `actor`, credits `to`; checks paused/deactivated/frozen/amount/balance. |
| 9 | Create tokens | `mint` / `batchMint` | Role-restricted (issuer/minter authorized) |  | y | Issuer or operator (`isAuthorized`) | `TokenAdmin.Mint` with `isAuthorized actor issuer operators`. |
| 10 | Cancel tokens | `burn` / `batchBurn` / `burnFrom` | Role-restricted (issuer/burner authorized) | Implementations SHOULD use a dedicated issuer/authorized burn path for forced cancellation scenarios. | y | Issuer or operator (`isAuthorized`) | `TokenAdmin.Burn` burns from target holder when authorized. |

#### Optional

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 11 | Approve | ERC20 `approve(address spender, uint256 value)` | Token holder | Grants a delegate permission to transfer a specific amount of tokens from the token account. This is optional, but implementations SHOULD include it since secondary market capability may depend on delegated approval to automate trading and settlement for regulated entities. Issuers SHOULD consult relevant trading and settlement venues if listing is contemplated. | n | N/A | No allowance/delegated transfer mechanism in current Canton scope. |

##### Note

> This subsection can be used to detail how each mandatory function is implemented, including role model, execution flow, and specific chain-level behavior.

### Pause module (mandatory)

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 12 | Pause tokens | `pause` | Role-restricted (pauser/admin authorized) | Pause must prevent all transfers until `unpause` is called. | y | Issuer or operator (`isAuthorized`) | `TokenConfig.Pause`; `TokenAdmin.Transfer` enforces `not cfg.paused`. |
| 13 | Unpause tokens | `unpause` | Role-restricted (pauser/admin authorized) |  | y | Issuer or operator (`isAuthorized`) | `TokenConfig.Unpause`. |
| 14 | Deactivate contract | `deactivateContract` | Role-restricted (admin authorized) | Must permanently disable the token (except in upgradeability patterns where deactivation behavior is explicitly defined). | y | Issuer or operator (`isAuthorized`) | `TokenConfig.Deactivate`; state-changing ops assert `not cfg.deactivated`. |

#### Enforcement

#### Mandatory

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 15 | Freeze | `freeze` or `setAddressFrozen(true)` *(inferred from extracted PDF text)* | Role-restricted (compliance/admin authorized) | Must block transfers to and from a given address. Single-function implementations are acceptable if they set a frozen status. | y | Issuer or operator (`isAuthorized`) | `TokenAdmin.Freeze` sets `Holding.frozen = True`; transfer blocks if sender/receiver frozen. |
| 16 | Unfreeze | `unfreeze` or `setAddressFrozen(false)` *(inferred from extracted PDF text)* | Role-restricted (compliance/admin authorized) | Single-function implementations are acceptable if they clear a frozen status. | y | Issuer or operator (`isAuthorized`) | `TokenAdmin.Unfreeze` sets `Holding.frozen = False`. |

#### Optional

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 17 | Enforce a transfer | `forcedTransfer(address from, address to, uint256 value)` | Role-restricted (operator/compliance authorized) | Enforcement transfer is performed via `forcedTransfer`. | n | N/A | Not implemented. |
| 18 | Partial freeze | `freezePartialTokens(address account, uint256 value)` / `unfreezePartialTokens(address account, uint256 value)` | Role-restricted (operator/compliance authorized) | Intended only to block a sold amount to avoid double-spend during settlement. | n | N/A | Not implemented. |

#### Transfer restriction (optional)

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 19 | Conditional transfer request | `RuleConditionalTransferLight.detectTransferRestriction(from, to, value)` / `detectTransferRestrictionFrom(spender, from, to, value)` and `approvedCount(from, to, value)` | Public (`view`) | Request is represented by a transfer restricted until approval count is non-zero. | n | N/A | Not implemented. |
| 20 | Conditional transfer approval | `RuleConditionalTransferLight.approveTransfer(from, to, value)` (or `approveAndTransferIfAllowed`) | Role-restricted (compliance/approver authorized) | Approval is consumed on transfer via `transferred(...)`; cancellation via `cancelTransferApproval(...)`. | n | N/A | Not implemented. |
| 21 | Assign to whitelist | CMTAT Allowlist: `setAddressAllowlist(account, status)`, `batchSetAddressAllowlist(accounts, status)`, `isAllowlisted(account)`; Rules whitelist: `addAddress`, `removeAddress`, `addAddresses`, `removeAddresses`, `isAddressListed` | Role-restricted for setters; public (`view`) for checks | CMTAT Allowlist and Rules whitelist are alternative whitelist implementations. | n | N/A | No allowlist module in current scope. |

##### Note

> This subsection can be used to detail the different transfer restrictions available.

#### Access Control

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 22 | Grant role | `grantRole(bytes32 role, address account)` (OpenZeppelin AccessControl via CMTAT/Rules modules) | Role admin (`DEFAULT_ADMIN_ROLE` or role admin) | Used for roles such as `ALLOWLIST_ROLE`, `DEBT_ROLE`, `OPERATOR_ROLE`, `COMPLIANCE_MANAGER_ROLE`. | n | N/A | No dynamic RBAC; static `issuer` + `operators` list in contracts. |
| 23 | Revoke role | `revokeRole(bytes32 role, address account)` | Role admin (`DEFAULT_ADMIN_ROLE` or role admin) | AccessControl role removal. | n | N/A | No dynamic RBAC; roles are not mutable via dedicated choice. |
| 24 | Role attribution | `hasRole(bytes32 role, address account)` / `getRoleAdmin(bytes32 role)` | Public (`view`) | In CMTAT `AccessControlModule`, `DEFAULT_ADMIN_ROLE` is treated as having all roles in `hasRole`. | n | N/A | No `hasRole` interface; authorization via `isAuthorized`. |

##### Note

> This subsection can be used to detail the concrete authorization model (roles, admins, delegates, approvers) and implementation-specific exceptions. It MAY also be relevant to explain how access control works in the implementation being approved.

**Note (How Access Control Works in Canton/Daml):**
- Access to state changes is enforced by Daml `controller` declarations on choices, not by `msg.sender`.
- Contract visibility is governed by `signatory` and `observer` parties.
- In this implementation, privileged actions additionally check `isAuthorized actor issuer operators` (issuer or listed operator).
- There is no on-ledger dynamic RBAC module (`grantRole`/`revokeRole`) in the current scope; role-like permissions come from contract data (`issuer`, `operators`) and choice logic.

#### Snapshot (optional)
| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 25 | Schedule a snapshot | `scheduleSnapshot(uint256 time)` | Role-restricted (snapshot scheduler/admin authorized) | SnapshotEngine `ISnapshotScheduler`. | n | N/A | Not implemented. |
| 26 | Reschedule a snapshot | `rescheduleSnapshot(uint256 oldTime, uint256 newTime)` | Role-restricted (snapshot scheduler/admin authorized) | `newTime` must stay between adjacent scheduled snapshots (not before previous / not after next). | n | N/A | Not implemented. |
| 27 | Unschedule a snapshot | `unscheduleLastSnapshot(uint256 time)` / `unscheduleSnapshotNotOptimized(uint256 time)` | Role-restricted (snapshot scheduler/admin authorized) | `unscheduleLastSnapshot` is restricted to the latest scheduled snapshot; `unscheduleSnapshotNotOptimized` supports generic unscheduling. | n | N/A | Not implemented. |
| 28 | Snapshot time | `getAllSnapshots()` / `getNextSnapshots()` | Public (`view`) | Returns created snapshot times and pending scheduled times. | n | N/A | Not implemented. |
| 29 | Snapshot total supply | `snapshotTotalSupply(uint256 time)` | Public (`view`) | `ISnapshotState`. | n | N/A | Not implemented. |
| 30 | Snapshot balance | `snapshotBalanceOf(uint256 time, address tokenHolder)` | Public (`view`) | `ISnapshotState` (see also `snapshotInfo`). | n | N/A | Not implemented. |
##### Note
> This subsection can be used to detail snapshot scheduling and query behavior, including timing constraints and permission specifics.

#### Dividend (optional)

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 31 | Distribution create parameters |  |  |  | n | N/A | Not implemented. |
| 32 | Distribution set eligibility |  |  |  | n | N/A | Not implemented. |
| 33 | Distribution set deposit |  |  |  | n | N/A | Not implemented. |
| 34 | Distribution claim deposit |  |  |  | n | N/A | Not implemented. |
| 35 | Distribution schedule |  |  |  | n | N/A | Not implemented. |
| 36 | Distribution unschedule |  |  |  | n | N/A | Not implemented. |
##### Note
> This subsection can be used to detail dividend/distribution workflow specifics and jurisdiction- or product-specific handling rules.
> No direct CMTAT Solidity equivalent is currently defined for these items; they are implementation-specific. However, a prototype is available on the CMTA GitHub organization: https://github.com/CMTA/IncomeVault

#### Credit Events (optional)
| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 37 | Flag as default | `setCreditEvents(CreditEvents)` -> `creditEvents().flagDefault` | Role-restricted (issuer/compliance/admin authorized) | Managed in `ICMTATCreditEvents.CreditEvents`. | n | N/A | Not implemented. |
| 38 | Remove default flag | `setCreditEvents(CreditEvents)` with `flagDefault = false` | Role-restricted (issuer/compliance/admin authorized) | Same function as ID 37 with different value. | n | N/A | Not implemented. |
| 39 | Flag as redeemed | `setCreditEvents(CreditEvents)` -> `creditEvents().flagRedeemed` | Role-restricted (issuer/compliance/admin authorized) | Managed in `ICMTATCreditEvents.CreditEvents`. | n | N/A | Not implemented. |
| 40 | Set rating | `setCreditEvents(CreditEvents)` -> `creditEvents().rating` | Role-restricted (issuer/compliance/admin authorized) | Managed in `ICMTATCreditEvents.CreditEvents`. | n | N/A | Not implemented. |
##### Note
> This subsection can be used to detail how credit event states are updated, governed, and audited in the implementation being approved.

### Debt (optional)
| ID | Attribute | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 41 | Guarantor identifier | `debt().debtIdentifier.guarantor` (set via `setDebt`) | Read: public (`view`); write: role-restricted (`setDebt`) | Debt module (`ICMTATDebt.DebtIdentifier`). | n | N/A | Debt module not implemented. |
| 42 | Debtholder representative identifier | `debt().debtIdentifier.debtHolder` (set via `setDebt`) | Read: public (`view`); write: role-restricted (`setDebt`) | Debt module (`ICMTATDebt.DebtIdentifier`). | n | N/A | Debt module not implemented. |
| 43 | Unique identifier / hash | `tokenId()` and `terms().doc.documentHash` | Public (`view`) | `tokenId` is optional (implementations MAY omit it); document hash is in `terms` metadata. | y (partial) | Contract visibility based | `tokenId` implemented; explicit document hash field not implemented (`termsRef` text present). |
| 44 | Issuance date | `debt().debtInstrument.issuanceDate` (set via `setDebt` / `setDebtInstrument`) | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`ICMTATDebt.DebtInstrument`). | n | N/A | Debt module not implemented. |
| 45 | Currency of payments | `debt().debtInstrument.currency` / `debt().debtInstrument.currencyContract` | Read: public (`view`); write: role-restricted (`setDebt*`) | Supports symbol-like string and token/asset contract address. | n | N/A | Debt module not implemented. |
| 46 | Par value | `debt().debtInstrument.parValue` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`uint256`). | n | N/A | Debt module not implemented. |
| 47 | Minimum denomination | `debt().debtInstrument.minimumDenomination` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`uint256`). | n | N/A | Debt module not implemented. |
| 48 | Maturity date | `debt().debtInstrument.maturityDate` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | N/A | Debt module not implemented. |
| 49 | Interest rate | `debt().debtInstrument.interestRate` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`uint256`). | n | N/A | Debt module not implemented. |
| 50 | Coupon payment frequency | `debt().debtInstrument.couponPaymentFrequency` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | N/A | Debt module not implemented. |
| 51 | Interest schedule format: A) start date/end date/period; B) start date/end date/day of period; C) date 1/date 2/date 3 | `debt().debtInstrument.interestScheduleFormat` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | N/A | Debt module not implemented. |
| 52 | Interest payment date: A) period; B) specific date | `debt().debtInstrument.interestPaymentDate` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | N/A | Debt module not implemented. |
| 53 | Day count convention | `debt().debtInstrument.dayCountConvention` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | N/A | Debt module not implemented. |
| 54 | Business day convention | `debt().debtInstrument.businessDayConvention` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | N/A | Debt module not implemented. |
##### Note
> This subsection can be used to detail supplementary attributes and to explain specific representation or governance choices made by the implementation being approved.

## Guideline for New Blockchain Implementations

If you create a version for another blockchain, use this section to build a correspondence table between the CMTAT framework, the CMTAT Solidity version, and your implementation.

### Freeze

To be compatible with [ERC-3643](https://eips.ethereum.org/EIPS/eip-3643), freeze is implemented with a single function: `setAddressFrozen(targetAddress, frozenStatus)`.

For non-EVM blockchains, implementations MAY separate this into two distinct functions:

```solidity
freeze(address targetAddress)
unfreeze(address targetAddress)
```

##### Note

> This Canton implementation separates freeze into two explicit choices (`Freeze` and `Unfreeze`), consistent with the non-EVM option above.

### CMTAT Extended

In the table below, the CMTAT framework extended features are mapped to Solidity features.

| CMTAT Functionalities | CMTAT Solidity corresponding features | CMTAT Allowlist | CMTAT Light | CMTAT Debt | CMTAT Standard | Present in implementation being approved (`y/n`) | Implementation details |
|---|---|---|---|---|---|---|---|
| On-chain snapshot | `snapshotModule` and `snapshotEngine` | ✔ | ✘ | ✔ | ✔ | n | Not implemented. |
| Forced transfer | `forcedTransfer` | ✔ | ✘ | ✔ | ✔ | n | Not implemented. |
| Forced burn | `forcedBurn` | ✘ | ✔ | ✘ | ✘ | n | Not implemented. |
| Freeze partial token | `freezePartialTokens` / `unfreezePartialTokens` | ✔ | ✘ | ✔ | ✔ | n | Not implemented. |
| Integrated whitelisting/allowlisting | CMTAT Allowlist | ✔ | ✘ | ✘ | ✘ | n | Not implemented. |
| External whitelisting/allowlisting | CMTAT with rule whitelist | ✘ | ✘ | ✔ | ✔ | n | Not implemented. |
| RuleEngine / transfer hook | CMTAT with RuleEngine | ✘ | ✘ | ✔ | ✔ | n | Not implemented. |
| Upgradeability | CMTAT Upgradeable version | ✔ | ✔ | ✔ | ✔ | n | Not implemented (no proxy pattern in this package). |
| Fee payer / gasless | CMTAT with ERC-2771 module | ✔ | ✘ | ✘ | ✔ | n | Not applicable to Canton execution model; not implemented. |

##### Note

> This section can be used to detail supplementary features implemented beyond the mandatory baseline and specific cases in the target chain.
> For non-EVM blockchains, it MAY be relevant to explain how gasless/gas sponsorship and upgradeability work in the particular blockchain targeted.

#### Upgradeability in Canton

In Canton/Daml, upgradeability is package-version evolution: you publish a new compatible DAR, run old and new versions side by side during transition, and migrate contracts only where business or data-shape changes require it, instead of swapping logic behind an EVM proxy.

- There is no Solidity proxy pattern in this package. We are on Canton/Daml (not EVM), so upgrades are done at the Daml package (DAR) level.
- Smart Contract Upgrade (SCU) applies when the new DAR is a valid upgrade of the previous DAR in the same package lineage.
- Keep `daml.yaml` package `name` stable across versions, bump `version`, and use the `upgrades:` field so build-time compatibility checks are enforced.
- Uploading a new DAR is non-destructive: old and new package versions can coexist, and mixed-version operation is expected until old contracts are archived/migrated.
- Existing contracts are not bulk-rewritten. Runtime upgrade/downgrade semantics apply when contracts are fetched/exercised.
- New choices/features on existing contracts require relevant participant/validator package availability and vetting for stakeholders.
- If your change is not SCU-compatible, or you need explicit data transformation, implement migration workflows/choices that archive old contracts and create new-version contracts (signatory-authorized).
- Practical process to add new features in Canton:
  1. Keep package `name`, bump `version`, add `upgrades:` to prior DAR, and implement SCU-compatible changes.
  2. Run upgrade compatibility checks and integration tests (type-level and workflow-level).
  3. Upload and vet the new DAR on participant nodes involved in stakeholder workflows.
  4. Roll out backends/frontends to support mixed-version operation.
  5. For contracts requiring transformation, execute migration choices/scripts (archive+create) in controlled batches.
  6. Retire v1 paths only after migration completion and stakeholder readiness.

#### Gas / fee payer model in Canton

- Canton does not have EVM gas metering or ERC-2771-style meta-transaction fee sponsorship.
- Execution/operational costs are participant and infrastructure concerns (node/domain operation), not per-transaction gas paid by end users in the EVM sense.
- Therefore, "gasless" in the ERC-2771 meaning is not a direct concept in this Canton implementation.

### Forced Burn and Forced Transfer

In the standard burn function, tokens from a frozen wallet MUST NOT be burnable. CMTAT offers `forcedTransfer` to force a transfer or a burn.

If `forcedTransfer` is not available, implementations MAY implement only `forcedBurn` (as in CMTAT Light). Implementations MAY also implement both. In that case, only `forcedBurn` SHOULD burn tokens, and `forcedTransfer` SHOULD NOT burn tokens.

With the CMTAT Solidity version, when `forcedTransfer` is available, `forcedBurn` is not implemented to reduce contract code size. This limitation MAY not apply to other blockchains.

##### Note

> This Canton implementation does not include `forcedTransfer` or `forcedBurn` in the current scope. Authorized burn via `Burn` is available, but a dedicated forced-transfer enforcement path is out of scope.

### Implementation Details

| Functionalities | CMTAT Solidity | Access Control (CMTAT Solidity) | Note | Present in implementation being approved (`y/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|
| Mint while pause | ✔ | Role-restricted (minter/issuer authorized) | Dedicated cross-chain mint (for example `crosschainMint`) cannot be performed while paused. | y | Issuer/operator via `isAuthorized` | `Mint` does not check `paused`; it checks `not deactivated`. |
| Burn while pause | ✔ | Role-restricted (burner/issuer authorized) | Dedicated cross-chain burn (for example `crosschainBurn`) cannot be performed while paused. | y | Issuer/operator via `isAuthorized` | `Burn` does not check `paused`; it checks `not deactivated`. |
| Self-Burn for everyone | ✘ | Not permitted | Token holders cannot burn their own tokens; only authorized addresses can burn. | n | N/A | No holder self-burn choice. |
| Self-Burn for authorized addresses | ✔ | Role-restricted (authorized burner) |  | y | Issuer/operator via `isAuthorized` | Authorized actor can burn holder balance via `Burn`. |
| Standard burn on a frozen address | ✘ | Not permitted in standard burn path | Requires `forcedTransfer` or `forcedBurn`. | y (behavior differs) | Issuer/operator via `isAuthorized` | `Burn` currently has no frozen-check, so authorized burn from frozen holding is possible. |
| Burn tokens with `forcedTransfer` | ✔ | Role-restricted (operator/compliance authorized) | See notes above. | n | N/A | `forcedTransfer` is not implemented. |

### Self-Burn

Only the issuer and authorized addresses (not the token holder) can burn a token in CMTAT Solidity, which reflects legal requirements in several jurisdictions.

Once issued, a security can only be cancelled by its issuer, not its holder. Since the token represents the security, the same rule applies. An investor who wants to exit should transfer to the issuer, who can then cancel when legally permitted.

You MAY still add self-burn in your version if it fits your legal or business context.

## Supplementary features

> This section MAY be used to document supplementary features beyond the CMTAT standard that are present in the implementation being approved.

- Canton/Daml privacy is party-scoped (stakeholder/observer visibility), unlike fully public EVM state.
- Authorization model is explicit in choices (`controller`) plus `isAuthorized` helper.
- Lifecycle model uses immutable contract updates (archive + recreate).

## Reference

Submodules used in this project and current checked-out versions:

| Submodule | Repository | Version | Commit |
|---|---|---|---|
| CMTAT | https://github.com/CMTA/CMTAT | `v3.2.0` | `49544f4de1993008acfc9e848d0bf03bd31d8579` |
| CMTAT-equivalency-assessment | https://github.com/CMTA/CMTAT-equivalency-assessment | `v0.2.0` | `a0b5f516447aec9dea51b48c420817e0b821de5d` |
| CMTAT-Confidential | https://github.com/CMTA/CMTAT-Confidential | `v0.2.0` | `99fb89bc1331edaeaf662546dcb81f3acfe7be2e` |
