#include <iostream>
#include <string>
#include <fstream>


using namespace std;

struct Node {
string text;
Node* next;
Node* prev;
};

struct Undo {
string tempText; 
Node* tempNode; 
Undo* next;
};

class Notepad {
private:
Node* head;
Node* tail;
Undo* undoHead;

void pushUndo(string t) {
Undo* newNode = new Undo();
newNode->tempText = t;
newNode->tempNode = nullptr; 
newNode->next = undoHead;
undoHead = newNode;
}

public:
Notepad() {
head = nullptr;
tail = nullptr;
undoHead = nullptr;
}

void addLine(string text) {
Node* newNode = new Node();
newNode->text = text;
newNode->next = nullptr;
newNode->prev = tail;

if (tail != nullptr) {
tail->next = newNode;
} 
else {
head = newNode;
}
tail = newNode;

pushUndo("ADD");
cout<<"Line added."<<endl;
}

void display() {
if (head == nullptr) {
cout<<"Empty Document"<<endl;
return;
}

cout<<"Document"<<endl;
Node* current = head;
int i = 1;
while (current != nullptr) {
cout<<i<<": " << current->text<<endl;
current = current->next;
i++;
}
cout<<"----------------"<<endl;
}

void undo() {
if (undoHead == nullptr) {
cout<<"Nothing to undo."<<endl;
return;
}

Undo* tempUndo = undoHead;
string t = tempUndo->tempText;
        
if (t == "ADD") {
if (tail != nullptr) {
Node* nodeToDelete = tail;
tail = tail->prev;
if (tail != nullptr) {
tail->next = nullptr;
} 
else {
head = nullptr;
}
delete nodeToDelete;
cout<<"Undo successful: Removed last line."<<endl;
}
}

undoHead = undoHead->next;
delete tempUndo;
}

void saveToFile(string filename) {
ofstream outFile(filename);
if (!outFile.is_open()) {
cout<<"Error: Could not open file for saving."<<endl;
return;
}

Node* current = head;
while (current != nullptr) {
outFile<<current->text<<endl;
current = current->next;
}
outFile.close();
cout<<"Saved to "<<filename<<endl;
}

void loadFromFile(string filename) {
ifstream inFile(filename);
if (!inFile.is_open()) {
cout<<"Error: Could not open file "<<filename<<endl;
return;
}

while (head != nullptr) {
Node* temp = head;
head = head->next;
delete temp;
}
tail = nullptr;
       
while (undoHead != nullptr) {
Undo* temp = undoHead;
undoHead = undoHead->next;
delete temp;
}

string line;
while (getline(inFile, line)) {
Node* newNode = new Node();
newNode->text = line;
newNode->next = nullptr;
newNode->prev = tail;

if (tail != nullptr) {
tail->next = newNode;
} 
else {
head = newNode;
}
tail = newNode;
}
        
inFile.close();
cout<<"Loaded from "<<filename<<endl;
}
};

int main() {
Notepad note;
int choice;
string input;

while (true) {
cout<<"Notepad"<<endl;
cout<<"1. Add Line"<<endl;
cout<<"2. Display Text"<<endl;
cout<<"3. Undo"<<endl;
cout<<"4. Save to File"<<endl;
cout<<"5. Open File"<<endl;
cout<<"6. Exit"<<endl;
cout<<"Enter choice: ";
        
if (!(cin >> choice)) {
cin.clear();
cin.ignore(10000, '\n');
cout<<"Invalid input. Please enter a number."<<endl;
continue;
}
        
cin.ignore(); 

switch (choice) {
case 1:
cout<<"Enter text: ";
getline(cin, input);
note.addLine(input);
break;
case 2:
note.display();
break;
case 3:
note.undo();
break;
case 4:
cout<<"Enter filename to save: ";
getline(cin, input);
note.saveToFile(input);
break;
case 5:
cout<<"Enter filename to open: ";
getline(cin, input);
note.loadFromFile(input);
break;
case 6:
cout<<"Exiting"<<endl;
return 0;
default:
cout<<"Invalid choice."<<endl;
}
}
return 0;
}
