use anyhow::{Result, anyhow};
use lazy_static::lazy_static;
use std::sync::Mutex;
use crate::core::{crypto, db, net, mesh};
use tokio::runtime::Runtime;
use serde_json::json;

// GLOBAL SINGLETONS
lazy_static! {
    // We hold the OPEN database connection here.
    static ref DB: Mutex<Option<db::Database>> = Mutex::new(None);
    static ref RUNTIME: Runtime = Runtime::new().unwrap();
    static ref RELAY_URL: Mutex<String> = Mutex::new("wss://relay.damus.io".to_string());
}

// Helper to access DB safely
fn with_db<F, R>(f: F) -> Result<R>
where F: FnOnce(&db::Database) -> Result<R> {
    let lock = DB.lock().map_err(|_| anyhow!("DB Mutex Poisoned"))?;
    match &*lock {
        Some(db) => f(db),
        None => Err(anyhow!("Database not initialized. Call init_core first.")),
    }
}

pub fn init_core(app_files_dir: String) -> Result<()> {
    let db_path = format!("{}/gossamer.db", app_files_dir);
    
    // Initialize DB once
    let mut lock = DB.lock().map_err(|_| anyhow!("DB Mutex Poisoned"))?;
    if lock.is_none() {
        let db = db::Database::init(&db_path)?;
        
        // Auto-create identity if missing
        if db.get_identity()?.is_none() {
            db.save_identity(&crypto::generate_identity())?;
        }
        
        *lock = Some(db);
    }
    Ok(())
}

pub fn set_relay_url(url: String) -> Result<()> {
    *RELAY_URL.lock().unwrap() = url;
    Ok(())
}

pub fn get_relay_url() -> Result<String> {
    Ok(RELAY_URL.lock().unwrap().clone())
}

pub fn get_my_identity() -> Result<String> {
    with_db(|db| {
        let id = db.get_identity()?.ok_or(anyhow!("No Identity"))?;
        Ok(hex::encode(id))
    })
}

pub fn send_message(dest_hex: String, content: String) -> Result<()> {
    let dest_bytes = hex::decode(&dest_hex).map_err(|_| anyhow!("Invalid Hex"))?;
    
    // 1. Get Identity for Sender Field
    let my_id_hex = get_my_identity()?;
    let payload = json!({
        "sender": my_id_hex,
        "content": content
    }).to_string();
    
    // 2. Network Send (Non-blocking try)
    let relay = RELAY_URL.lock().unwrap().clone();
    if let Err(e) = RUNTIME.block_on(net::send_to_relay(&relay, &dest_bytes, &payload)) {
        println!("Relay Send Warning: {}", e);
    }
    
    // 3. Local Save
    with_db(|db| {
        db.save_message(&uuid::Uuid::new_v4().to_string(), "Me", &content, true)?;
        Ok(())
    })
}

pub fn sync_messages() -> Result<Vec<ChatMessage>> {
    // 1. Fetch from Network
    // We need the identity to check the relay
    let my_id_bytes = with_db(|db| {
        db.get_identity()?.ok_or(anyhow!("No Identity"))
    })?;

    let relay = RELAY_URL.lock().unwrap().clone();
    if let Ok(new_msgs) = RUNTIME.block_on(net::check_relay(&relay, &my_id_bytes)) {
        // Save incoming
        with_db(|db| {
            for raw_msg in new_msgs {
                let (sender, content) = if let Ok(val) = serde_json::from_str::<serde_json::Value>(&raw_msg) {
                    let s = val["sender"].as_str().unwrap_or("Unknown");
                    let c = val["content"].as_str().unwrap_or("");
                    (s.to_string(), c.to_string())
                } else {
                    ("Unknown".to_string(), raw_msg)
                };
                
                let alias = db.resolve_sender(&sender);
                // Ignore errors on save (duplicates)
                let _ = db.save_message(&uuid::Uuid::new_v4().to_string(), &alias, &content, false);
            }
            Ok(())
        })?;
    }

    // 2. Return All
    with_db(|db| {
        let rows = db.get_messages()?;
        let mut result = Vec::new();
        for (id, sender, text, time, is_me) in rows {
            result.push(ChatMessage { id, sender, text, time, is_me });
        }
        Ok(result)
    })
}

