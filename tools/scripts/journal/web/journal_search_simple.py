import os
import re
import argparse
import json
from pathlib import Path

class SimpleJournalSearch:
    def __init__(self):
        self.entries_dir = Path("docs/journal_de_bord/entries")
        self.index_file = Path("docs/journal_de_bord/.search_index.json")
        
        # Chargement ou création de l'index
        if self.index_file.exists():
            self.load_index()
        else:
            self.build_index()
    
    def load_index(self):
        """Charge l'index existant."""
        with open(self.index_file, 'r', encoding='utf-8') as f:
            self.index = json.load(f)
    
    def build_index(self):
        """Construit l'index de recherche."""
        self.index = []
        
        for entry_file in self.entries_dir.glob("*.md"):
            with open(entry_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extraction des métadonnées
            title_match = re.search(r'title: (.+)', content)
            date_match = re.search(r'date: (.+)', content)
            tags_match = re.search(r'tags: \[(.+)\]', content)
            
            if title_match and date_match:
                title = title_match.group(1)
                date = date_match.group(1)
                tags = []
                if tags_match:
                    tags = [t.strip() for t in tags_match.group(1).split(',')]
                
                # Extraction des sections
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
                
                # Création des entrées d'index pour chaque section
                for section_name, section_text in sections.items():
                    entry = {
                        'file': entry_file.name,
                        'title': title,
                        'date': date,
                        'tags': tags,
                        'section': section_name,
                        'content': section_text,
                        'keywords': self._extract_keywords(title + " " + section_name + " " + section_text)
                    }
                    self.index.append(entry)
        
        # Sauvegarde de l'index
        with open(self.index_file, 'w', encoding='utf-8') as f:
            json.dump(self.index, f, ensure_ascii=False, indent=2)
    
    def _extract_keywords(self, text):
        """Extrait les mots-clés d'un texte."""
        # Conversion en minuscules
        text = text.lower()
        
        # Suppression des caractères spéciaux
        text = re.sub(r'[^\w\s]', ' ', text)
        
        # Suppression des chiffres
        text = re.sub(r'\d+', ' ', text)
        
        # Suppression des espaces multiples
        text = re.sub(r'\s+', ' ', text).strip()
        
        # Extraction des mots
        words = text.split()
        
        # Suppression des mots vides
        stop_words = {'le', 'la', 'les', 'un', 'une', 'des', 'et', 'ou', 'de', 'du', 'au', 'aux', 'a', 'à', 'ce', 'ces', 'cette', 'en', 'par', 'pour', 'sur', 'dans', 'avec', 'sans', 'qui', 'que', 'quoi', 'dont', 'où', 'comment', 'pourquoi', 'quand', 'est', 'sont', 'sera', 'seront', 'été', 'être', 'avoir', 'eu', 'il', 'elle', 'ils', 'elles', 'nous', 'vous', 'je', 'tu', 'on', 'se', 'sa', 'son', 'ses', 'leur', 'leurs', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes', 'notre', 'nos', 'votre', 'vos'}
        keywords = [word for word in words if word not in stop_words and len(word) > 2]
        
        return keywords
    
    def search(self, query, n=5):
        """Recherche dans le journal en utilisant les mots-clés."""
        # Extraction des mots-clés de la requête
        query_keywords = self._extract_keywords(query)
        
        # Calcul du score pour chaque entrée
        scores = []
        for i, entry in enumerate(self.index):
            score = 0
            for keyword in query_keywords:
                if keyword in entry['keywords']:
                    score += 1
                if keyword in entry['title'].lower():
                    score += 2
                if keyword in entry['section'].lower():
                    score += 1
            
            scores.append((i, score))
        
        # Tri par score décroissant
        scores.sort(key=lambda x: x[1], reverse=True)
        
        # Récupération des n meilleurs résultats
        results = []
        for i, score in scores[:n]:
            if score > 0:  # Ne retourner que les résultats pertinents
                results.append(self.index[i])
        
        return results
    
    def search_by_tag(self, tag):
        """Recherche par tag."""
        results = []
        for entry in self.index:
            if tag in entry['tags']:
                results.append(entry)
        
        return results
    
    def search_by_date(self, date):
        """Recherche par date."""
        results = []
        for entry in self.index:
            if entry['date'] == date:
                results.append(entry)
        
        return results

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Rechercher dans le journal de bord")
    parser.add_argument("--query", help="Requête de recherche")
    parser.add_argument("--n", type=int, default=5, help="Nombre de résultats")
    parser.add_argument("--tag", help="Rechercher par tag")
    parser.add_argument("--date", help="Rechercher par date (YYYY-MM-DD)")
    parser.add_argument("--rebuild", action="store_true", help="Reconstruire l'index")
    
    args = parser.parse_args()
    
    search = SimpleJournalSearch()
    if args.rebuild:
        search.build_index()
        print("Index reconstruit avec succès")
    
    if args.tag:
        results = search.search_by_tag(args.tag)
        print(f"Résultats pour le tag '{args.tag}':")
    elif args.date:
        results = search.search_by_date(args.date)
        print(f"Résultats pour la date '{args.date}':")
    elif args.query:
        results = search.search(args.query, args.n)
        print(f"Résultats pour '{args.query}':")
    else:
        if not args.rebuild:
            parser.print_help()
            exit(0)
        results = []
    
    for i, result in enumerate(results):
        print(f"\n{i+1}. {result['title']} ({result['date']}) - Section: {result['section']}")
        print(f"   Fichier: {result['file']}")
        print(f"   Tags: {', '.join(result['tags'])}")
        print(f"   Extrait: {result['content'][:150]}...")
