# Scripts utilitaires

Ce dossier contient des scripts utilitaires pour le projet N8N.

## Environnement virtuel Python

Pour tous les scripts Python de ce dossier, il est recommandé d'utiliser un environnement virtuel :

```bash
# Création de l'environnement virtuel
python -m venv .venv

# Activation de l'environnement virtuel
# Sur Windows (PowerShell)
.\.venv\Scripts\Activate.ps1
# Sur Windows (CMD)
.\.venv\Scripts\activate.bat
# Sur Linux/macOS
source .venv/bin/activate

# Installation des dépendances
pip install -r requirements.txt
```

## Scripts disponibles

### batch_fix_markdown.py

Script batch pour appliquer `fix_markdown_v3.py` à tous les fichiers Markdown d'un répertoire :
- Recherche récursive dans les sous-répertoires
- Filtrage par motifs d'inclusion/exclusion
- Mode dry-run pour tester sans modifier les fichiers
- Journalisation détaillée des opérations

#### Dépendances

- Python 3.6+
- fix_markdown_v3.py (inclus dans ce dossier)

#### Utilisation

```bash
python batch_fix_markdown.py [options]
```

Options principales :
- `--dir` : Répertoire racine contenant les fichiers Markdown (défaut: répertoire courant)
- `--script` : Chemin vers le script fix_markdown_v3.py (défaut: scripts/fix_markdown_v3.py)
- `--exclude-dir` : Répertoire à exclure (peut être utilisé plusieurs fois)
- `--exclude-file` : Fichier à exclure (peut être utilisé plusieurs fois)
- `--include` : Motif pour filtrer les fichiers (ex: 'phase')
- `--non-recursive` : Ne pas rechercher récursivement dans les sous-répertoires
- `--dry-run` : Afficher les commandes sans les exécuter
- `--script-args` : Arguments supplémentaires à passer au script fix_markdown_v3.py

Exemples :
```bash
# Traiter tous les fichiers Markdown du projet
python batch_fix_markdown.py

# Traiter uniquement les fichiers contenant 'phase' dans le dossier 'plans'
python batch_fix_markdown.py --dir plans --include phase

# Mode dry-run pour voir quels fichiers seraient traités
python batch_fix_markdown.py --dry-run

# Passer des arguments supplémentaires à fix_markdown_v3.py
python batch_fix_markdown.py --script-args --no-toc --title "Documentation du Projet"
```

### fix_markdown_v3.py (Recommandé)

Version améliorée et générique pour restructurer n'importe quel fichier Markdown :
- Détection automatique du titre principal du document
- Support complet des niveaux de titre H1 à H6
- Options de personnalisation avancées
- Traitement par lots possible

#### Dépendances

- Python 3.6+
- ftfy (pour la correction d'encodage)

#### Installation

```bash
pip install ftfy
```

#### Utilisation

```bash
python fix_markdown_v3.py "chemin/vers/fichier.md"
```

Par défaut, le fichier restructuré sera sauvegardé avec le suffixe "-restructured" dans le même répertoire.

Options principales :
- `-o`, `--output_file` : Spécifier un chemin de sortie personnalisé
- `--max-level` : Niveau de titre maximal à traiter (défaut: 4)
- `--no-toc` : Désactiver la génération de la table des matières
- `--title` : Forcer un titre principal spécifique
- `--keep-preamble` : Conserver le contenu avant le premier titre
- `--no-clean-redundancy` : Désactiver la suppression des doublons
- `--ignore-pattern` : Ignorer les lignes correspondant à un motif (peut être utilisé plusieurs fois)

Exemples :
```bash
# Utilisation simple
python fix_markdown_v3.py "plans/plan de transition/phase3-transi.md"

# Avec options personnalisées
python fix_markdown_v3.py "notes.md" --title "Mes Notes" --max-level 3 --no-clean-redundancy

# Ignorer certains motifs
python fix_markdown_v3.py "brouillon.md" --ignore-pattern "^TODO:" --ignore-pattern "DRAFT ONLY"
```

### fix_markdown_v2.py (Ancienne version)

Script pour restructurer les fichiers Markdown volumineux en :
- Harmonisant la hiérarchie des titres
- Éliminant les redondances
- Organisant clairement les étapes d'implémentation
- Corrigeant les erreurs d'encodage

#### Utilisation

```bash
python fix_markdown_v2.py "chemin/vers/fichier.md"
```

Par défaut, le fichier restructuré sera sauvegardé avec le suffixe "-restructuré" dans le même répertoire.

Options :
- `-o`, `--output_file` : Spécifier un chemin de sortie personnalisé

Exemple :
```bash
python fix_markdown_v2.py "plans/plan de transition/phase3-transi.md" -o "plans/plan de transition/phase3-clean.md"
```
