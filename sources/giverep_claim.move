/// Module: giverep_claim
module giverep_claim::giverep_claim;

use sui::balance;
use sui::coin;
use sui::event;

public struct Pool<phantom T> has key {
    id: UID,
    balance: balance::Balance<T>,
    managers: vector<address>,
}

// --- Events ---

public struct PoolCreatedEvent has copy, drop {
    pool_id: ID,
    managers: vector<address>,
}

public struct DepositEvent<phantom T> has copy, drop {
    pool_id: ID,
    amount: u64,
    depositor: address,
}

public struct WithdrawEvent<phantom T> has copy, drop {
    pool_id: ID,
    amount: u64,
    withdrawer: address,
}

public struct ClaimEvent<phantom T> has copy, drop {
    pool_id: ID,
    amount: u64,
    manager: address,
    receiver: address,
}

public fun init_pool<T>(managers: vector<address>, ctx: &mut TxContext) {
    let pool = Pool {
        id: object::new(ctx),
        balance: balance::zero<T>(),
        managers,
    };

    event::emit(PoolCreatedEvent {
        pool_id: object::id(&pool),
        managers,
    });

    transfer::share_object(pool);
}

const EINVALID_CLAIM: u64 = 0;

public fun deposit<T>(pool: &mut Pool<T>, deposit: coin::Coin<T>, ctx: &mut TxContext) {
    let amount = coin::value(&deposit);
    pool.balance.join(deposit.into_balance());

    event::emit(DepositEvent<T> {
        pool_id: object::id(pool),
        amount,
        depositor: ctx.sender(),
    });
}

public fun withdraw<T>(pool: &mut Pool<T>, amount: u64, ctx: &mut TxContext): coin::Coin<T> {
    let balance = pool.balance.split(amount);
    let coin = coin::from_balance(balance, ctx);

    event::emit(WithdrawEvent<T> {
        pool_id: object::id(pool),
        amount,
        withdrawer: ctx.sender(),
    });

    coin
}

public fun claim<T>(pool: &mut Pool<T>, amount: u64, ctx: &mut TxContext) {
    let balance = pool.balance.split(amount);
    let sponsor = ctx.sponsor().extract();
    assert!(
        pool.managers.contains(&ctx.sender()) && 
        sponsor != ctx.sender(),
        EINVALID_CLAIM,
    );
    let output = coin::from_balance(balance, ctx);

    event::emit(ClaimEvent<T> {
        pool_id: object::id(pool),
        amount,
        manager: ctx.sender(),
        receiver: sponsor,
    });

    transfer::public_transfer(output, sponsor);
}
