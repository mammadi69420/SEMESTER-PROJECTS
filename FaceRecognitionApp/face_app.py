import sys
import subprocess

def install_dependencies():
    packages = {
        'cv2': 'opencv-contrib-python',  # Requires contrib for face recognition module
        'PIL': 'Pillow',
        'numpy': 'numpy'
    }
    
    for module_name, package_name in packages.items():
        try:
            if module_name == 'cv2':
                import cv2
                cv2.face  # Accessing cv2.face to check if contrib is installed
            else:
                __import__(module_name)
        except (ImportError, AttributeError):
            print(f"Installing missing dependency: {package_name}")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package_name])

# Run dependency check before importing anything else
install_dependencies()

import cv2
import tkinter as tk
from tkinter import messagebox, simpledialog
from PIL import Image, ImageTk
import os
import json
import numpy as np
import shutil

class FaceApp:
    def __init__(self, window, window_title):
        self.window = window
        self.window.title(window_title)
        
        # Paths setup
        self.dataset_path = 'dataset'
        self.trainer_file = 'trainer.yml'
        self.names_file = 'names.json'
        
        if not os.path.exists(self.dataset_path):
            os.makedirs(self.dataset_path)
        # Load cascade classifier
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        # Load recognizer
        self.recognizer = cv2.face.LBPHFaceRecognizer_create()
        self.names = {}
        self.load_names()
        
        # state flags
        self.mode = 'idle' # idle, register, recognize
        self.register_count = 0
        self.current_user_id = 0
        self.target_count = 0
        
        # Guided registration stages (e.g., 5 stages total)
        self.guided_instructions = ["Look Straight Ahead"]
        
        # Check if trained file exists, if so load it
        if os.path.exists(self.trainer_file):
            try:
                self.recognizer.read(self.trainer_file)
                print("Model loaded.")
            except Exception as e:
                print(f"Could not load model: {e}")

        # Open video source (by default webcam 0)
        self.vid = cv2.VideoCapture(0)

        # UI Elements
        self.top_frame = tk.Frame(window, bg='grey')
        self.top_frame.pack(fill=tk.X)
        
        self.btn_register = tk.Button(self.top_frame, text="Register Face", width=15, command=self.start_register)
        self.btn_register.pack(side=tk.LEFT, padx=10, pady=10)
        
        self.btn_recognize = tk.Button(self.top_frame, text="Recognize Face", width=15, command=self.start_recognize)
        self.btn_recognize.pack(side=tk.LEFT, padx=10, pady=10)
        
        self.btn_manage = tk.Button(self.top_frame, text="Manage Users", width=15, command=self.manage_users)
        self.btn_manage.pack(side=tk.LEFT, padx=10, pady=10)
        
        self.btn_stop = tk.Button(self.top_frame, text="Stop All / Idle", width=15, command=self.stop_all)
        self.btn_stop.pack(side=tk.LEFT, padx=10, pady=10)

        self.lbl_status = tk.Label(self.top_frame, text="Status: Idle", fg="blue", bg="grey")
        self.lbl_status.pack(side=tk.RIGHT, padx=20)

        # Create a canvas that can fit the above video source size
        self.canvas = tk.Canvas(window, width=self.vid.get(cv2.CAP_PROP_FRAME_WIDTH), height=self.vid.get(cv2.CAP_PROP_FRAME_HEIGHT))
        self.canvas.pack()

        # After it is called once, the update method will be automatically called every delay milliseconds
        self.delay = 15
        self.update()

        self.window.protocol("WM_DELETE_WINDOW", self.on_closing)
        self.window.mainloop()

    def load_names(self):
        if os.path.exists(self.names_file):
            with open(self.names_file, 'r') as f:
                self.names = json.load(f)
                # Ensure keys are integers
                self.names = {int(k): v for k, v in self.names.items()}
        else:
            self.names = {}

    def save_names(self):
        with open(self.names_file, 'w') as f:
            json.dump(self.names, f)

    def start_register(self):
        name = simpledialog.askstring("Input", "Enter your Name:", parent=self.window)
        if name:
            # Check if name already exists
            existing_id = None
            for uid, uname in self.names.items():
                if uname.lower() == name.lower():
                    existing_id = uid
                    break

            if existing_id is not None:
                self.current_user_id = existing_id
                user_folder = os.path.join(self.dataset_path, name)
                # Count existing photos for this user
                existing_photos = [f for f in os.listdir(user_folder) if f.startswith(f"User.{existing_id}.")] if os.path.exists(user_folder) else []
                self.register_count = len(existing_photos)
                print(f"Found existing user {name} with ID {self.current_user_id}. Appending to {self.register_count} existing samples.")
            else:
                self.current_user_id = max(self.names.keys() if self.names else [0]) + 1
                self.names[self.current_user_id] = name
                self.save_names()
                self.register_count = 0
                user_folder = os.path.join(self.dataset_path, name)
                if not os.path.exists(user_folder):
                    os.makedirs(user_folder)
                print(f"Created new user {name} with ID {self.current_user_id}.")

            self.target_count = self.register_count + 50 # 5 stages * 10 samples each = 50 MORE samples
            self.guided_stage = 0
            self.mode = 'register'
            self.lbl_status.config(text=f"Status: Registering '{name}'...")
    
    def start_recognize(self):
        if not os.path.exists(self.trainer_file):
            messagebox.showwarning("Warning", "No faces registered yet! Register a face first.")
            return
        self.mode = 'recognize'
        self.lbl_status.config(text="Status: Recognizing faces...")

    def stop_all(self):
        self.mode = 'idle'
        self.lbl_status.config(text="Status: Idle")

    def manage_users(self):
        self.stop_all() # pause recognizing/registering
        
        manage_win = tk.Toplevel(self.window)
        manage_win.title("Manage Users")
        manage_win.geometry("300x400")
        
        lbl = tk.Label(manage_win, text="Registered Users:", font=("Arial", 12))
        lbl.pack(pady=10)
        
        listbox = tk.Listbox(manage_win, width=30, height=15)
        listbox.pack(pady=5)
        
        # Populate listbox
        # Use a mapping to easily find the ID to delete later
        listbox_mapping = [] 
        for uid, uname in self.names.items():
            listbox.insert(tk.END, f"ID: {uid} - {uname}")
            listbox_mapping.append(uid)
            
        def delete_selected():
            selection = listbox.curselection()
            if not selection:
                messagebox.showwarning("Warning", "Select a user to delete.", parent=manage_win)
                return
                
            index = selection[0]
            uid_to_delete = listbox_mapping[index]
            uname_to_delete = self.names[uid_to_delete]
            
            confirm = messagebox.askyesno("Confirm", f"Are you sure you want to delete '{uname_to_delete}' (ID: {uid_to_delete}) and all their face data?", parent=manage_win)
            
            if confirm:
                # 1. Remove from dictionary and save
                del self.names[uid_to_delete]
                self.save_names()
                
                # 2. Delete the user's image folder from dataset
                user_folder = os.path.join(self.dataset_path, uname_to_delete)
                if os.path.exists(user_folder):
                    # Count files before deleting for the info message
                    deleted_count = len([f for f in os.listdir(user_folder) if os.path.isfile(os.path.join(user_folder, f))])
                    shutil.rmtree(user_folder)
                else:
                    deleted_count = 0
                
                # 3. Retrain model
                messagebox.showinfo("Info", f"Deleted folder and {deleted_count} images for {uname_to_delete}. Retraining model...", parent=manage_win)
                self.train_model()
                
                # 4. Refresh Listbox
                listbox.delete(index)
                del listbox_mapping[index]
                messagebox.showinfo("Success", f"User '{uname_to_delete}' successfully removed.", parent=manage_win)

        btn_delete = tk.Button(manage_win, text="Delete Selected User", bg="red", fg="white", command=delete_selected)
        btn_delete.pack(pady=10)

        # Close button
        btn_close = tk.Button(manage_win, text="Close", command=manage_win.destroy)
        btn_close.pack(pady=5)

    def update(self):
        ret, frame = self.vid.read()
        
        if ret:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY) if len(frame.shape) == 3 else frame
            
            # Detect frontal faces only
            faces = self.face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

            if self.mode == 'register':
                # Display instruction
                cv2.putText(frame, self.guided_instructions[0], (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 3)

                for (x, y, w, h) in faces:
                    cv2.rectangle(frame, (x,y), (x+w,y+h), (255,0,0), 2)
                    self.register_count += 1
                    user_name = self.names[self.current_user_id]
                    
                    # Extract face and apply Histogram Equalization to normalize lighting
                    face_crop = gray[y:y+h, x:x+w]
                    face_crop = cv2.equalizeHist(face_crop)
                    
                    save_path = os.path.join(self.dataset_path, user_name, f"User.{self.current_user_id}.{self.register_count}.jpg")
                    cv2.imwrite(save_path, face_crop)
                    
                    # Target count progress
                    cv2.putText(frame, f"Samples: {self.register_count}/{self.target_count}", (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255,0,0), 2)
                    
                    if self.register_count >= self.target_count:
                        self.mode = 'idle'
                        self.lbl_status.config(text="Status: Training Model...")
                        self.window.update()
                        self.train_model()
                        self.lbl_status.config(text="Status: Idle - Registration Complete")
                        messagebox.showinfo("Success", "Face Registered Successfully!")
                        break # Only capture up to target_count

            elif self.mode == 'recognize':
                for (x, y, w, h) in faces:
                    # Extract face and apply Histogram Equalization
                    face_crop = gray[y:y+h, x:x+w]
                    face_crop = cv2.equalizeHist(face_crop)
                    
                    id_, confidence = self.recognizer.predict(face_crop)
                    
                    # Check confidence. 0 is perfect match. For LBPH, a lower number means a better match.
                    # A distance > 55 is often a false positive with equalization.
                    
                    if confidence < 55:
                        name = self.names.get(id_, "Unknown")
                        # Adjusted accuracy calculation for equalized images
                        accuracy = max(0, min(100, round(100 - (confidence * 1.5))))
                        conf_str = f"  {accuracy}% match"
                        color = (0, 255, 0) # Green for recognized
                    else:
                        name = "Unknown"
                        conf_str = ""
                        color = (0, 0, 255) # Red for unknown
                    
                    cv2.rectangle(frame, (x,y), (x+w,y+h), color, 2)
                    cv2.putText(frame, str(name), (x+5, y-5), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)
                    if conf_str:
                        cv2.putText(frame, str(conf_str), (x+5, y+h-5), cv2.FONT_HERSHEY_SIMPLEX, 1, (255,255,0), 1)

            # Convert frame to format Tkinter accepts
            frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            self.photo = ImageTk.PhotoImage(image=Image.fromarray(frame))
            self.canvas.create_image(0, 0, image=self.photo, anchor=tk.NW)
            
        self.window.after(self.delay, self.update)

    def train_model(self):
        # Recursively find all .jpg files inside dataset/ directory subfolders
        imagePaths = []
        for root, dirs, files in os.walk(self.dataset_path):
            for file in files:
                if file.endswith(".jpg"):
                    imagePaths.append(os.path.join(root, file))
                    
        faceSamples = []
        ids = []
        
        for imagePath in imagePaths:
            try:
                PIL_img = Image.open(imagePath).convert('L') # Convert to grayscale
                img_numpy = np.array(PIL_img, 'uint8')
                
                # Extract user id from filename: User.ID.Count.jpg
                id_ = int(os.path.split(imagePath)[-1].split(".")[1])
                
                # Detect face in sample image
                faces = self.face_cascade.detectMultiScale(img_numpy, scaleFactor=1.1, minNeighbors=3, minSize=(20, 20))
                
                # It should only find 1 main face in cropped sample pictures anyway
                for (x, y, w, h) in faces:
                    face_roi = img_numpy[y:y+h, x:x+w]
                    # Apply equalization during training as well
                    face_roi = cv2.equalizeHist(face_roi)
                    faceSamples.append(face_roi)
                    ids.append(id_)
                    break # Just take the first valid detection in the cropped image
            except Exception as e:
                print(f"Error processing {imagePath}: {e}")

        if len(faceSamples) > 0 and len(ids) > 0:
            print("Training...")
            self.recognizer.train(faceSamples, np.array(ids))
            self.recognizer.write(self.trainer_file)
            print(f"Model trained with {len(np.unique(ids))} faces and saved.")
        else:
            print("Not enough data to train.")

    def on_closing(self):
        self.vid.release()
        self.window.destroy()

if __name__ == '__main__':
    FaceApp(tk.Tk(), "Face Recognition System")
