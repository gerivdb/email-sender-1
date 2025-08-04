import sys
import yaml

def validate_yaml_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            yaml.safe_load(f)
        print(f"OK: {path}")
        return True
    except Exception as e:
        print(f"ERROR in {path}: {e}")
        return False

if __name__ == "__main__":
    files = sys.argv[1:]
    all_ok = True
    for file in files:
        if not validate_yaml_file(file):
            all_ok = False
    if not all_ok:
        sys.exit(1)
