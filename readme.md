# 🛡️ Privacy-Preserving Fingerprint Verification System using zk-SNARKs

This project implements a zero-knowledge proof (zk-SNARK)-based fingerprint verification system that enables confidential identity screening at airport checkpoints. It verifies whether a scanned fingerprint matches any entry in a sensitive terrorist watchlist—**without revealing** either the individual's biometric data or the contents of the watchlist.This project is a prototype which can handle small inputs.

---

## ✨ Features

- ✅ Privacy-preserving fingerprint matching using zk-SNARKs  
- 🧠 ORB (Oriented FAST and Rotated BRIEF) feature-based fingerprint descriptor matching  
- 🔐 Deterministic Circom circuit for secure biometric comparison  
- 🧮 BigInt-based descriptor encoding for compatibility with finite field constraints  
- 🧾 Separation of proof generation (simulated airport terminal) and proof verification (government authorities)  

---

## 🧩 System Components

### 1. Tamper-Proof Fingerprint Scanner (Simulated)

⚠️ Hardware scanner functionality is simulated using image input and python.

- Input: Fingerprint image
- Processing:
  - Extract ORB keypoints and descriptors using OpenCV
  - Save results as `.pkl` for further processing

---

### 2. Feature Serialization & Encoding Module

- Converts `.pkl` files into Circom-compatible `.json` structure
- Pads and encodes keypoints/descriptors as **BigInts** to satisfy finite field constraints

---

### 3. Watchlist Loader

- Loads pre-processed terrorist fingerprint descriptors
- Validates structural compatibility with live scan data (padding, descriptor length, etc.)

---

### 4. Circom ORB Matcher Circuit

- Performs **binary descriptor comparison** using Hamming distances
- Applies a minimum match threshold (e.g., Lowe’s ratio test)
- Circuit Output: `1` for match, `0` for no match

---

### 5. zk-SNARK Prover

- Simulated airport terminal generates a **zero-knowledge proof** that:
  - A fingerprint match exists in the loaded watchlist
  - No fingerprint data or match index is leaked

---

### 6. zk-SNARK Verifier

- Government authority verifies the proof
- Learns **only** whether a valid match occurred—nothing else

---


---

## 🛠️ Tech Stack

- zk-SNARKs (Groth16 / PLONK via `snarkjs`)
- Circom for custom fingerprint match circuit
- OpenCV for ORB feature extraction
- Python for preprocessing and descriptor encoding
- Node.js for proof generation and verification

---

 This project  was developed as a mini project for the Network Security Lab as part of Mtech coursework.



