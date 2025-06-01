# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Sui Move smart contract project called `giverep_claim` that implements a token claim system with pool management. The system allows super admins to create pools that managers can operate, enabling sponsored token claims through the Sui blockchain.

## Architecture

### Core Components

- **SuperAdmin**: Global administrative authority that can create pools and manage other super admins
- **Pool<T>**: Generic pools that hold tokens of type T, managed by designated managers
- **Claim System**: Uses Sui's sponsored transaction feature where managers approve claims for users

### Key Features

- Multi-level access control (super admins → managers → users)
- Pool-based token distribution with balance tracking
- Claim tracking to prevent double-claims per user per pool
- Manager and super admin management functions
- Event emission for all major operations

## Development Commands

### Building and Testing
```bash
# Build the Move package
sui move build

# Run all tests
sui move test

# Run specific test
sui move test --filter test_name

# Build with verbose output
sui move build --dump-bytecode-as-base64 --path .
```

### Code Generation
The project uses Sui TypeScript SDK generation:
```bash
# Generate TypeScript bindings (if gen.toml is properly configured)
# Configuration is in GiveRepClaim/gen.toml
```

## File Structure

- `sources/giverep_claim.move` - Main smart contract implementation
- `tests/giverep_claim_tests.move` - Comprehensive test suite
- `Move.toml` - Package configuration and dependencies
- `GiveRepClaim/` - Generated TypeScript SDK files
- `GiveRepClaim/gen.toml` - Configuration for TypeScript generation

## Testing Patterns

The test suite follows these patterns:
- Uses `sui::test_scenario` for transaction simulation
- Constants for test addresses (ADMIN1, MANAGER1, USER1, etc.)
- Helper functions: `setup_test()` and `mint_for_testing()`
- Tests both success cases and expected failures with `#[expected_failure]`
- Comprehensive coverage of authorization logic

## Key Constraints

- Super admins cannot remove the last super admin
- Managers cannot be removed if they're the last manager of a pool
- Claims require sponsored transactions (sponsor != manager)
- Users cannot claim twice from the same pool
- Pool deletion requires zero balance and empty claim table

## Deployment Information

The contract is deployed on Sui mainnet:
- Package ID: `0xeff887fb31a8c019cdb6716633ed7b4929b7c6c59eb0e278c08a3547ab358654`
- RPC endpoint: `https://fullnode.mainnet.sui.io:443`