# 🕸️ Gossamer: The Digital Aether

![Status](https://img.shields.io/badge/Status-Production_Ready-00F0FF?style=for-the-badge) ![Mesh](https://img.shields.io/badge/Mesh-Multi--Hop_Active-FF005C?style=for-the-badge) ![Security](https://img.shields.io/badge/Crypto-XChaCha20--Poly1305-6C63FF?style=for-the-badge)

**Gossamer** is a decentralized, delay-tolerant, metadata-private messaging system. It allows devices to communicate securely without a central server, using a hybrid network of global Internet relays and local Bluetooth Mesh networking.

If the internet goes down, Gossamer keeps working.

---

## 🧩 The Concept (For Everyone)

Imagine you want to send a secret letter, but you don't want the Post Office to know you sent it.

1.  **Standard Apps:** You hand the letter to the Post Office (Server). They promise not to read it, but they write down exactly *who* sent it, *who* received it, and *when*. This is **Metadata**.
2.  **Gossamer:** You lock your letter in an unbreakable titanium box. You walk into a crowded city square and throw the box into the air.
    *   Everyone nearby catches a copy.
    *   They pass it to their friends, who pass it to their friends.
    *   Eventually, the box reaches the intended recipient.
    *   **Only they** have the key to open it.
    *   To everyone else, it’s just a locked box. They don't know who threw it, and they don't know who it's for.

**Gossamer digitizes this process.**
*   **Online:** It throws the "box" onto thousands of decentralized servers (Nostr Relays).
*   **Offline:** It whispers the "box" via Bluetooth Low Energy (BLE) to people walking past you.

---

## ✨ Key Capabilities

### 1. 📡 Multi-Hop Mesh Network
Gossamer devices act as **Relays**.
*   **Local Propagation:** Messages travel via Bluetooth between devices in physical proximity (~100 meters).
*   **Store-and-Forward:** If you are offline, your encrypted message hops onto nearby phones ("Mules"). These phones carry the message physically until they find an internet connection or the recipient.
*   **Blind Routing:** Intermediate nodes **cannot read** the message. They simply pass the encrypted blob along based on a temporary hash.

### 2. 🔐 Ghost Identities
*   **No Phone Numbers:** You are identified only by a cryptographic key pair.
*   **Rolling Mailboxes:** Your "address" changes every hour based on a secure schedule. Even if a spy monitors the network 24/7, they cannot link your messages together over time.
*   **Zero Metadata:** The network knows nothing about your social graph.

### 3. 🤝 Neural Handshake
*   **NFC:** Tap two phones together to instantly and securely exchange identities.
*   **QR Scanning:** Use the built-in scanner to verify a peer's identity visually.

---

## 📖 User Guide

### Installation
1.  Download the latest `.apk` from the **[Releases Page](../../releases)**.
2.  Install it on your Android device.

### First Run
The app will generate your **Root Secret**.
> ⚠️ **CRITICAL:** Go to **Settings (Gear Icon) > Identity Backup**. Write this key down. There is no "Forgot Password" button. If you lose this key, your identity is gone forever.

### How to Chat
1.  **Add Contact:** Tap the **New Message** button. You can:
    *   Tap the **NFC Icon** and touch phones with a friend.
    *   Tap the **QR Icon** to scan their screen.
2.  **Compose:** Write your message.
3.  **Send:** Tap **INITIATE UPLINK**.
    *   The app encrypts the payload.
    *   It uploads it to the Internet Relay (if available).
    *   It simultaneously broadcasts it via Bluetooth Mesh.

### The Radar
*   The **Radar Screen** visualizes the invisible network around you.
*   When you see **"MESH ONLINE"**, your phone is actively scanning for and broadcasting encrypted packets to nearby devices.

---

## 🛠️ Technical Stack

| Layer | Technology | Description |
| :--- | :--- | :--- |
| **UI Framework** | Flutter | Material 3, Riverpod, Custom Painters |
| **Core Logic** | Rust | Compiled to native ARM64 via FFI |
| **Bridge** | `flutter_rust_bridge` | Zero-copy communication between Dart and Rust |
| **Database** | SQLite | Thread-safe local storage |
| **Crypto** | `secp256k1` | Schnorr Signatures (Bitcoin compatible) |
| **Encryption** | XChaCha20-Poly1305 | Authenticated Encryption with Extended Nonce |

---

## 🏗️ Contributing

Gossamer is Open Source. We believe privacy is a human right.

1.  Fork this repository.
2.  Create a feature branch.
3.  Submit a Pull Request.

*"We are the ghosts in the machine."*
