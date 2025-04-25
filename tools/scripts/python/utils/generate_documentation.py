import os
from script_database import ScriptDatabase

def generate_readme(directory):
    db = ScriptDatabase()
    scripts = db.get_scripts()
    readme_content = "# Scripts in {}\n\n".format(directory)
    for script in scripts:
        script_path = script['path']
        metadata = script['metadata']
        readme_content += "## {}\n".format(os.path.basename(script_path))
        readme_content += "### Metadata\n"
        for key, value in metadata.items():
            if key != 'pylint_output':
                readme_content += "- {}: {}\n".format(key.capitalize(), value)
        readme_content += "### pylint Output\n```\n{}\n```\n\n".format(metadata.get('pylint_output', 'No pylint output'))
    return readme_content

def main():
    directory = 'src'
    readme_content = generate_readme(directory)
    with open(os.path.join(directory, 'README.md'), 'w', encoding='utf-8') as file:
        file.write(readme_content)
    print("README.md generated in src/")

if __name__ == "__main__":
    main()
