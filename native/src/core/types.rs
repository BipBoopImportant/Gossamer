use serde::{Deserialize, Serialize};
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct GossamerPacket {
    pub mailbox_id: String,
    pub cipher_text: Vec<u8>,
    pub nonce: Vec<u8>,
    pub created_at: u64,
    pub ttl: u64,
}
