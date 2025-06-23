import { bcs } from "@mysten/sui/bcs";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { fromBase64, toHex } from "@mysten/sui/utils";
import dotenv from "dotenv";

dotenv.config();

async function main() {
  // a test secret key, don't use it in production
  const suiSecretKeyForTest = process.env.SUI_PRIVATE_KEY as string;

  const keypair = Ed25519Keypair.fromSecretKey(suiSecretKeyForTest);

  console.log("getPublicKeyHex", toHex(keypair.getPublicKey().toRawBytes()));
  console.log("toSuiAddress", keypair.toSuiAddress());

  function createClaimStructSerialized({
    pool_id,
    receiver,
    amount,
  }: {
    pool_id: string;
    receiver: string;
    amount: string;
  }) {
    const ClaimStruct = bcs.struct("ClaimStruct", {
      pool_id: bcs.Address,
      receiver: bcs.Address,
      amount: bcs.U64,
    });
    return ClaimStruct.serialize({
      pool_id,
      receiver,
      amount,
    });
  }

  const claimStructSerialized = createClaimStructSerialized({
    pool_id:
      "0x94737099fa12869ad430fd3a31e01ab3d2257a746611734fcc7c774fcbd5bb3d",
    receiver:
      "0x94737099fa12869ad430fd3a31e01ab3d2257a746611734fcc7c774fcbd5bb3d",
    amount: "100000000000",
  });

  console.log(
    "claimStructSerialized.toBytes()",
    claimStructSerialized.toBytes()
  );

  console.log(
    "claimStructSerialized.toBase64()",
    claimStructSerialized.toBase64()
  );

  const bytes = claimStructSerialized.toBytes();

  const signature = await keypair.sign(bytes);

  console.log({
    signature: toHex(signature),
    bytes: toHex(bytes),
  });
}

main();
