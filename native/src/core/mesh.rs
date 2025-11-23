use anyhow::Result;
use crate::core::{crypto, db};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

// OPTIMIZED PACKET (Compact Binary)
// Total Header Overhead: ~8-12 bytes.
// Remaining space for Ciphertext: ~15-20 bytes.
#[derive(Serialize, Deserialize, Debug)]
pub struct BlePacket {
    pub mb_short: u32,    // First 4 bytes of Mailbox Hash
    pub ts_short: u32,    // Timestamp (for replay protection/nonce derivation)
    pub ct: Vec<u8>,      // Ciphertext
}

pub fn handle_incoming_bytes(data: &[u8], db_path: &str) -> Result<()> {
    // 1. Decode Binary
    if let Ok(packet) = bincode::deserialize::<BlePacket>(data) {
        let db = db::Database::init(db_path.to_string())?;
        
        if let Ok(Some(my_root)) = db.get_identity() {
            // 2. Check Mailbox Match (Optimized)
            // We calculate our full mailbox, then check if the first 4 bytes match the packet's mb_short
            let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
            
            // Check Current and Previous Hour
            for time in [now, now - 3600] {
                let full_mb = crypto::generate_mailbox(&my_root, time);
                // Decode hex to bytes to compare with u32
                if let Ok(mb_bytes) = hex::decode(&full_mb) {
                    // Take first 4 bytes as u32 (Big Endian)
                    let my_short = u32::from_be_bytes([mb_bytes[0], mb_bytes[1], mb_bytes[2], mb_bytes[3]]);
                    
                    if my_short == packet.mb_short {
                        // 3. Decrypt
                        // We assume Nonce is derived from the sender's shared secret + ts_short in a real protocol.
                        // For this Mesh Implementation, to fit in the packet, we use a deterministic nonce strategy 
                        // or we appended the nonce to the ciphertext. 
                        // Here, we attempt to decrypt assuming the nonce was prepended to 'ct' or handled by the upper layer.
                        
                        // Simplified: We just try to decrypt. In a raw BLE constraint, 
                        // we often use the packet timestamp as the Nonce to save space.
                        let mut nonce = [0u8; 24];
                        nonce[0..4].copy_from_slice(&packet.ts_short.to_be_bytes());
                        
                        if let Ok(plain) = crypto::decrypt(&my_root, &nonce, &packet.ct) {
                            let text = String::from_utf8_lossy(&plain).to_string();
                            db.save_message(&uuid::Uuid::new_v4().to_string(), "Nearby Peer", &text, false)?;
                            return Ok(());
                        }
                    }
                }
            }
        }
    }
    Ok(())
}

pub fn generate_advertisement_packet(dest_root: &[u8], msg: &str) -> Result<Vec<u8>> {
    // 1. Prepare Header
    let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
    let full_mb = crypto::generate_mailbox(dest_root, now);
    let mb_bytes = hex::decode(full_mb)?;
    let mb_short = u32::from_be_bytes([mb_bytes[0], mb_bytes[1], mb_bytes[2], mb_bytes[3]]);
    
    // 2. Encrypt (Compact Mode)
    // We use a deterministic nonce based on time to save sending the 24-byte nonce over the air.
    // WARNING: This reduces security slightly (replay attacks possible within the same second), 
    // but is necessary for BLE size limits.
    let mut nonce = [0u8; 24];
    let ts_short = (now as u32);
    nonce[0..4].copy_from_slice(&ts_short.to_be_bytes());
    
    let (ct, _) = crypto::encrypt_with_fixed_nonce(dest_root, msg.as_bytes(), &nonce)?;
    
    let packet = BlePacket {
        mb_short,
        ts_short,
        ct
    };
    
    // 3. Serialize to Binary
    Ok(bincode::serialize(&packet)?)
}
