use anyhow::Result;
use rusqlite::{Connection, params};
use std::sync::{Arc, Mutex};

pub struct Database {
    conn: Arc<Mutex<Connection>>,
}

impl Database {
    pub fn init(path: &str) -> Result<Self> {
        let conn = Connection::open(path)?;
        conn.execute("PRAGMA journal_mode=WAL;", [])?;
        
        conn.execute("CREATE TABLE IF NOT EXISTS messages (
            id TEXT PRIMARY KEY,
            sender TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            is_me INTEGER NOT NULL
        )", [])?;
        
        conn.execute("CREATE TABLE IF NOT EXISTS identity (
            key TEXT PRIMARY KEY,
            root_secret BLOB
        )", [])?;

        conn.execute("CREATE TABLE IF NOT EXISTS contacts (
            pubkey TEXT PRIMARY KEY,
            alias TEXT NOT NULL
        )", [])?;

        // NEW: Table for reassembling images
        conn.execute("CREATE TABLE IF NOT EXISTS image_chunks (
            image_id TEXT NOT NULL,
            chunk_index INTEGER NOT NULL,
            total_chunks INTEGER NOT NULL,
            data BLOB NOT NULL,
            PRIMARY KEY (image_id, chunk_index)
        )", [])?;

        Ok(Self { conn: Arc::new(Mutex::new(conn)) })
    }

    pub fn save_message(&self, id: &str, sender: &str, content: &str, is_me: bool) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        let ts = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
        conn.execute("INSERT OR REPLACE INTO messages (id, sender, content, timestamp, is_me) VALUES (?1, ?2, ?3, ?4, ?5)", params![id, sender, content, ts, if is_me {1} else {0}])?;
        Ok(())
    }

    pub fn get_messages(&self) -> Result<Vec<(String, String, String, u64, bool)>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT id, sender, content, timestamp, is_me FROM messages ORDER BY timestamp ASC LIMIT 500")?;
        let rows = stmt.query_map([], |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?, row.get(4)?)))?;
        let mut res = Vec::new();
        for r in rows { res.push(r?); }
        Ok(res)
    }

    pub fn get_identity(&self) -> Result<Option<Vec<u8>>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT root_secret FROM identity WHERE key = 'main'")?;
        let mut rows = stmt.query([])?;
        if let Ok(Some(row)) = rows.next() { return Ok(Some(row.get(0)?)); }
        Ok(None)
    }

    pub fn save_identity(&self, secret: &[u8]) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute("INSERT OR REPLACE INTO identity (key, root_secret) VALUES ('main', ?1)", params![secret])?;
        Ok(())
    }

    pub fn resolve_sender(&self, pubkey: &str) -> String {
        let conn = self.conn.lock().unwrap();
        if let Ok(mut stmt) = conn.prepare("SELECT alias FROM contacts WHERE pubkey = ?1") {
            if let Ok(mut rows) = stmt.query([pubkey]) {
                if let Ok(Some(row)) = rows.next() {
                     if let Ok(alias) = row.get::<_, String>(0) { return alias; }
                }
            }
        }
        if pubkey.len() > 8 { return format!("{}...", &pubkey[0..8]); }
        pubkey.to_string()
    }
    
    // -- Image Chunk Methods --
    pub fn save_chunk(&self, image_id: &str, index: u32, total: u32, data: &[u8]) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "INSERT OR IGNORE INTO image_chunks (image_id, chunk_index, total_chunks, data) VALUES (?1, ?2, ?3, ?4)",
            params![image_id, index, total, data]
        )?;
        Ok(())
    }

    pub fn get_image_chunks(&self, image_id: &str) -> Result<Option<Vec<u8>>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT data, total_chunks FROM image_chunks WHERE image_id = ?1 ORDER BY chunk_index ASC")?;
        let rows = stmt.query_map([image_id], |row| {
            Ok((row.get::<_, Vec<u8>>(0)?, row.get::<_, u32>(1)?))
        })?;

        let mut chunks = Vec::new();
        let mut total_chunks = 0;
        for r in rows {
            let (data, total) = r?;
            chunks.push(data);
            total_chunks = total;
        }

        // Check if we have all the pieces
        if chunks.len() as u32 == total_chunks && total_chunks > 0 {
            // Reassemble
            Ok(Some(chunks.concat()))
        } else {
            Ok(None) // Image is incomplete
        }
    }
}
