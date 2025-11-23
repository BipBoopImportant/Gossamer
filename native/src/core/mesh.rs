use anyhow::Result;
use crate::core::{crypto, db};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Serialize, Deserialize, Debug)]
pub struct BlePacket {
    pub mb_short: u32,
    pub ts_short: u32,
    pub ct: Vec<u8>,
}

pub fn handle_incoming_bytes(data: &[u8], db_path: &str) -> Result<()> {
    if let Ok(packet) = bincode::deserialize::<BlePacket>(data) {
        let db = db::Database::init(db_path.to_string())?;
        let mut is_for_me = false;

        if let Ok(Some(my_root)) = db.get_identity() {
            let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
            for time in [now, now - 3600] {
                let full_mb = crypto::generate_mailbox(&my_root, time);
                if let Ok(mb_bytes) = hex::decode(&full_mb) {
                    let my_short = u32::from_be_bytes([mb_bytes[0], mb_bytes[1], mb_bytes[2], mb_bytes[3]]);
                    if my_short == packet.mb_short {
                        let mut nonce = [0u8; 24];
                        nonce[0..4].copy_from_slice(&packet.ts_short.to_be_bytes());
                        if let Ok(plain) = crypto::decrypt(&my_root, &nonce, &packet.ct) {
                            let text = String::from_utf8_lossy(&plain).to_string();
                            db.save_message(&uuid::Uuid::new_v4().to_string(), "Mesh Peer", &text, false)?;
                            is_for_me = true;
                            break;
                        }
                    }
                }
            }
        }

        if !is_for_me {
            let _ = db.save_transit(data);
        }
    }
    Ok(())
}

pub fn generate_advertisement_packet(dest_root: &[u8], msg: &str) -> Result<Vec<u8>> {
    let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
    let full_mb = crypto::generate_mailbox(dest_root, now);
    let mb_bytes = hex::decode(full_mb)?;
    let mb_short = u32::from_be_bytes([mb_bytes[0], mb_bytes[1], mb_bytes[2], mb_bytes[3]]);
    
    let mut nonce = [0u8; 24];
    // FIX: Removed parentheses around cast
    let ts_short = now as u32;
    nonce[0..4].copy_from_slice(&ts_short.to_be_bytes());
    
    let (ct, _) = crypto::encrypt_with_fixed_nonce(dest_root, msg.as_bytes(), &nonce)?;
    
    let packet = BlePacket { mb_short, ts_short, ct };
    Ok(bincode::serialize(&packet)?)
}

pub fn get_next_packet_to_broadcast(db_path: &str) -> Result<Option<Vec<u8>>> {
    let db = db::Database::init(db_path.to_string())?;
    if rand::random::<bool>() {
        if let Ok(Some(transit)) = db.get_random_transit() {
            return Ok(Some(transit));
        }
    }
    Ok(None)
}
