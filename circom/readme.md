
# ZK Proof Generation Workflow

---

## 1. Circuit Compilation
Compile your Circom circuit to generate the necessary files.  
```bash
circom matcher.circom --r1cs --wasm --sym
```

---

## 2. Witness Generation
Generate the witness using the compiled WebAssembly file and the input JSON data.  
```bash
node matcher_js/generate_witness.js matcher_js/matcher.wasm input.json witness.wtns
```

---

## 3. Export the Witness to JSON
Export the witness to a JSON format for later use.  
```bash
snarkjs wtns export json witness.wtns witness.json
```

---

## 4. Starting the Ceremony
Start a new powersoftau ceremony with a specific curve and set the number of constraints.  
```bash
snarkjs powersoftau new bn128 13 pot13_0000.ptau -v
```

---

## 5. Contribute Entropy
Add your contribution (entropy) to the ceremony.  
```bash
snarkjs powersoftau contribute pot13_0000.ptau pot13_0001.ptau --name="Your Name" -v
```

---

## 6. Phase 2 Preparation
Prepare for Phase 2 of the ceremony, finalizing the powersoftau.  
```bash
snarkjs powersoftau prepare phase2 pot13_0001.ptau pot13_final.ptau -v
```

---

## 7. Groth16 Setup
Perform the Groth16 setup to create the `.zkey` file for your circuit.  
```bash
snarkjs groth16 setup matcher.r1cs pot13_final.ptau circuit_0000.zkey
```

---

## 8. Contribute to the .zkey
Add your contribution to the `.zkey` file.  
```bash
snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="Your Contribution" -v
```

---

## 9. Export the Verification Key
Export the verification key for later verification.  
```bash
snarkjs zkey export verificationkey circuit_0001.zkey verification_key.json
```

---

## 10. Generate the Proof
Generate the proof using your `.zkey` file and witness.  
```bash
snarkjs groth16 prove circuit_0001.zkey witness.wtns proof.json public.json
```

---

## 11. Verify the Proof
Verify the generated proof using the verification key.  
```bash
snarkjs groth16 verify verification_key.json public.json proof.json
```

---

This step-by-step process will guide you from compiling the circuit to verifying the proof, ensuring every stage is completed smoothly.
