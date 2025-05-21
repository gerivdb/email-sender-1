import os
import re
import json

MODES_DIR = os.path.join(os.path.dirname(__file__), '../development/methodologies/modes')
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), '../snippets')
OUTPUT_FILE = os.path.join(OUTPUT_DIR, 'modes.code-snippets')

snippet_pattern = re.compile(
    r'##\s*Snippet VS Code.*?```json\s*([\s\S]*?)\s*```',
    re.IGNORECASE
)

def extract_snippets():
    snippets = {}
    for fname in os.listdir(MODES_DIR):
        if not fname.endswith('.md'):
            continue
        path = os.path.join(MODES_DIR, fname)
        with open(path, encoding='utf-8') as f:
            content = f.read()
        match = snippet_pattern.search(content)
        if match:
            try:
                snippet_json = json.loads(match.group(1))
                snippets.update(snippet_json)
                print(f"Snippet extrait de {fname}")
            except Exception as e:
                print(f"Erreur JSON dans {fname}: {e}")
        else:
            print(f"Aucun snippet trouvé dans {fname}")
    return snippets

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    snippets = extract_snippets()
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(snippets, f, ensure_ascii=False, indent=2)
    print(f"Snippets VS Code générés dans {OUTPUT_FILE}")

if __name__ == '__main__':
    main()
