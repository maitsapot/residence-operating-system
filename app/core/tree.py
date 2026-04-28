import os

EXCLUDE = {"venv", "__pycache__", ".git", ".idea", ".vscode"}

def print_tree(start_path=".", indent=""):
    items = sorted(os.listdir(start_path))
    
    for item in items:
        if item in EXCLUDE:
            continue
        
        path = os.path.join(start_path, item)
        print(f"{indent}|-- {item}")
        
        if os.path.isdir(path):
            print_tree(path, indent + "   ")

if __name__ == "__main__":
    print_tree()