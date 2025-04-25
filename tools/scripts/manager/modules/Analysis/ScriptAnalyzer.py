#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Module d'analyse avancée des scripts.

Ce module permet d'analyser les scripts du projet pour détecter les dépendances,
les fonctions, les classes et générer des rapports détaillés.
"""

import ast
import json
import pickle
import fnmatch
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional, Set

try:
    import pandas as pd
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False
    print("Attention: pandas non trouvé. Le rapport HTML ne sera pas généré.")

try:
    from graphviz import Digraph
    GRAPHVIZ_AVAILABLE = True
except ImportError:
    GRAPHVIZ_AVAILABLE = False
    print("Attention: graphviz non trouvé. La visualisation ne sera pas disponible.")


class ScriptAnalyzer:
    """
    Analyse les scripts du projet pour détecter les dépendances,
    les fonctions, les classes et générer des rapports détaillés.
    """
    
    def __init__(self, root_directory: str, cache_file: str = ".script_analyzer_cache.pkl"):
        """
        Initialise l'analyseur de scripts.
        
        Args:
            root_directory: Répertoire racine contenant les scripts à analyser
            cache_file: Fichier de cache pour stocker les résultats d'analyse
        """
        self.root_dir = Path(root_directory)
        self.cache_file = Path(cache_file)
        self.inventory = {}
        self.last_scan_time = None
    
    def scan_scripts(self, force_rescan: bool = False, extensions: List[str] = None) -> Dict[str, Dict]:
        """
        Analyse les scripts dans le répertoire racine.
        
        Args:
            force_rescan: Force une nouvelle analyse même si un cache existe
            extensions: Liste des extensions de fichiers à analyser (par défaut: ['.ps1', '.py', '.cmd', '.bat', '.sh'])
            
        Returns:
            Dictionnaire contenant les informations sur les scripts
        """
        if not force_rescan and self._load_cache():
            return self.inventory
        
        if extensions is None:
            extensions = ['.ps1', '.py', '.cmd', '.bat', '.sh']
        
        print(f"Analyse des scripts dans {self.root_dir}...")
        self.inventory = {}
        self.last_scan_time = datetime.now()
        
        # Parcourir tous les fichiers avec les extensions spécifiées
        for ext in extensions:
            for file_path in self.root_dir.rglob(f"*{ext}"):
                rel_path = file_path.relative_to(self.root_dir)
                script_type = self._get_script_type(file_path)
                
                info = {
                    "path": str(rel_path),
                    "absolute_path": str(file_path),
                    "type": script_type,
                    "size": file_path.stat().st_size,
                    "last_modified": datetime.fromtimestamp(file_path.stat().st_mtime).isoformat(),
                    "functions": [],
                    "classes": [],
                    "dependencies": [],
                    "error": None
                }
                
                try:
                    # Analyser le contenu du fichier
                    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                    
                    # Extraire les métadonnées selon le type de script
                    if script_type == "Python":
                        self._analyze_python_script(content, info)
                    elif script_type == "PowerShell":
                        self._analyze_powershell_script(content, info)
                    else:
                        self._analyze_generic_script(content, info)
                
                except Exception as e:
                    info["error"] = str(e)
                
                self.inventory[str(rel_path)] = info
        
        print(f"Analyse terminée. {len(self.inventory)} scripts trouvés.")
        self._save_cache()
        return self.inventory
    
    def _get_script_type(self, file_path: Path) -> str:
        """
        Détermine le type de script en fonction de l'extension.
        
        Args:
            file_path: Chemin du fichier
            
        Returns:
            Type de script (PowerShell, Python, Batch, Shell, Unknown)
        """
        ext = file_path.suffix.lower()
        if ext == ".ps1":
            return "PowerShell"
        elif ext == ".py":
            return "Python"
        elif ext in [".cmd", ".bat"]:
            return "Batch"
        elif ext == ".sh":
            return "Shell"
        else:
            return "Unknown"
    
    def _analyze_python_script(self, content: str, info: Dict) -> None:
        """
        Analyse un script Python pour extraire les fonctions, classes et dépendances.
        
        Args:
            content: Contenu du script
            info: Dictionnaire d'informations à mettre à jour
        """
        try:
            tree = ast.parse(content)
            
            # Extraire les fonctions
            info["functions"] = [node.name for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)]
            
            # Extraire les classes
            info["classes"] = [node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
            
            # Extraire les dépendances
            dependencies = set()
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for name in node.names:
                        dependencies.add(name.name.split('.')[0])
                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        dependencies.add(node.module.split('.')[0])
            
            info["dependencies"] = list(dependencies)
        
        except SyntaxError as e:
            info["error"] = f"Erreur de syntaxe: {e}"
    
    def _analyze_powershell_script(self, content: str, info: Dict) -> None:
        """
        Analyse un script PowerShell pour extraire les fonctions et dépendances.
        
        Args:
            content: Contenu du script
            info: Dictionnaire d'informations à mettre à jour
        """
        # Extraire les fonctions
        import re
        functions = re.findall(r'function\s+([A-Za-z0-9\-_]+)', content)
        info["functions"] = functions
        
        # Extraire les dépendances (Import-Module)
        dependencies = re.findall(r'Import-Module\s+([A-Za-z0-9\-_\.\\\/]+)', content)
        info["dependencies"] = dependencies
    
    def _analyze_generic_script(self, content: str, info: Dict) -> None:
        """
        Analyse un script générique pour extraire des informations de base.
        
        Args:
            content: Contenu du script
            info: Dictionnaire d'informations à mettre à jour
        """
        # Analyse basique pour les autres types de scripts
        lines = content.split('\n')
        info["line_count"] = len(lines)
    
    def _load_cache(self) -> bool:
        """
        Charge les données du cache si disponible.
        
        Returns:
            True si le cache a été chargé avec succès, False sinon
        """
        if self.cache_file.exists():
            try:
                with open(self.cache_file, "rb") as f:
                    cached_data = pickle.load(f)
                    self.inventory, self.last_scan_time = cached_data
                    print(f"Données chargées depuis le cache ({self.cache_file})")
                    return True
            except Exception as e:
                print(f"Erreur lors du chargement du cache: {e}")
        return False
    
    def _save_cache(self) -> None:
        """
        Sauvegarde les données dans le cache.
        """
        try:
            with open(self.cache_file, "wb") as f:
                pickle.dump((self.inventory, self.last_scan_time), f)
            print(f"Données sauvegardées dans le cache ({self.cache_file})")
        except Exception as e:
            print(f"Erreur lors de la sauvegarde du cache: {e}")
    
    def generate_report(self, output_path: str = "script_analysis_report") -> None:
        """
        Génère des rapports sur les scripts analysés.
        
        Args:
            output_path: Chemin de base pour les fichiers de rapport (sans extension)
        """
        if not self.inventory:
            print("Aucun script analysé. Exécutez scan_scripts() d'abord.")
            return
        
        # Générer le rapport JSON
        json_path = f"{output_path}.json"
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump({
                "timestamp": self.last_scan_time.isoformat() if self.last_scan_time else None,
                "scripts": self.inventory
            }, f, indent=2)
        print(f"Rapport JSON généré: {json_path}")
        
        # Générer le rapport HTML si pandas est disponible
        if PANDAS_AVAILABLE:
            html_path = f"{output_path}.html"
            df = pd.DataFrame(list(self.inventory.values()))
            
            # Simplifier les colonnes de listes pour l'affichage HTML
            for col in ['functions', 'classes', 'dependencies']:
                if col in df.columns:
                    df[col] = df[col].apply(lambda x: ', '.join(x) if isinstance(x, list) else str(x))
            
            # Générer le HTML
            html_content = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Rapport d'analyse des scripts</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    h1 { color: #2c3e50; }
                    table { border-collapse: collapse; width: 100%; }
                    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                    th { background-color: #f2f2f2; }
                    tr:nth-child(even) { background-color: #f9f9f9; }
                    .error { color: red; }
                </style>
            </head>
            <body>
                <h1>Rapport d'analyse des scripts</h1>
                <p>Date d'analyse: {}</p>
                <p>Nombre de scripts: {}</p>
                {}
            </body>
            </html>
            """.format(
                self.last_scan_time.strftime("%Y-%m-%d %H:%M:%S") if self.last_scan_time else "Inconnue",
                len(self.inventory),
                df.to_html(index=False)
            )
            
            with open(html_path, "w", encoding="utf-8") as f:
                f.write(html_content)
            
            print(f"Rapport HTML généré: {html_path}")
    
    def visualize_dependencies(self, output_path: str = "script_dependencies") -> None:
        """
        Génère une visualisation des dépendances entre les scripts.
        
        Args:
            output_path: Chemin de sortie pour le fichier de visualisation (sans extension)
        """
        if not GRAPHVIZ_AVAILABLE:
            print("Graphviz n'est pas disponible. Impossible de générer la visualisation.")
            return
        
        if not self.inventory:
            print("Aucun script analysé. Exécutez scan_scripts() d'abord.")
            return
        
        # Créer le graphe
        dot = Digraph(comment='Dépendances entre scripts')
        dot.attr(rankdir='LR')  # Orientation de gauche à droite
        
        # Ajouter les nœuds (scripts)
        for path, info in self.inventory.items():
            script_type = info.get("type", "Unknown")
            color = {
                "PowerShell": "lightblue",
                "Python": "lightgreen",
                "Batch": "lightyellow",
                "Shell": "lightgray"
            }.get(script_type, "white")
            
            dot.node(path, label=path, style="filled", fillcolor=color)
        
        # Ajouter les arêtes (dépendances)
        for path, info in self.inventory.items():
            dependencies = info.get("dependencies", [])
            for dep in dependencies:
                # Vérifier si la dépendance correspond à un script connu
                for target_path in self.inventory.keys():
                    if target_path.endswith(f"/{dep}.py") or target_path == f"{dep}.py":
                        dot.edge(path, target_path)
        
        # Générer la visualisation
        try:
            dot.render(output_path, format="svg", cleanup=True)
            print(f"Visualisation des dépendances générée: {output_path}.svg")
        except Exception as e:
            print(f"Erreur lors de la génération de la visualisation: {e}")
    
    def find_duplicated_code(self, min_similarity: float = 0.8) -> List[Dict]:
        """
        Détecte les duplications de code entre les scripts.
        
        Args:
            min_similarity: Seuil minimal de similarité (0.0 à 1.0)
            
        Returns:
            Liste des duplications détectées
        """
        from difflib import SequenceMatcher
        
        duplications = []
        scripts = list(self.inventory.items())
        
        for i in range(len(scripts)):
            path1, info1 = scripts[i]
            
            # Ignorer les scripts avec erreur
            if info1.get("error"):
                continue
            
            for j in range(i + 1, len(scripts)):
                path2, info2 = scripts[j]
                
                # Ignorer les scripts avec erreur
                if info2.get("error"):
                    continue
                
                # Comparer uniquement les scripts du même type
                if info1.get("type") != info2.get("type"):
                    continue
                
                # Lire le contenu des fichiers
                try:
                    with open(self.root_dir / path1, "r", encoding="utf-8", errors="ignore") as f1:
                        content1 = f1.read()
                    
                    with open(self.root_dir / path2, "r", encoding="utf-8", errors="ignore") as f2:
                        content2 = f2.read()
                    
                    # Calculer la similarité
                    similarity = SequenceMatcher(None, content1, content2).ratio()
                    
                    if similarity >= min_similarity:
                        duplications.append({
                            "file1": path1,
                            "file2": path2,
                            "similarity": similarity
                        })
                
                except Exception as e:
                    print(f"Erreur lors de la comparaison de {path1} et {path2}: {e}")
        
        return duplications


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Analyseur de scripts")
    parser.add_argument("directory", help="Répertoire contenant les scripts à analyser")
    parser.add_argument("--force", action="store_true", help="Force une nouvelle analyse")
    parser.add_argument("--report", help="Génère un rapport (chemin de base sans extension)")
    parser.add_argument("--viz", help="Génère une visualisation des dépendances (chemin sans extension)")
    parser.add_argument("--dupes", action="store_true", help="Détecte les duplications de code")
    
    args = parser.parse_args()
    
    analyzer = ScriptAnalyzer(args.directory)
    analyzer.scan_scripts(force_rescan=args.force)
    
    if args.report:
        analyzer.generate_report(args.report)
    
    if args.viz:
        analyzer.visualize_dependencies(args.viz)
    
    if args.dupes:
        duplications = analyzer.find_duplicated_code()
        print(f"\nDuplications détectées: {len(duplications)}")
        for dup in duplications:
            print(f"  {dup['file1']} <-> {dup['file2']} (similarité: {dup['similarity']:.2f})")
