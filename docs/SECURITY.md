# SPACE Security Plan

- No custom cryptography. Plan: libsignal (Signal Protocol) for 1:1; MLS (RFC 9420) or sender keys for groups.
- Server stores ciphertext, public keys and metadata only.
- `device_keys` and `one_time_prekeys` hold PUBLIC key material only. Private keys stay in Android Keystore / iOS Keychain.
- Prekeys are consumed through the `claim_prekey` RPC so they are single-use.
- Phase 1 contains NO encryption code. SPACE must not be described as secure or audited until Phase 5 is built and independently reviewed.
- Known gaps to address: block checks inside `create_direct_conversation`, rate limiting, metadata minimization, group membership RPCs.
