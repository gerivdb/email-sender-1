#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Gestionnaire de fichiers pour projets n8n et Notion
---------------------------------------------------
Ce script aide à organiser, analyser et gérer les fichiers dans un projet
utilisant n8n et Notion, en se concentrant sur les workflows et les fichiers JSON.

Fonctionnalités:
- Analyse des fichiers JSON (notamment workflows n8n)
- Organisation des fichiers par type et contenu
- Détection des caractères accentués problématiques
- Création d'inventaires de fichiers exportables
"""

import json
import os
import pandas as pd
import re
import shutil
from datetime import datetime
from jsonpath_ng import parse
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union


class FileManager:
    """Classe principale pour la gestion des fichiers du projet."""
    
    def __init__(self, root_dir: Union[str, Path] = "."):
        """
        Initialise le gestionnaire de fichiers.
        
        Args:
            root_dir: Répertoire racine du projet (par défaut: répertoire courant)
        """
        self.root_dir = Path(root_dir).resolve()
        self.inventory = []
        
    def scan_directory(self, dir_path: Union[str, Path] = None, 
                      file_extensions: List[str] = None) -> List[Dict]:
        """
        Analyse un répertoire et crée un inventaire des fichiers.
        
        Args:
            dir_path: Chemin du répertoire à analyser (par défaut: root_dir)
            file_extensions: Liste des extensions de fichiers à inclure (par défaut: tous)
            
        Returns:
            Liste de dictionnaires contenant les métadonnées des fichiers
        """
        if dir_path is None:
            dir_path = self.root_dir
        else:
            dir_path = Path(dir_path)
            
        self.inventory = []
        
        for file_path in self._get_files(dir_path, file_extensions):
            try:
                file_info = {
                    "path": str(file_path),
                    "name": file_path.name,
                    "extension": file_path.suffix.lower(),
                    "size": file_path.stat().st_size,
                    "modified": datetime.fromtimestamp(file_path.stat().st_mtime),
                    "has_accents": self._has_accents(file_path.name),
                }
                
                # Analyse supplémentaire pour les fichiers JSON
                if file_path.suffix.lower() == ".json":
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            json_data = json.load(f)
                            
                        # Détection de workflow n8n
                        if isinstance(json_data, dict) and "nodes" in json_data:
                            file_info["type"] = "n8n_workflow"
                            file_info["node_count"] = len(json_data.get("nodes", []))
                            
                            # Extraction du nom du workflow s'il existe
                            if "name" in json_data:
                                file_info["workflow_name"] = json_data["name"]
                                
                            # Vérification des problèmes d'encodage dans le workflow
                            file_info["has_encoding_issues"] = self._check_encoding_issues(json_data)
                    except (json.JSONDecodeError, UnicodeDecodeError):
                        file_info["type"] = "invalid_json"
                
                self.inventory.append(file_info)
            except Exception as e:
                print(f"Erreur lors de l'analyse du fichier {file_path}: {str(e)}")
                
        return self.inventory
    
    def create_inventory_report(self, output_format: str = "csv", 
                               output_path: Optional[str] = None) -> str:
        """
        Crée un rapport d'inventaire des fichiers.
        
        Args:
            output_format: Format de sortie ('csv', 'json', ou 'html')
            output_path: Chemin du fichier de sortie (optionnel)
            
        Returns:
            Chemin du fichier de rapport généré
        """
        if not self.inventory:
            print("Aucun inventaire disponible. Exécutez scan_directory() d'abord.")
            return ""
            
        df = pd.DataFrame(self.inventory)
        
        if output_path is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_path = f"inventory_report_{timestamp}.{output_format}"
            
        output_path = Path(output_path)
        
        if output_format == "csv":
            df.to_csv(output_path, index=False, encoding='utf-8')
        elif output_format == "json":
            df.to_json(output_path, orient="records", date_format="iso")
        elif output_format == "html":
            df.to_html(output_path, index=False)
        else:
            raise ValueError(f"Format de sortie non pris en charge: {output_format}")
            
        print(f"Rapport d'inventaire créé: {output_path}")
        return str(output_path)
    
    def organize_files(self, target_dir: Union[str, Path], 
                      organize_by: str = "type",
                      move_files: bool = False) -> Dict[str, List[str]]:
        """
        Organise les fichiers dans des sous-répertoires.
        
        Args:
            target_dir: Répertoire cible pour l'organisation
            organize_by: Critère d'organisation ('type', 'extension', 'date')
            move_files: Si True, déplace les fichiers; sinon, les copie
            
        Returns:
            Dictionnaire des fichiers organisés par catégorie
        """
        if not self.inventory:
            print("Aucun inventaire disponible. Exécutez scan_directory() d'abord.")
            return {}
            
        target_dir = Path(target_dir)
        target_dir.mkdir(parents=True, exist_ok=True)
        
        organized_files = {}
        
        for file_info in self.inventory:
            file_path = Path(file_info["path"])
            
            if organize_by == "type":
                if "type" in file_info and file_info["type"] == "n8n_workflow":
                    category = "n8n_workflows"
                else:
                    category = file_info["extension"].replace(".", "") or "other"
            elif organize_by == "extension":
                category = file_info["extension"].replace(".", "") or "no_extension"
            elif organize_by == "date":
                category = file_info["modified"].strftime("%Y-%m")
            else:
                raise ValueError(f"Critère d'organisation non pris en charge: {organize_by}")
                
            category_dir = target_dir / category
            category_dir.mkdir(exist_ok=True)
            
            dest_path = category_dir / file_path.name
            
            # Éviter les conflits de noms
            if dest_path.exists():
                timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
                dest_path = category_dir / f"{file_path.stem}_{timestamp}{file_path.suffix}"
                
            if move_files:
                shutil.move(str(file_path), str(dest_path))
                operation = "Déplacé"
            else:
                shutil.copy2(str(file_path), str(dest_path))
                operation = "Copié"
                
            print(f"{operation}: {file_path} -> {dest_path}")
            
            if category not in organized_files:
                organized_files[category] = []
                
            organized_files[category].append(str(dest_path))
            
        return organized_files
    
    def fix_accented_characters(self, target_dir: Union[str, Path] = None,
                               create_backup: bool = True) -> List[Dict]:
        """
        Corrige les problèmes de caractères accentués dans les noms de fichiers.
        
        Args:
            target_dir: Répertoire cible (par défaut: utilise root_dir)
            create_backup: Si True, crée une sauvegarde avant modification
            
        Returns:
            Liste des fichiers modifiés avec leurs anciens et nouveaux noms
        """
        if target_dir is None:
            target_dir = self.root_dir
        else:
            target_dir = Path(target_dir)
            
        modified_files = []
        
        for file_path in self._get_files(target_dir):
            if self._has_accents(file_path.name):
                new_name = self._remove_accents(file_path.name)
                new_path = file_path.parent / new_name
                
                if create_backup:
                    backup_path = file_path.with_suffix(f"{file_path.suffix}.bak")
                    shutil.copy2(str(file_path), str(backup_path))
                    print(f"Sauvegarde créée: {backup_path}")
                
                shutil.move(str(file_path), str(new_path))
                print(f"Renommé: {file_path} -> {new_path}")
                
                modified_files.append({
                    "original_path": str(file_path),
                    "new_path": str(new_path),
                    "original_name": file_path.name,
                    "new_name": new_name
                })
                
        return modified_files
    
    def analyze_n8n_workflows(self) -> Dict:
        """
        Analyse les workflows n8n pour extraire des informations utiles.
        
        Returns:
            Dictionnaire contenant des statistiques et informations sur les workflows
        """
        if not self.inventory:
            print("Aucun inventaire disponible. Exécutez scan_directory() d'abord.")
            return {}
            
        workflow_stats = {
            "total_workflows": 0,
            "workflows_with_issues": 0,
            "node_types": {},
            "workflows": []
        }
        
        for file_info in self.inventory:
            if file_info.get("type") != "n8n_workflow":
                continue
                
            workflow_stats["total_workflows"] += 1
            
            if file_info.get("has_encoding_issues", False):
                workflow_stats["workflows_with_issues"] += 1
                
            # Analyse détaillée du workflow
            try:
                file_path = Path(file_info["path"])
                with open(file_path, 'r', encoding='utf-8') as f:
                    workflow_data = json.load(f)
                    
                workflow_info = {
                    "name": workflow_data.get("name", "Sans nom"),
                    "path": str(file_path),
                    "node_count": len(workflow_data.get("nodes", [])),
                    "nodes": []
                }
                
                # Analyse des nœuds
                for node in workflow_data.get("nodes", []):
                    node_type = node.get("type", "unknown")
                    
                    if node_type not in workflow_stats["node_types"]:
                        workflow_stats["node_types"][node_type] = 0
                        
                    workflow_stats["node_types"][node_type] += 1
                    
                    workflow_info["nodes"].append({
                        "name": node.get("name", "Sans nom"),
                        "type": node_type
                    })
                    
                workflow_stats["workflows"].append(workflow_info)
            except Exception as e:
                print(f"Erreur lors de l'analyse du workflow {file_info['path']}: {str(e)}")
                
        return workflow_stats
    
    def _get_files(self, dir_path: Path, file_extensions: List[str] = None) -> List[Path]:
        """Récupère les fichiers d'un répertoire avec filtrage par extension."""
        files = []
        
        for item in dir_path.glob("**/*"):
            if item.is_file():
                if file_extensions is None or item.suffix.lower() in file_extensions:
                    files.append(item)
                    
        return files
    
    def _has_accents(self, text: str) -> bool:
        """Vérifie si un texte contient des caractères accentués."""
        accent_pattern = re.compile(r'[àáâäæãåāèéêëēėęîïíīįìôöòóœøōõûüùúūÿ]', re.IGNORECASE)
        return bool(accent_pattern.search(text))
    
    def _remove_accents(self, text: str) -> str:
        """Remplace les caractères accentués par leurs équivalents non accentués."""
        replacements = {
            'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'æ': 'ae', 'ã': 'a', 'å': 'a', 'ā': 'a',
            'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e',
            'î': 'i', 'ï': 'i', 'í': 'i', 'ī': 'i', 'į': 'i', 'ì': 'i',
            'ô': 'o', 'ö': 'o', 'ò': 'o', 'ó': 'o', 'œ': 'oe', 'ø': 'o', 'ō': 'o', 'õ': 'o',
            'û': 'u', 'ü': 'u', 'ù': 'u', 'ú': 'u', 'ū': 'u',
            'ÿ': 'y',
            'À': 'A', 'Á': 'A', 'Â': 'A', 'Ä': 'A', 'Æ': 'AE', 'Ã': 'A', 'Å': 'A', 'Ā': 'A',
            'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E', 'Ē': 'E', 'Ė': 'E', 'Ę': 'E',
            'Î': 'I', 'Ï': 'I', 'Í': 'I', 'Ī': 'I', 'Į': 'I', 'Ì': 'I',
            'Ô': 'O', 'Ö': 'O', 'Ò': 'O', 'Ó': 'O', 'Œ': 'OE', 'Ø': 'O', 'Ō': 'O', 'Õ': 'O',
            'Û': 'U', 'Ü': 'U', 'Ù': 'U', 'Ú': 'U', 'Ū': 'U',
            'Ÿ': 'Y'
        }
        
        for accent, replacement in replacements.items():
            text = text.replace(accent, replacement)
            
        return text
    
    def _check_encoding_issues(self, json_data: Dict) -> bool:
        """Vérifie les problèmes d'encodage dans les données JSON."""
        # Convertir en chaîne pour rechercher des problèmes
        json_str = json.dumps(json_data)
        
        # Recherche de caractères problématiques typiques
        problematic_patterns = [
            r'\\u00[89][0-9a-f]',  # Caractères UTF-8 mal encodés
            r'Ã©', r'Ã¨', r'Ã§',   # Caractères accentués mal encodés
            r'â€™', r'â€œ', r'â€'  # Guillemets et tirets mal encodés
        ]
        
        for pattern in problematic_patterns:
            if re.search(pattern, json_str):
                return True
                
        return False


