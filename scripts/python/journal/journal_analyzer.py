import re
import json
import sys
from pathlib import Path
from collections import Counter
from datetime import datetime, timedelta

# Essayer d'importer les dépendances, sinon afficher un message d'erreur
try:
    import numpy as np
    import pandas as pd
    import matplotlib.pyplot as plt
    from wordcloud import WordCloud
except ImportError:
    print("Erreur: Certaines dépendances ne sont pas installées.")
    print("Installez-les avec: pip install numpy pandas matplotlib wordcloud")
    sys.exit(1)

class JournalAnalyzer:
    def __init__(self):
        self.journal_dir = Path("docs/journal_de_bord")
        self.entries_dir = self.journal_dir / "entries"
        self.analysis_dir = self.journal_dir / "analysis"
        self.analysis_dir.mkdir(exist_ok=True, parents=True)
        
        # Charger toutes les entrées
        self.entries = self._load_entries()
        
    def _load_entries(self):
        """Charge toutes les entrées du journal."""
        entries = []
        
        for entry_file in self.entries_dir.glob("*.md"):
            with open(entry_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extraire les métadonnées
            title_match = re.search(r'title: (.+)', content)
            date_match = re.search(r'date: (.+)', content)
            time_match = re.search(r'heure: (.+)', content)
            tags_match = re.search(r'tags: \[(.+)\]', content)
            
            if not title_match or not date_match:
                continue
            
            title = title_match.group(1)
            date = date_match.group(1)
            time = time_match.group(1) if time_match else "00-00"
            
            tags = []
            if tags_match:
                tags = [tag.strip() for tag in tags_match.group(1).split(',')]
            
            # Extraire le contenu principal (sans les métadonnées)
            content_match = re.search(r'---\n[\s\S]*?\n---\n([\s\S]*)', content)
            if content_match:
                main_content = content_match.group(1)
            else:
                main_content = content
            
            # Essayer de parser la date et l'heure
            try:
                dt = datetime.strptime(f"{date} {time.replace('-', ':')}", "%Y-%m-%d %H:%M")
            except ValueError:
                try:
                    dt = datetime.strptime(date, "%Y-%m-%d")
                except ValueError:
                    # Utiliser la date actuelle si le format est invalide
                    dt = datetime.now()
            
            entries.append({
                "file": entry_file.name,
                "title": title,
                "date": date,
                "time": time,
                "tags": tags,
                "content": main_content,
                "datetime": dt
            })
        
        # Trier par date
        entries.sort(key=lambda x: x["datetime"])
        
        return entries
    
    def analyze_term_frequency(self, period="month", top_n=20):
        """Analyse la fréquence des termes par période."""
        # Regrouper les entrées par période
        periods = {}
        
        for entry in self.entries:
            if period == "day":
                period_key = entry["date"]
            elif period == "week":
                # Calculer le début de la semaine (lundi)
                dt = entry["datetime"]
                start_of_week = dt - timedelta(days=dt.weekday())
                period_key = start_of_week.strftime("%Y-%m-%d")
            elif period == "month":
                period_key = entry["datetime"].strftime("%Y-%m")
            else:
                period_key = "all"
            
            if period_key not in periods:
                periods[period_key] = []
            
            periods[period_key].append(entry)
        
        # Analyser chaque période
        results = {}
        
        for period_key, period_entries in periods.items():
            # Concaténer tout le contenu
            all_content = " ".join([entry["content"] for entry in period_entries])
            
            # Nettoyer le texte
            clean_content = re.sub(r'[^\w\s]', ' ', all_content.lower())
            clean_content = re.sub(r'\s+', ' ', clean_content).strip()
            
            # Compter les mots
            words = clean_content.split()
            word_counts = Counter(words)
            
            # Filtrer les mots vides
            stop_words = {'le', 'la', 'les', 'un', 'une', 'des', 'et', 'ou', 'de', 'du', 'au', 'aux', 'a', 'à', 'ce', 'ces', 'cette', 'en', 'par', 'pour', 'sur', 'dans', 'avec', 'sans', 'qui', 'que', 'quoi', 'dont', 'où', 'comment', 'pourquoi', 'quand', 'est', 'sont', 'sera', 'seront', 'été', 'être', 'avoir', 'eu', 'il', 'elle', 'ils', 'elles', 'nous', 'vous', 'je', 'tu', 'on', 'se', 'sa', 'son', 'ses', 'leur', 'leurs', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes', 'notre', 'nos', 'votre', 'vos'}
            filtered_counts = {word: count for word, count in word_counts.items() if word not in stop_words and len(word) > 2}
            
            # Prendre les N termes les plus fréquents
            top_terms = dict(sorted(filtered_counts.items(), key=lambda x: x[1], reverse=True)[:top_n])
            
            results[period_key] = {
                "top_terms": top_terms,
                "entry_count": len(period_entries),
                "word_count": len(words)
            }
        
        # Sauvegarder les résultats
        with open(self.analysis_dir / "term_frequency.json", 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
        
        return results
    
    def generate_word_cloud(self, period_key=None):
        """Génère un nuage de mots pour une période donnée."""
        # Charger les résultats d'analyse
        try:
            with open(self.analysis_dir / "term_frequency.json", 'r', encoding='utf-8') as f:
                results = json.load(f)
        except FileNotFoundError:
            results = self.analyze_term_frequency()
        
        # Si aucune période n'est spécifiée, utiliser toutes les entrées
        if not period_key:
            # Concaténer tout le contenu
            all_content = " ".join([entry["content"] for entry in self.entries])
            
            # Nettoyer le texte
            clean_content = re.sub(r'[^\w\s]', ' ', all_content.lower())
            clean_content = re.sub(r'\s+', ' ', clean_content).strip()
            
            # Générer le nuage de mots
            wordcloud = WordCloud(width=800, height=400, background_color='white', 
                                  stopwords=set(['le', 'la', 'les', 'un', 'une', 'des', 'et', 'ou', 'de', 'du']),
                                  max_words=100, contour_width=3, contour_color='steelblue')
            wordcloud.generate(clean_content)
            
            # Sauvegarder l'image
            plt.figure(figsize=(10, 5))
            plt.imshow(wordcloud, interpolation='bilinear')
            plt.axis("off")
            plt.tight_layout(pad=0)
            plt.savefig(self.analysis_dir / "wordcloud_all.png", dpi=300, bbox_inches='tight')
            plt.close()
            
            return str(self.analysis_dir / "wordcloud_all.png")
        
        # Générer pour une période spécifique
        if period_key in results:
            # Créer un texte à partir des termes les plus fréquents
            text = " ".join([f"{term} " * count for term, count in results[period_key]["top_terms"].items()])
            
            # Générer le nuage de mots
            wordcloud = WordCloud(width=800, height=400, background_color='white', 
                                  max_words=100, contour_width=3, contour_color='steelblue')
            wordcloud.generate(text)
            
            # Sauvegarder l'image
            plt.figure(figsize=(10, 5))
            plt.imshow(wordcloud, interpolation='bilinear')
            plt.axis("off")
            plt.tight_layout(pad=0)
            plt.savefig(self.analysis_dir / f"wordcloud_{period_key}.png", dpi=300, bbox_inches='tight')
            plt.close()
            
            return str(self.analysis_dir / f"wordcloud_{period_key}.png")
        
        return None
    
    def analyze_tag_evolution(self):
        """Analyse l'évolution des tags au fil du temps."""
        # Regrouper par mois
        months = {}
        
        for entry in self.entries:
            month = entry["datetime"].strftime("%Y-%m")
            
            if month not in months:
                months[month] = {"entries": [], "tags": Counter()}
            
            months[month]["entries"].append(entry)
            months[month]["tags"].update(entry["tags"])
        
        # Analyser l'évolution
        evolution = {}
        all_tags = set()
        
        for month, data in months.items():
            # Calculer la fréquence relative des tags
            total_tags = sum(data["tags"].values())
            tag_frequency = {tag: count / total_tags for tag, count in data["tags"].items()} if total_tags > 0 else {}
            
            evolution[month] = {
                "tag_counts": dict(data["tags"]),
                "tag_frequency": tag_frequency,
                "entry_count": len(data["entries"])
            }
            
            all_tags.update(data["tags"].keys())
        
        # Préparer les données pour la visualisation
        tags_data = {tag: [] for tag in all_tags}
        months_sorted = sorted(evolution.keys())
        
        for month in months_sorted:
            for tag in all_tags:
                tags_data[tag].append(evolution[month]["tag_frequency"].get(tag, 0))
        
        # Créer un DataFrame pour faciliter la visualisation
        df = pd.DataFrame(tags_data, index=months_sorted)
        
        # Sauvegarder les données
        df.to_csv(self.analysis_dir / "tag_evolution.csv")
        
        # Créer une visualisation
        plt.figure(figsize=(12, 8))
        
        # Sélectionner les 10 tags les plus fréquents
        top_tags = Counter()
        for month_data in evolution.values():
            top_tags.update(month_data["tag_counts"])
        
        top_10_tags = [tag for tag, _ in top_tags.most_common(10)]
        
        for tag in top_10_tags:
            plt.plot(months_sorted, df[tag], marker='o', linewidth=2, label=tag)
        
        plt.title("Évolution des tags au fil du temps")
        plt.xlabel("Mois")
        plt.ylabel("Fréquence relative")
        plt.legend()
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # Sauvegarder l'image
        plt.savefig(self.analysis_dir / "tag_evolution.png", dpi=300, bbox_inches='tight')
        plt.close()
        
        return {
            "evolution": evolution,
            "visualization": str(self.analysis_dir / "tag_evolution.png")
        }
    
    def analyze_topic_trends(self):
        """Analyse les tendances des sujets au fil du temps."""
        # Extraire les sections "Optimisations identifiées" et "Enseignements techniques"
        topics = {
            "system": [],
            "code": [],
            "errors": [],
            "workflow": [],
            "music": []
        }
        
        for entry in self.entries:
            content = entry["content"]
            
            # Optimisations système
            system_match = re.search(r'Pour le système:(.*?)(?=Pour le code:|$)', content, re.DOTALL)
            if system_match and system_match.group(1).strip():
                topics["system"].append({
                    "date": entry["datetime"],
                    "content": system_match.group(1).strip(),
                    "entry": entry["file"]
                })
            
            # Optimisations code
            code_match = re.search(r'Pour le code:(.*?)(?=Pour la gestion des erreurs:|$)', content, re.DOTALL)
            if code_match and code_match.group(1).strip():
                topics["code"].append({
                    "date": entry["datetime"],
                    "content": code_match.group(1).strip(),
                    "entry": entry["file"]
                })
            
            # Gestion des erreurs
            errors_match = re.search(r'Pour la gestion des erreurs:(.*?)(?=Pour les workflows:|$)', content, re.DOTALL)
            if errors_match and errors_match.group(1).strip():
                topics["errors"].append({
                    "date": entry["datetime"],
                    "content": errors_match.group(1).strip(),
                    "entry": entry["file"]
                })
            
            # Workflows
            workflow_match = re.search(r'Pour les workflows:(.*?)(?=##|$)', content, re.DOTALL)
            if workflow_match and workflow_match.group(1).strip():
                topics["workflow"].append({
                    "date": entry["datetime"],
                    "content": workflow_match.group(1).strip(),
                    "entry": entry["file"]
                })
            
            # Impact musical
            music_match = re.search(r'## Impact sur le projet musical\n([\s\S]*?)(?=\n##|$)', content)
            if music_match and music_match.group(1).strip():
                topics["music"].append({
                    "date": entry["datetime"],
                    "content": music_match.group(1).strip(),
                    "entry": entry["file"]
                })
        
        # Analyser l'évolution des sujets par mois
        monthly_topics = {}
        
        for topic, entries in topics.items():
            by_month = {}
            
            for entry in entries:
                month = entry["date"].strftime("%Y-%m")
                
                if month not in by_month:
                    by_month[month] = []
                
                by_month[month].append(entry)
            
            monthly_topics[topic] = by_month
        
        # Créer une visualisation
        plt.figure(figsize=(12, 8))
        
        months = sorted(set(month for topic_data in monthly_topics.values() for month in topic_data.keys()))
        topic_counts = {topic: [len(monthly_topics[topic].get(month, [])) for month in months] for topic in topics.keys()}
        
        for topic, counts in topic_counts.items():
            plt.plot(months, counts, marker='o', linewidth=2, label=topic)
        
        plt.title("Évolution des sujets au fil du temps")
        plt.xlabel("Mois")
        plt.ylabel("Nombre d'entrées")
        plt.legend()
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # Sauvegarder l'image
        plt.savefig(self.analysis_dir / "topic_trends.png", dpi=300, bbox_inches='tight')
        plt.close()
        
        # Sauvegarder les données
        with open(self.analysis_dir / "topic_trends.json", 'w', encoding='utf-8') as f:
            json.dump({
                "monthly_topics": {topic: {month: [{"content": e["content"], "entry": e["entry"]} for e in entries] 
                                         for month, entries in months_data.items()}
                                for topic, months_data in monthly_topics.items()},
                "topic_counts": {topic: {months[i]: count for i, count in enumerate(counts)} 
                               for topic, counts in topic_counts.items()}
            }, f, ensure_ascii=False, indent=2)
        
        return {
            "monthly_topics": monthly_topics,
            "visualization": str(self.analysis_dir / "topic_trends.png")
        }
    
    def cluster_entries(self, n_clusters=5):
        """Regroupe les entrées par similarité de contenu."""
        try:
            from sklearn.feature_extraction.text import TfidfVectorizer
            from sklearn.cluster import KMeans
        except ImportError:
            print("Erreur: scikit-learn n'est pas installé.")
            print("Installez-le avec: pip install scikit-learn")
            return None
        
        # Extraire le contenu de toutes les entrées
        contents = [entry["content"] for entry in self.entries]
        
        # Vectoriser le contenu avec TF-IDF
        vectorizer = TfidfVectorizer(
            max_features=1000,
            stop_words=['le', 'la', 'les', 'un', 'une', 'des', 'et', 'ou', 'de', 'du'],
            ngram_range=(1, 2)
        )
        X = vectorizer.fit_transform(contents)
        
        # Appliquer K-means clustering
        kmeans = KMeans(n_clusters=n_clusters, random_state=42)
        clusters = kmeans.fit_predict(X)
        
        # Ajouter les clusters aux entrées
        for i, entry in enumerate(self.entries):
            entry["cluster"] = int(clusters[i])
        
        # Analyser chaque cluster
        cluster_analysis = {}
        for cluster_id in range(n_clusters):
            # Entrées dans ce cluster
            cluster_entries = [entry for entry in self.entries if entry["cluster"] == cluster_id]
            
            # Extraire les termes les plus représentatifs
            cluster_content = " ".join([entry["content"] for entry in cluster_entries])
            
            # Nettoyer le texte
            clean_content = re.sub(r'[^\w\s]', ' ', cluster_content.lower())
            clean_content = re.sub(r'\s+', ' ', clean_content).strip()
            
            # Compter les mots
            words = clean_content.split()
            word_counts = Counter(words)
            
            # Filtrer les mots vides
            stop_words = {'le', 'la', 'les', 'un', 'une', 'des', 'et', 'ou', 'de', 'du', 'au', 'aux', 'a', 'à', 'ce', 'ces', 'cette', 'en', 'par', 'pour', 'sur', 'dans', 'avec', 'sans', 'qui', 'que', 'quoi', 'dont', 'où', 'comment', 'pourquoi', 'quand', 'est', 'sont', 'sera', 'seront', 'été', 'être', 'avoir', 'eu', 'il', 'elle', 'ils', 'elles', 'nous', 'vous', 'je', 'tu', 'on', 'se', 'sa', 'son', 'ses', 'leur', 'leurs', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes', 'notre', 'nos', 'votre', 'vos'}
            filtered_counts = {word: count for word, count in word_counts.items() if word not in stop_words and len(word) > 2}
            
            # Prendre les 10 termes les plus fréquents
            top_terms = dict(sorted(filtered_counts.items(), key=lambda x: x[1], reverse=True)[:10])
            
            # Déterminer un nom pour le cluster basé sur les termes les plus fréquents
            cluster_name = ", ".join(list(top_terms.keys())[:3])
            
            cluster_analysis[cluster_id] = {
                "name": f"Cluster {cluster_id}: {cluster_name}",
                "entries": [{"title": entry["title"], "date": entry["date"], "file": entry["file"]} for entry in cluster_entries],
                "top_terms": top_terms,
                "entry_count": len(cluster_entries)
            }
        
        # Sauvegarder les résultats
        with open(self.analysis_dir / "clusters.json", 'w', encoding='utf-8') as f:
            json.dump(cluster_analysis, f, ensure_ascii=False, indent=2)
        
        return cluster_analysis

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Analyse du journal de bord")
    parser.add_argument("--term-frequency", action="store_true", help="Analyser la fréquence des termes")
    parser.add_argument("--word-cloud", action="store_true", help="Générer un nuage de mots")
    parser.add_argument("--tag-evolution", action="store_true", help="Analyser l'évolution des tags")
    parser.add_argument("--topic-trends", action="store_true", help="Analyser les tendances des sujets")
    parser.add_argument("--cluster", action="store_true", help="Regrouper les entrées par similarité")
    parser.add_argument("--all", action="store_true", help="Exécuter toutes les analyses")
    parser.add_argument("--period", choices=["day", "week", "month", "all"], default="month", 
                        help="Période pour l'analyse de fréquence des termes")
    parser.add_argument("--n-clusters", type=int, default=5, help="Nombre de clusters pour le regroupement")
    
    args = parser.parse_args()
    
    analyzer = JournalAnalyzer()
    
    if args.all or args.term_frequency:
        print("Analyse de la fréquence des termes...")
        analyzer.analyze_term_frequency(args.period)
    
    if args.all or args.word_cloud:
        print("Génération du nuage de mots...")
        analyzer.generate_word_cloud()
    
    if args.all or args.tag_evolution:
        print("Analyse de l'évolution des tags...")
        analyzer.analyze_tag_evolution()
    
    if args.all or args.topic_trends:
        print("Analyse des tendances des sujets...")
        analyzer.analyze_topic_trends()
    
    if args.all or args.cluster:
        print("Regroupement des entrées...")
        analyzer.cluster_entries(args.n_clusters)
    
    if not any([args.all, args.term_frequency, args.word_cloud, args.tag_evolution, args.topic_trends, args.cluster]):
        parser.print_help()
    else:
        print("Analyse terminée. Résultats sauvegardés dans", analyzer.analysis_dir)
