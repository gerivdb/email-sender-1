import os
from difflib import SequenceMatcher

def read_file_content(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return file.read()
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return ""

def compare_files(file1, file2):
    content1 = read_file_content(file1)
    content2 = read_file_content(file2)
    similarity = SequenceMatcher(None, content1, content2).ratio()
    return similarity

def detect_redundancies(directory):
    python_files = [os.path.join(directory, f) for f in os.listdir(directory) if f.endswith('.py')]
    for i in range(len(python_files)):
        for j in range(i + 1, len(python_files)):
            file1 = python_files[i]
            file2 = python_files[j]
            similarity = compare_files(file1, file2)
            if similarity > 0.5:  # Adjust the threshold as needed
                print(f"Similarity between {file1} and {file2}: {similarity:.2f}")

def main():
    directory = 'src'
    detect_redundancies(directory)

if __name__ == "__main__":
    main()