def main():
    """Fonction principale pour l'exécution en ligne de commande."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Gestionnaire de fichiers pour projets n8n et Notion")
    parser.add_argument("--dir", "-d", default=".", help="Répertoire à analyser")
    parser.add_argument("--action", "-a", choices=["scan", "organize", "fix-accents", "analyze-workflows"],
                       default="scan", help="Action à effectuer")
    parser.add_argument("--output", "-o", help="Chemin du fichier de sortie")
    parser.add_argument("--format", "-f", choices=["csv", "json", "html"], 
                       default="csv", help="Format de sortie pour les rapports")
    parser.add_argument("--target", "-t", help="Répertoire cible pour l'organisation")
    parser.add_argument("--organize-by", choices=["type", "extension", "date"], 
                       default="type", help="Critère d'organisation")
    parser.add_argument("--move", action="store_true", help="Déplacer les fichiers au lieu de les copier")
    
    args = parser.parse_args()
    
    manager = FileManager(args.dir)
    
    if args.action == "scan":
        manager.scan_directory()
        if args.output:
            manager.create_inventory_report(args.format, args.output)
        else:
            manager.create_inventory_report(args.format)
    elif args.action == "organize":
        if not args.target:
            print("Erreur: --target est requis pour l'action 'organize'")
            return
        manager.scan_directory()
        manager.organize_files(args.target, args.organize_by, args.move)
    elif args.action == "fix-accents":
        manager.fix_accented_characters()
    elif args.action == "analyze-workflows":
        manager.scan_directory()
        workflow_stats = manager.analyze_n8n_workflows()
        print(f"Total des workflows: {workflow_stats['total_workflows']}")
        print(f"Workflows avec problèmes d'encodage: {workflow_stats['workflows_with_issues']}")
        print("Types de nœuds:")
        for node_type, count in workflow_stats["node_types"].items():
            print(f"  - {node_type}: {count}")


if __name__ == "__main__":
    main()
