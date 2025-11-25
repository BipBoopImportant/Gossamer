use anyhow::{Result, anyhow};
use crate::core::{crypto, db, net, mesh};
use serde_json::json;

// Helper functions and state are assumed to be in core::state
use crate::core::state::{self, block_on};

fn get_db() -> Result<db::Database> {
    let path = state::get_db_path();
    db::Database::init(&path)
}

// --- API Functions ---
pub fn init_core(app_files_dir: String) -> Result<()> {
    let db_path = format!("{}/gossamer.db", app_files_dir);
    state::set_db_path(db_path.clone());
    let db = db::Database::init(&db_path)?;
    if db.get_identity()?.is_none() {
        db.save_identity(&crypto::generate_identity())?;
    }
    Ok(())
}

pub fn get_my_identity() -> Result<String> {
    get_db()?.get_identity()?.ok_or(anyhow!("No Identity")).map(hex::encode)
}

fn send_chunked_data(dest_hex: String, data_bytes: Vec<u8>, data_type: &str, placeholder_prefix: &str) -> Result<()> {
    const CHUNK_SIZE: usize = 8 * 1024;
    
    let db = get_db()?;
    let my_id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
    let dest_bytes = hex::decode(dest_hex)?;
    let relay = state::get_relay();
    let unique_id = uuid::Uuid::new_v4().to_string();
    
    let total_chunks = (data_bytes.len() as f64 / CHUNK_SIZE as f64).ceil() as u32;

    for (i, chunk) in data_bytes.chunks(CHUNK_SIZE).enumerate() {
        let payload = json!({
            "sender": hex::encode(&my_id),
            "type": data_type,
            "id": unique_id,
            "chunk_index": i as u32,
            "total_chunks": total_chunks,
            "data": base64::encode(chunk)
        }).to_string();
        
        block_on(net::send_to_relay(&relay, &dest_bytes, &payload))?;
    }
    
    let placeholder = format!("{}://{}", placeholder_prefix, unique_id);
    db.save_message(&uuid::Uuid::new_v4().to_string(), "Me", &placeholder, true)?;
    
    Ok(())
}

pub fn send_message(dest_hex: String, content: String) -> Result<()> {
    let db = get_db()?;
    let my_id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
    let payload = json!({"sender": hex::encode(&my_id), "type": "text", "content": content}).to_string();
    let dest_bytes = hex::decode(dest_hex)?;
    let relay = state::get_relay();
    block_on(net::send_to_relay(&relay, &dest_bytes, &payload))?;
    db.save_message(&uuid::Uuid::new_v4().to_string(), "Me", &content, true)?;
    Ok(())
}

pub fn send_image(dest_hex: String, image_bytes: Vec<u8>) -> Result<()> {
    send_chunked_data(dest_hex, image_bytes, "image_chunk", "gossamer_image")
}

// NEW: Send Voice
pub fn send_voice(dest_hex: String, voice_bytes: Vec<u8>) -> Result<()> {
    send_chunked_data(dest_hex, voice_bytes, "voice_chunk", "gossamer_voice")
}

pub fn sync_messages() -> Result<Vec<ChatMessage>> {
    let db = get_db()?;
    
    if let Ok(Some(my_id)) = db.get_identity() {
        let relay = state::get_relay();
        if let Ok(new_msgs) = block_on(net::check_relay(&relay, &my_id)) {
            for raw_msg in new_msgs {
                if let Ok(val) = serde_json::from_str::<serde_json::Value>(&raw_msg) {
                    let sender = val["sender"].as_str().unwrap_or("Unknown").to_string();
                    let alias = db.resolve_sender(&sender);
                    
                    match val["type"].as_str() {
                        Some("text") => {
                            let content = val["content"].as_str().unwrap_or("");
                            let _ = db.save_message(&uuid::Uuid::new_v4().to_string(), &alias, content, false);
                        },
                        Some(chunk_type) if chunk_type == "image_chunk" || chunk_type == "voice_chunk" => {
                            let id = val["id"].as_str().unwrap_or("");
                            let index = val["chunk_index"].as_u64().unwrap_or(0) as u32;
                            let total = val["total_chunks"].as_u64().unwrap_or(0) as u32;
                            let data_b64 = val["data"].as_str().unwrap_or("");
                            if let Ok(data) = base64::decode(data_b64) {
                                if db.save_chunk(id, index, total, &data).is_ok() {
                                    if let Ok(Some(_)) = db.get_image_chunks(id) {
                                        let prefix = if chunk_type == "image_chunk" { "gossamer_image" } else { "gossamer_voice" };
                                        let placeholder = format!("{}://{}", prefix, id);
                                        let _ = db.save_message(id, &alias, &placeholder, false);
                                    }
                                }
                            }
                        },
                        _ => {}
                    }
                }
            }
        }
    }

    let rows = db.get_messages()?;
    Ok(rows.into_iter().map(|(id, s, t, time, is_me)| ChatMessage { id, sender: s, text: t, time, is_me }).collect())
}

pub fn get_image(image_id: String) -> Result<Vec<u8>> {
    get_db()?.get_image_chunks(&image_id)?.ok_or(anyhow!("Image incomplete"))
}

// NEW: Get Voice (Uses same chunk logic as images)
pub fn get_voice(voice_id: String) -> Result<Vec<u8>> {
    get_db()?.get_image_chunks(&voice_id)?.ok_or(anyhow!("Voice data incomplete"))
}

// -- Unchanged Methods --
pub fn add_contact(pubkey: String, alias: String) -> Result<()> { get_db()?.add_contact(&pubkey, &alias) }
pub fn get_contacts() -> Result<Vec<Contact>> {
    let rows = get_db()?.get_contacts()?;
    Ok(rows.into_iter().map(|(pubkey, alias)| Contact { pubkey, alias }).collect())
}

// -- Bridge Structs --
pub struct ChatMessage { pub id: String, pub sender: String, pub text: String, pub time: u64, pub is_me: bool }
pub struct Contact { pub pubkey: String, pub alias: String }
