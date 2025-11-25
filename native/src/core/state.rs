use std::sync::Mutex;
use tokio::runtime::Runtime;
use lazy_static::lazy_static;

lazy_static! {
    pub static ref DB_PATH: Mutex<String> = Mutex::new("gossamer.db".to_string());
    pub static ref RUNTIME: Runtime = Runtime::new().unwrap();
    pub static ref RELAY_URL: Mutex<String> = Mutex::new("wss://relay.damus.io".to_string());
}

pub fn set_db_path(path: String) {
    *DB_PATH.lock().unwrap() = path;
}

pub fn get_db_path() -> String {
    DB_PATH.lock().unwrap().clone()
}

pub fn set_relay(url: String) {
    *RELAY_URL.lock().unwrap() = url;
}

pub fn get_relay() -> String {
    RELAY_URL.lock().unwrap().clone()
}

pub fn block_on<F: std::future::Future>(future: F) -> F::Output {
    RUNTIME.block_on(future)
}
