use anyhow::Result;
use lazy_static::lazy_static;
use std::sync::Mutex;
use flutter_rust_bridge::StreamSink;
use crate::core::crypto;

// GLOBAL STATE (In-Memory for this demo, ideally DB)
struct AppState {
    root_secret: Option<Vec<u8>>,
}

lazy_static! {
    static ref STATE: Mutex<AppState> = Mutex::new(AppState { root_secret: None });
}

pub fn init_core() -> Result<String> {
    // Generate a random identity if none exists
    let mut state = STATE.lock().unwrap();
    if state.root_secret.is_none() {
        let mut key = [0u8; 32];
        use rand::RngCore;
        rand::thread_rng().fill_bytes(&mut key);
        state.root_secret = Some(key.to_vec());
    }
    Ok("Core Ready".into())
}

pub fn get_identity() -> Result<String> {
    let state = STATE.lock().unwrap();
    if let Some(key) = &state.root_secret {
        return Ok(hex::encode(key));
    }
    Ok("NOT_INITIALIZED".into())
}

pub fn send_message_mock(dest_hex: String, msg: String) -> Result<String> {
    // 1. Simulate Encryption
    let dest_bytes = hex::decode(dest_hex).unwrap_or(vec![0; 32]);
    let (ct, _) = crypto::encrypt(&dest_bytes, msg.as_bytes())?;
    
    // 2. Simulate Network Delay
    std::thread::sleep(std::time::Duration::from_millis(500));
    
    Ok(format!("Sent {} bytes to Relay", ct.len()))
}

pub fn check_inbox_mock() -> Result<Vec<String>> {
    // Return dummy decrypted messages for UI testing
    Ok(vec![
        "Signal strength: 98%".into(),
        "Handshake verified.".into()
    ])
}
