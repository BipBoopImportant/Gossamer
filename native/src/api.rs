use anyhow::Result;
use lazy_static::lazy_static;
use std::sync::Mutex;
use flutter_rust_bridge::StreamSink;
use crate::core::{crypto, db, net};

lazy_static! {
    static ref DB_PATH: Mutex<String> = Mutex::new("gossamer.db".to_string());
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
    let rt = tokio::runtime::Runtime::new()?;
    rt.block_on(net::send_to_relay(&dest_bytes, &content))?;
    
    let path = DB_PATH.lock().unwrap().clone();
    let db = db::Database::init(path)?;
    db.save_message(&uuid::Uuid::new_v4().to_string(), "Me", &content, true)?;
    Ok(())
}

pub fn sync_messages() -> Result<Vec<ChatMessage>> {
    let path = DB_PATH.lock().unwrap().clone();
    let db = db::Database::init(path)?;
    
    if let Ok(Some(my_id)) = db.get_identity() {
        let rt = tokio::runtime::Runtime::new()?;
        if let Ok(new_msgs) = rt.block_on(net::check_relay(&my_id)) {
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

pub struct ChatMessage {
    pub id: String,
    pub sender: String,
    pub text: String,
    pub time: u64,
    pub is_me: bool,
}
