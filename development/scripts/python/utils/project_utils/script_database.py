import json

class ScriptDatabase:
    def __init__(self, db_path='scripts_db.json'):
        self.db_path = db_path
        self.load_db()

    def load_db(self):
        try:
            with open(self.db_path, 'r', encoding='utf-8') as file:
                self.db = json.load(file)
        except FileNotFoundError:
            self.db = {'scripts': []}

    def save_db(self):
        with open(self.db_path, 'w', encoding='utf-8') as file:
            json.dump(self.db, file, indent=4)

    def update_script(self, script_path, script_type, metadata):
        for script in self.db['scripts']:
            if script['path'] == script_path:
                script['type'] = script_type
                script['metadata'] = metadata
                self.save_db()
                return
        self.db['scripts'].append({
            'path': script_path,
            'type': script_type,
            'metadata': metadata
        })
        self.save_db()

    def get_scripts(self):
        return self.db['scripts']

if __name__ == "__main__":
    db = ScriptDatabase()
    # Exemple d'utilisation
    db.update_script('example.ps1', 'PowerShell', {'description': 'Exemple de script', 'author': 'John Doe', 'date': '2025-04-08'})
    print(db.get_scripts())
