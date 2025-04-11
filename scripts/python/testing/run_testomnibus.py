#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
TestOmnibus - Outil d'exécution et d'analyse rapide des tests Python

Ce script permet d'exécuter les tests Python, d'analyser les erreurs,
et de générer des rapports détaillés pour faciliter le débogage.
"""

import os
import sys
import argparse
import subprocess
import json
import time
import re
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor
from datetime import datetime

def parse_arguments():
    """Parse les arguments de ligne de commande."""
    parser = argparse.ArgumentParser(description="TestOmnibus - Exécution et analyse des tests Python")
    parser.add_argument("-d", "--directory", default="tests", help="Répertoire des tests")
    parser.add_argument("-p", "--pattern", default="test_*.py", help="Pattern des fichiers de test")
    parser.add_argument("-j", "--jobs", type=int, default=os.cpu_count(), help="Nombre de processus parallèles")
    parser.add_argument("-v", "--verbose", action="store_true", help="Mode verbeux")
    parser.add_argument("--pdb", action="store_true", help="Lancer pdb en cas d'échec")
    parser.add_argument("--report", action="store_true", help="Générer un rapport HTML")
    parser.add_argument("--report-dir", default="test_reports", help="Répertoire des rapports")
    parser.add_argument("--analyze", action="store_true", help="Analyser les erreurs")
    parser.add_argument("--save-errors", action="store_true", help="Sauvegarder les erreurs dans la base de données")
    parser.add_argument("--error-db", default="error_database.json", help="Chemin de la base de données d'erreurs")
    parser.add_argument("--testmon", action="store_true", help="Utiliser pytest-testmon pour exécuter uniquement les tests affectés")
    parser.add_argument("--cov", action="store_true", help="Générer un rapport de couverture")
    parser.add_argument("--cov-report", default="html", help="Format du rapport de couverture (html, xml, term)")
    parser.add_argument("--tb", default="auto", help="Format des tracebacks (auto, short, long, native)")
    parser.add_argument("--allure", action="store_true", help="Générer un rapport Allure")
    parser.add_argument("--allure-dir", default="allure-results", help="Répertoire des résultats Allure")
    parser.add_argument("--jenkins", action="store_true", help="Générer un rapport JUnit pour Jenkins")
    parser.add_argument("--jenkins-dir", default="jenkins-results", help="Répertoire des résultats Jenkins")
    return parser.parse_args()

def find_test_files(directory, pattern):
    """Trouve tous les fichiers de test correspondant au pattern."""
    path = Path(directory)
    if not path.exists():
        print(f"ERREUR: Le répertoire {directory} n'existe pas.")
        return []

    # Vérifier si le pattern est un chemin de fichier spécifique
    if os.path.isfile(os.path.join(directory, pattern)):
        return [Path(os.path.join(directory, pattern))]

    # Vérifier si le pattern contient des spécificateurs de test pytest (::)
    if '::' in pattern:
        # Extraire le chemin du fichier et le pattern de test
        file_path, test_pattern = pattern.split('::', 1)
        if os.path.isfile(os.path.join(directory, file_path)):
            # Retourner le fichier spécifique avec le pattern de test dans un dictionnaire
            file_path_str = os.path.join(directory, file_path)
            return [{'path': file_path_str, 'test_pattern': test_pattern}]

    # Gérer les patterns spéciaux
    if pattern.startswith('*') and not pattern.startswith('*.') and not pattern.startswith('*/'):
        # Pattern comme '*test*' - rechercher dans tous les fichiers Python
        python_files = list(path.glob("**/*.py"))
        return [f for f in python_files if pattern[1:-1] in f.name]

    # Gérer les patterns de répertoire
    if '/' in pattern and not pattern.endswith('.py'):
        # Pattern comme 'subdir/*' - ajouter *.py si nécessaire
        if pattern.endswith('*'):
            pattern = pattern + '*.py'
        elif pattern.endswith('/'):
            pattern = pattern + '*.py'
        else:
            pattern = pattern + '/*.py'

    # Gérer les patterns sans extension
    if not pattern.endswith('.py') and '*' not in pattern:
        # Essayer d'abord le pattern exact
        exact_matches = list(path.glob(f"**/{pattern}.py"))
        if exact_matches:
            return exact_matches

        # Sinon, chercher des fichiers contenant le pattern
        return list(path.glob(f"**/*{pattern}*.py"))

    # Pattern standard
    return list(path.glob(f"**/{pattern}"))

def run_test_file(test_file, verbose=False, pdb=False, testmon=False, cov=False, cov_report="html", tb="auto",
                 allure=False, allure_dir="allure-results", jenkins=False, jenkins_dir="jenkins-results"):
    """Exécute un fichier de test et retourne les résultats."""
    start_time = time.time()

    # Construire la commande de base
    cmd = ["python", "-m", "pytest"]

    # Vérifier si test_file est un dictionnaire avec un pattern de test
    if isinstance(test_file, dict) and 'path' in test_file and 'test_pattern' in test_file:
        # Format: fichier.py::TestClass::test_method
        cmd.append(f"{test_file['path']}::{test_file['test_pattern']}")
        file_path = test_file['path']
        test_pattern = test_file['test_pattern']
    else:
        cmd.append(str(test_file))
        file_path = str(test_file)
        test_pattern = None

    if verbose:
        cmd.append("-v")

    if pdb:
        cmd.append("--pdb")

    if testmon:
        cmd.append("--testmon")

    # Ajouter la capture des données de couverture
    if cov:
        cmd.extend(["--cov", "--cov-report", cov_report])

    # Format des tracebacks
    cmd.extend([f"--tb={tb}"])

    # Ajouter le support pour Allure
    if allure:
        # Créer le répertoire Allure s'il n'existe pas
        os.makedirs(allure_dir, exist_ok=True)
        cmd.extend(["--alluredir", allure_dir])

    # Ajouter le support pour Jenkins
    if jenkins:
        # Créer le répertoire Jenkins s'il n'existe pas
        os.makedirs(jenkins_dir, exist_ok=True)
        cmd.extend(["--junitxml", os.path.join(jenkins_dir, f"{os.path.basename(str(test_file))}.xml")])

    # Exécuter le test
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        end_time = time.time()

        # Analyser la sortie pour déterminer le nombre de tests exécutés
        test_summary = re.search(r"(\d+) passed, (\d+) failed", result.stdout)
        passed_tests = 0
        failed_tests = 0

        if test_summary:
            passed_tests = int(test_summary.group(1))
            failed_tests = int(test_summary.group(2))

        # Vérifier si des tests ont été ignorés ou sautés
        skipped_tests = 0
        skipped_match = re.search(r"(\d+) skipped", result.stdout)
        if skipped_match:
            skipped_tests = int(skipped_match.group(1))

        # Vérifier si des tests ont généré des erreurs
        error_tests = 0
        error_match = re.search(r"(\d+) error", result.stdout)
        if error_match:
            error_tests = int(error_match.group(1))

        return {
            "file": file_path,
            "success": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "duration": end_time - start_time,
            "returncode": result.returncode,
            "passed_tests": passed_tests,
            "failed_tests": failed_tests,
            "skipped_tests": skipped_tests,
            "error_tests": error_tests,
            "test_pattern": test_pattern,
            "allure_dir": allure_dir if allure else None,
            "jenkins_dir": jenkins_dir if jenkins else None
        }
    except Exception as e:
        return {
            "file": file_path,
            "success": False,
            "stdout": "",
            "stderr": f"Erreur lors de l'exécution du test: {str(e)}",
            "duration": time.time() - start_time,
            "returncode": -1,
            "passed_tests": 0,
            "failed_tests": 0,
            "skipped_tests": 0,
            "error_tests": 0,
            "test_pattern": test_pattern,
            "allure_dir": allure_dir if allure else None,
            "jenkins_dir": jenkins_dir if jenkins else None
        }

def run_tests_parallel(test_files, jobs, verbose=False, pdb=False, testmon=False, cov=False, cov_report="html", tb="auto",
                      allure=False, allure_dir="allure-results", jenkins=False, jenkins_dir="jenkins-results"):
    """Exécute les tests en parallèle."""
    results = []

    # Si pdb est activé, exécuter les tests séquentiellement
    if pdb:
        print("Mode débogage activé, exécution séquentielle des tests...")
        for test_file in test_files:
            results.append(run_test_file(test_file, verbose, pdb, testmon, cov, cov_report, tb, allure, allure_dir, jenkins, jenkins_dir))
        return results

    # Sinon, exécuter en parallèle
    with ProcessPoolExecutor(max_workers=jobs) as executor:
        futures = {executor.submit(run_test_file, test_file, verbose, pdb, testmon, cov, cov_report, tb, allure, allure_dir, jenkins, jenkins_dir): test_file for test_file in test_files}

        for future in futures:
            results.append(future.result())

    # Si Allure est activé, générer le rapport Allure
    if allure and results:
        try:
            # Vérifier si allure est installé
            allure_check = subprocess.run(["allure", "--version"], capture_output=True, text=True)
            if allure_check.returncode == 0:
                print(f"\nGénération du rapport Allure dans {allure_dir}...")
                # Générer le rapport Allure
                allure_report_dir = os.path.join(os.path.dirname(allure_dir), "allure-report")
                subprocess.run(["allure", "generate", allure_dir, "-o", allure_report_dir, "--clean"], capture_output=True)
                print(f"Rapport Allure généré dans {allure_report_dir}")

                # Ajouter le chemin du rapport Allure aux résultats
                for result in results:
                    result["allure_report_dir"] = allure_report_dir
            else:
                print("\nAllure n'est pas installé. Le rapport Allure n'a pas été généré.")
                print("Pour installer Allure, consultez https://docs.qameta.io/allure/")
        except Exception as e:
            print(f"\nErreur lors de la génération du rapport Allure: {str(e)}")

    return results

def extract_error_details(stderr_output):
    """Extrait les détails des erreurs à partir de la sortie stderr."""
    error_details = []

    # Analyser la sortie pour extraire les erreurs de test
    # Format: FAILED test_file.py::TestClass::test_method - ErrorType: message
    failed_tests_pattern = r"FAILED ([^\s]+)::([^\s]+)::([^\s]+) - ([^:]+): (.*?)$"
    failed_tests = re.findall(failed_tests_pattern, stderr_output, re.MULTILINE)

    # Rechercher les assertions échouées dans le résumé des tests
    summary_pattern = r"FAILED ([^\s]+)::([^\s]+)::([^\s]+) - ([^:]+): (.*?)$"
    summary_matches = re.findall(summary_pattern, stderr_output, re.MULTILINE)

    # Rechercher les assertions échouées dans les détails
    assertion_pattern = r"E\s+([^:]+Error|[^:]+Exception):\s*(.*?)$"
    assertion_matches = re.findall(assertion_pattern, stderr_output, re.MULTILINE)

    # Rechercher les exceptions dans les tracebacks
    traceback_pattern = r"([^:]+Error|[^:]+Exception):\s*(.*?)$"
    traceback_matches = re.findall(traceback_pattern, stderr_output, re.MULTILINE)

    # Ajouter les erreurs du résumé des tests
    for file_path, class_name, test_name, error_type, message in summary_matches:
        error_details.append({
            "file": file_path,
            "class": class_name,
            "test": test_name,
            "type": error_type,
            "message": message.strip(),
            "source": "summary"
        })

    # Ajouter les assertions échouées des détails
    for error_type, message in assertion_matches:
        # Vérifier si cette erreur existe déjà
        if not any(e["type"] == error_type and e["message"] == message.strip() for e in error_details):
            error_details.append({
                "type": error_type,
                "message": message.strip(),
                "source": "assertion"
            })

    # Ajouter les exceptions des tracebacks
    for error_type, message in traceback_matches:
        # Vérifier si cette erreur existe déjà
        if not any(e["type"] == error_type and e["message"] == message.strip() for e in error_details):
            error_details.append({
                "type": error_type,
                "message": message.strip(),
                "source": "traceback"
            })

    # Si aucune erreur n'a été trouvée mais que des tests ont échoué
    if not error_details:
        # Rechercher les lignes FAILED dans la sortie
        failed_lines = re.findall(r"^(.*FAILED.*)$", stderr_output, re.MULTILINE)

        for line in failed_lines:
            # Essayer d'extraire le nom du test
            test_match = re.search(r"([^\s]+)::([^\s]+)::([^\s]+)", line)
            if test_match:
                file_path, class_name, test_name = test_match.groups()
                error_details.append({
                    "file": file_path,
                    "class": class_name,
                    "test": test_name,
                    "type": "TestFailure",
                    "message": "Test échoué sans message d'erreur spécifique",
                    "source": "failed_line"
                })

    # Si toujours aucune erreur trouvée mais le test a échoué, ajouter une erreur générique
    if not error_details and "FAILED" in stderr_output:
        error_details.append({
            "type": "TestFailure",
            "message": "Test échoué sans message d'erreur spécifique",
            "source": "generic"
        })

    return error_details

def analyze_test_results(results):
    """Analyse les résultats des tests pour identifier les patterns d'erreur."""
    error_patterns = {}
    failed_tests = [r for r in results if not r["success"]]

    # Calculer le nombre total de tests passés et échoués
    total_passed = sum(r.get("passed_tests", 0) for r in results)
    total_failed = sum(r.get("failed_tests", 0) for r in results)

    # Si les compteurs sont à 0, utiliser l'ancienne méthode
    if total_passed == 0 and total_failed == 0:
        total_passed = len(results) - len(failed_tests)
        total_failed = len(failed_tests)

    for test in failed_tests:
        # Extraire les détails des erreurs
        error_details = extract_error_details(test["stderr"])

        for error in error_details:
            # Construire la clé d'erreur
            if "file" in error and "class" in error and "test" in error:
                error_key = f"{error['file']}::{error['class']}::{error['test']} - {error['type']}: {error['message']}"
            else:
                error_key = f"{error['type']}: {error['message']}"

            # Ajouter l'erreur au pattern
            if error_key in error_patterns:
                if test["file"] not in error_patterns[error_key]["files"]:
                    error_patterns[error_key]["files"].append(test["file"])
                error_patterns[error_key]["count"] += 1
            else:
                error_patterns[error_key] = {
                    "files": [test["file"]],
                    "count": 1,
                    "type": error.get("type", "Unknown"),
                    "message": error.get("message", ""),
                    "source": error.get("source", "unknown")
                }

    # Trier les patterns d'erreur par nombre d'occurrences
    sorted_patterns = {k: v for k, v in sorted(
        error_patterns.items(),
        key=lambda item: item[1]["count"],
        reverse=True
    )}

    # Analyser les tendances
    error_trends = analyze_error_trends(error_patterns)

    return {
        "total": sum(r.get("passed_tests", 0) + r.get("failed_tests", 0) for r in results) or len(results),
        "passed": total_passed,
        "failed": total_failed,
        "error_patterns": sorted_patterns,
        "error_trends": error_trends
    }

