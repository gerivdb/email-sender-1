import re
import json
import numpy as np
from pathlib import Path
from typing import List, Dict, Any, Optional
import logging

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('journal_topics.log')
    ]
)

logger = logging.getLogger("journal_topics")

class TopicModeling:
    """Modélisation de sujets pour les entrées du journal."""
    
    def __init__(self, n_topics: int = 10, n_top_words: int = 10):
        self.journal_dir = Path("docs/journal_de_bord")
        self.entries_dir = self.journal_dir / "entries"
        self.analysis_dir = self.journal_dir / "analysis"
        self.analysis_dir.mkdir(exist_ok=True, parents=True)
        
        self.n_topics = n_topics
        self.n_top_words = n_top_words
        
        # Stopwords français
        self.stopwords = set([
            'le', 'la', 'les', 'un', 'une', 'des', 'et', 'ou', 'de', 'du', 'au', 'aux', 'a', 'à', 
            'ce', 'ces', 'cette', 'en', 'par', 'pour', 'sur', 'dans', 'avec', 'sans', 'qui', 'que', 
            'quoi', 'dont', 'où', 'comment', 'pourquoi', 'quand', 'est', 'sont', 'sera', 'seront', 
            'été', 'être', 'avoir', 'eu', 'il', 'elle', 'ils', 'elles', 'nous', 'vous', 'je', 'tu', 
            'on', 'se', 'sa', 'son', 'ses', 'leur', 'leurs', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes', 
            'notre', 'nos', 'votre', 'vos'
        ])
    
    def _load_entries(self) -> List[Dict[str, Any]]:
        """Charge toutes les entrées du journal."""
        entries = []
        
        for entry_file in self.entries_dir.glob("*.md"):
            try:
                with open(entry_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Extraire les métadonnées YAML
                metadata = {}
                if content.startswith('---'):
                    end_index = content.find('---', 3)
                    if end_index != -1:
                        yaml_content = content[3:end_index].strip()
                        for line in yaml_content.split('\n'):
                            if ':' in line:
                                key, value = line.split(':', 1)
                                key = key.strip()
                                value = value.strip()
                                
                                if key == 'tags' and value.startswith('[') and value.endswith(']'):
                                    value = [tag.strip() for tag in value[1:-1].split(',')]
                                elif key == 'related' and value.startswith('[') and value.endswith(']'):
                                    value = [file.strip() for file in value[1:-1].split(',')]
                                
                                metadata[key] = value
                        
                        # Extraire le contenu sans les métadonnées
                        content = content[end_index + 3:].strip()
                
                # Nettoyer le contenu
                content = re.sub(r'```.*?```', '', content, flags=re.DOTALL)  # Supprimer les blocs de code
                content = re.sub(r'#.*?\n', '', content)  # Supprimer les titres
                
                entries.append({
                    "file": str(entry_file),
                    "id": entry_file.stem,
                    "title": metadata.get('title', entry_file.stem),
                    "date": metadata.get('date', ''),
                    "tags": metadata.get('tags', []),
                    "content": content
                })
            except Exception as e:
                logger.error(f"Erreur lors du chargement de l'entrée {entry_file}: {e}")
        
        return entries
    
    def extract_topics_lda(self) -> Dict[str, Any]:
        """Extrait les sujets des entrées du journal avec LDA."""
        try:
            from sklearn.feature_extraction.text import CountVectorizer
            from sklearn.decomposition import LatentDirichletAllocation
        except ImportError:
            logger.error("Les bibliothèques scikit-learn ne sont pas installées. Veuillez les installer avec 'pip install scikit-learn'")
            return {}
        
        logger.info(f"Extraction des sujets avec LDA (n_topics={self.n_topics})...")
        
        entries = self._load_entries()
        
        if not entries:
            logger.warning("Aucune entrée trouvée")
            return {}
        
        try:
            # Vectoriser les contenus
            vectorizer = CountVectorizer(
                max_features=1000,
                stop_words=list(self.stopwords),
                min_df=2
            )
            X = vectorizer.fit_transform([entry["content"] for entry in entries])
            
            # Appliquer LDA
            lda = LatentDirichletAllocation(
                n_components=self.n_topics,
                random_state=42,
                learning_method='online'
            )
            lda.fit(X)
            
            # Extraire les mots les plus importants pour chaque sujet
            feature_names = vectorizer.get_feature_names_out()
            topics = []
            
            for topic_idx, topic in enumerate(lda.components_):
                top_words_idx = topic.argsort()[:-self.n_top_words - 1:-1]
                top_words = [feature_names[i] for i in top_words_idx]
                
                topics.append({
                    "id": topic_idx,
                    "name": f"Sujet {topic_idx}: {', '.join(top_words[:3])}",
                    "top_words": top_words,
                    "weight": float(topic.sum())
                })
            
            # Attribuer des sujets aux entrées
            entry_topics = []
            
            for i, entry in enumerate(entries):
                # Transformer l'entrée
                entry_vec = X[i]
                
                # Prédire la distribution des sujets
                topic_distribution = lda.transform(entry_vec)[0]
                
                # Trouver le sujet dominant
                dominant_topic = int(np.argmax(topic_distribution))
                
                entry_topics.append({
                    "entry_id": entry["id"],
                    "file": entry["file"],
                    "title": entry["title"],
                    "date": entry["date"],
                    "dominant_topic": dominant_topic,
                    "topic_distribution": {str(j): float(topic_distribution[j]) for j in range(self.n_topics)}
                })
            
            # Sauvegarder les résultats
            results = {
                "topics": topics,
                "entry_topics": entry_topics
            }
            
            with open(self.analysis_dir / "topics_lda.json", 'w', encoding='utf-8') as f:
                json.dump(results, f, ensure_ascii=False, indent=2)
            
            logger.info(f"Extraction des sujets terminée, {len(topics)} sujets extraits")
            return results
        except Exception as e:
            logger.error(f"Erreur lors de l'extraction des sujets: {e}")
            return {}
    
    def extract_topics_bertopic(self) -> Dict[str, Any]:
        """Extrait les sujets des entrées du journal avec BERTopic."""
        try:
            from bertopic import BERTopic
            from sentence_transformers import SentenceTransformer
        except ImportError:
            logger.error("Les bibliothèques bertopic et sentence-transformers ne sont pas installées. Veuillez les installer avec 'pip install bertopic sentence-transformers'")
            return {}
        
        logger.info("Extraction des sujets avec BERTopic...")
        
        entries = self._load_entries()
        
        if not entries:
            logger.warning("Aucune entrée trouvée")
            return {}
        
        try:
            # Préparer les documents
            documents = [entry["content"] for entry in entries]
            
            # Initialiser le modèle d'embeddings
            embedding_model = SentenceTransformer("distiluse-base-multilingual-cased-v1")
            
            # Initialiser BERTopic
            topic_model = BERTopic(
                embedding_model=embedding_model,
                nr_topics=self.n_topics,
                language="french"
            )
            
            # Ajuster le modèle
            topics, probs = topic_model.fit_transform(documents)
            
            # Extraire les informations sur les sujets
            topic_info = topic_model.get_topic_info()
            
            # Préparer les résultats
            bertopic_topics = []
            
            for topic_id, topic_words in topic_model.get_topics().items():
                if topic_id == -1:  # Outlier topic
                    continue
                
                # Extraire les mots les plus importants
                top_words = [word for word, _ in topic_words[:self.n_top_words]]
                
                # Trouver le nom du sujet
                topic_name = f"Sujet {topic_id}"
                for _, row in topic_info.iterrows():
                    if row["Topic"] == topic_id:
                        topic_name = row["Name"]
                        break
                
                bertopic_topics.append({
                    "id": topic_id,
                    "name": topic_name,
                    "top_words": top_words,
                    "count": int(topic_info[topic_info["Topic"] == topic_id]["Count"].values[0])
                })
            
            # Attribuer des sujets aux entrées
            entry_topics = []
            
            for i, (entry, topic, prob) in enumerate(zip(entries, topics, probs)):
                entry_topics.append({
                    "entry_id": entry["id"],
                    "file": entry["file"],
                    "title": entry["title"],
                    "date": entry["date"],
                    "topic": int(topic),
                    "probability": float(prob)
                })
            
            # Sauvegarder les résultats
            results = {
                "topics": bertopic_topics,
                "entry_topics": entry_topics
            }
            
            with open(self.analysis_dir / "topics_bertopic.json", 'w', encoding='utf-8') as f:
                json.dump(results, f, ensure_ascii=False, indent=2)
            
            # Sauvegarder les visualisations
            try:
                # Visualisation des sujets
                fig = topic_model.visualize_topics()
                fig.write_html(str(self.analysis_dir / "topics_visualization.html"))
                
                # Visualisation de la distribution des sujets au fil du temps
                timestamps = [entry["date"] for entry in entries]
                fig = topic_model.visualize_topics_over_time(documents, timestamps)
                fig.write_html(str(self.analysis_dir / "topics_over_time.html"))
                
                # Visualisation de la hiérarchie des sujets
                fig = topic_model.visualize_hierarchy()
                fig.write_html(str(self.analysis_dir / "topics_hierarchy.html"))
                
                logger.info("Visualisations des sujets sauvegardées")
            except Exception as e:
                logger.error(f"Erreur lors de la sauvegarde des visualisations: {e}")
            
            logger.info(f"Extraction des sujets terminée, {len(bertopic_topics)} sujets extraits")
            return results
        except Exception as e:
            logger.error(f"Erreur lors de l'extraction des sujets avec BERTopic: {e}")
            return {}
    
    def extract_topics_by_section(self) -> Dict[str, Any]:
        """Extrait les sujets par section du journal."""
        logger.info("Extraction des sujets par section...")
        
        entries = self._load_entries()
        
        if not entries:
            logger.warning("Aucune entrée trouvée")
            return {}
        
        try:
            # Sections à analyser
            sections = {
                "system": "Optimisations pour le système",
                "code": "Optimisations pour le code",
                "errors": "Gestion des erreurs",
                "workflow": "Workflows",
                "music": "Impact sur le projet musical"
            }
            
            # Extraire le contenu par section
            section_contents = {section: [] for section in sections}
            
            for entry in entries:
                content = entry["content"]
                
                for section, section_title in sections.items():
                    # Rechercher la section dans le contenu
                    pattern = rf"## .*{section_title}.*\n(.*?)(?=\n## |$)"
                    match = re.search(pattern, content, re.DOTALL)
                    
                    if match:
                        section_content = match.group(1).strip()
                        if section_content:
                            section_contents[section].append({
                                "entry_id": entry["id"],
                                "file": entry["file"],
                                "title": entry["title"],
                                "date": entry["date"],
                                "content": section_content
                            })
            
            # Analyser les sujets par section
            section_topics = {}
            
            for section, contents in section_contents.items():
                if not contents:
                    logger.warning(f"Aucun contenu trouvé pour la section '{section}'")
                    continue
                
                # Regrouper par mois
                months = {}
                
                for item in contents:
                    date = item["date"]
                    if not date:
                        continue
                    
                    month = date[:7]  # YYYY-MM
                    
                    if month not in months:
                        months[month] = []
                    
                    months[month].append(item)
                
                # Extraire les sujets les plus fréquents par mois
                month_topics = {}
                
                for month, month_contents in months.items():
                    # Extraire les termes les plus fréquents
                    text = " ".join([item["content"] for item in month_contents])
                    
                    # Nettoyer le texte
                    text = re.sub(r'[^\w\s]', ' ', text.lower())
                    
                    # Compter les occurrences des mots
                    words = text.split()
                    word_counts = {}
                    
                    for word in words:
                        if word not in self.stopwords and len(word) > 2:
                            if word in word_counts:
                                word_counts[word] += 1
                            else:
                                word_counts[word] = 1
                    
                    # Sélectionner les termes les plus fréquents
                    top_terms = sorted(word_counts.items(), key=lambda x: x[1], reverse=True)[:10]
                    
                    # Calculer le total des occurrences
                    total = sum([count for _, count in top_terms])
                    
                    # Normaliser les fréquences
                    topics = {term: count / total for term, count in top_terms}
                    
                    month_topics[month] = topics
                
                section_topics[section] = month_topics
            
            # Sauvegarder les résultats
            with open(self.analysis_dir / "topics_by_section.json", 'w', encoding='utf-8') as f:
                json.dump(section_topics, f, ensure_ascii=False, indent=2)
            
            logger.info("Extraction des sujets par section terminée")
            return section_topics
        except Exception as e:
            logger.error(f"Erreur lors de l'extraction des sujets par section: {e}")
            return {}

# Point d'entrée
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Modélisation de sujets pour le journal de bord")
    parser.add_argument("--lda", action="store_true", help="Extraire les sujets avec LDA")
    parser.add_argument("--bertopic", action="store_true", help="Extraire les sujets avec BERTopic")
    parser.add_argument("--sections", action="store_true", help="Extraire les sujets par section")
    parser.add_argument("--n-topics", type=int, default=10, help="Nombre de sujets à extraire")
    parser.add_argument("--n-top-words", type=int, default=10, help="Nombre de mots par sujet")
    
    args = parser.parse_args()
    
    topic_modeling = TopicModeling(n_topics=args.n_topics, n_top_words=args.n_top_words)
    
    if args.lda:
        topic_modeling.extract_topics_lda()
    
    if args.bertopic:
        topic_modeling.extract_topics_bertopic()
    
    if args.sections:
        topic_modeling.extract_topics_by_section()
    
    if not (args.lda or args.bertopic or args.sections):
        # Par défaut, exécuter LDA et l'analyse par section
        topic_modeling.extract_topics_lda()
        topic_modeling.extract_topics_by_section()
