# Private Policy — Privacy-Preserving Programmable Spending Limits

**BRAINWAVE 2026 — Special Blockchain Track**

**Team:** TeamX  
**Team Leader:** Bhise Pavankumar Dattatray  
**College:** M. S. Bidve Engineering College, Latur

## 1. Overview

Private Policy is a privacy-preserving programmable spending policy implemented as an Aztec.nr smart contract. It allows an account owner to configure a daily spending limit and enforces that limit inside private contract execution.

The prototype tracks three private values per owner:

- `daily_limit` — configured spending limit.
- `spent_today` — cumulative amount spent during the current 24-hour period.
- `last_reset_timestamp` — start timestamp of the current 24-hour period.

## 2. Problem

Blockchain applications often need spending guardrails for wallets, treasury accounts and controlled payments. A conventional implementation can expose policy state or require a centralized service to enforce the rules.

The goal is to enforce programmable spending constraints while keeping the policy state in private contract storage.

## 3. Proposed Solution

The contract provides private functions to initialize and update a policy and to perform a spend operation.

For each spend request, the contract:

1. Identifies the owner from the private message sender.
2. Reads the owner's private daily limit.
3. Reads the current period's private spending total and reset timestamp.
4. Checks whether 24 hours have elapsed.
5. Starts a new period when required, otherwise accumulates spending.
6. Rejects the request when the resulting spend exceeds the daily limit.

## 4. Contract Functions

### Private functions

- `constructor()` — contract initializer.
- `initialize_policy(daily_limit)` — initializes the owner's private policy.
- `update_policy(new_daily_limit)` — updates the owner's private limit.
- `spend(amount)` — enforces the daily spending policy.

### Utility functions

- `get_daily_limit(owner)`
- `get_spent_today(owner)`
- `get_last_reset_timestamp(owner)`
- `get_policy_status(owner)`

## 5. Enforcement Logic

The contract uses a 24-hour period represented by 86,400 seconds.

If the period has not expired:

`new_spent = previous_spent + amount`

and the contract requires:

`new_spent <= daily_limit`

If the period has expired, the contract resets the period and requires:

`amount <= daily_limit`

A failing assertion rejects the transaction.

## 6. Technology Stack

- Aztec Protocol
- Aztec.nr / Noir
- Private smart-contract functions
- `PrivateMutable` private state
- `UintNote`
- Aztec Wallet CLI
- Aztec Local Network
- GitHub Codespaces

Prototype environment used Aztec v5.0.1.

## 7. Prototype Validation

The prototype was deployed and exercised on the local Aztec network. The following behavior was tested:

- Policy initialized with a daily limit of 5000.
- Spending transactions were submitted successfully while within the configured limit.
- A subsequent spend simulation failed with `Daily spending limit exceeded` once cumulative spending exceeded the limit.
- Utility calls returned the configured policy state, including a 5000 daily limit.
- Aztec local-network epoch/time tooling was explored for testing period-reset behavior.

The rejection is enforced by the contract itself rather than by an external application check.

## 8. Impact and Future Scope

Private Policy can be extended for:

- wallet spending controls;
- DAO and treasury policies;
- role-based spending limits;
- merchant/category limits;
- emergency spending freezes;
- multiple policy windows;
- programmable authorization rules.

## 9. Repository Structure

The core contract is located at:

`policy_contract/policy_contract_contract/src/main.nr`

## 10. Project Links

Repository: https://github.com/pone-dev/private-policy-poc

Documentation: this README

## 11. BRAINWAVE Submission

This project is submitted under the Special Blockchain Track. The presentation follows the official BRAINWAVE 2026 submission structure and describes the problem, solution, methodology, feasibility, features, technology stack, impact and sources.
