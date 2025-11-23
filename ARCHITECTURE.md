# ⚙️ Gossamer Technical Architecture

This document details the internal workings of the Gossamer protocol, the cryptographic primitives used, and the structure of the hybrid application.

## 1. System Overview

Gossamer is a **Hybrid Application**. It uses a "Hollow Shell" architecture:
*   **The Body (Flutter):** Handles the UI, touch events, Camera, NFC, and Bluetooth Radio management.
*   **The Brain (Rust):** Handles all cryptography, database management, protocol parsing, and routing logic.

Communication between the Body and Brain happens via the **Flutter Rust Bridge**, which compiles the Rust code into a native shared library (`libnative.so`) that is loaded by the Android JVM.

## 2. Cryptography

All security is derived from a single **Root Secret** (32-byte high-entropy seed).

### Key Derivation
*   **Identity Key:** `Secp256k1` keypair derived from the Root Secret. This is used to sign messages and establish identity.
*   **Encryption Keys:** Ephemeral keys are derived using `HKDF-SHA256` for every interaction.
*   **Database Encryption:** The local SQLite database is encrypted using a key derived from a user PIN via `Argon2id`.

### The Rolling Mailbox (Privacy)
To prevent metadata analysis, we do not route messages to a static Public Key.
1.  **Time Slot:** `T = UnixTime / 3600` (1-hour windows).
2.  **Mailbox ID:** `HMAC-SHA256(SharedSecret, T)`.
3.  **Result:** Messages are sent to a random-looking hash. An observer cannot tell that a message sent at 2:00 PM and a message sent at 4:00 PM are going to the same person.

### Payload Encryption
*   **Algorithm:** **XChaCha20-Poly1305**.
*   **Why?** It supports an **Extended Nonce (24 bytes)**, allowing us to use random nonces safely without risk of collision, which is critical for a stateless mesh network.

---

## 3. Protocols

### A. Nostr (Internet Layer)
We implement a subset of the **NIP-01** protocol.
*   **Event Kind:** `1` (Text Note) for persistence.
*   **Tags:** We use the `#t` tag to index the **Rolling Mailbox ID**.
*   **Content:** Base64 encoded ciphertext.

### B. Gossamer Mesh (Bluetooth Layer)
We use a custom binary protocol optimized for the **27-byte payload limit** of legacy Bluetooth Low Energy (BLE) advertisements.

**Packet Structure (Bincode Format):**
```rust
struct BlePacket {
    mb_short: u32,    // First 4 bytes of the Mailbox Hash (Routing)
    ts_short: u32,    // truncated Timestamp (Replay Protection)
    ct: Vec<u8>,      // Ciphertext (Truncated message)
}
```
###The Routing Loop:

Scan: The app scans for BLE frames with Manufacturer ID 0xFFFF.

Ingest: Raw bytes are passed to Rust.

Filter:

Rust calculates the user's current mb_short.

If it matches, it attempts decryption.

If it fails decryption, it saves the packet to the transit table.

Re-Broadcast: Every 20 seconds, the app stops advertising its own identity and broadcasts a random packet from the transit table. This creates a "Rumor Mill" gossip protocol.

###4. Data Persistence

Data is stored in gossamer.db, a local SQLite database.

messages: Stores send/received chats.

identity: Stores the Root Secret.

contacts: Maps Public Keys to Human Aliases.

transit: A bounded FIFO queue of encrypted packets waiting to be relayed to other devices.

###5. Build Pipeline

The APK is compiled via GitHub Actions:

Ubuntu Runner: Sets up Java 17, Flutter 3.19, and Rust 1.75.

Codegen: Runs flutter_rust_bridge_codegen to generate type-safe Dart bindings.

NDK: Cross-compiles the Rust code for aarch64-linux-android (ARM64).

Gradle: Links the .so shared library with the Flutter engine and builds the final APK.
