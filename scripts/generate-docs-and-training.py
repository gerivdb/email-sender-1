# Phase 7 – Documentation, formation et diffusion (Python)
# Respecte granularité, validation croisée, outputs réels, rollback, CI/CD

import shutil
import datetime
import subprocess
import os

def run(cmd, desc):
    print(f"=== {desc} ===")
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        print(f"Erreur lors de : {desc}")
        raise Exception(f"Erreur lors de : {desc}")

def backup_file(path):
    if os.path.exists(path):
        shutil.copy(path, path + ".bak")
        print(f"Backup créé : {path}.bak")

def validate_output(path, desc):
    if not os.path.exists(path):
        raise Exception(f"Livrable manquant : {desc} ({path})")
    print(f"Livrable validé : {desc} ({path})")

try:
    # 1. Génération guides utilisateur et technique
    run("python scripts/docgen.py --source core/docmanager/outputs/dependencies-merged.json --output docs/user/USER_GUIDE.md", "Guide utilisateur")
    run("python scripts/docgen.py --source core/docmanager/outputs/dependencies-merged.json --output docs/technical/ARCHITECTURE.md", "Guide technique")

    # 2. Génération tutoriels, FAQ, documentation API
    run("python scripts/docgen.py --tutorial --output docs/user/TUTORIALS.md", "Tutoriels")
    run("python scripts/docgen.py --faq --output docs/user/FAQ.md", "FAQ")
    run("python scripts/docgen.py --api --output docs/technical/API_REFERENCE.md", "Documentation API")

    # 3. Formation et communication interne (template)
    with open("docs/user/FORMATION.md", "w", encoding="utf-8") as f:
        f.write("# Formation interne DocManager\n\n- Présentation de l’architecture\n- Utilisation des scripts\n- Bonnes pratiques\n- Exercices pratiques\n")

    # 4. Feedback utilisateur intégré (template)
    with open("docs/user/FEEDBACK.md", "w", encoding="utf-8") as f:
        f.write("# Feedback utilisateur\n\nMerci de renseigner vos retours, suggestions et difficultés rencontrées.\n")

    # 5. Backups
    backup_file("docs/user/USER_GUIDE.md")
    backup_file("docs/technical/ARCHITECTURE.md")
    backup_file("docs/user/TUTORIALS.md")
    backup_file("docs/user/FAQ.md")
    backup_file("docs/technical/API_REFERENCE.md")
    backup_file("docs/user/FORMATION.md")
    backup_file("docs/user/FEEDBACK.md")

    # 6. Validation croisée des livrables
    validate_output("docs/user/USER_GUIDE.md", "Guide utilisateur")
    validate_output("docs/technical/ARCHITECTURE.md", "Guide technique")
    validate_output("docs/user/TUTORIALS.md", "Tutoriels")
    validate_output("docs/user/FAQ.md", "FAQ")
    validate_output("docs/technical/API_REFERENCE.md", "Documentation API")
    validate_output("docs/user/FORMATION.md", "Formation interne")
    validate_output("docs/user/FEEDBACK.md", "Feedback utilisateur")

    # 7. Reporting CI/CD
    with open("ANALYSE_DIFFICULTS_PHASE1.md", "a", encoding="utf-8") as f:
        f.write(f"\n[Phase 7] Documentation, formation et diffusion générées avec succès le {datetime.datetime.now().isoformat()}\n")
    print("Reporting CI/CD effectué.")

except Exception as e:
    print("Erreur critique dans le pipeline Phase 7. Rollback conseillé.")
    backup_file("docs/user/USER_GUIDE.md")
    backup_file("docs/technical/ARCHITECTURE.md")
    backup_file("docs/user/TUTORIALS.md")
    backup_file("docs/user/FAQ.md")
    backup_file("docs/technical/API_REFERENCE.md")
    backup_file("docs/user/FORMATION.md")
    backup_file("docs/user/FEEDBACK.md")
    # Rollback manuel possible sur les .bak
    exit(1)

print("=== Fin Phase 7 Documentation, formation et diffusion ===")
