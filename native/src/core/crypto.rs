use anyhow::Result;
use argon2::{Argon2, PasswordHasher, password_hash::SaltString};
use chacha20poly1305::{aead::{Aead, KeyInit, OsRng}, XChaCha20Poly1305, XNonce};
use hkdf::Hkdf;
use hmac::{Hmac, Mac};
use rand::RngCore;
use sha2::Sha256;
use base64::prelude::*;

type HmacSha256 = Hmac<Sha256>;

pub fn derive_key(pin: &str) -> Result<String> {
    let salt = SaltString::encode_b64(b"gossamer_salt_v1").map_err(|e| anyhow::anyhow!(e))?;
    let argon2 = Argon2::default();
    let hash = argon2.hash_password(pin.as_bytes(), &salt).map_err(|e| anyhow::anyhow!(e))?;
    Ok(hash.to_string())
}

pub fn generate_mailbox(root: &[u8], time: u64) -> String {
    let slot = time / 3600;
    let mut mac = <HmacSha256 as Mac>::new_from_slice(root).expect("HMAC");
    mac.update(&slot.to_be_bytes());
    hex::encode(mac.finalize().into_bytes())
}

pub fn encrypt(root: &[u8], data: &[u8]) -> Result<(Vec<u8>, Vec<u8>)> {
    let mut nonce = [0u8; 24];
    OsRng.fill_bytes(&mut nonce);
    let hk = Hkdf::<Sha256>::new(Some(&nonce), root);
    let mut key = [0u8; 32];
    hk.expand(b"gossamer_enc", &mut key).unwrap();
    
    let cipher = XChaCha20Poly1305::new_from_slice(&key).unwrap();
    let ct = cipher.encrypt(XNonce::from_slice(&nonce), data).map_err(|_| anyhow::anyhow!("Enc failed"))?;
    Ok((ct, nonce.to_vec()))
}

pub fn decrypt(root: &[u8], nonce: &[u8], data: &[u8]) -> Result<Vec<u8>> {
    let hk = Hkdf::<Sha256>::new(Some(nonce), root);
    let mut key = [0u8; 32];
    hk.expand(b"gossamer_enc", &mut key).unwrap();
    let cipher = XChaCha20Poly1305::new_from_slice(&key).unwrap();
    cipher.decrypt(XNonce::from_slice(nonce), data).map_err(|_| anyhow::anyhow!("Dec failed"))
}
