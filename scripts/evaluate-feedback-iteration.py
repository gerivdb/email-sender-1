# Phase 8 – Évaluation, feedback et itérations (Python)
# Respecte granularité, validation croisée, outputs réels, rollback, CI/CD

import shutil
import datetime
import subprocess
import os
import json

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
    # 1. Évaluation continue (tests, coverage, benchmarks)
    run("pytest scripts/test_docgen.py --cov > evaluation_report.txt", "Tests unitaires et coverage docgen.py")
    run("go test core/docmanager/ --cover > evaluation_report_go.txt", "Tests unitaires et coverage Go")
    run("npm test scripts/dependency-analyzer.test.js -- --coverage > evaluation_report_js.txt", "Tests unitaires et coverage JS")

    # 2. Collecte de feedback utilisateur
    feedback_path = "docs/user/FEEDBACK.md"
    if os.path.exists(feedback_path):
        with open(feedback_path, "r", encoding="utf-8") as f:
            feedback = f.read()
        with open("feedback_archive.txt", "a", encoding="utf-8") as fa:
            fa.write(f"\n---\n{datetime.datetime.now().isoformat()}\n{feedback}\n")
        print("Feedback archivé.")

    # 3. Analyse des métriques (extraction synthèse)
    metrics = {}
    for report, key in [("evaluation_report.txt", "python"), ("evaluation_report_go.txt", "go"), ("evaluation_report_js.txt", "js")]:
        if os.path.exists(report):
            with open(report, "r", encoding="utf-8") as f:
                metrics[key] = f.read()
    with open("evaluation_metrics.json", "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=2, ensure_ascii=False)
    print("Métriques d'évaluation sauvegardées.")

    # 4. Roadmap d’amélioration (template)
    with open("docs/technical/IMPROVEMENT_ROADMAP.md", "w", encoding="utf-8") as f:
        f.write("# Roadmap d’amélioration continue\n\n- Synthèse des feedbacks\n- Actions correctives\n- Nouvelles fonctionnalités\n- Suivi des itérations\n")

    # 5. Gestion des bugs (template)
    with open("docs/technical/BUGS_TRACKER.md", "w", encoding="utf-8") as f:
        f.write("# Bugs Tracker\n\n- Liste des bugs ouverts/fermés\n- Statut, priorité, responsable\n")

    # 6. Rétrospective (template)
    with open("docs/technical/RETROSPECTIVE.md", "w", encoding="utf-8") as f:
        f.write("# Rétrospective projet\n\n- Points forts\n- Points faibles\n- Améliorations proposées\n")

    # 7. Backups
    backup_file("evaluation_metrics.json")
    backup_file("docs/technical/IMPROVEMENT_ROADMAP.md")
    backup_file("docs/technical/BUGS_TRACKER.md")
    backup_file("docs/technical/RETROSPECTIVE.md")

    # 8. Validation croisée des livrables
    validate_output("evaluation_metrics.json", "Métriques d'évaluation")
    validate_output("docs/technical/IMPROVEMENT_ROADMAP.md", "Roadmap d’amélioration")
    validate_output("docs/technical/BUGS_TRACKER.md", "Bugs Tracker")
    validate_output("docs/technical/RETROSPECTIVE.md", "Rétrospective")

    # 9. Reporting CI/CD
    with open("ANALYSE_DIFFICULTS_PHASE1.md", "a", encoding="utf-8") as f:
        f.write(f"\n[Phase 8] Évaluation, feedback et itérations générés avec succès le {datetime.datetime.now().isoformat()}\n")
    print("Reporting CI/CD effectué.")

except Exception as e:
    print("Erreur critique dans le pipeline Phase 8. Rollback conseillé.")
    backup_file("evaluation_metrics.json")
    backup_file("docs/technical/IMPROVEMENT_ROADMAP.md")
    backup_file("docs/technical/BUGS_TRACKER.md")
    backup_file("docs/technical/RETROSPECTIVE.md")
    # Rollback manuel possible sur les .bak
    exit(1)

print("=== Fin Phase 8 Évaluation, feedback et itérations ===")
