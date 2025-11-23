# 🕸️ Gossamer: The Digital Aether

![Status](https://img.shields.io/badge/Status-Production_Ready-00F0FF?style=for-the-badge) ![Mesh](https://img.shields.io/badge/Mesh-Multi--Hop_Active-FF005C?style=for-the-badge) ![Security](https://img.shields.io/badge/Crypto-XChaCha20--Poly1305-6C63FF?style=for-the-badge)

**Gossamer** is a decentralized, delay-tolerant, metadata-private messaging system. It allows devices to communicate securely without a central server, using both global Internet relays and local Bluetooth Mesh networking.

---

## 🚀 Core Capabilities

### 1. 📡 Multi-Hop Mesh Network
Gossamer devices act as **Relays**.
*   **Local:** Messages travel via Bluetooth Low Energy (BLE) between devices in proximity.
*   **Store-and-Forward:** If you are offline, your message is encrypted and stored on nearby phones ("Mules"). These phones carry your message physically until they meet the recipient or reach the internet.
*   **Blind Routing:** Intermediate nodes **cannot read** the message or know who it is for. They only see a rolling hash "Mailbox ID".

### 2. 🔐 Identity & Security
*   **Ephemeral Identities:** No phone numbers. No emails. Just a cryptographic key pair.
*   **Zero Metadata:** The network does not know who is talking to whom.
*   **Encryption:** All payloads are encrypted with **XChaCha20-Poly1305**.
*   **Perfect Forward Secrecy:** Keys roll over every hour.

### 3. 🤝 Physical Handshake
*   **NFC Neural Link:** Tap two phones together to securely exchange identities instantly.
*   **QR Code Scanning:** Scan a peer's code to add them to your encrypted contact list.

---

## 📖 User Guide

### Getting Started
1.  **Install:** Download the `.apk` from the Releases tab.
2.  **Setup:** The app auto-generates your **Root Secret** on first launch. Back this up in Settings!

### Sending a Message
1.  Tap **NEW MESSAGE**.
2.  **Select Recipient:**
    *   **Scan QR:** Tap the QR icon to scan a friend's screen.
    *   **NFC:** Tap the Wifi/NFC icon and touch phones.
    *   **Contacts:** Tap the Book icon to pick a saved contact.
3.  **Type & Send:** Your message is instantly encrypted and blasted out via **Both** Internet (Nostr) and Bluetooth (Mesh).

### Receiving
*   **Radar Screen:** Watch the scanner. When "MESH ONLINE" appears, you are actively relaying packets.
*   **Inbox:** Messages decrypt automatically when they arrive.

---

## 🛠️ Technical Stack

| Layer | Technology |
| :--- | :--- |
| **UI** | Flutter (Material 3, Riverpod, Animate) |
| **Bridge** | `flutter_rust_bridge` (FFI) |
| **Core Logic** | Rust (Tokio Async Runtime) |
| **Database** | SQLite (Bundled, Thread-Safe) |
| **Crypto** | `secp256k1` (Signatures), `chacha20poly1305` (Encryption) |
| **Protocol** | Nostr (NIP-01) + Custom Binary BLE Protocol |

### Mesh Protocol Specs
*   **Transport:** BLE Manufacturer Data (0xFFFF)
*   **Format:** Bincode (Compact Binary)
*   **Routing:** Epidemic / Gossip Protocol with TTL
*   **Packet Size:** < 27 Bytes (Legacy BLE Compatible)

---

## 🔮 Future Roadmap
*   [ ] **Image Support:** Sharding large files into BLE streams.
*   [ ] **Group Chats:** Ratchet trees for multi-party encryption.
*   [ ] **Desktop Client:** Linux/Windows support.

---

*"We are the ghosts in the machine."*
