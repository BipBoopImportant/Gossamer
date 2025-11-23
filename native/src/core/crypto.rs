use anyhow::Result;
use chacha20poly1305::{aead::{Aead, KeyInit, OsRng}, XChaCha20Poly1305, XNonce};
use hkdf::Hkdf;
use hmac::{Hmac, Mac};
use rand::{RngCore, thread_rng};
use sha2::Sha256;
use secp256k1::{Secp256k1, KeyPair, XOnlyPublicKey};

type HmacSha256 = Hmac<Sha256>;

pub fn generate_identity() -> Vec<u8> {
    let mut key = [0u8; 32];
    thread_rng().fill_bytes(&mut key);
    key.to_vec()
}

pub fn generate_mailbox(root: &[u8], timestamp: u64) -> String {
    let time_slot = timestamp / 3600;
    let mut mac = <HmacSha256 as Mac>::new_from_slice(root).expect("HMAC");
    mac.update(&time_slot.to_be_bytes());
    hex::encode(mac.finalize().into_bytes())
}

pub fn encrypt_with_fixed_nonce(root: &[u8], data: &[u8], nonce_bytes: &[u8; 24]) -> Result<(Vec<u8>, Vec<u8>)> {
    let hk = Hkdf::<Sha256>::new(Some(nonce_bytes), root);
    let mut key = [0u8; 32];
    hk.expand(b"gossamer_enc", &mut key).unwrap();
    
    let cipher = XChaCha20Poly1305::new_from_slice(&key).unwrap();
    let ct = cipher.encrypt(XNonce::from_slice(nonce_bytes), data).map_err(|_| anyhow::anyhow!("Enc failed"))?;
    Ok((ct, nonce_bytes.to_vec()))
}

pub fn encrypt(root: &[u8], data: &[u8]) -> Result<(Vec<u8>, Vec<u8>)> {
    let mut nonce = [0u8; 24];
    OsRng.fill_bytes(&mut nonce);
    encrypt_with_fixed_nonce(root, data, &nonce)
}

pub fn decrypt(root: &[u8], nonce: &[u8], data: &[u8]) -> Result<Vec<u8>> {
    let hk = Hkdf::<Sha256>::new(Some(nonce), root);
    let mut key = [0u8; 32];
    hk.expand(b"gossamer_enc", &mut key).unwrap();
    let cipher = XChaCha20Poly1305::new_from_slice(&key).unwrap();
    cipher.decrypt(XNonce::from_slice(nonce), data).map_err(|_| anyhow::anyhow!("Dec failed"))
}

pub fn get_ephemeral_signer() -> (KeyPair, XOnlyPublicKey) {
    let secp = Secp256k1::new();
    // FIX: Correctly return the KeyPair and Public Key as a tuple
    let (sk, pk) = secp.generate_keypair(&mut thread_rng());
    (sk, pk)
}