def analyze_error_trends(error_patterns):
    """Analyse les tendances des erreurs."""
    # Compter les erreurs par type
    error_types = {}
    for error_key, error_info in error_patterns.items():
        error_type = error_info["type"]
        if error_type in error_types:
            error_types[error_type] += error_info["count"]
        else:
            error_types[error_type] = error_info["count"]

    # Trier les types d'erreur par nombre d'occurrences
    sorted_types = {k: v for k, v in sorted(
        error_types.items(),
        key=lambda item: item[1],
        reverse=True
    )}

    return {
        "error_types": sorted_types,
        "total_errors": sum(error_types.values()),
        "unique_errors": len(error_patterns)
    }

def save_errors_to_database(results, analysis, db_path):
    """Sauvegarde les erreurs dans une base de données JSON."""
    # Charger la base de données existante ou créer une nouvelle
    if os.path.exists(db_path):
        try:
            with open(db_path, 'r') as f:
                error_db = json.load(f)
        except json.JSONDecodeError:
            error_db = {"errors": [], "history": [], "trends": []}
    else:
        error_db = {"errors": [], "history": [], "trends": []}

    # Ajouter une entrée à l'historique
    timestamp = datetime.now().isoformat()
    history_entry = {
        "timestamp": timestamp,
        "total_tests": analysis["total"],
        "passed_tests": analysis["passed"],
        "failed_tests": analysis["failed"],
        "error_count": len(analysis["error_patterns"])
    }
    error_db["history"].append(history_entry)

    # Ajouter ou mettre à jour les erreurs
    failed_tests = [r for r in results if not r["success"]]

    for test in failed_tests:
        error_details = extract_error_details(test["stderr"])

        for error in error_details:
            # Construire la signature de l'erreur
            if "file" in error and "class" in error and "test" in error:
                error_key = f"{error['file']}::{error['class']}::{error['test']} - {error['type']}: {error['message']}"
                test_info = {
                    "file": error["file"],
                    "class": error["class"],
                    "test": error["test"]
                }
            else:
                error_key = f"{error['type']}: {error['message']}"
                test_info = {
                    "file": test["file"],
                    "class": "Unknown",
                    "test": "Unknown"
                }

            # Vérifier si cette erreur existe déjà
            existing_error = next((e for e in error_db["errors"] if e["signature"] == error_key), None)

            if existing_error:
                # Mettre à jour l'erreur existante
                existing_error["occurrences"] += 1
                existing_error["last_seen"] = timestamp

                # Ajouter le fichier s'il n'existe pas déjà
                if test["file"] not in existing_error["files"]:
                    existing_error["files"].append(test["file"])

                # Ajouter l'occurrence à l'historique des occurrences
                if "occurrence_history" not in existing_error:
                    existing_error["occurrence_history"] = []

                existing_error["occurrence_history"].append({
                    "timestamp": timestamp,
                    "file": test["file"]
                })
            else:
                # Ajouter une nouvelle erreur
                new_error = {
                    "signature": error_key,
                    "type": error["type"],
                    "message": error["message"],
                    "files": [test["file"]],
                    "test_info": test_info,
                    "first_seen": timestamp,
                    "last_seen": timestamp,
                    "occurrences": 1,
                    "resolved": False,
                    "source": error.get("source", "unknown"),
                    "occurrence_history": [{
                        "timestamp": timestamp,
                        "file": test["file"]
                    }]
                }
                error_db["errors"].append(new_error)

    # Mettre à jour les tendances
    update_error_trends(error_db)

    # Sauvegarder la base de données mise à jour
    os.makedirs(os.path.dirname(os.path.abspath(db_path)), exist_ok=True)
    with open(db_path, 'w') as f:
        json.dump(error_db, f, indent=2)

    return error_db

