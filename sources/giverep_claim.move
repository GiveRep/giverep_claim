/// Module: giverep_claim
module giverep_claim::giverep_claim;

use sui::balance;
use sui::coin;
use sui::event;
use sui::table;

public struct SuperAdmin has key {
    id: UID,
    super_admin: vector<address>,
}

public struct Pool<phantom T> has key {
    id: UID,
    workspace_id: u64,
    balance: balance::Balance<T>,
    managers: vector<address>,
    claimed: table::Table<address, bool>,
}

// --- Events ---

public struct PoolCreatedEvent has copy, drop {
    pool_id: ID,
    workspace_id: u64,
    initial_amount: u64,
    managers: vector<address>,
}

public struct DepositEvent<phantom T> has copy, drop {
    pool_id: ID,
    workspace_id: u64,
    amount: u64,
    depositor: address,
}

public struct WithdrawEvent<phantom T> has copy, drop {
    pool_id: ID,
    workspace_id: u64,
    amount: u64,
    withdrawer: address,
}

public struct ClaimEvent<phantom T> has copy, drop {
    pool_id: ID,
    workspace_id: u64,
    amount: u64,
    manager: address,
    receiver: address,
}

public struct PoolDeletedEvent has copy, drop {
    pool_id: ID,
    workspace_id: u64,
    sender: address,
}

fun init(ctx: &mut TxContext) {
    let super_admin = SuperAdmin {
        id: object::new(ctx),
        super_admin: vector[
            ctx.sender(),
            @0xa40ec206390843153d219411366a48c7e68ef962cbfc30d4598d82b86636b978,
        ],
    };
    transfer::share_object(super_admin);
}

public fun add_super_admin(super_admin: &mut SuperAdmin, manager: address, ctx: &mut TxContext) {
    assert!(super_admin.super_admin.contains(&ctx.sender()), E_UNAUTHORIZED);
    super_admin.super_admin.push_back(manager);
}

public fun remove_super_admin(super_admin: &mut SuperAdmin, manager: address, ctx: &mut TxContext) {
    assert!(
        super_admin.super_admin.contains(&ctx.sender()) &&
        super_admin.super_admin.length() > 1,
        E_UNAUTHORIZED,
    );
    let (_, index) = super_admin.super_admin.index_of(&manager);
    super_admin.super_admin.remove(index);
}

public fun create_pool<T>(
    workspace_id: u64,
    super_admin: &SuperAdmin,
    managers: vector<address>,
    initial_coin: coin::Coin<T>,
    ctx: &mut TxContext,
) {
    assert!(super_admin.super_admin.contains(&ctx.sender()), E_UNAUTHORIZED);
    let pool = Pool {
        id: object::new(ctx),
        workspace_id,
        balance: initial_coin.into_balance(),
        managers,
        claimed: table::new(ctx),
    };

    event::emit(PoolCreatedEvent {
        pool_id: object::id(&pool),
        workspace_id,
        initial_amount: pool.balance.value(),
        managers,
    });

    transfer::share_object(pool);
}

const E_INVALID_CLAIM: u64 = 0;
const E_UNAUTHORIZED: u64 = 1;

public fun deposit<T>(pool: &mut Pool<T>, deposit: coin::Coin<T>, ctx: &mut TxContext) {
    assert_is_manager(pool, ctx.sender());
    let amount = coin::value(&deposit);
    pool.balance.join(deposit.into_balance());

    event::emit(DepositEvent<T> {
        pool_id: object::id(pool),
        workspace_id: pool.workspace_id,
        amount,
        depositor: ctx.sender(),
    });
}

public fun withdraw<T>(pool: &mut Pool<T>, amount: u64, ctx: &mut TxContext): coin::Coin<T> {
    assert_is_manager(pool, ctx.sender());

    let balance = pool.balance.split(amount);
    let coin = coin::from_balance(balance, ctx);

    event::emit(WithdrawEvent<T> {
        pool_id: object::id(pool),
        workspace_id: pool.workspace_id,
        amount,
        withdrawer: ctx.sender(),
    });

    coin
}

public fun add_manager<T>(pool: &mut Pool<T>, manager: address, ctx: &mut TxContext) {
    assert_is_manager(pool, ctx.sender());
    pool.managers.push_back(manager);
}

public fun remove_manager<T>(pool: &mut Pool<T>, manager: address, ctx: &mut TxContext) {
    assert_is_manager(pool, ctx.sender());
    assert!(pool.managers.length() > 1, E_UNAUTHORIZED);
    let (_, index) = pool.managers.index_of(&manager);
    pool.managers.remove(index);
}

public fun delete_table_fields<T>(pool: &mut Pool<T>, user: address, ctx: &mut TxContext) {
    assert_is_manager(pool, ctx.sender());
    pool.claimed.remove(user);
}

public fun delete_pool<T>(pool: Pool<T>, ctx: &mut TxContext) {
    assert_is_manager(&pool, ctx.sender());
    let pool_id = object::id(&pool);

    let Pool {
        id,
        workspace_id,
        balance,
        managers: _,
        claimed,
    } = pool;

    event::emit(PoolDeletedEvent {
        pool_id,
        workspace_id,
        sender: ctx.sender(),
    });

    id.delete();
    balance.destroy_zero();
    claimed.destroy_empty();
}

public fun claim<T>(pool: &mut Pool<T>, amount: u64, ctx: &mut TxContext) {
    assert_is_manager(pool, ctx.sender());

    let sponsor = ctx.sponsor().extract();
    assert!(sponsor != ctx.sender() &&
        !pool.claimed.contains(sponsor), E_INVALID_CLAIM);

    event::emit(ClaimEvent<T> {
        pool_id: object::id(pool),
        workspace_id: pool.workspace_id,
        amount,
        manager: ctx.sender(),
        receiver: sponsor,
    });

    pool.claimed.add(sponsor, true);

    let balance = pool.balance.split(amount);
    let output = coin::from_balance(balance, ctx);

    transfer::public_transfer(output, sponsor);
}

fun assert_is_manager<T>(pool: &Pool<T>, sender: address) {
    assert!(is_manager(pool, sender), E_UNAUTHORIZED);
}

fun is_manager<T>(pool: &Pool<T>, sender: address): bool {
    pool.managers.contains(&sender)
}
