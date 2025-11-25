use anyhow::{Result, anyhow};
use lazy_static::lazy_static;
use std::sync::Mutex;
use crate::core::{crypto, db, net, mesh};
use tokio::runtime::Runtime;
use serde_json::json;

lazy_static! {
    static ref DB_PATH: Mutex<String> = Mutex::new("gossamer.db".to_string());
    static ref RUNTIME: Runtime = Runtime::new().unwrap();
    static ref RELAY_URL: Mutex<String> = Mutex::new("wss://relay.damus.io".to_string());
}

fn with_db<F, R>(f: F) -> Result<R>
where F: FnOnce(&db::Database) -> Result<R> {
    let path = DB_PATH.lock().unwrap().clone();
    let db = db::Database::init(&path)?;
    f(&db)
}

pub fn init_core(app_files_dir: String) -> Result<()> {
    let db_path = format!("{}/gossamer.db", app_files_dir);
    state::set_db_path(db_path.clone());
    let db = db::Database::init(&db_path)?;
    if db.get_identity()?.is_none() {
        db.save_identity(&crypto::generate_identity())?;
    }
    Ok(())
}

pub fn send_message(dest_hex: String, content: String) -> Result<()> {
    println!("[Rust] send_message called. Dest: {}, Content: {}", &dest_hex[0..4], content);
    
    let dest_bytes = hex::decode(&dest_hex).map_err(|e| anyhow!("Invalid Hex: {}", e))?;
    
    // 1. Get my identity
    let my_id_hex = with_db(|db| {
        let id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
        Ok(hex::encode(id))
    })?;

    // 2. Create payload
    let payload = json!({
        "sender": my_id_hex,
        "content": content
    }).to_string();
    
    let relay = RELAY_URL.lock().unwrap().clone();
    
    // 3. FIX: BLOCK on the network call to ensure it completes.
    println!("[Rust] Connecting to relay: {}", relay);
    RUNTIME.block_on(net::send_to_relay(&relay, &dest_bytes, &payload))?;
    println!("[Rust] Relay send successful.");
    
    // 4. Save to DB
    with_db(|db| {
        db.save_message(&uuid::Uuid::new_v4().to_string(), "Me", &content, true)?;
        Ok(())
    })
}

// ... [The rest of api.rs remains the same] ...

pub fn set_relay_url(url: String) -> Result<()> {
    state::set_relay(url);
    Ok(())
}

pub fn get_relay_url() -> Result<String> {
    Ok(state::get_relay())
}

pub fn get_my_identity() -> Result<String> {
    with_db(|db| {
        let id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
        Ok(hex::encode(id))
    })
}

pub fn sync_messages() -> Result<Vec<ChatMessage>> {
    let my_id_bytes = with_db(|db| db.get_identity()?.ok_or(anyhow!("No Identity")))?;
    let relay = RELAY_URL.lock().unwrap().clone();
    
    if let Ok(new_msgs) = RUNTIME.block_on(net::check_relay(&relay, &my_id_bytes)) {
        with_db(|db| {
            for raw_msg in new_msgs {
                let (sender, content) = if let Ok(val) = serde_json::from_str::<serde_json::Value>(&raw_msg) {
                    (val["sender"].as_str().unwrap_or("Unknown").to_string(), 
                     val["content"].as_str().unwrap_or("").to_string())
                } else { ("Unknown".to_string(), raw_msg) };
                
                let alias = db.resolve_sender(&sender);
                let _ = db.save_message(&uuid::Uuid::new_v4().to_string(), &alias, &content, false);
            }
            Ok(())
        })?;
    }

    with_db(|db| {
        let rows = db.get_messages()?;
        Ok(rows.into_iter().map(|(id, sender, text, time, is_me)| ChatMessage { id, sender, text, time, is_me }).collect())
    })
}

pub fn add_contact(pubkey: String, alias: String) -> Result<()> {
    with_db(|db| db.add_contact(&pubkey, &alias))
}

pub fn get_contacts() -> Result<Vec<Contact>> {
    with_db(|db| {
        let rows = db.get_contacts()?;
        Ok(rows.into_iter().map(|(pubkey, alias)| Contact { pubkey, alias }).collect())
    })
}

pub fn prepare_mesh_packet(dest_hex: String, content: String) -> Result<Vec<u8>> {
    let dest_bytes = hex::decode(dest_hex)?;
    let my_id_hex = get_my_identity()?;
    let payload = json!({ "sender": my_id_hex, "content": content }).to_string();
    mesh::generate_advertisement_packet(&dest_bytes, &payload)
}

pub fn ingest_mesh_packet(data: Vec<u8>) -> Result<()> {
    with_db(|db| {
        if let Ok(packet) = bincode::deserialize::<mesh::BlePacket>(&data) {
             if let Ok(Some(my_root)) = db.get_identity() {
                 // ... (Rest of mesh logic)
             }
        }
        Ok(())
    })
}

pub fn get_transit_packet() -> Result<Vec<u8>> {
    with_db(|db| {
        if rand::random::<bool>() {
            return db.get_random_transit()?.ok_or(anyhow!("No transit packets"));
        }
        Ok(Vec::new())
    }).unwrap_or_default()
}

pub struct ChatMessage { pub id: String, pub sender: String, pub text: String, pub time: u64, pub is_me: bool }
pub struct Contact { pub pubkey: String, pub alias: String }
