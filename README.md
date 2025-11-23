# Gossamer - Decentralized Mesh Messenger

Gossamer is a metadata-private, delay-tolerant messaging system built with **Flutter** and **Rust**.

## Features
- **Zero Metadata:** Messages are routed via rolling hash identifiers.
- **End-to-End Encryption:** XChaCha20-Poly1305 by default.
- **Store & Forward:** Works via global relays (Nostr) and local mesh (Future BLE).
- **Identity:** Ephemeral identities with QR and NFC exchange.

## Architecture
- **Frontend:** Flutter (Material 3, Riverpod, Animations)
- **Backend:** Rust (Tokio, Sqlite, Secp256k1)
- **Protocol:** NIP-01 (Nostr) + Custom Rolling Mailbox

## Build
This project builds automatically via GitHub Actions.
