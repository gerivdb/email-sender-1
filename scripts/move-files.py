#!/usr/bin/env python3
"""
move-files.py — Déplacement de fichiers selon une configuration YAML.
Auteur : Roo (généré pour Roo-Code)
Version : 1.0
Date : 2025-08-01

Fonctionnalités :
- Lecture et validation du fichier YAML de configuration (schéma attendu).
- Mode dry-run (simulation sans déplacement réel).
- Rollback (restauration des fichiers déplacés).
- Audit/logging des opérations (fichier log).
- Documentation inline et métadonnées.
- Portabilité (aucune dépendance non standard sans commentaire).
- Utilisation : python scripts/move-files.py --config file-moves.yaml [--dry-run] [--rollback]
"""

import os
import sys
import shutil
import argparse
import datetime

try:
    import yaml  # type: ignore
except ImportError:
    print("⚠️  Le module PyYAML est requis. Installez-le avec : pip install pyyaml")
    sys.exit(1)

LOG_FILE = "move-files.audit.log"
ROLLBACK_FILE = "move-files.rollback.log"

def log(msg):
    timestamp = datetime.datetime.now().isoformat()
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{timestamp}] {msg}\n")

def save_rollback(src, dst):
    with open(ROLLBACK_FILE, "a", encoding="utf-8") as f:
        f.write(f"{dst}|{src}\n")

def load_rollback():
    if not os.path.exists(ROLLBACK_FILE):
        print("Aucune opération à annuler.")
        return []
    with open(ROLLBACK_FILE, "r", encoding="utf-8") as f:
        return [line.strip().split("|") for line in f if "|" in line]

def clear_rollback():
    if os.path.exists(ROLLBACK_FILE):
        os.remove(ROLLBACK_FILE)

def validate_config(data):
    # Schéma minimal attendu : liste de mouvements avec src et dst
    if not isinstance(data, dict) or "moves" not in data:
        raise ValueError("Le fichier YAML doit contenir une clé 'moves' (liste de déplacements).")
    for move in data["moves"]:
        if not isinstance(move, dict) or "src" not in move or "dst" not in move:
            raise ValueError("Chaque déplacement doit contenir 'src' et 'dst'.")
    return True

def move_files(config, dry_run=False):
    for move in config["moves"]:
        src = move["src"]
        dst = move["dst"]
        if not os.path.exists(src):
            log(f"ERREUR: Source introuvable : {src}")
            print(f"Source introuvable : {src}")
            continue
        if dry_run:
            print(f"[DRY-RUN] {src} -> {dst}")
            log(f"DRY-RUN: {src} -> {dst}")
        else:
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.move(src, dst)
            log(f"Déplacé : {src} -> {dst}")
            save_rollback(src, dst)
            print(f"Déplacé : {src} -> {dst}")

def rollback():
    ops = load_rollback()
    if not ops:
        print("Aucune opération à annuler.")
        return
    for dst, src in reversed(ops):
        if os.path.exists(dst):
            os.makedirs(os.path.dirname(src), exist_ok=True)
            shutil.move(dst, src)
            log(f"Rollback : {dst} -> {src}")
            print(f"Rollback : {dst} -> {src}")
        else:
            log(f"ERREUR: Fichier à restaurer introuvable : {dst}")
            print(f"Fichier à restaurer introuvable : {dst}")
    clear_rollback()

def main():
    parser = argparse.ArgumentParser(description="Déplacement de fichiers selon une configuration YAML.")
    parser.add_argument("--config", required=False, default="file-moves.yaml", help="Fichier YAML de configuration")
    parser.add_argument("--dry-run", action="store_true", help="Simuler les déplacements sans les effectuer")
    parser.add_argument("--rollback", action="store_true", help="Annuler les derniers déplacements")
    args = parser.parse_args()

    if args.rollback:
        rollback()
        return

    if not os.path.exists(args.config):
        print(f"Fichier de configuration introuvable : {args.config}")
        sys.exit(1)

    with open(args.config, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    try:
        validate_config(data)
    except Exception as e:
        print(f"Erreur de validation du YAML : {e}")
        sys.exit(1)

    move_files(data, dry_run=args.dry_run)
    if args.dry_run:
        print("Simulation terminée. Aucun fichier déplacé.")
    else:
        print("Déplacement terminé. Voir le log pour le détail.")

if __name__ == "__main__":
    main()