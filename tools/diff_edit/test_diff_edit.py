# Test automatique du script diff_edit.py

import subprocess
import os

def test_diff_edit():
    # Préparation
    src = 'tools/diff_edit/exemple_markdown.md'
    patch = 'tools/diff_edit/exemple_patch_diffedit.txt'
    backup = None
    # Remettre le fichier à l'état initial
    with open(src, 'w', encoding='utf-8') as f:
        f.write('# Titre\nAncien contenu à remplacer.\n')
    # Exécution du patch
    result = subprocess.run([
        'python', 'tools/diff_edit/diff_edit.py',
        '--file', src,
        '--patch', patch
    ], capture_output=True, text=True)
    assert 'Modification appliquée avec succès.' in result.stdout
    # Vérification du contenu
    with open(src, encoding='utf-8') as f:
        content = f.read()
    assert 'Nouveau contenu inséré par diff Edit.' in content
    # Vérification du backup
    backups = [f for f in os.listdir('tools/diff_edit') if f.startswith('exemple_markdown.md.bak_')]
    assert backups, 'Backup non généré'
    print('Test diff_edit.py : OK')

if __name__ == '__main__':
    test_diff_edit()