def update_error_trends(error_db):
    """Met à jour les tendances d'erreurs dans la base de données."""
    # Initialiser les tendances si elles n'existent pas
    if "trends" not in error_db:
        error_db["trends"] = []

    # Obtenir la date actuelle
    today = datetime.now().date().isoformat()

    # Compter les erreurs par type pour aujourd'hui
    error_counts = {}
    for error in error_db["errors"]:
        error_type = error["type"]
        last_seen = datetime.fromisoformat(error["last_seen"]).date().isoformat()

        if last_seen == today:
            if error_type in error_counts:
                error_counts[error_type] += 1
            else:
                error_counts[error_type] = 1

    # Ajouter ou mettre à jour l'entrée de tendance pour aujourd'hui
    existing_trend = next((t for t in error_db["trends"] if t["date"] == today), None)

    if existing_trend:
        existing_trend["error_counts"] = error_counts
    else:
        error_db["trends"].append({
            "date": today,
            "error_counts": error_counts
        })

    # Limiter l'historique des tendances aux 30 derniers jours
    if len(error_db["trends"]) > 30:
        error_db["trends"] = sorted(error_db["trends"], key=lambda t: t["date"], reverse=True)[:30]

def generate_html_report(results, analysis, report_dir):
    """Génère un rapport HTML des résultats de test."""
    os.makedirs(report_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = os.path.join(report_dir, f"testomnibus_report_{timestamp}.html")

    # Créer un rapport HTML
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("""<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TestOmnibus Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        header {
            background-color: #f4f4f4;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #444;
        }
        .summary {
            display: flex;
            justify-content: space-between;
            background-color: #f9f9f9;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .summary-item {
            text-align: center;
            padding: 10px;
        }
        .success {
            color: #28a745;
        }
        .failure {
            color: #dc3545;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f4f4f4;
        }
        tr:hover {
            background-color: #f9f9f9;
        }
        .error-details {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border-left: 4px solid #dc3545;
        }
        pre {
            background-color: #f1f1f1;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        .timestamp {
            color: #6c757d;
            font-size: 0.9em;
        }
        .progress-bar {
            height: 20px;
            background-color: #e9ecef;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .progress {
            height: 100%;
            background-color: #28a745;
            border-radius: 5px;
            text-align: center;
            color: white;
            line-height: 20px;
        }
        .tab {
            overflow: hidden;
            border: 1px solid #ccc;
            background-color: #f1f1f1;
            border-radius: 5px 5px 0 0;
        }
        .tab button {
            background-color: inherit;
            float: left;
            border: none;
            outline: none;
            cursor: pointer;
            padding: 14px 16px;
            transition: 0.3s;
        }
        .tab button:hover {
            background-color: #ddd;
        }
        .tab button.active {
            background-color: #ccc;
        }
        .tabcontent {
            display: none;
            padding: 6px 12px;
            border: 1px solid #ccc;
            border-top: none;
            border-radius: 0 0 5px 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>TestOmnibus Report</h1>
            <p class="timestamp">Généré le: """ + datetime.now().strftime("%d/%m/%Y à %H:%M:%S") + """</p>
        </header>

        <div class="summary">
            <div class="summary-item">
                <h3>Total</h3>
                <p>""" + str(analysis['total']) + """</p>
            </div>
            <div class="summary-item">
                <h3>Réussis</h3>
                <p class="success">""" + str(analysis['passed']) + """</p>
            </div>
            <div class="summary-item">
                <h3>Échoués</h3>
                <p class="failure">""" + str(analysis['failed']) + """</p>
            </div>
            <div class="summary-item">
                <h3>Taux de réussite</h3>
                <p>""" + (f"{(analysis['passed'] / analysis['total'] * 100):.1f}%" if analysis['total'] > 0 else "N/A") + """</p>
            </div>
        </div>

        <div class="progress-bar">
            <div class="progress" style="width: """ + (f"{(analysis['passed'] / analysis['total'] * 100):.1f}%" if analysis['total'] > 0 else "0%") + """;">
                """ + (f"{(analysis['passed'] / analysis['total'] * 100):.1f}%" if analysis['total'] > 0 else "0%") + """
            </div>
        </div>

        <div class="tab">
            <button class="tablinks active" onclick="openTab(event, 'Summary')">Résumé</button>
            <button class="tablinks" onclick="openTab(event, 'ErrorPatterns')">Patterns d'erreur</button>
            <button class="tablinks" onclick="openTab(event, 'ErrorTrends')">Tendances</button>
            <button class="tablinks" onclick="openTab(event, 'TestDetails')">Détails des tests</button>
            <button class="tablinks" onclick="openTab(event, 'FailureDetails')">Détails des échecs</button>
            <button class="tablinks" onclick="openTab(event, 'AllureReport')" id="allureButton" style="display:none;">Rapport Allure</button>
        </div>

        <div id="Summary" class="tabcontent" style="display: block;">
            <h2>Résumé des tests</h2>
            <p>Ce rapport présente les résultats de l'exécution de """ + str(analysis['total']) + """ tests.</p>
            <p>""" + str(analysis['passed']) + """ tests ont réussi et """ + str(analysis['failed']) + """ tests ont échoué.</p>

            <h3>Répartition des résultats</h3>
            <table>
                <tr>
                    <th>Statut</th>
                    <th>Nombre</th>
                    <th>Pourcentage</th>
                </tr>
                <tr>
                    <td class="success">Réussis</td>
                    <td>""" + str(analysis['passed']) + """</td>
                    <td>""" + (f"{(analysis['passed'] / analysis['total'] * 100):.1f}%" if analysis['total'] > 0 else "N/A") + """</td>
                </tr>
                <tr>
                    <td class="failure">Échoués</td>
                    <td>""" + str(analysis['failed']) + """</td>
                    <td>""" + (f"{(analysis['failed'] / analysis['total'] * 100):.1f}%" if analysis['total'] > 0 else "N/A") + """</td>
                </tr>
            </table>
        </div>

        <div id="ErrorPatterns" class="tabcontent">
            <h2>Patterns d'erreur</h2>""")

        # Patterns d'erreur
        if analysis['error_patterns']:
            f.write("""
            <p>Les patterns d'erreur suivants ont été identifiés :</p>
            <table>
                <tr>
                    <th>Erreur</th>
                    <th>Type</th>
                    <th>Occurrences</th>
                    <th>Fichiers</th>
                </tr>""")

            for error, error_info in analysis['error_patterns'].items():
                f.write(f"""
                <tr>
                    <td>{error_info.get('message', error)}</td>
                    <td>{error_info.get('type', 'Unknown')}</td>
                    <td>{error_info.get('count', 0)}</td>
                    <td>{', '.join([os.path.basename(file) for file in error_info.get('files', [])])}</td>
                </tr>""")

            f.write("""
            </table>""")
        else:
            f.write("""
            <p>Aucun pattern d'erreur n'a été identifié.</p>""")

        f.write("""
        </div>

        <div id="ErrorTrends" class="tabcontent">
            <h2>Tendances d'erreur</h2>""")

        # Tendances d'erreur
        if 'error_trends' in analysis and analysis['error_trends']['total_errors'] > 0:
            f.write("""
            <h3>Répartition des erreurs par type</h3>
            <p>Total des erreurs: {0} | Erreurs uniques: {1}</p>
            <div class="chart-container" style="position: relative; height:300px; width:100%">
                <canvas id="errorTypesChart"></canvas>
            </div>

            <h3>Détails des types d'erreur</h3>
            <table>
                <tr>
                    <th>Type d'erreur</th>
                    <th>Occurrences</th>
                    <th>Pourcentage</th>
                </tr>""".format(analysis['error_trends']['total_errors'], analysis['error_trends']['unique_errors']))

            total_errors = analysis['error_trends']['total_errors']
            for error_type, count in analysis['error_trends']['error_types'].items():
                percentage = (count / total_errors * 100) if total_errors > 0 else 0
                f.write(f"""
                <tr>
                    <td>{error_type}</td>
                    <td>{count}</td>
                    <td>{percentage:.1f}%</td>
                </tr>""")

            f.write("""
            </table>

            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <script>
                // Créer le graphique des types d'erreur
                var ctx = document.getElementById('errorTypesChart').getContext('2d');
                var errorTypesChart = new Chart(ctx, {
                    type: 'pie',
                    data: {
                        labels: [""")

            # Ajouter les labels
            labels = [f"'{error_type}'" for error_type in analysis['error_trends']['error_types'].keys()]
            f.write(", ".join(labels))

            f.write("""],
                        datasets: [{
                            label: 'Types d\'erreur',
                            data: [""")

            # Ajouter les données
            data = [str(count) for count in analysis['error_trends']['error_types'].values()]
            f.write(", ".join(data))

            f.write("""],
                            backgroundColor: [
                                'rgba(255, 99, 132, 0.7)',
                                'rgba(54, 162, 235, 0.7)',
                                'rgba(255, 206, 86, 0.7)',
                                'rgba(75, 192, 192, 0.7)',
                                'rgba(153, 102, 255, 0.7)',
                                'rgba(255, 159, 64, 0.7)',
                                'rgba(199, 199, 199, 0.7)',
                                'rgba(83, 102, 255, 0.7)',
                                'rgba(40, 159, 64, 0.7)',
                                'rgba(210, 199, 199, 0.7)'
                            ],
                            borderColor: [
                                'rgba(255, 99, 132, 1)',
                                'rgba(54, 162, 235, 1)',
                                'rgba(255, 206, 86, 1)',
                                'rgba(75, 192, 192, 1)',
                                'rgba(153, 102, 255, 1)',
                                'rgba(255, 159, 64, 1)',
                                'rgba(199, 199, 199, 1)',
                                'rgba(83, 102, 255, 1)',
                                'rgba(40, 159, 64, 1)',
                                'rgba(210, 199, 199, 1)'
                            ],
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: {
                                position: 'top',
                            },
                            title: {
                                display: true,
                                text: 'Répartition des erreurs par type'
                            }
                        }
                    }
                });
            </script>"""
            )
        else:
            f.write("""
            <p>Aucune tendance d'erreur n'a été identifiée.</p>""")

        f.write("""
        </div>

        <div id="TestDetails" class="tabcontent">
            <h2>Détails des tests</h2>
            <table>
                <tr>
                    <th>Fichier</th>
                    <th>Statut</th>
                    <th>Durée</th>
                </tr>""")

        # Détails des tests
        for result in sorted(results, key=lambda x: x['file']):
            status_class = "success" if result["success"] else "failure"
            status_text = "Réussi" if result["success"] else "Échoué"
            f.write(f"""
                <tr>
                    <td>{result['file']}</td>
                    <td class='{status_class}'>{status_text}</td>
                    <td>{result['duration']:.2f}s</td>
                </tr>""")

        f.write("""
            </table>
        </div>

        <div id="FailureDetails" class="tabcontent">
            <h2>Détails des échecs</h2>""")

        # Détails des échecs
        failed_tests = [r for r in results if not r["success"]]
        if failed_tests:
            for i, test in enumerate(failed_tests):
                f.write(f"""
            <div class="error-details">
                <h3>{i+1}. {test['file']}</h3>
                <pre>{test['stderr']}</pre>
            </div>""")
        else:
            f.write("""
            <p>Aucun test n'a échoué.</p>""")

        f.write("""
        </div>

        <script>
        function openTab(evt, tabName) {
            var i, tabcontent, tablinks;
            tabcontent = document.getElementsByClassName("tabcontent");
            for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
            }
            tablinks = document.getElementsByClassName("tablinks");
            for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }
            document.getElementById(tabName).style.display = "block";
            evt.currentTarget.className += " active";
        }
        </script>
    </div>
</body>
</html>""")

    return report_path

def main():
    """Fonction principale."""
    args = parse_arguments()

    print(f"TestOmnibus - Recherche des tests dans {args.directory}...")
    test_files = find_test_files(args.directory, args.pattern)

    if not test_files:
        print("Aucun fichier de test trouvé.")
        return 1

    print(f"Trouvé {len(test_files)} fichiers de test.")

    # Vérifier si les dépendances pour Allure sont installées
    if args.allure:
        try:
            # Vérifier si pytest-allure-adaptor est installé
            import importlib.util
            allure_spec = importlib.util.find_spec("allure")
            if allure_spec is None:
                print("\nLe module pytest-allure-adaptor n'est pas installé. Installation en cours...")
                subprocess.run(["pip", "install", "allure-pytest"], check=True)
                print("Module allure-pytest installé avec succès.")

            # Vérifier si allure est installé
            allure_check = subprocess.run(["allure", "--version"], capture_output=True, text=True)
            if allure_check.returncode != 0:
                print("\nAllure n'est pas installé. Le rapport Allure ne sera pas généré automatiquement.")
                print("Pour installer Allure, consultez https://docs.qameta.io/allure/")
        except Exception as e:
            print(f"\nErreur lors de la vérification des dépendances Allure: {str(e)}")

    print(f"Exécution des tests avec {args.jobs} processus parallèles...")
    results = run_tests_parallel(
        test_files,
        args.jobs,
        args.verbose,
        args.pdb,
        args.testmon,
        args.cov,
        args.cov_report,
        args.tb,
        args.allure,
        args.allure_dir,
        args.jenkins,
        args.jenkins_dir
    )

    # Compter les succès et les échecs
    total_passed = sum(r.get("passed_tests", 0) for r in results)
    total_failed = sum(r.get("failed_tests", 0) for r in results)
    total_skipped = sum(r.get("skipped_tests", 0) for r in results)
    total_errors = sum(r.get("error_tests", 0) for r in results)

    # Si les compteurs sont à 0, utiliser l'ancienne méthode
    if total_passed == 0 and total_failed == 0:
        successes = sum(1 for r in results if r["success"])
        failures = len(results) - successes
        print(f"\nRésultats: {successes}/{len(results)} tests réussis, {failures} échecs.")
    else:
        total_tests = total_passed + total_failed + total_skipped + total_errors
        print(f"\nRésultats: {total_passed}/{total_tests} tests réussis, {total_failed} échecs, {total_skipped} ignorés, {total_errors} erreurs.")

    # Analyser les résultats si demandé
    if args.analyze or args.report or args.save_errors:
        print("\nAnalyse des résultats...")
        analysis = analyze_test_results(results)

        if analysis["error_patterns"] and args.analyze:
            print("\nPatterns d'erreur détectés:")
            for error, error_info in analysis["error_patterns"].items():
                print(f"  - {error_info.get('type', 'Unknown')}: {error_info.get('message', error)}")
                print(f"    {error_info.get('count', 0)} occurrences dans: {', '.join([os.path.basename(file) for file in error_info.get('files', [])])}")

        if 'error_trends' in analysis and args.analyze:
            print("\nTendances d'erreur:")
            print(f"  Total des erreurs: {analysis['error_trends']['total_errors']}")
            print(f"  Erreurs uniques: {analysis['error_trends']['unique_errors']}")
            print("  Répartition par type:")
            for error_type, count in analysis['error_trends']['error_types'].items():
                print(f"    - {error_type}: {count} occurrences")
    else:
        analysis = {
            "total": total_passed + total_failed + total_skipped + total_errors,
            "passed": total_passed,
            "failed": total_failed,
            "skipped": total_skipped,
            "errors": total_errors,
            "error_patterns": {}
        }

    # Sauvegarder les erreurs si demandé
    if args.save_errors:
        print(f"\nSauvegarde des erreurs dans {args.error_db}...")
        error_db = save_errors_to_database(results, analysis, args.error_db)
        print(f"Base de données mise à jour avec {len(error_db['errors'])} erreurs.")

    # Générer un rapport si demandé
    if args.report:
        print(f"\nGénération du rapport HTML dans {args.report_dir}...")
        report_path = generate_html_report(results, analysis, args.report_dir)
        print(f"Rapport généré: {report_path}")

        # Ouvrir le rapport dans le navigateur si demandé
        if os.path.exists(report_path):
            print(f"Pour ouvrir le rapport, visitez: file://{os.path.abspath(report_path)}")

    # Afficher les informations sur le rapport Allure si généré
    if args.allure and any("allure_report_dir" in r for r in results):
        allure_report_dir = next((r["allure_report_dir"] for r in results if "allure_report_dir" in r), None)
        if allure_report_dir:
            print(f"\nRapport Allure généré dans {allure_report_dir}")
            print(f"Pour ouvrir le rapport Allure, exécutez: allure open {allure_report_dir}")

    # Afficher les informations sur le rapport Jenkins si généré
    if args.jenkins:
        print(f"\nRapports JUnit pour Jenkins générés dans {args.jenkins_dir}")
        print("Ces rapports peuvent être utilisés par Jenkins pour afficher les résultats des tests.")

    return 0 if total_failed == 0 and total_errors == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
