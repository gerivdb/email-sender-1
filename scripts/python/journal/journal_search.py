import os
import re
import argparse
import json
from pathlib import Path
import numpy as np

# Correction pour les versions récentes de huggingface_hub
import warnings
warnings.filterwarnings("ignore")

from sentence_transformers import SentenceTransformer

class JournalSearch:
    def __init__(self):
        self.model = SentenceTransformer('all-MiniLM-L6-v2')
        self.entries_dir = Path("docs/journal_de_bord/entries")
        self.index_file = Path("docs/journal_de_bord/.search_index.json")
        self.vector_file = Path("docs/journal_de_bord/.search_vectors.npy")

        # Chargement ou création de l'index
        if self.index_file.exists() and self.vector_file.exists():
            self.load_index()
        else:
            self.build_index()

    def load_index(self):
        """Charge l'index existant."""
        with open(self.index_file, 'r', encoding='utf-8') as f:
            self.index = json.load(f)

        self.vectors = np.load(str(self.vector_file))

    def build_index(self):
        """Construit l'index de recherche."""
        self.index = []
        vectors = []

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
                        'content': section_text
                    }
                    self.index.append(entry)

                    # Création du vecteur d'embedding
                    text_to_embed = f"{title} {section_name} {section_text}"
                    vector = self.model.encode(text_to_embed)
                    vectors.append(vector)

        # Sauvegarde de l'index
        with open(self.index_file, 'w', encoding='utf-8') as f:
            json.dump(self.index, f, ensure_ascii=False, indent=2)

        # Sauvegarde des vecteurs
        self.vectors = np.array(vectors)
        np.save(str(self.vector_file), self.vectors)

    def search(self, query, n=5):
        """Recherche dans le journal en utilisant la similarité cosinus."""
        # Conversion de la requête en vecteur
        query_vector = self.model.encode(query)

        # Calcul de la similarité cosinus avec tous les vecteurs
        similarities = np.dot(self.vectors, query_vector) / (
            np.linalg.norm(self.vectors, axis=1) * np.linalg.norm(query_vector)
        )

        # Récupération des indices des n vecteurs les plus similaires
        top_indices = np.argsort(similarities)[::-1][:n]

        # Récupération des résultats
        results = []
        for idx in top_indices:
            results.append(self.index[idx])

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

    search = JournalSearch()
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
