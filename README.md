
# 🕸️ Gossamer: The Digital Aether

![Gossamer Status](https://img.shields.io/badge/Status-Operational-00F0FF?style=for-the-badge) ![Encryption](https://img.shields.io/badge/Encryption-End--to--End-6C63FF?style=for-the-badge) ![Mesh](https://img.shields.io/badge/Mesh-Active-FF005C?style=for-the-badge)

**Gossamer** is a secure, decentralized messaging system that works even when the internet doesn't. It turns every phone into a relay node, creating an invisible, unbreakable network of communication.

---

## 🧐 What is Gossamer? (The Analogy)

Imagine sending a letter.

*   **Standard Apps (WhatsApp, Signal):** You give your letter to a single, giant Post Office (Server). If the Post Office burns down, or if the roads (Internet) are closed, your letter is lost.
*   **Gossamer:** You fold your letter into a paper airplane. You throw it into a crowd.
    *   Everyone catches it, but it's locked in a titanium box.
    *   They pass it along to their neighbors.
    *   Eventually, it reaches your friend. Their key opens the box.
    *   **No Post Office required.**

Gossamer uses both the **Internet** (when available) and **Bluetooth** (when offline) to ensure your message *always* finds a path.

---

## ✨ Key Features

### 📡 Hybrid Mesh Network
Gossamer is **Delay-Tolerant**. It doesn't care if you are offline right now.
*   **Internet Mode:** Uses global, censorship-resistant **Nostr** relays to bounce messages across the world.
*   **Offline Mode:** Uses **Bluetooth Low Energy (BLE)** to whisper messages to nearby phones. If you are at a concert, protest, or subway with no signal, you can still chat with people around you.

### 👻 Ghost Identities
You don't have a phone number. You don't have a username.
*   **Rolling IDs:** Your "address" changes every hour. Even if someone intercepts a message, they can't tell it was for you, because your address has already changed by the time they look at it.
*   **Zero Metadata:** The network knows *nothing* about who is talking to whom.

### 🔐 Military-Grade Encryption
*   **XChaCha20-Poly1305:** The same encryption standard used by WireGuard and Google.
*   **Perfect Forward Secrecy:** Even if your key is stolen tomorrow, your messages from yesterday remain locked forever.

### 🤝 Physical Handshake
*   **NFC Neural Link:** Tap two phones together to securely exchange keys. No typing required.
*   **QR Code Scan:** Instantly verify identities through a camera scan.

---

## 🚀 Getting Started

### 1. Install
Download the latest `app-release.apk` from the **[Releases Page](../../releases)**.

### 2. Create Identity
When you launch Gossamer, it generates a **Root Secret**.
> ⚠️ **WARNING:** This key is *YOU*. If you lose it, you lose your account forever. There is no "Password Reset." Write it down.

### 3. Connect with Friends
*   **Tap:** Open the "Identity" tab and tap "NFC Share". Tap your friend's phone.
*   **Scan:** Use the "Scan" button in the Compose screen to scan their QR code.

### 4. Send a Message
*   Type your message.
*   Hit **INITIATE UPLINK**.
*   The Radar will pulse. Your message is now floating in the Digital Aether, hunting for its destination.

---

## 🛠️ Technical Architecture

For the engineers and cyber-punks:

| Component | Technology | Description |
| :--- | :--- | :--- |
| **UI Framework** | Flutter (Dart) | Material 3, Riverpod State Management |
| **Core Logic** | Rust | Compiled to native code via FFI |
| **Database** | SQLite (SQLCipher) | AES-256 Encrypted local storage |
| **Protocol** | Nostr (NIP-01) | Decentralized relay protocol |
| **Local Mesh** | BLE Advertising | Custom compact binary protocol |
| **Signatures** | Schnorr (BIP-340) | Bitcoin-compatible cryptographic signatures |

### Directory Structure
*   `lib/`: The Flutter Frontend (The Face).
*   `native/`: The Rust Backend (The Brain).
*   `.github/workflows/`: The Cloud Build System (The Factory).

---

## 🔮 Future Roadmap

*   [ ] **Image Support:** Splitting large files into tiny BLE packets.
*   [ ] **Multi-Hop Routing:** allowing messages to jump from Phone A -> Phone B -> Phone C via Bluetooth.
*   [ ] **Desktop Client:** Linux/Windows/Mac support.

---

## 🤝 Contributing

Gossamer is Open Source. We believe privacy is a human right.

1.  Fork the repo.
2.  Create a branch (`git checkout -b feature/amazing-idea`).
3.  Commit your changes.
4.  Push to the branch.
5.  Open a Pull Request.

---

*"We are the ghosts in the machine."*
