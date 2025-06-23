import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

const keypair = Ed25519Keypair.generate();

console.log(keypair.toSuiAddress());
console.log(keypair.getPublicKey().toBase64());
console.log(keypair.getSecretKey());
