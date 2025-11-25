use anyhow::{Result, anyhow};
use crate::core::{crypto, db, net, state};
use serde_json::json;
use flutter_rust_bridge::StreamSink;

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

// NEW: This function creates the live event stream
pub fn create_event_stream(s: StreamSink<String>) -> Result<()> {
    // Spawn a Tokio task that will listen for network events and push them to Flutter
    state::block_on(async move {
        let db = state::with_db(|db| Ok(db.clone())).unwrap(); // simplified
        let my_id = db.get_identity().unwrap().unwrap();
        
        // This loop will run forever, listening for live events
        net::listen_for_events(my_id, s).await;
    });
    Ok(())
}

pub fn send_typing_status(dest_hex: String, is_typing: bool) -> Result<()> {
    let db = state::get_db()?;
    let my_id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
    let dest_bytes = hex::decode(dest_hex)?;
    let relay = state::get_relay();
    
    // Create ephemeral "typing" event
    let payload = json!({
        "sender": hex::encode(&my_id),
        "type": "typing_status",
        "is_typing": is_typing
    }).to_string();
    
    state::block_on(net::send_to_relay(&relay, &dest_bytes, &payload, 20000))?; // Use ephemeral kind
    Ok(())
}

// ... [Existing Methods: get_my_identity, send_message, sync, etc.] ...
// The rest of the API remains unchanged but we need to include them for the script
pub fn get_my_identity() -> Result<String> { state::with_db(|db| Ok(hex::encode(db.get_identity()?.ok_or(anyhow!("No Identity"))?))) }
pub fn send_message(dest_hex: String, content: String) -> Result<()> {
    let db = state::get_db()?;
    let my_id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
    let payload = json!({"sender": hex::encode(&my_id), "type": "text", "content": content}).to_string();
    let dest_bytes = hex::decode(dest_hex)?;
    let relay = state::get_relay();
    state::block_on(net::send_to_relay(&relay, &dest_bytes, &payload, 1))?;
    db.save_message(&uuid::Uuid::new_v4().to_string(), "Me", &content, true)?;
    Ok(())
}
pub fn sync_messages() -> Result<Vec<ChatMessage>> {
    let db = state::get_db()?;
    if let Ok(Some(my_id)) = db.get_identity() {
        let relay = state::get_relay();
        if let Ok(new_msgs) = state::block_on(net::check_relay(&relay, &my_id)) {
            for raw_msg in new_msgs {
                if let Ok(val) = serde_json::from_str::<serde_json::Value>(&raw_msg) {
                    let sender = val["sender"].as_str().unwrap_or("Unknown").to_string();
                    let alias = db.resolve_sender(&sender);
                    match val["type"].as_str() {
                        Some("text") => {
                            let content = val["content"].as_str().unwrap_or("");
                            let _ = db.save_message(&uuid::Uuid::new_v4().to_string(), &alias, content, false);
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
pub fn add_contact(pubkey: String, alias: String) -> Result<()> { state::get_db()?.add_contact(&pubkey, &alias) }
pub fn get_contacts() -> Result<Vec<Contact>> {
    let rows = state::get_db()?.get_contacts()?;
    Ok(rows.into_iter().map(|(pubkey, alias)| Contact { pubkey, alias }).collect())
}
pub struct ChatMessage { pub id: String, pub sender: String, pub text: String, pub time: u64, pub is_me: bool }
pub struct Contact { pub pubkey: String, pub alias: String }
