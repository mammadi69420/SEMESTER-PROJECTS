from cryptography.fernet import Fernet

def generate_key():
    """Generates a key and returns it."""
    return Fernet.generate_key()

def encrypt_message(message, key):
    """
    Encrypts a message using the provided key.
    
    Args:
        message (str): The message to encrypt.
        key (bytes): The Fernet key.
        
    Returns:
        bytes: The encrypted message.
    """
    f = Fernet(key)
    encrypted_message = f.encrypt(message.encode())
    return encrypted_message

def decrypt_message(encrypted_message, key):
    """
    Decrypts an encrypted message using the provided key.
    
    Args:
        encrypted_message (bytes): The message to decrypt.
        key (bytes): The Fernet key.
        
    Returns:
        str: The decrypted message.
    """
    f = Fernet(key)
    decrypted_message = f.decrypt(encrypted_message).decode()
    return decrypted_message
