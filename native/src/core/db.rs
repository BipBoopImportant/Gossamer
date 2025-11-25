use anyhow::Result;
use rusqlite::{Connection, params};
use rand::seq::SliceRandom;

// Database now holds the Connection directly (not wrapped in Arc<Mutex>)
// We will wrap the whole Database struct in a Mutex in api.rs
pub struct Database {
    conn: Connection,
}

impl Database {
    pub fn init(path: &str) -> Result<Self> {
        let conn = Connection::open(path)?;
        
        // Enable Write-Ahead Logging for concurrency performance
        // Set timeout to wait for locks instead of crashing immediately
        conn.pragma_update(None, "journal_mode", "WAL")?;
        conn.pragma_update(None, "busy_timeout", 5000)?; 
        
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

        Ok(Self { conn })
    }

    pub fn save_message(&self, id: &str, sender: &str, content: &str, is_me: bool) -> Result<()> {
        let ts = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
        self.conn.execute(
            "INSERT INTO messages (id, sender, content, timestamp, is_me) VALUES (?1, ?2, ?3, ?4, ?5)",
            params![id, sender, content, ts, if is_me {1} else {0}]
        )?;
        Ok(())
    }

    pub fn get_messages(&self) -> Result<Vec<(String, String, String, u64, bool)>> {
        let mut stmt = self.conn.prepare("SELECT id, sender, content, timestamp, is_me FROM messages ORDER BY timestamp ASC LIMIT 500")?;
        let rows = stmt.query_map([], |row| {
            Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?, row.get(4)?))
        })?;
        let mut res = Vec::new();
        for r in rows { res.push(r?); }
        Ok(res)
    }

    pub fn get_identity(&self) -> Result<Option<Vec<u8>>> {
        let mut stmt = self.conn.prepare("SELECT root_secret FROM identity WHERE key = 'main'")?;
        let mut rows = stmt.query([])?;
        if let Ok(Some(row)) = rows.next() { return Ok(Some(row.get(0)?)); }
        Ok(None)
    }

    pub fn save_identity(&self, secret: &[u8]) -> Result<()> {
        self.conn.execute("INSERT OR REPLACE INTO identity (key, root_secret) VALUES ('main', ?1)", params![secret])?;
        Ok(())
    }

    pub fn resolve_sender(&self, pubkey: &str) -> String {
        if let Ok(mut stmt) = self.conn.prepare("SELECT alias FROM contacts WHERE pubkey = ?1") {
            if let Ok(mut rows) = stmt.query([pubkey]) {
                if let Ok(Some(row)) = rows.next() {
                    if let Ok(alias) = row.get::<_, String>(0) {
                        return alias;
                    }
                }
            }
        }
        // Fallback
        if pubkey.len() > 8 {
            return format!("{}...", &pubkey[0..8]);
        }
        pubkey.to_string()
    }

    pub fn add_contact(&self, pubkey: &str, alias: &str) -> Result<()> {
        self.conn.execute("INSERT OR REPLACE INTO contacts (pubkey, alias) VALUES (?1, ?2)", params![pubkey, alias])?;
        Ok(())
    }

    pub fn get_contacts(&self) -> Result<Vec<(String, String)>> {
        let mut stmt = self.conn.prepare("SELECT pubkey, alias FROM contacts ORDER BY alias ASC")?;
        let rows = stmt.query_map([], |row| Ok((row.get(0)?, row.get(1)?)))?;
        let mut res = Vec::new();
        for r in rows { res.push(r?); }
        Ok(res)
    }

    pub fn save_transit(&self, packet: &[u8]) -> Result<()> {
        let hash = md5::compute(packet); 
        let hash_hex = format!("{:x}", hash);
        let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
        self.conn.execute("INSERT OR IGNORE INTO transit (hash, packet, received_at) VALUES (?1, ?2, ?3)", params![hash_hex, packet, now])?;
        self.conn.execute("DELETE FROM transit WHERE rowid NOT IN (SELECT rowid FROM transit ORDER BY received_at DESC LIMIT 100)", [])?;
        Ok(())
    }

    pub fn get_random_transit(&self) -> Result<Option<Vec<u8>>> {
        let mut stmt = self.conn.prepare("SELECT packet FROM transit ORDER BY RANDOM() LIMIT 1")?;
        let mut rows = stmt.query([])?;
        if let Ok(Some(row)) = rows.next() { return Ok(Some(row.get(0)?)); }
        Ok(None)
    }
}
