import tkinter as tk
from tkinter import messagebox
import crypto_logic as crypto

class EncryptionApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Secure Encryption Tool")
        self.root.geometry("600x600")
        self.root.configure(bg="#2E3440")  # Dark background

        # Styles
        self.bg_color = "#2E3440"
        self.fg_color = "#D8DEE9"  # whitish text
        self.accent_color = "#88C0D0"  # light blue
        self.button_color = "#4C566A"
        self.button_text = "#ECEFF4"
        self.input_bg = "#3B4252"
        self.input_fg = "#ECEFF4"
        
        # Font settings
        self.header_font = ("Helvetica", 16, "bold")
        self.label_font = ("Helvetica", 12)
        self.text_font = ("Consolas", 10)

        self.create_widgets()

    def create_widgets(self):
        # Header
        header = tk.Label(self.root, text="Encryption & Decryption Tool", 
                          bg=self.bg_color, fg=self.accent_color, font=self.header_font)
        header.pack(pady=20)

        # Key Section
        key_frame = tk.Frame(self.root, bg=self.bg_color)
        key_frame.pack(fill="x", padx=20, pady=10)

        tk.Label(key_frame, text="Encryption Key:", bg=self.bg_color, fg=self.fg_color, font=self.label_font).pack(anchor="w")
        
        self.key_entry = tk.Entry(key_frame, bg=self.input_bg, fg=self.input_fg, font=self.text_font, relief="flat", insertbackground="white")
        self.key_entry.pack(fill="x", pady=5, ipady=5)

        btn_frame = tk.Frame(key_frame, bg=self.bg_color)
        btn_frame.pack(fill="x", pady=5)
        
        tk.Button(btn_frame, text="Generate Key", command=self.generate_key, 
                  bg=self.button_color, fg=self.button_text, relief="flat", activebackground=self.accent_color).pack(side="left", padx=5)
        tk.Button(btn_frame, text="Copy Key", command=self.copy_key, 
                   bg=self.button_color, fg=self.button_text, relief="flat", activebackground=self.accent_color).pack(side="left", padx=5)

        # Input Section
        input_frame = tk.Frame(self.root, bg=self.bg_color)
        input_frame.pack(fill="both", expand=True, padx=20, pady=10)
        
        tk.Label(input_frame, text="Input Text:", bg=self.bg_color, fg=self.fg_color, font=self.label_font).pack(anchor="w")
        self.input_text = tk.Text(input_frame, height=5, bg=self.input_bg, fg=self.input_fg, font=self.text_font, relief="flat", insertbackground="white")
        self.input_text.pack(fill="x", pady=5)

        # Action Buttons
        action_frame = tk.Frame(self.root, bg=self.bg_color)
        action_frame.pack(fill="x", padx=20, pady=10)
        
        tk.Button(action_frame, text="Encrypt", command=self.encrypt, 
                  bg=self.accent_color, fg="#2E3440", font=("Helvetica", 10, "bold"), relief="flat", width=15).pack(side="left", padx=20)
        tk.Button(action_frame, text="Decrypt", command=self.decrypt, 
                  bg=self.accent_color, fg="#2E3440", font=("Helvetica", 10, "bold"), relief="flat", width=15).pack(side="right", padx=20)

        # Output Section
        output_frame = tk.Frame(self.root, bg=self.bg_color)
        output_frame.pack(fill="both", expand=True, padx=20, pady=10)
        
        tk.Label(output_frame, text="Result:", bg=self.bg_color, fg=self.fg_color, font=self.label_font).pack(anchor="w")
        self.output_text = tk.Text(output_frame, height=5, bg=self.input_bg, fg=self.input_fg, font=self.text_font, relief="flat", state="disabled")
        self.output_text.pack(fill="x", pady=5)

    def generate_key(self):
        key = crypto.generate_key()
        self.key_entry.delete(0, tk.END)
        self.key_entry.insert(0, key.decode())

    def copy_key(self):
        key = self.key_entry.get()
        if key:
            self.root.clipboard_clear()
            self.root.clipboard_append(key)
            messagebox.showinfo("Success", "Key copied to clipboard!")
        else:
            messagebox.showwarning("Warning", "No key to copy!")

    def encrypt(self):
        key = self.key_entry.get()
        message = self.input_text.get("1.0", tk.END).strip()
        
        if not key:
            messagebox.showerror("Error", "Please provide an encryption key.")
            return
        if not message:
            messagebox.showerror("Error", "Please enter text to encrypt.")
            return
            
        try:
            encrypted = crypto.encrypt_message(message, key.encode())
            self.output_text.config(state="normal")
            self.output_text.delete("1.0", tk.END)
            self.output_text.insert("1.0", encrypted.decode())
            self.output_text.config(state="disabled")
        except Exception as e:
            messagebox.showerror("Error", f"Encryption Failed: {str(e)}")

    def decrypt(self):
        key = self.key_entry.get()
        message = self.input_text.get("1.0", tk.END).strip()
        
        if not key:
            messagebox.showerror("Error", "Please provide an encryption key.")
            return
        if not message:
            messagebox.showerror("Error", "Please enter ciphertext to decrypt.")
            return
            
        try:
            decrypted = crypto.decrypt_message(message.encode(), key.encode())
            self.output_text.config(state="normal")
            self.output_text.delete("1.0", tk.END)
            self.output_text.insert("1.0", decrypted)
            self.output_text.config(state="disabled")
        except Exception as e:
            messagebox.showerror("Error", "Decryption Failed. Check your key and input.")

if __name__ == "__main__":
    root = tk.Tk()
    app = EncryptionApp(root)
    root.mainloop()
