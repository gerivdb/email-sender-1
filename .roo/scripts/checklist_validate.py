# coding: utf-8
"""
Script Roo-Code : Validation checklist template mode
Vérifie la présence des critères obligatoires dans un template de mode Roo.
Usage : python checklist_validate.py <template_path> <report_path>
"""

import sys
import re

REQUIRED_CHECKLIST = [
    "Ready for prod",
    "Security reviewed",
    "Rollback OK"
]

def main():
    if len(sys.argv) < 3:
        print("Usage: python checklist_validate.py <template_path> <report_path>")
        sys.exit(1)

    template_path = sys.argv[1]
    report_path = sys.argv[2]

    try:
        with open(template_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"Erreur lecture template : {e}")
        sys.exit(2)

    results = []
    for item in REQUIRED_CHECKLIST:
        found = re.search(rf"{re.escape(item)}", content, re.IGNORECASE)
        results.append((item, bool(found)))

    with open(report_path, "w", encoding="utf-8") as f:
        f.write("# Rapport de validation checklist Roo-Code\n\n")
        for item, ok in results:
            status = "✅" if ok else "❌"
            f.write(f"- {item}: {status}\n")
        if all(ok for _, ok in results):
            f.write("\n**Checklist complète : validation réussie.**\n")
        else:
            f.write("\n**Checklist incomplète : corrections requises.**\n")

if __name__ == "__main__":
    main()