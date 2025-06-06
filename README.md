# GiveRep Claim

A Sui Move smart contract for token distribution through a pool-based claim system with multi-level access control.

## Overview

GiveRep Claim enables organizations to distribute tokens efficiently on the Sui blockchain through:
- **Pool Management**: Create and manage token pools for different distribution campaigns
- **Access Control**: Multi-tier permissions (Super Admins → Managers → Users)
- **Sponsored Claims**: Managers approve user claims through Sui's sponsored transaction feature
- **Claim Tracking**: Prevents double-claims and tracks distribution history

## Features

- ✅ Generic pool system supporting any token type
- ✅ Hierarchical access control
- ✅ Sponsored transaction support
- ✅ Event emission for all operations
- ✅ Comprehensive test coverage
- ✅ TypeScript SDK generation

## Installation

```bash
# Clone the repository
git clone https://github.com/your-org/giverep_claim.git
cd giverep_claim

# Build the Move package
sui move build

# Run tests
sui move test
```

## Usage

### For Smart Contract Developers

```move
// Example: Creating a pool
public entry fun create_pool<T>(
    cap: &SuperAdminCap,
    manager: address,
    ctx: &mut TxContext
)

// Example: Claiming tokens
public entry fun claim<T>(
    pool: &mut Pool<T>,
    sponsored_claim: SponsoredClaim,
    ctx: &mut TxContext
)
```

### For TypeScript/JavaScript Developers

```typescript
// Import the generated SDK
import { GiveRepClaim } from './GiveRepClaim';

// Use the SDK to interact with the contract
// (SDK documentation available in GiveRepClaim/README.md)
```

## Architecture

The system consists of three main components:

1. **SuperAdmin**: Global administrators who can:
   - Create new pools
   - Add/remove other super admins
   - Delete empty pools

2. **Pool<T>**: Token distribution pools that:
   - Hold tokens of a specific type
   - Track balances and claims
   - Are managed by designated managers

3. **Claim System**: Enables:
   - Managers to approve claims for users
   - Sponsored transactions (sponsor ≠ manager)
   - One-time claims per user per pool

## Development

### Building

```bash
# Standard build
sui move build

# Build with bytecode output
sui move build --dump-bytecode-as-base64 --path .
```

### Testing

```bash
# Run all tests
sui move test

# Run specific test
sui move test --filter test_create_pool

# Run with coverage
sui move test --coverage
```

### Code Generation

Generate TypeScript bindings:
```bash
# Configure in GiveRepClaim/gen.toml
# Then run generation command (see gen.toml for details)
```

## Deployment

### Mainnet

- **Package ID**: `0xeff887fb31a8c019cdb6716633ed7b4929b7c6c59eb0e278c08a3547ab358654`
- **RPC Endpoint**: `https://fullnode.mainnet.sui.io:443`

## Security Considerations

- Super admins cannot remove the last super admin (prevents lockout)
- Managers cannot be removed if they're the last manager of a pool
- Claims require proper authorization through sponsored transactions
- Pool deletion requires zero balance and no pending claims

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[Your License Here]

## Contact

[Your Contact Information]