pub fn add_contact(pubkey: String, alias: String) -> Result<()> {
    with_db(|db| {
        db.add_contact(&pubkey, &alias)?;
        Ok(())
    })
}

pub fn get_contacts() -> Result<Vec<Contact>> {
    with_db(|db| {
        let rows = db.get_contacts()?;
        let mut result = Vec::new();
        for (pubkey, alias) in rows {
            result.push(Contact { pubkey, alias });
        }
        Ok(result)
    })
}

pub fn prepare_mesh_packet(dest_hex: String, content: String) -> Result<Vec<u8>> {
    let dest_bytes = hex::decode(&dest_hex).map_err(|_| anyhow!("Invalid Hex"))?;
    let my_id_hex = get_my_identity()?;
    let payload = json!({ "sender": my_id_hex, "content": content }).to_string();
    mesh::generate_advertisement_packet(&dest_bytes, &payload)
}

pub fn ingest_mesh_packet(data: Vec<u8>) -> Result<()> {
    with_db(|db| {
        // Mesh handling needs DB access to check identity and save
        // We refactor handle_incoming_bytes to take the DB reference directly
        // But since mesh::handle_incoming_bytes was designed to open DB itself, 
        // we need to update mesh.rs too or pass the DB path. 
        // Actually, let's make mesh logic pure or pass the keys.
        
        // Simplified: We load keys here and decrypt here? 
        // Better: Update mesh.rs to take a &Database
        
        // For now, let's keep the existing logic in mesh.rs but pass the DB_PATH string
        // Wait, mesh.rs opens new connection. That's bad.
        // Let's just implement the logic inline here to use the singleton.
        
        if let Ok(packet) = bincode::deserialize::<mesh::BlePacket>(&data) {
             if let Ok(Some(my_root)) = db.get_identity() {
                 // ... (Logic replicated from mesh.rs but using 'db' reference)
                 let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
                 for time in [now, now - 3600] {
                    let full_mb = crypto::generate_mailbox(&my_root, time);
                    if let Ok(mb_bytes) = hex::decode(&full_mb) {
                        let my_short = u32::from_be_bytes([mb_bytes[0], mb_bytes[1], mb_bytes[2], mb_bytes[3]]);
                        if my_short == packet.mb_short {
                            let mut nonce = [0u8; 24];
                            nonce[0..4].copy_from_slice(&packet.ts_short.to_be_bytes());
                            if let Ok(plain) = crypto::decrypt(&my_root, &nonce, &packet.ct) {
                                let raw_text = String::from_utf8_lossy(&plain).to_string();
                                // Parse JSON sender
                                let (sender, content) = if let Ok(val) = serde_json::from_str::<serde_json::Value>(&raw_text) {
                                    (val["sender"].as_str().unwrap_or("Unknown").to_string(), 
                                     val["content"].as_str().unwrap_or("").to_string())
                                } else { ("Unknown".to_string(), raw_text) };
                                
                                let alias = db.resolve_sender(&sender);
                                db.save_message(&uuid::Uuid::new_v4().to_string(), &alias, &content, false)?;
                                return Ok(());
                            }
                        }
                    }
                 }
             }
             // Transit
             let _ = db.save_transit(&data);
        }
        Ok(())
    })
}

pub fn get_transit_packet() -> Result<Vec<u8>> {
    with_db(|db| {
        if rand::random::<bool>() {
            if let Ok(Some(transit)) = db.get_random_transit() {
                return Ok(transit);
            }
        }
        Ok(Vec::new())
    })
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
