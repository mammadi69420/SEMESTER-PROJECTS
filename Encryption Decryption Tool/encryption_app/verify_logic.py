import crypto_logic as crypto

def test_encryption_decryption():
    try:
        # Generate Key
        key = crypto.generate_key()
        print(f"Generated Key: {key}")
        
        # Test Data
        original_message = "Secret Message"
        
        # Encrypt
        encrypted = crypto.encrypt_message(original_message, key)
        print(f"Encrypted: {encrypted}")
        
        # Decrypt
        decrypted = crypto.decrypt_message(encrypted, key)
        print(f"Decrypted: {decrypted}")
        
        # Validation
        assert original_message == decrypted
        print("SUCCESS: Decryption matches original message.")
        
    except Exception as e:
        print(f"FAILURE: {e}")

if __name__ == "__main__":
    test_encryption_decryption()
