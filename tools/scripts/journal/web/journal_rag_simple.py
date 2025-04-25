import os
import re
import json
import argparse
from pathlib import Path

class SimpleJournalRAG:
    def __init__(self):
        self.entries_dir = Path("docs/journal_de_bord/entries")
        self.rag_dir = Path("docs/journal_de_bord/rag")
        self.rag_dir.mkdir(exist_ok=True, parents=True)
        
        self.index_file = self.rag_dir / "index.json"
        self.chunks_file = self.rag_dir / "chunks.json"
        
        # Chargement ou création de l'index
        if self.index_file.exists() and self.chunks_file.exists():
            self.load_index()
        else:
            self.build_index()
    
    def load_index(self):
        """Charge l'index existant."""
        with open(self.index_file, 'r', encoding='utf-8') as f:
            self.index = json.load(f)
        
        with open(self.chunks_file, 'r', encoding='utf-8') as f:
            self.chunks = json.load(f)
    
    def build_index(self):
        """Construit l'index RAG."""
        self.index = []
        self.chunks = []
        
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
                
                # Découpage du contenu en chunks
                chunks = self._chunk_content(content)
                
                for i, chunk in enumerate(chunks):
                    chunk_id = f"{entry_file.stem}-{i}"
                    
                    # Extraction des mots-clés
                    keywords = self._extract_keywords(chunk)
                    
                    # Ajout du chunk à l'index
                    self.chunks.append({
                        "id": chunk_id,
                        "file": str(entry_file.name),
                        "title": title,
                        "date": date,
                        "tags": tags,
                        "content": chunk,
                        "keywords": keywords
                    })
                    
                    # Ajout à l'index
                    self.index.append({
                        "id": chunk_id,
                        "file": str(entry_file.name),
                        "title": title,
                        "date": date,
                        "keywords": keywords
                    })
        
        # Sauvegarde de l'index
        with open(self.index_file, 'w', encoding='utf-8') as f:
            json.dump(self.index, f, ensure_ascii=False, indent=2)
        
        # Sauvegarde des chunks
        with open(self.chunks_file, 'w', encoding='utf-8') as f:
            json.dump(self.chunks, f, ensure_ascii=False, indent=2)
    
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
    
    def _chunk_content(self, content, max_chunk_size=1000, overlap=200):
        """Découpe le contenu en chunks avec chevauchement."""
        # Suppression des métadonnées YAML
        content_without_yaml = re.sub(r'^---.*?---\n', '', content, flags=re.DOTALL)
        
        # Découpage par sections
        sections = []
        current_section = None
        section_content = []
        
        for line in content_without_yaml.split('\n'):
            if line.startswith('## '):
                if current_section:
                    sections.append((current_section, '\n'.join(section_content)))
                    section_content = []
                current_section = line
            elif current_section:
                section_content.append(line)
        
        if current_section and section_content:
            sections.append((current_section, '\n'.join(section_content)))
        
        # Création des chunks
        chunks = []
        for section_title, section_text in sections:
            # Si la section est courte, on la garde entière
            if len(section_text) <= max_chunk_size:
                chunks.append(f"{section_title}\n{section_text}")
            else:
                # Sinon, on la découpe avec chevauchement
                words = section_text.split()
                words_per_chunk = max_chunk_size // 5  # Approximation
                
                for i in range(0, len(words), words_per_chunk - overlap):
                    chunk_words = words[i:i + words_per_chunk]
                    chunk_text = ' '.join(chunk_words)
                    chunks.append(f"{section_title} (partie {i//words_per_chunk + 1})\n{chunk_text}")
        
        return chunks
    
    def query(self, query_text, n=3):
        """Interroge le système RAG en utilisant les mots-clés."""
        # Extraction des mots-clés de la requête
        query_keywords = self._extract_keywords(query_text)
        
        # Calcul du score pour chaque entrée
        scores = []
        for i, entry in enumerate(self.index):
            score = 0
            for keyword in query_keywords:
                if keyword in entry['keywords']:
                    score += 1
                if keyword in entry['title'].lower():
                    score += 2
            
            scores.append((i, score))
        
        # Tri par score décroissant
        scores.sort(key=lambda x: x[1], reverse=True)
        
        # Récupération des n meilleurs résultats
        results = []
        for i, score in scores[:n]:
            if score > 0:  # Ne retourner que les résultats pertinents
                chunk_id = self.index[i]["id"]
                chunk = next((c for c in self.chunks if c["id"] == chunk_id), None)
                if chunk:
                    results.append(chunk)
        
        return results
    
    def generate_response(self, query_text, n=3):
        """Génère une réponse basée sur les résultats de la recherche."""
        results = self.query(query_text, n)
        
        if not results:
            return "Aucune information pertinente trouvée dans le journal de bord."
        
        # Construction de la réponse
        response = f"Voici les informations pertinentes trouvées dans le journal de bord pour '{query_text}':\n\n"
        
        for i, result in enumerate(results):
            response += f"### {i+1}. {result['title']} ({result['date']})\n\n"
            response += f"{result['content']}\n\n"
            response += f"Source: [{result['file']}](docs/journal_de_bord/entries/{result['file']})\n\n"
            response += "---\n\n"
        
        return response
    
    def export_for_augment(self):
        """Exporte les données pour Augment/Claude."""
        augment_file = self.rag_dir / "augment_memories.json"
        
        memories = []
        for chunk in self.chunks:
            memory = {
                "title": f"{chunk['title']} ({chunk['date']})",
                "content": chunk['content'],
                "tags": chunk['tags'],
                "source": f"docs/journal_de_bord/entries/{chunk['file']}"
            }
            memories.append(memory)
        
        with open(augment_file, 'w', encoding='utf-8') as f:
            json.dump(memories, f, ensure_ascii=False, indent=2)
        
        print(f"Données exportées pour Augment dans {augment_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Système RAG pour le journal de bord")
    parser.add_argument("--query", help="Requête à poser au système RAG")
    parser.add_argument("--rebuild", action="store_true", help="Reconstruire l'index")
    parser.add_argument("--export", action="store_true", help="Exporter pour Augment/Claude")
    
    args = parser.parse_args()
    
    rag = SimpleJournalRAG()
    
    if args.rebuild:
        rag.build_index()
        print("Index RAG reconstruit avec succès")
    
    if args.export:
        rag.export_for_augment()
    
    if args.query:
        response = rag.generate_response(args.query)
        print(response)
