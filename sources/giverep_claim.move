/// Module: giverep_claim
module giverep_claim::giverep_claim;

use sui::balance;
use sui::coin;
use sui::event;
use sui::table;

public struct Whitelist has key {
    id: UID,
    whitelist: vector<address>,
}

public struct Pool<phantom T> has key {
    id: UID,
    balance: balance::Balance<T>,
    managers: vector<address>,
    claimed: table::Table<address, bool>,
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

public struct ClaimRemovedEvent has copy, drop {
    pool_id: ID,
    user: address,
}

public struct PoolDeletedEvent has copy, drop {
    pool_id: ID,
    sender: address,
}

fun init(ctx: &mut TxContext) {
    let whitelist = Whitelist {
        id: object::new(ctx),
        whitelist: vector[
            ctx.sender(),
            @0xa40ec206390843153d219411366a48c7e68ef962cbfc30d4598d82b86636b978,
        ],
    };
    transfer::share_object(whitelist);
}

public fun add_whitelist(whitelist: &mut Whitelist, manager: address, ctx: &mut TxContext) {
    assert!(whitelist.whitelist.contains(&ctx.sender()), E_UNAUTHORIZED);
    whitelist.whitelist.push_back(manager);
}

public fun remove_whitelist(whitelist: &mut Whitelist, manager: address, ctx: &mut TxContext) {
    assert!(
        whitelist.whitelist.contains(&ctx.sender()) &&
        whitelist.whitelist.length() > 1,
        E_UNAUTHORIZED,
    );
    let (_, index) = whitelist.whitelist.index_of(&manager);
    whitelist.whitelist.remove(index);
}

public fun init_pool<T>(whitelist: &Whitelist, managers: vector<address>, ctx: &mut TxContext) {
    assert!(whitelist.whitelist.contains(&ctx.sender()), E_UNAUTHORIZED);
    let pool = Pool {
        id: object::new(ctx),
        balance: balance::zero<T>(),
        managers,
        claimed: table::new(ctx),
    };

    event::emit(PoolCreatedEvent {
        pool_id: object::id(&pool),
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

    event::emit(ClaimRemovedEvent {
        pool_id: object::id(pool),
        user,
    });
}

public fun delete_pool<T>(pool: Pool<T>, ctx: &mut TxContext) {
    assert_is_manager(&pool, ctx.sender());
    let pool_id = object::id(&pool);

    let Pool {
        id,
        balance,
        managers: _,
        claimed,
    } = pool;

    event::emit(PoolDeletedEvent {
        pool_id,
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
