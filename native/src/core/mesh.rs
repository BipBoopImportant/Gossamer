use anyhow::Result;
use crate::core::{crypto, db};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub enum MeshPacket {
    Msg {
        mailbox: String,
        ct: Vec<u8>,
        nonce: Vec<u8>,
    },
    // Heartbeat/Handshake could go here
}

pub fn handle_incoming_bytes(data: &[u8], db_path: &str) -> Result<()> {
    // 1. Deserialize Packet
    // We use bincode or JSON. For simplicity/robustness here: JSON
    // In a real raw BLE environment, we'd use dense binary, but JSON is safer for this bridge demo.
    if let Ok(packet) = serde_json::from_slice::<MeshPacket>(data) {
        match packet {
            MeshPacket::Msg { mailbox, ct, nonce } => {
                // 2. Check if it's for us
                let db = db::Database::init(db_path.to_string())?;
                if let Ok(Some(my_root)) = db.get_identity() {
                    // Check if this mailbox matches ours (Current or Prev hour)
                    let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
                    let my_box_now = crypto::generate_mailbox(&my_root, now);
                    let my_box_prev = crypto::generate_mailbox(&my_root, now - 3600);
                    
                    if mailbox == my_box_now || mailbox == my_box_prev {
                        // 3. Decrypt
                        if let Ok(plain) = crypto::decrypt(&my_root, &nonce, &ct) {
                            let text = String::from_utf8_lossy(&plain).to_string();
                            // 4. Save to DB
                            db.save_message(&uuid::Uuid::new_v4().to_string(), "Nearby Peer", &text, false)?;
                        }
                    }
                }
            }
        }
    }
    Ok(())
}

pub fn generate_advertisement_packet(dest_root: &[u8], msg: &str) -> Result<Vec<u8>> {
    let (ct, nonce) = crypto::encrypt(dest_root, msg.as_bytes())?;
    let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
    let mailbox = crypto::generate_mailbox(dest_root, now);
    
    let packet = MeshPacket::Msg { mailbox, ct, nonce };
    Ok(serde_json::to_vec(&packet)?)
}
