use anyhow::Result;
use rusqlite::{Connection, params};
use std::sync::{Arc, Mutex};
use rand::seq::SliceRandom;

pub struct Database {
    conn: Arc<Mutex<Connection>>,
}

impl Database {
    pub fn init(path: String) -> Result<Self> {
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

        conn.execute("CREATE TABLE IF NOT EXISTS transit (
            hash TEXT PRIMARY KEY,
            packet BLOB,
            received_at INTEGER
        )", [])?;

        Ok(Self { conn: Arc::new(Mutex::new(conn)) })
    }

    pub fn save_message(&self, id: &str, sender: &str, content: &str, is_me: bool) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        let ts = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
        conn.execute("INSERT INTO messages (id, sender, content, timestamp, is_me) VALUES (?1, ?2, ?3, ?4, ?5)", params![id, sender, content, ts, if is_me {1} else {0}])?;
        Ok(())
    }

    pub fn get_messages(&self) -> Result<Vec<(String, String, String, u64, bool)>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT id, sender, content, timestamp, is_me FROM messages ORDER BY timestamp ASC LIMIT 500")?;
        // FIX: Handle rows result mapping
        let rows = stmt.query_map([], |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?, row.get(4)?)))?;
        let mut res = Vec::new();
        for r in rows { res.push(r?); }
        Ok(res)
    }

    pub fn get_identity(&self) -> Result<Option<Vec<u8>>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT root_secret FROM identity WHERE key = 'main'")?;
        // FIX: Handle query result properly
        let mut rows = stmt.query([])?;
        if let Ok(Some(row)) = rows.next() { return Ok(Some(row.get(0)?)); }
        Ok(None)
    }

    pub fn save_identity(&self, secret: &[u8]) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute("INSERT OR REPLACE INTO identity (key, root_secret) VALUES ('main', ?1)", params![secret])?;
        Ok(())
    }

    pub fn add_contact(&self, pubkey: &str, alias: &str) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute("INSERT OR REPLACE INTO contacts (pubkey, alias) VALUES (?1, ?2)", params![pubkey, alias])?;
        Ok(())
    }

    pub fn get_contacts(&self) -> Result<Vec<(String, String)>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT pubkey, alias FROM contacts ORDER BY alias ASC")?;
        let rows = stmt.query_map([], |row| Ok((row.get(0)?, row.get(1)?)))?;
        let mut res = Vec::new();
        for r in rows { res.push(r?); }
        Ok(res)
    }

    pub fn save_transit(&self, packet: &[u8]) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        let hash = md5::compute(packet); 
        let hash_hex = format!("{:x}", hash);
        let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
        conn.execute("INSERT OR IGNORE INTO transit (hash, packet, received_at) VALUES (?1, ?2, ?3)", params![hash_hex, packet, now])?;
        conn.execute("DELETE FROM transit WHERE rowid NOT IN (SELECT rowid FROM transit ORDER BY received_at DESC LIMIT 100)", [])?;
        Ok(())
    }

    pub fn get_random_transit(&self) -> Result<Option<Vec<u8>>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT packet FROM transit ORDER BY RANDOM() LIMIT 1")?;
        let mut rows = stmt.query([])?;
        if let Ok(Some(row)) = rows.next() { return Ok(Some(row.get(0)?)); }
        Ok(None)
    }
}
