module giverep_claim::giverep_claim_tests;

use giverep_claim::giverep_claim::create_claim_struct;
use std::debug::print;
use sui::address;
use sui::bcs;
use sui::ed25519;
use sui::hash;

const PUBLIC_KEY_HEX: vector<u8> =
    x"a14988fb47d403d60f8e171445ecde4b96650d816a510d0f477727fb53cb5f0a";

#[test]
#[allow(implicit_const_copy)]
fun test_verify_hex_public_key() {
    let public_key = vector<u8>[
        161,
        73,
        136,
        251,
        71,
        212,
        3,
        214,
        15,
        142,
        23,
        20,
        69,
        236,
        222,
        75,
        150,
        101,
        13,
        129,
        106,
        81,
        13,
        15,
        71,
        119,
        39,
        251,
        83,
        203,
        95,
        10,
    ];

    assert!(PUBLIC_KEY_HEX == public_key, 0);
}

#[test]
fun test_address_from_public_key() {
    let mut public_key_with_flag = *&PUBLIC_KEY_HEX;
    public_key_with_flag.insert(0, 0x00);
    let addr = address::from_bytes(
        hash::blake2b256(&public_key_with_flag),
    );
    print(&addr);
}

#[test]
#[allow(implicit_const_copy)]
fun test_signature() {
    let signature =
        x"9532fae7a8586126a98e6d32ac64961ac498c755dfd1ebb3980f259003c052e4f04724e606e83c4dd17b82703628bd8f8d6ec49ee0ddb26fa5b94a797d2ceb0b";
    let message =
        x"94737099fa12869ad430fd3a31e01ab3d2257a746611734fcc7c774fcbd5bb3d94737099fa12869ad430fd3a31e01ab3d2257a746611734fcc7c774fcbd5bb3d00e8764817000000";

    let is_verified = ed25519::ed25519_verify(
        &signature,
        &PUBLIC_KEY_HEX,
        &message,
    );
    assert!(is_verified, 0);
}

#[test]
#[allow(implicit_const_copy)]
fun test_sign_claim_struct() {
    let claim_struct = create_claim_struct(
        object::id_from_address(
            @0x94737099fa12869ad430fd3a31e01ab3d2257a746611734fcc7c774fcbd5bb3d,
        ),
        @0x94737099fa12869ad430fd3a31e01ab3d2257a746611734fcc7c774fcbd5bb3d,
        100000000000,
    );

    let bytes = bcs::to_bytes(&claim_struct);
    let signature =
        x"9532fae7a8586126a98e6d32ac64961ac498c755dfd1ebb3980f259003c052e4f04724e606e83c4dd17b82703628bd8f8d6ec49ee0ddb26fa5b94a797d2ceb0b";

    let is_verified = ed25519::ed25519_verify(
        &signature,
        &PUBLIC_KEY_HEX,
        &bytes,
    );
    assert!(is_verified, 0);

    let mut public_key_with_flag = *&PUBLIC_KEY_HEX;
    public_key_with_flag.insert(0, 0x00);
    let addr = address::from_bytes(
        hash::blake2b256(&public_key_with_flag),
    );
    assert!(addr == @0x94737099fa12869ad430fd3a31e01ab3d2257a746611734fcc7c774fcbd5bb3d, 0);
}
