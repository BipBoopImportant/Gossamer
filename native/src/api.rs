use anyhow::{Result, anyhow};
use crate::core::{crypto, db, net, mesh, state};
use serde_json::json;
use flutter_rust_bridge::StreamSink;

// --- Helper Functions ---
fn get_db() -> Result<db::Database> {
    let path = state::get_db_path();
    db::Database::init(&path)
}

fn block_on<F: std::future::Future>(future: F) -> F::Output {
    state::block_on(future)
}

// --- API Functions Exposed to Flutter ---

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

pub fn send_message(dest_hex: String, content: String) -> Result<()> {
    let db = get_db()?;
    let my_id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
    let payload = json!({"sender": hex::encode(&my_id), "type": "text", "content": &content}).to_string();
    let dest_bytes = hex::decode(dest_hex)?;
    let relay = state::get_relay();
    block_on(net::send_to_relay(&relay, &dest_bytes, &payload, 1))?;
    db.save_message(&uuid::Uuid::new_v4().to_string(), "Me", &content, true)?;
    Ok(())
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
                        // In a full implementation, add image/voice chunk handling here
                        _ => {}
                    }
                }
            }
        }
    }
    let rows = db.get_messages()?;
    Ok(rows.into_iter().map(|(id, s, t, time, is_me)| ChatMessage { id, sender: s, text: t, time, is_me }).collect())
}

pub fn add_contact(pubkey: String, alias: String) -> Result<()> {
    get_db()?.add_contact(&pubkey, &alias)
}

pub fn get_contacts() -> Result<Vec<Contact>> {
    let rows = get_db()?.get_contacts()?;
    Ok(rows.into_iter().map(|(pubkey, alias)| Contact { pubkey, alias }).collect())
}

// --- Mesh Functions (Re-activated) ---
pub fn prepare_mesh_packet(dest_hex: String, content: String) -> Result<Vec<u8>> {
    let dest_bytes = hex::decode(dest_hex)?;
    let my_id_hex = get_my_identity()?;
    let payload = json!({ "sender": my_id_hex, "content": content }).to_string();
    mesh::generate_advertisement_packet(&dest_bytes, &payload)
}

pub fn ingest_mesh_packet(data: Vec<u8>) -> Result<()> {
    let path = state::get_db_path();
    mesh::handle_incoming_bytes(&data, &path)
}

pub fn get_transit_packet() -> Result<Vec<u8>> {
    let path = state::get_db_path();
    if let Ok(Some(packet)) = mesh::get_next_packet_to_broadcast(&path) {
        return Ok(packet);
    }
    Ok(Vec::new())
}

// --- Live Typing Functions (Re-activated) ---
pub fn create_event_stream(s: StreamSink<String>) -> Result<()> {
    let db = get_db()?;
    let my_id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
    state::RUNTIME.spawn(async move {
        net::listen_for_events(my_id, s).await;
    });
    Ok(())
}

pub fn send_typing_status(dest_hex: String, is_typing: bool) -> Result<()> {
    let db = get_db()?;
    let my_id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
    let dest_bytes = hex::decode(dest_hex)?;
    let relay = state::get_relay();
    let payload = json!({
        "sender": hex::encode(&my_id),
        "type": "typing_status",
        "is_typing": is_typing
    }).to_string();
    // Use ephemeral kind 20000 for live events
    block_on(net::send_to_relay(&relay, &dest_bytes, &payload, 20000))?;
    Ok(())
}

// --- Bridge Structs ---
pub struct ChatMessage { pub id: String, pub sender: String, pub text: String, pub time: u64, pub is_me: bool }
pub struct Contact { pub pubkey: String, pub alias: String }
