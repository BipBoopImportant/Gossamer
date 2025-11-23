use anyhow::Result;
use crate::core::crypto;
use futures_util::{SinkExt, StreamExt};
use serde_json::{json, Value};
use tokio_tungstenite::{connect_async, tungstenite::protocol::Message};
use url::Url;
use base64::prelude::*;
use secp256k1::{Secp256k1, Message as SecpMessage};
use sha2::{Sha256, Digest};

// In Rustls mode, connect_async automatically uses the bundled certs.
// No code change needed here, but we rewrite to ensure clean state.

pub async fn send_to_relay(dest_root: &[u8], msg: &str) -> Result<()> {
    let url = Url::parse("wss://relay.damus.io")?;
    let (mut ws, _) = connect_async(url).await?;

    // 1. Encrypt
    let (ct, nonce) = crypto::encrypt(dest_root, msg.as_bytes())?;
    let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
    let mailbox = crypto::generate_mailbox(dest_root, now);

    // 2. Construct Content
    let content = json!({
        "p": BASE64_STANDARD.encode(&ct),
        "n": BASE64_STANDARD.encode(&nonce)
    }).to_string();

    let (kp, pk) = crypto::get_ephemeral_signer();
    let pk_hex = hex::encode(pk.serialize());
    
    let event_json = json!([0, pk_hex, now, 1, [["t", mailbox]], content]).to_string();

    let mut hasher = Sha256::new();
    hasher.update(event_json.as_bytes());
    let id = hasher.finalize();
    let id_hex = hex::encode(id);

    let secp = Secp256k1::new();
    let sig = secp.sign_schnorr(&SecpMessage::from_slice(&id)?, &kp);
    let sig_hex = hex::encode(sig.as_ref());

    let final_msg = json!([
        "EVENT", {
            "id": id_hex,
            "pubkey": pk_hex,
            "created_at": now,
            "kind": 1,
            "tags": [["t", mailbox]],
            "content": content,
            "sig": sig_hex
        }
    ]);

    ws.send(Message::Text(final_msg.to_string())).await?;
    // Small delay to ensure transmit
    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    ws.close(None).await?;
    Ok(())
}

pub async fn check_relay(my_root: &[u8]) -> Result<Vec<String>> {
    let url = Url::parse("wss://relay.damus.io")?;
    let (mut ws, _) = connect_async(url).await?;

    let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs();
    let mailbox = crypto::generate_mailbox(my_root, now); 

    // Request last 50 messages
    let req = json!([ "REQ", "gossamer_sub", { "kinds": [1], "#t": [mailbox], "limit": 50 } ]);
    ws.send(Message::Text(req.to_string())).await?;

    let mut results = Vec::new();
    let timeout = tokio::time::sleep(tokio::time::Duration::from_secs(2));
    tokio::pin!(timeout);

    loop {
        tokio::select! {
            msg = ws.next() => {
                match msg {
                    Some(Ok(Message::Text(txt))) => {
                        if let Ok(v) = serde_json::from_str::<Value>(&txt) {
                            if v[0] == "EOSE" { break; }
                            if v[0] == "EVENT" {
                                let content = v[2]["content"].as_str().unwrap_or("");
                                // Handle both raw string and JSON envelope
                                let json_content = if let Ok(j) = serde_json::from_str::<Value>(content) { j } else { Value::Null };
                                
                                if let (Some(p), Some(n)) = (json_content["p"].as_str(), json_content["n"].as_str()) {
                                    let ct = BASE64_STANDARD.decode(p).unwrap_or_default();
                                    let nonce = BASE64_STANDARD.decode(n).unwrap_or_default();
                                    if let Ok(plain) = crypto::decrypt(my_root, &nonce, &ct) {
                                        results.push(String::from_utf8_lossy(&plain).to_string());
                                    }
                                }
                            }
                        }
                    }
                    _ => break,
                }
            }
            _ = &mut timeout => { break; }
        }
    }
    Ok(results)
}
