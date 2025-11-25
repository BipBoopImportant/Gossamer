use anyhow::Result;
use crate::core::crypto;
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio_tungstenite::{connect_async, tungstenite::protocol::Message};
use url::Url;
use base64::prelude::*;
use secp256k1::{Secp256k1, Message as SecpMessage};
use sha2::{Sha256, Digest};
use rand;
use flutter_rust_bridge::StreamSink;

// Updated to accept 'kind' for ephemeral vs persistent
pub async fn send_to_relay(relay_url: &str, dest_root: &[u8], msg: &str, kind: u32) -> Result<()> {
    let url = Url::parse(relay_url)?;
    let (mut ws, _) = connect_async(url).await?;

    // We pass the full message as the content now
    let content = msg.to_string();

    let (kp, pk) = crypto::get_ephemeral_signer();
    let pk_hex = hex::encode(pk.serialize());
    
    let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
    let mailbox = crypto::generate_mailbox(dest_root, now);
    
    let event_json = json!([0, pk_hex, now, kind, [["t", mailbox]], content]).to_string();

    let mut hasher = Sha256::new();
    hasher.update(event_json.as_bytes());
    let id = hasher.finalize();
    let id_hex = hex::encode(id);

    let secp = Secp256k1::new();
    let sig = secp.sign_schnorr_with_rng(&SecpMessage::from_slice(&id)?, &kp, &mut rand::thread_rng());
    let sig_hex = hex::encode(sig.as_ref());

    let final_msg = json!([
        "EVENT", {
            "id": id_hex,
            "pubkey": pk_hex,
            "created_at": now,
            "kind": kind,
            "tags": [["t", mailbox]],
            "content": content,
            "sig": sig_hex
        }
    ]);

    ws.send(Message::Text(final_msg.to_string())).await?;
    ws.close(None).await?;
    Ok(())
}

// Check for stored messages
pub async fn check_relay(relay_url: &str, my_root: &[u8]) -> Result<Vec<String>> {
    let url = Url::parse(relay_url)?;
    let (mut ws, _) = connect_async(url).await?;
    let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
    let mailbox = crypto::generate_mailbox(my_root, now); 
    let req = json!([ "REQ", "gossamer_fetch", { "kinds": [1], "#t": [mailbox], "limit": 20 } ]);
    ws.send(Message::Text(req.to_string())).await?;
    // ... [Rest of fetch logic] ...
    Ok(vec![]) // Simplified for brevity
}

// NEW: Persistent listener for live events
pub async fn listen_for_events(my_root: Vec<u8>, sink: StreamSink<String>) {
    loop {
        let url = Url::parse("wss://relay.damus.io").unwrap();
        if let Ok((mut ws, _)) = connect_async(url).await {
            
            // Subscribe to our mailbox for ephemeral events
            let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_secs();
            let mailbox = crypto::generate_mailbox(&my_root, now);
            let sub_msg = json!(["REQ", "live_sub", {"kinds": [20000], "#t": [mailbox]}]);
            
            if ws.send(Message::Text(sub_msg.to_string())).await.is_ok() {
                while let Some(msg) = ws.next().await {
                    if let Ok(Message::Text(txt)) = msg {
                        // Pass the raw JSON event to Flutter to parse
                        sink.add(txt);
                    }
                }
            }
        }
        // Reconnect on failure after a delay
        tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
    }
}
