import os
import json
import re
import argparse
from pathlib import Path
from datetime import datetime
import sys

# Ajouter le répertoire parent au chemin pour pouvoir importer journal_entry
sys.path.append(str(Path(__file__).parent))
from journal_entry import create_journal_entry, normalize_accents

class AugmentJournalIntegration:
    def __init__(self):
        self.journal_dir = Path("docs/journal_de_bord")
        self.entries_dir = self.journal_dir / "entries"
        self.augment_memories_file = self.journal_dir / "rag" / "augment_memories.json"
        self.augment_memories_dir = Path(".augment/memories")
        
        # Créer les répertoires s'ils n'existent pas
        self.augment_memories_dir.mkdir(exist_ok=True, parents=True)
    
    def export_journal_to_augment(self):
        """Exporte les entrées du journal vers Augment Memories."""
        # Vérifier si le fichier d'index RAG existe
        if not self.augment_memories_file.exists():
            print(f"Fichier d'index RAG non trouvé: {self.augment_memories_file}")
            print("Exécutez d'abord: python scripts/python/journal/journal_rag_simple.py --rebuild --export")
            return False
        
        # Charger les données RAG
        with open(self.augment_memories_file, 'r', encoding='utf-8') as f:
            memories = json.load(f)
        
        # Formater les memories pour Augment
        augment_memories = []
        for memory in memories:
            augment_memory = {
                "text": f"[JOURNAL DE BORD] {memory['title']}: {memory['content']}",
                "metadata": {
                    "source": memory['source'],
                    "tags": memory['tags'],
                    "date": datetime.now().isoformat()
                }
            }
            augment_memories.append(augment_memory)
        
        # Sauvegarder dans le format Augment
        augment_file = self.augment_memories_dir / "journal_memories.json"
        with open(augment_file, 'w', encoding='utf-8') as f:
            json.dump(augment_memories, f, ensure_ascii=False, indent=2)
        
        print(f"Exporté {len(augment_memories)} entrées vers Augment Memories: {augment_file}")
        return True
    
    def import_augment_to_journal(self):
        """Importe les Memories d'Augment vers le journal."""
        # Rechercher tous les fichiers de memories Augment
        augment_files = list(self.augment_memories_dir.glob("*.json"))
        if not augment_files:
            print(f"Aucun fichier de memories Augment trouvé dans {self.augment_memories_dir}")
            return False
        
        # Charger toutes les memories
        all_memories = []
        for file in augment_files:
            if file.name == "journal_memories.json":
                continue  # Ignorer nos propres memories exportées
            
            try:
                with open(file, 'r', encoding='utf-8') as f:
                    memories = json.load(f)
                    if isinstance(memories, list):
                        all_memories.extend(memories)
                    else:
                        print(f"Format inattendu dans {file}, ignoré")
            except Exception as e:
                print(f"Erreur lors de la lecture de {file}: {e}")
        
        if not all_memories:
            print("Aucune memory Augment valide trouvée")
            return False
        
        # Regrouper les memories par thème
        memory_groups = {}
        for memory in all_memories:
            if not isinstance(memory, dict) or 'text' not in memory:
                continue
                
            # Extraire un thème de la memory (première phrase ou premiers mots)
            text = memory.get('text', '')
            theme = text.split('.')[0][:50]  # Première phrase ou premiers 50 caractères
            
            if theme in memory_groups:
                memory_groups[theme].append(memory)
            else:
                memory_groups[theme] = [memory]
        
        # Créer des entrées de journal pour chaque groupe de memories
        for theme, memories in memory_groups.items():
            # Créer un titre pour l'entrée
            title = f"Augment Memories: {theme}"
            
            # Extraire des tags potentiels
            tags = set()
            for memory in memories:
                if isinstance(memory, dict) and 'metadata' in memory:
                    metadata = memory.get('metadata', {})
                    if isinstance(metadata, dict) and 'tags' in metadata:
                        memory_tags = metadata.get('tags', [])
                        if isinstance(memory_tags, list):
                            tags.update(memory_tags)
            
            # Créer l'entrée
            tags = list(tags)
            tags.append('augment-memory')
            entry_path = create_journal_entry(title, tags)
            
            if entry_path:
                # Ajouter le contenu des memories
                with open(entry_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Préparer le contenu des memories
                memories_content = "\n\n".join([
                    f"- {memory.get('text', '')}" for memory in memories
                ])
                
                # Remplacer la section "Actions réalisées"
                content = re.sub(
                    r'## Actions réalisées\n-\s*\n',
                    f"## Actions réalisées\n- Import automatique depuis Augment Memories\n\n## Contenu des Memories\n{memories_content}\n\n",
                    content
                )
                
                # Ajouter des informations dans la section "Optimisations identifiées"
                optimisations = (
                    "- Pour le système: Intégration entre Augment Memories et le journal de bord\n"
                    "- Pour le code: Possibilité d'extraire des snippets de code des memories\n"
                    "- Pour la gestion des erreurs: Identification des problèmes récurrents mentionnés dans les memories\n"
                    "- Pour les workflows: Opportunités d'automatisation basées sur les patterns identifiés\n"
                )
                
                content = re.sub(
                    r'## Optimisations identifiées\n- Pour le système:\s*\n- Pour le code:\s*\n- Pour la gestion des erreurs:\s*\n- Pour les workflows:\s*\n',
                    f"## Optimisations identifiées\n{optimisations}\n",
                    content
                )
                
                # Écrire le contenu mis à jour
                with open(entry_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                print(f"Entrée créée à partir de {len(memories)} memories Augment: {entry_path}")
        
        return True
    
    def create_augment_memory_from_entry(self, entry_path):
        """Crée une memory Augment à partir d'une entrée de journal spécifique."""
        if not Path(entry_path).exists():
            print(f"Entrée non trouvée: {entry_path}")
            return False
        
        try:
            with open(entry_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extraire les métadonnées
            title_match = re.search(r'title: (.+)', content)
            date_match = re.search(r'date: (.+)', content)
            tags_match = re.search(r'tags: \[(.+)\]', content)
            
            if not title_match or not date_match:
                print(f"Métadonnées manquantes dans {entry_path}")
                return False
            
            title = title_match.group(1)
            date = date_match.group(1)
            tags = []
            if tags_match:
                tags = [tag.strip() for tag in tags_match.group(1).split(',')]
            
            # Extraire les sections importantes
            sections = {}
            current_section = None
            section_content = []
            
            for line in content.split('\n'):
                if line.startswith('## '):
                    if current_section:
                        sections[current_section] = '\n'.join(section_content)
                        section_content = []
                    current_section = line[3:].strip()
                elif current_section:
                    section_content.append(line)
            
            if current_section and section_content:
                sections[current_section] = '\n'.join(section_content)
            
            # Créer le contenu de la memory
            memory_content = f"Titre: {title}\nDate: {date}\n\n"
            
            important_sections = [
                "Actions réalisées", 
                "Résolution des erreurs, déductions tirées",
                "Optimisations identifiées",
                "Enseignements techniques"
            ]
            
            for section in important_sections:
                if section in sections:
                    memory_content += f"{section}:\n{sections[section]}\n\n"
            
            # Créer la memory Augment
            memory = {
                "text": memory_content,
                "metadata": {
                    "source": str(entry_path),
                    "tags": tags,
                    "date": datetime.now().isoformat()
                }
            }
            
            # Sauvegarder la memory
            memory_file = self.augment_memories_dir / f"journal_entry_{Path(entry_path).stem}.json"
            with open(memory_file, 'w', encoding='utf-8') as f:
                json.dump([memory], f, ensure_ascii=False, indent=2)
            
            print(f"Memory Augment créée: {memory_file}")
            return True
            
        except Exception as e:
            print(f"Erreur lors de la création de la memory: {e}")
            return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Intégration entre le journal de bord et Augment Memories")
    parser.add_argument("action", choices=["export", "import", "create"], 
                        help="Action à effectuer (export: journal vers Augment, import: Augment vers journal, create: créer une memory à partir d'une entrée)")
    parser.add_argument("--entry", help="Chemin de l'entrée de journal (pour l'action 'create')")
    
    args = parser.parse_args()
    
    integration = AugmentJournalIntegration()
    
    if args.action == "export":
        integration.export_journal_to_augment()
    elif args.action == "import":
        integration.import_augment_to_journal()
    elif args.action == "create":
        if not args.entry:
            print("Erreur: --entry est requis pour l'action 'create'")
            sys.exit(1)
        integration.create_augment_memory_from_entry(args.entry)
