# Minimal Account Abstraction

An ERC-4337 compliant smart contract wallet implementation built with Foundry. Demonstrates core account abstraction concepts: custom signature validation, EntryPoint integration, and on-chain execution.

## How It Works

```
User signs UserOperation
        ↓
EntryPoint calls validateUserOp()
        ↓
MinimalAccount verifies ECDSA signature against owner
        ↓
EntryPoint calls execute() to run the transaction
```

## Contract

**`MinimalAccount.sol`**
- Implements `IAccount` (ERC-4337 interface)
- ECDSA signature validation — only the owner can authorize transactions
- `execute()` — runs arbitrary calls to any address, callable by owner or EntryPoint
- `validateUserOp()` — validates signature and prefunds EntryPoint for gas

## Key Concepts

| Concept | Description |
|---------|-------------|
| EntryPoint | Singleton contract that orchestrates all ERC-4337 transactions |
| UserOperation | Struct containing transaction data + signature |
| `missingAccountFunds` | ETH the wallet must send to EntryPoint to cover gas |
| ECDSA validation | `recover(ethSignedHash, signature) == owner` |

## Running Tests

```bash
forge install
forge test
```

**8 tests** covering: owner signature validation, non-owner rejection, execute access control, fuzz testing, and invariant testing (128,000+ calls).

## Deploy

```bash
# Local
forge script script/DeployMinimalAccount.s.sol --rpc-url http://localhost:8545 --broadcast

# Sepolia
forge script script/DeployMinimalAccount.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## Tech Stack

- Solidity 0.8.24
- Foundry
- ERC-4337 (`eth-infinitism/account-abstraction`)
- OpenZeppelin (ECDSA, Ownable)
