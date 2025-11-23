# Gossamer - Decentralized Mesh Messenger

Gossamer is a metadata-private, delay-tolerant messaging system built with **Flutter** and **Rust**.

## Features
- **Zero Metadata:** Messages are routed via rolling hash identifiers.
- **End-to-End Encryption:** XChaCha20-Poly1305 by default.
- **Hybrid Network:**
  - **Internet:** NIP-01 Nostr Relays (Global)
  - **Local Mesh:** Bluetooth Low Energy (BLE) Advertising (Proximity)
- **Identity:** Ephemeral identities with QR and NFC exchange.

## Architecture
- **Frontend:** Flutter (Material 3, Riverpod, Animations)
- **Backend:** Rust (Tokio, Sqlite, Secp256k1)
- **Bridge:** flutter_rust_bridge FFI

## Usage
1. Exchange keys via QR/NFC.
2. Send message.
3. App attempts delivery via Relay AND Bluetooth Broadcast simultaneously.
