use anyhow::Result;
use crate::core::{crypto, db, net, mesh, state};
use serde_json::json;

// API functions must be clean for the code generator

pub fn init_core(app_files_dir: String) -> Result<()> {
    let db_path = format!("{}/gossamer.db", app_files_dir);
    state::set_db_path(db_path.clone());
    
    // Fix: init expects &str
    let db = db::Database::init(&db_path)?;
    if db.get_identity()?.is_none() {
        db.save_identity(&crypto::generate_identity())?;
    }
    Ok(())
}

pub fn set_relay_url(url: String) -> Result<()> {
    state::set_relay(url);
    Ok(())
}

pub fn get_relay_url() -> Result<String> {
    Ok(state::get_relay())
}

pub fn get_my_identity() -> Result<String> {
    let path = state::get_db_path();
    let db = db::Database::init(&path)?;
    let id = db.get_identity()?.ok_or(anyhow::anyhow!("No Identity"))?;
    Ok(hex::encode(id))
}

pub fn send_message(dest_hex: String, content: String) -> Result<()> {
    let dest_bytes = hex::decode(dest_hex)?;
    
    let path = state::get_db_path();
    let db = db::Database::init(&path)?;
    let my_id = db.get_identity()?.ok_or(anyhow::anyhow!("No Identity"))?;
    let my_id_hex = hex::encode(my_id);
    
    let payload = json!({
        "sender": my_id_hex,
        "content": content
    }).to_string();
    
    let relay = state::get_relay();
    
    // Fix: Use state helper to block on async
    if let Err(e) = state::block_on(net::send_to_relay(&relay, &dest_bytes, &payload)) {
        println!("Relay Send Error: {}", e);
    }
    
    db.save_message(&uuid::Uuid::new_v4().to_string(), "Me", &content, true)?;
    Ok(())
}

pub fn sync_messages() -> Result<Vec<ChatMessage>> {
    let path = state::get_db_path();
    let db = db::Database::init(&path)?;
    
    if let Ok(Some(my_id)) = db.get_identity() {
        let relay = state::get_relay();
        if let Ok(new_msgs) = state::block_on(net::check_relay(&relay, &my_id)) {
            for raw_msg in new_msgs {
                let (sender, content) = if let Ok(val) = serde_json::from_str::<serde_json::Value>(&raw_msg) {
                    let s = val["sender"].as_str().unwrap_or("Unknown");
                    let c = val["content"].as_str().unwrap_or("");
                    (s.to_string(), c.to_string())
                } else {
                    ("Unknown".to_string(), raw_msg)
                };
                
                let alias = db.resolve_sender(&sender);
                let _ = db.save_message(&uuid::Uuid::new_v4().to_string(), &alias, &content, false);
            }
        }
    }

    let rows = db.get_messages()?;
    let mut result = Vec::new();
    for (id, sender, text, time, is_me) in rows {
        result.push(ChatMessage { id, sender, text, time, is_me });
    }
    Ok(result)
}

pub fn add_contact(pubkey: String, alias: String) -> Result<()> {
    let path = state::get_db_path();
    let db = db::Database::init(&path)?;
    db.add_contact(&pubkey, &alias)?;
    Ok(())
}

pub fn get_contacts() -> Result<Vec<Contact>> {
    let path = state::get_db_path();
    let db = db::Database::init(&path)?;
    let rows = db.get_contacts()?;
    let mut result = Vec::new();
    for (pubkey, alias) in rows {
        result.push(Contact { pubkey, alias });
    }
    Ok(result)
}

pub fn prepare_mesh_packet(dest_hex: String, content: String) -> Result<Vec<u8>> {
    let dest_bytes = hex::decode(dest_hex)?;
    let path = state::get_db_path();
    let db = db::Database::init(&path)?;
    let my_id = db.get_identity()?.ok_or(anyhow::anyhow!("No Identity"))?;
    let my_id_hex = hex::encode(my_id);
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

pub struct ChatMessage {
    pub id: String,
    pub sender: String,
    pub text: String,
    pub time: u64,
    pub is_me: bool,
}

pub struct Contact {
    pub pubkey: String,
    pub alias: String,
}
