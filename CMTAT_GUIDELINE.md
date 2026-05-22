# CMTAT Mandatory-Only on Canton: Implementation Guideline

## Scope
This guideline covers only the **mandatory** items from `CMTATSpec.md`:
- Mandatory attributes: `1.a` to `1.e`
- Mandatory functions: `1.1` to `1.10`
- Optional modules (snapshot, dividends, debt, enforcement extras, etc.) are intentionally excluded.

## 1) Canton Design Approach
Implement the token as a Daml package with:
- One **TokenConfig** contract (global metadata and lifecycle state)
- A token-state layer for balances/freeze flags (either per-holder holdings or a ledger/state template)
- An issuer/operator authority model for mint/burn/pause/freeze/deactivate

Important modeling point for Canton:
- Because mandatory CMTAT behavior includes **issuer-authorized cancellation and freeze/unfreeze**, design state so issuer/operator can execute those actions without requiring holder signatures.

## 2) Data Model (Mandatory Attributes)
Create a `TokenConfig` template containing:
- `name : Text` -> requirement `1.a`
- `symbol : Text` -> requirement `1.b`
- `tokenId : Text` (or another immutable unique token identifier) -> requirement `1.c`
- `termsRef : Text` (URL/URI/hash pointer to legal docs) -> requirement `1.d`
- `decimals : Int` -> requirement `1.e`
- `paused : Bool`
- `deactivated : Bool`
- `issuer : Party`
- `operators : [Party]` (or explicit role templates)

Validation for decimals:
- Default to `decimals == 0`.
- If your legal framework explicitly permits fractions, allow non-zero decimals with documented legal justification.

## 3) Balance Model
Store balances as integer quantities tied to `tokenId`, plus a per-account frozen status.

Two valid patterns:
- **Per-holder contracts** (simple, readable)
- **Central token-state contract** (easier issuer-driven administration)

`totalSupply` must be well-defined and auditable, either:
- Derived from balances, or
- Maintained as explicit state with invariants proving consistency.

## 4) Mandatory Function Mapping

### 1.1 `totalSupply`
Expose a read path (query/service/API) returning current total issued outstanding units.

### 1.2 `balanceOf`
Expose a read path returning a holder’s current units.

### 1.3 `transfer`
Implement transfer logic that rejects when:
- Token is paused
- Token is deactivated
- Sender is frozen
- Receiver is frozen
- Amount <= 0 or sender has insufficient balance

On success, debit sender and credit receiver.

### 1.4 `mint`
Issuer/operator-only action that:
- Fails if deactivated
- Increases receiver balance by integer amount

Whether mint while paused is allowed:
- CMTAT Solidity notes indicate mint can be allowed while paused.
- Keep this behavior explicit and test-covered in your Canton version.

### 1.5 `burn`
Issuer/operator-only cancellation path that:
- Fails if deactivated
- Decreases target balance by amount (with sufficient-balance checks)
- Does not require token-holder self-burn capability

### 1.6 `pause`
Issuer/operator-only action:
- Set `paused = True`
- Transfers must fail while paused

### 1.7 `unpause`
Issuer/operator-only action:
- Set `paused = False`

### 1.8 `deactivateContract`
Issuer/admin-only **irreversible** action:
- Set `deactivated = True`
- Permanently disable token operations (at minimum transfer/mint/burn; freeze/unfreeze should also be blocked once deactivated)
- Keep read/query capability available

### 1.9 `freeze`
Issuer/operator-only action:
- Mark account as frozen
- Block transfers both from and to that account

### 1.10 `unfreeze`
Issuer/operator-only action:
- Clear account frozen status

## 5) Authorization Model
Minimum roles:
- `issuer` (ultimate authority)
- `operator` (delegated operational permissions)
- optional `admin` (if distinct from issuer)

Enforce role checks on privileged operations: `mint`, `burn`, `pause`, `unpause`, `freeze`, `unfreeze`, `deactivateContract`.

## 6) Required Invariants
- `name`, `symbol`, `tokenId`, `termsRef` remain well-defined
- `decimals` policy is enforced (`0` by default; legal exception explicitly governed)
- No negative balances
- Supply consistency (sum of balances and reported total supply align)
- No transfer while paused
- No transfer to/from frozen accounts
- No state-changing token operations after deactivation

## 7) Minimal Daml Skeleton (Illustrative Pseudocode)
Use this only as a shape reference; production code should centralize policy checks and avoid duplicated logic.

```daml
template TokenConfig
  with
    issuer : Party
    operators : [Party]
    name : Text
    symbol : Text
    tokenId : Text
    termsRef : Text
    decimals : Int
    paused : Bool
    deactivated : Bool
  where
    signatory issuer

    ensure decimals >= 0
    -- Enforce decimals==0 unless legal exception policy is enabled in your implementation.

    choice Pause : ContractId TokenConfig
      controller issuer
      do
        assertMsg "deactivated" (not deactivated)
        create this with paused = True

    choice Unpause : ContractId TokenConfig
      controller issuer
      do
        assertMsg "deactivated" (not deactivated)
        create this with paused = False

    choice Deactivate : ContractId TokenConfig
      controller issuer
      do create this with deactivated = True
```

## 8) Testing Checklist (Mandatory Coverage)
- Config creation enforces your decimals policy (`0` default; legal-exception path if supported)
- Mint increases holder balance and total supply
- Burn decreases holder balance and total supply
- Transfer updates balances and preserves total supply
- Pause blocks all transfers
- Unpause re-enables transfers
- Freeze blocks outbound and inbound transfers for frozen accounts
- Unfreeze restores transfer ability
- Deactivate permanently blocks state-changing token operations
- Role/permission tests for every privileged operation

## 9) Compliance Evidence Table
When you implement, fill `CMTATSpec.md` mandatory rows with:
- `y/n`
- exact module/template/choice names
- test case IDs proving each requirement

## 10) Practical Notes for Canton
- Keep metadata immutable except explicit operational flags.
- Store legal document hash/URI in `termsRef`; keep full legal text off-ledger if required.
- If you use per-holder contracts, ensure your stakeholder/controller model still allows issuer-authorized freeze/burn per CMTAT requirements.

---
This is an engineering guideline, not legal advice. Validate final behavior against your jurisdiction’s security-token rules.
