use anyhow::Result;
use lazy_static::lazy_static;
use std::sync::Mutex;
use crate::core::{crypto, db, net, mesh};
use tokio::runtime::Runtime;

lazy_static! {
    static ref DB_PATH: Mutex<String> = Mutex::new("gossamer.db".to_string());
    // OPTIMIZATION: Single global runtime instance
    static ref RUNTIME: Runtime = Runtime::new().unwrap();
}

pub fn init_core(app_files_dir: String) -> Result<()> {
    let db_path = format!("{}/gossamer.db", app_files_dir);
    *DB_PATH.lock().unwrap() = db_path.clone();
    let db = db::Database::init(db_path)?;
    if db.get_identity()?.is_none() {
        db.save_identity(&crypto::generate_identity())?;
    }
    Ok(())
}

pub fn get_my_identity() -> Result<String> {
    let path = DB_PATH.lock().unwrap().clone();
    let db = db::Database::init(path)?;
    let id = db.get_identity()?.ok_or(anyhow::anyhow!("No Identity"))?;
    Ok(hex::encode(id))
}

pub fn send_message(dest_hex: String, content: String) -> Result<()> {
    let dest_bytes = hex::decode(dest_hex)?;
    // Use global runtime to avoid spawning threads per call
    RUNTIME.block_on(net::send_to_relay(&dest_bytes, &content))?;
    
    let path = DB_PATH.lock().unwrap().clone();
    let db = db::Database::init(path)?;
    db.save_message(&uuid::Uuid::new_v4().to_string(), "Me", &content, true)?;
    Ok(())
}

pub fn prepare_mesh_packet(dest_hex: String, content: String) -> Result<Vec<u8>> {
    let dest_bytes = hex::decode(dest_hex)?;
    mesh::generate_advertisement_packet(&dest_bytes, &content)
}

pub fn ingest_mesh_packet(data: Vec<u8>) -> Result<()> {
    let path = DB_PATH.lock().unwrap().clone();
    mesh::handle_incoming_bytes(&data, &path)
}

pub fn get_transit_packet() -> Result<Vec<u8>> {
    let path = DB_PATH.lock().unwrap().clone();
    if let Ok(Some(packet)) = mesh::get_next_packet_to_broadcast(&path) {
        return Ok(packet);
    }
    Ok(Vec::new())
}

pub fn sync_messages() -> Result<Vec<ChatMessage>> {
    let path = DB_PATH.lock().unwrap().clone();
    let db = db::Database::init(path)?;
    if let Ok(Some(my_id)) = db.get_identity() {
        if let Ok(new_msgs) = RUNTIME.block_on(net::check_relay(&my_id)) {
            for msg in new_msgs {
                let _ = db.save_message(&uuid::Uuid::new_v4().to_string(), "Ghost", &msg, false);
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
    let path = DB_PATH.lock().unwrap().clone();
    let db = db::Database::init(path)?;
    db.add_contact(&pubkey, &alias)?;
    Ok(())
}

pub fn get_contacts() -> Result<Vec<Contact>> {
    let path = DB_PATH.lock().unwrap().clone();
    let db = db::Database::init(path)?;
    let rows = db.get_contacts()?;
    let mut result = Vec::new();
    for (pubkey, alias) in rows {
        result.push(Contact { pubkey, alias });
    }
    Ok(result)
}

// UI Functions
pub fn set_relay_url(url: String) -> Result<()> {
    net::set_relay(url);
    Ok(())
}

pub fn wipe_storage() -> Result<()> {
    let path = DB_PATH.lock().unwrap().clone();
    let db = db::Database::init(path)?;
    db.wipe_data()?;
    Ok(())
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
