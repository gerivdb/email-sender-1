#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Module de segmentation de texte pour EMAIL_SENDER_1.

Ce module fournit des fonctionnalités avancées pour analyser, segmenter
et traiter des données textuelles, avec un support particulier pour
les fichiers volumineux et les analyses intelligentes.

Auteur: EMAIL_SENDER_1 Team
Version: 1.0.0
Date: 2025-06-06
"""

import os
import sys
import logging
import re
from typing import Dict, List, Any, Union, Optional, Tuple, Iterator, Set
from pathlib import Path
import json
import math
from collections import Counter

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("TextSegmenter")

class TextSegmenter:
    """
    Classe principale pour la segmentation et l'analyse de données textuelles.
    
    Cette classe fournit des méthodes pour charger, analyser et segmenter
    des données textuelles, avec un support particulier pour les fichiers
    volumineux et les analyses intelligentes.
    """
    
    def __init__(self, max_chunk_size_kb: int = 10, preserve_paragraphs: bool = True, 
                 preserve_sentences: bool = True, smart_segmentation: bool = True):
        """
        Initialise un nouveau segmenteur de texte.
        
        Args:
            max_chunk_size_kb: Taille maximale des segments en KB
            preserve_paragraphs: Si True, préserve les paragraphes dans les segments
            preserve_sentences: Si True, préserve les phrases dans les segments
            smart_segmentation: Si True, utilise la segmentation intelligente
        """
        self.max_chunk_size_kb = max_chunk_size_kb
        self.preserve_paragraphs = preserve_paragraphs
        self.preserve_sentences = preserve_sentences
        self.smart_segmentation = smart_segmentation
        self.current_file = None
        self.current_text = None
        self.metadata = {}
        
        # Expressions régulières pour l'analyse de texte
        self.paragraph_pattern = re.compile(r'\n\s*\n')
        self.sentence_pattern = re.compile(r'(?<=[.!?])\s+(?=[A-Z])')
        self.word_pattern = re.compile(r'\b\w+\b')
    
    def load_file(self, file_path: Union[str, Path]) -> str:
        """
        Charge un fichier texte.
        
        Args:
            file_path: Chemin du fichier à charger
            
        Returns:
            Texte chargé
            
        Raises:
            FileNotFoundError: Si le fichier n'existe pas
        """
        file_path = Path(file_path)
        if not file_path.exists():
            raise FileNotFoundError(f"Le fichier {file_path} n'existe pas")
        
        logger.info(f"Chargement du fichier texte: {file_path}")
        
        # Vérifier la taille du fichier
        file_size_kb = file_path.stat().st_size / 1024
        logger.info(f"Taille du fichier: {file_size_kb:.2f} KB")
        
        # Charger le fichier
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                text = f.read()
            
            self.current_file = file_path
            self.current_text = text
            
            # Analyser le texte pour les métadonnées
            self._analyze_for_metadata(text)
            
            # Ajouter des métadonnées de fichier
            self.metadata.update({
                "file_path": str(file_path),
                "file_size_kb": file_size_kb
            })
            
            return text
        except Exception as e:
            logger.error(f"Erreur lors du chargement du fichier texte: {e}")
            raise
    
    def load_string(self, text: str) -> str:
        """
        Charge une chaîne de texte.
        
        Args:
            text: Texte à charger
            
        Returns:
            Texte chargé
        """
        logger.info("Chargement d'une chaîne de texte")
        
        # Vérifier la taille de la chaîne
        string_size_kb = len(text.encode('utf-8')) / 1024
        logger.info(f"Taille de la chaîne: {string_size_kb:.2f} KB")
        
        self.current_file = None
        self.current_text = text
        
        # Analyser le texte pour les métadonnées
        self._analyze_for_metadata(text)
        
        # Ajouter des métadonnées de chaîne
        self.metadata.update({
            "string_size_kb": string_size_kb
        })
        
        return text
    
    def segment(self, text: Optional[str] = None, method: str = "auto") -> List[str]:
        """
        Segmente le texte en morceaux plus petits.
        
        Args:
            text: Texte à segmenter (utilise le texte actuel si None)
            method: Méthode de segmentation ("auto", "paragraph", "sentence", "word", "char")
            
        Returns:
            Liste des segments de texte
            
        Raises:
            ValueError: Si aucun texte n'est chargé
        """
        if text is None:
            if self.current_text is None:
                raise ValueError("Aucun texte à segmenter")
            text = self.current_text
        
        logger.info(f"Segmentation du texte avec la méthode '{method}'")
        
        # Déterminer la méthode de segmentation
        if method == "auto":
            if self.smart_segmentation:
                return self._smart_segment(text)
            elif self.preserve_paragraphs:
                return self._segment_by_paragraphs(text)
            elif self.preserve_sentences:
                return self._segment_by_sentences(text)
            else:
                return self._segment_by_size(text)
        elif method == "paragraph":
            return self._segment_by_paragraphs(text)
        elif method == "sentence":
            return self._segment_by_sentences(text)
        elif method == "word":
            return self._segment_by_words(text)
        elif method == "char":
            return self._segment_by_size(text)
        else:
            raise ValueError(f"Méthode de segmentation inconnue: {method}")
    
    def segment_to_files(self, output_dir: Union[str, Path], prefix: str = "segment_", 
                         method: str = "auto") -> List[str]:
        """
        Segmente le texte actuel et enregistre les segments dans des fichiers.
        
        Args:
            output_dir: Répertoire de sortie
            prefix: Préfixe pour les noms de fichiers
            method: Méthode de segmentation
            
        Returns:
            Liste des chemins des fichiers créés
            
        Raises:
            ValueError: Si aucun texte n'est chargé
        """
        if self.current_text is None:
            raise ValueError("Aucun texte à segmenter")
        
        # Créer le répertoire de sortie si nécessaire
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Segmenter le texte
        segments = self.segment(method=method)
        
        # Enregistrer les segments dans des fichiers
        file_paths = []
        for i, segment in enumerate(segments):
            file_path = output_dir / f"{prefix}{i+1}.txt"
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(segment)
            file_paths.append(str(file_path))
        
        logger.info(f"Segments enregistrés dans {len(file_paths)} fichiers")
        
        return file_paths
    
    def analyze(self, text: Optional[str] = None) -> Dict[str, Any]:
        """
        Analyse le texte et retourne des informations détaillées.
        
        Args:
            text: Texte à analyser (utilise le texte actuel si None)
            
        Returns:
            Dictionnaire contenant les informations d'analyse
            
        Raises:
            ValueError: Si aucun texte n'est chargé
        """
        if text is None:
            if self.current_text is None:
                raise ValueError("Aucun texte à analyser")
            text = self.current_text
        
        # Analyser le texte
        analysis = {
            "basic_stats": self._get_basic_stats(text),
            "readability": self._analyze_readability(text),
            "language_features": self._analyze_language_features(text),
            "metadata": self.metadata.copy()
        }
        
        return analysis
    
    def _analyze_for_metadata(self, text: str) -> None:
        """
        Analyse le texte pour collecter des métadonnées.
        
        Args:
            text: Texte à analyser
        """
        # Compter les paragraphes, phrases et mots
        paragraphs = self.paragraph_pattern.split(text)
        paragraph_count = len(paragraphs)
        
        sentences = []
        for para in paragraphs:
            sentences.extend(self.sentence_pattern.split(para))
        sentence_count = len(sentences)
        
        words = self.word_pattern.findall(text)
        word_count = len(words)
        
        # Calculer la longueur moyenne des phrases et des mots
        avg_sentence_length = word_count / max(1, sentence_count)
        avg_word_length = sum(len(word) for word in words) / max(1, word_count)
        
        # Mettre à jour les métadonnées
        self.metadata.update({
            "paragraph_count": paragraph_count,
            "sentence_count": sentence_count,
            "word_count": word_count,
            "avg_sentence_length": avg_sentence_length,
            "avg_word_length": avg_word_length
        })
    
    def _get_basic_stats(self, text: str) -> Dict[str, Any]:
        """
        Obtient des statistiques de base sur le texte.
        
        Args:
            text: Texte à analyser
            
        Returns:
            Dictionnaire des statistiques de base
        """
        # Compter les caractères
        char_count = len(text)
        char_count_no_spaces = len(text.replace(" ", ""))
        
        # Compter les lignes
        line_count = text.count('\n') + 1
        
        # Compter les mots uniques
        words = self.word_pattern.findall(text.lower())
        unique_words = set(words)
        unique_word_count = len(unique_words)
        
        # Calculer la diversité lexicale
        lexical_diversity = unique_word_count / max(1, len(words))
        
        return {
            "char_count": char_count,
            "char_count_no_spaces": char_count_no_spaces,
            "line_count": line_count,
            "word_count": self.metadata.get("word_count", len(words)),
            "unique_word_count": unique_word_count,
            "lexical_diversity": lexical_diversity
        }
    
    def _analyze_readability(self, text: str) -> Dict[str, float]:
        """
        Analyse la lisibilité du texte.
        
        Args:
            text: Texte à analyser
            
        Returns:
            Dictionnaire des scores de lisibilité
        """
        # Récupérer les statistiques de base
        word_count = self.metadata.get("word_count", len(self.word_pattern.findall(text)))
        sentence_count = self.metadata.get("sentence_count", len(self.sentence_pattern.split(text)))
        
        # Compter les syllabes (approximation simple)
        def count_syllables(word):
            word = word.lower()
            if len(word) <= 3:
                return 1
            count = 0
            vowels = "aeiouy"
            if word[0] in vowels:
                count += 1
            for i in range(1, len(word)):
                if word[i] in vowels and word[i-1] not in vowels:
                    count += 1
            if word.endswith("e"):
                count -= 1
            if count == 0:
                count = 1
            return count
        
        words = self.word_pattern.findall(text.lower())
        syllable_count = sum(count_syllables(word) for word in words)
        
        # Calculer les scores de lisibilité
        
        # Flesch Reading Ease
        if sentence_count > 0 and word_count > 0:
            flesch = 206.835 - 1.015 * (word_count / sentence_count) - 84.6 * (syllable_count / word_count)
        else:
            flesch = 0
        
        # Flesch-Kincaid Grade Level
        if sentence_count > 0 and word_count > 0:
            fk_grade = 0.39 * (word_count / sentence_count) + 11.8 * (syllable_count / word_count) - 15.59
        else:
            fk_grade = 0
        
        # Gunning Fog Index
        complex_words = sum(1 for word in words if count_syllables(word) >= 3)
        if sentence_count > 0 and word_count > 0:
            fog = 0.4 * ((word_count / sentence_count) + 100 * (complex_words / word_count))
        else:
            fog = 0
        
        return {
            "flesch_reading_ease": flesch,
            "flesch_kincaid_grade": fk_grade,
            "gunning_fog": fog,
            "syllable_count": syllable_count,
            "complex_word_count": complex_words
        }
    
    def _analyze_language_features(self, text: str) -> Dict[str, Any]:
        """
        Analyse les caractéristiques linguistiques du texte.
        
        Args:
            text: Texte à analyser
            
        Returns:
            Dictionnaire des caractéristiques linguistiques
        """
        # Compter les mots les plus fréquents
        words = self.word_pattern.findall(text.lower())
        word_freq = Counter(words)
        top_words = word_freq.most_common(20)
        
        # Détecter les n-grammes fréquents (bigrammes)
        bigrams = []
        for i in range(len(words) - 1):
            bigrams.append((words[i], words[i+1]))
        bigram_freq = Counter(bigrams)
        top_bigrams = bigram_freq.most_common(10)
        
        # Détecter les motifs de ponctuation
        punctuation_pattern = re.compile(r'[,.;:!?()[\]{}"\'-]')
        punctuation = punctuation_pattern.findall(text)
        punct_freq = Counter(punctuation)
        
        # Détecter la langue (approximation simple)
        language = self._detect_language(text)
        
        return {
            "top_words": top_words,
            "top_bigrams": [f"{b[0]} {b[1]}" for b, _ in top_bigrams],
            "punctuation_frequency": dict(punct_freq),
            "detected_language": language
        }
    
    def _detect_language(self, text: str) -> str:
        """
        Détecte la langue du texte (approximation simple).
        
        Args:
            text: Texte à analyser
            
        Returns:
            Code de langue détecté
        """
        # Cette implémentation est très basique
        # Dans une version plus complète, on utiliserait langdetect ou une autre bibliothèque
        
        # Mots fréquents par langue
        lang_words = {
            "fr": set(["le", "la", "les", "un", "une", "des", "et", "ou", "en", "dans", "pour", "par", "sur", "avec"]),
            "en": set(["the", "a", "an", "of", "to", "in", "and", "or", "for", "with", "on", "at", "by", "from"]),
            "es": set(["el", "la", "los", "las", "un", "una", "unos", "unas", "y", "o", "en", "de", "por", "para"]),
            "de": set(["der", "die", "das", "ein", "eine", "und", "oder", "in", "für", "mit", "auf", "bei", "von"])
        }
        
        # Compter les mots par langue
        words = set(self.word_pattern.findall(text.lower()))
        lang_scores = {}
        
        for lang, lang_word_set in lang_words.items():
            intersection = words.intersection(lang_word_set)
            lang_scores[lang] = len(intersection) / len(lang_word_set)
        
        # Retourner la langue avec le score le plus élevé
        if not lang_scores:
            return "unknown"
        
        return max(lang_scores.items(), key=lambda x: x[1])[0]
    
    def _segment_by_paragraphs(self, text: str) -> List[str]:
        """
        Segmente le texte par paragraphes.
        
        Args:
            text: Texte à segmenter
            
        Returns:
            Liste des segments
        """
        paragraphs = self.paragraph_pattern.split(text)
        
        segments = []
        current_segment = ""
        current_size = 0
        
        for paragraph in paragraphs:
            # Ajouter un saut de ligne si ce n'est pas le premier paragraphe du segment
            if current_segment and not current_segment.endswith("\n\n"):
                paragraph = "\n\n" + paragraph
            
            # Estimer la taille du paragraphe
            paragraph_size_kb = len(paragraph.encode('utf-8')) / 1024
            
            # Si le paragraphe est trop grand, le segmenter par phrases
            if paragraph_size_kb > self.max_chunk_size_kb:
                paragraph_segments = self._segment_by_sentences(paragraph)
                segments.extend(paragraph_segments)
                continue
            
            # Si l'ajout de ce paragraphe dépasse la taille maximale, créer un nouveau segment
            if current_size + paragraph_size_kb > self.max_chunk_size_kb and current_segment:
                segments.append(current_segment)
                current_segment = paragraph
                current_size = paragraph_size_kb
            else:
                # Ajouter le paragraphe au segment courant
                current_segment += paragraph
                current_size += paragraph_size_kb
        
        # Ajouter le dernier segment s'il n'est pas vide
        if current_segment:
            segments.append(current_segment)
        
        return segments
    
    def _segment_by_sentences(self, text: str) -> List[str]:
        """
        Segmente le texte par phrases.
        
        Args:
            text: Texte à segmenter
            
        Returns:
            Liste des segments
        """
        # Diviser le texte en phrases
        sentences = []
        for paragraph in self.paragraph_pattern.split(text):
            paragraph_sentences = self.sentence_pattern.split(paragraph)
            for i, sentence in enumerate(paragraph_sentences):
                if i > 0:
                    # Ajouter l'espace et la ponctuation qui ont été supprimés par le split
                    sentence = " " + sentence
                sentences.append(sentence)
        
        segments = []
        current_segment = ""
        current_size = 0
        
        for sentence in sentences:
            # Estimer la taille de la phrase
            sentence_size_kb = len(sentence.encode('utf-8')) / 1024
            
            # Si la phrase est trop grande, la segmenter par mots
            if sentence_size_kb > self.max_chunk_size_kb:
                sentence_segments = self._segment_by_words(sentence)
                segments.extend(sentence_segments)
                continue
            
            # Si l'ajout de cette phrase dépasse la taille maximale, créer un nouveau segment
            if current_size + sentence_size_kb > self.max_chunk_size_kb and current_segment:
                segments.append(current_segment)
                current_segment = sentence
                current_size = sentence_size_kb
            else:
                # Ajouter la phrase au segment courant
                current_segment += sentence
                current_size += sentence_size_kb
        
        # Ajouter le dernier segment s'il n'est pas vide
        if current_segment:
            segments.append(current_segment)
        
        return segments
    
    def _segment_by_words(self, text: str) -> List[str]:
        """
        Segmente le texte par mots.
        
        Args:
            text: Texte à segmenter
            
        Returns:
            Liste des segments
        """
        # Diviser le texte en mots tout en préservant les espaces et la ponctuation
        pattern = re.compile(r'(\b\w+\b|\s+|[^\w\s])')
        tokens = pattern.findall(text)
        
        segments = []
        current_segment = ""
        current_size = 0
        
        for token in tokens:
            # Estimer la taille du token
            token_size_kb = len(token.encode('utf-8')) / 1024
            
            # Si le token est trop grand (rare), le segmenter par caractères
            if token_size_kb > self.max_chunk_size_kb:
                token_segments = self._segment_by_size(token)
                segments.extend(token_segments)
                continue
            
            # Si l'ajout de ce token dépasse la taille maximale, créer un nouveau segment
            if current_size + token_size_kb > self.max_chunk_size_kb and current_segment:
                segments.append(current_segment)
                current_segment = token
                current_size = token_size_kb
            else:
                # Ajouter le token au segment courant
                current_segment += token
                current_size += token_size_kb
        
        # Ajouter le dernier segment s'il n'est pas vide
        if current_segment:
            segments.append(current_segment)
        
        return segments
    
    def _segment_by_size(self, text: str) -> List[str]:
        """
        Segmente le texte par taille fixe.
        
        Args:
            text: Texte à segmenter
            
        Returns:
            Liste des segments
        """
        # Calculer la taille maximale en caractères
        max_chars = int(self.max_chunk_size_kb * 1024 / 2)  # Approximation pour UTF-8
        
        # Segmenter le texte
        segments = []
        for i in range(0, len(text), max_chars):
            segment = text[i:i + max_chars]
            segments.append(segment)
        
        return segments
    
    def _smart_segment(self, text: str) -> List[str]:
        """
        Segmente le texte de manière intelligente.
        
        Args:
            text: Texte à segmenter
            
        Returns:
            Liste des segments
        """
        # Analyser le texte pour déterminer la meilleure méthode de segmentation
        paragraph_count = self.metadata.get("paragraph_count", len(self.paragraph_pattern.split(text)))
        sentence_count = self.metadata.get("sentence_count", len(self.sentence_pattern.split(text)))
        word_count = self.metadata.get("word_count", len(self.word_pattern.findall(text)))
        
        # Estimer la taille moyenne des paragraphes, phrases et mots
        text_size_kb = len(text.encode('utf-8')) / 1024
        avg_paragraph_size_kb = text_size_kb / max(1, paragraph_count)
        avg_sentence_size_kb = text_size_kb / max(1, sentence_count)
        avg_word_size_kb = text_size_kb / max(1, word_count)
        
        logger.info(f"Taille moyenne des paragraphes: {avg_paragraph_size_kb:.2f} KB")
        logger.info(f"Taille moyenne des phrases: {avg_sentence_size_kb:.2f} KB")
        
        # Choisir la méthode de segmentation en fonction des tailles moyennes
        if avg_paragraph_size_kb <= self.max_chunk_size_kb * 0.8:
            logger.info("Utilisation de la segmentation par paragraphes")
            return self._segment_by_paragraphs(text)
        elif avg_sentence_size_kb <= self.max_chunk_size_kb * 0.8:
            logger.info("Utilisation de la segmentation par phrases")
            return self._segment_by_sentences(text)
        elif avg_word_size_kb <= self.max_chunk_size_kb * 0.1:
            logger.info("Utilisation de la segmentation par mots")
            return self._segment_by_words(text)
        else:
            logger.info("Utilisation de la segmentation par taille fixe")
            return self._segment_by_size(text)


# Fonctions utilitaires pour l'utilisation en ligne de commande

def segment_file(file_path: str, output_dir: str, max_chunk_size_kb: int = 10, 
                preserve_paragraphs: bool = True, preserve_sentences: bool = True,
                smart_segmentation: bool = True, method: str = "auto") -> List[str]:
    """
    Segmente un fichier texte et enregistre les segments dans des fichiers.
    
    Args:
        file_path: Chemin du fichier texte
        output_dir: Répertoire de sortie
        max_chunk_size_kb: Taille maximale des segments en KB
        preserve_paragraphs: Si True, préserve les paragraphes dans les segments
        preserve_sentences: Si True, préserve les phrases dans les segments
        smart_segmentation: Si True, utilise la segmentation intelligente
        method: Méthode de segmentation
        
    Returns:
        Liste des chemins des fichiers créés
    """
    segmenter = TextSegmenter(
        max_chunk_size_kb=max_chunk_size_kb,
        preserve_paragraphs=preserve_paragraphs,
        preserve_sentences=preserve_sentences,
        smart_segmentation=smart_segmentation
    )
    segmenter.load_file(file_path)
    return segmenter.segment_to_files(output_dir, method=method)

def analyze_file(file_path: str, output_file: Optional[str] = None) -> Dict[str, Any]:
    """
    Analyse un fichier texte et retourne des informations détaillées.
    
    Args:
        file_path: Chemin du fichier texte
        output_file: Fichier de sortie pour l'analyse (optionnel)
        
    Returns:
        Dictionnaire contenant les informations d'analyse
    """
    segmenter = TextSegmenter()
    segmenter.load_file(file_path)
    analysis = segmenter.analyze()
    
    if output_file:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(analysis, f, ensure_ascii=False, indent=2)
    
    return analysis


# Point d'entrée pour l'utilisation en ligne de commande
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Outil de segmentation et d'analyse de texte")
    subparsers = parser.add_subparsers(dest="command", help="Commande à exécuter")
    
    # Commande 'segment'
    segment_parser = subparsers.add_parser("segment", help="Segmenter un fichier texte")
    segment_parser.add_argument("file", help="Chemin du fichier texte")
    segment_parser.add_argument("--output-dir", "-o", default="./output", help="Répertoire de sortie")
    segment_parser.add_argument("--max-chunk-size", "-m", type=int, default=10, help="Taille maximale des segments en KB")
    segment_parser.add_argument("--no-preserve-paragraphs", action="store_true", help="Ne pas préserver les paragraphes")
    segment_parser.add_argument("--no-preserve-sentences", action="store_true", help="Ne pas préserver les phrases")
    segment_parser.add_argument("--no-smart-segmentation", action="store_true", help="Désactiver la segmentation intelligente")
    segment_parser.add_argument("--method", choices=["auto", "paragraph", "sentence", "word", "char"], default="auto", help="Méthode de segmentation")
    
    # Commande 'analyze'
    analyze_parser = subparsers.add_parser("analyze", help="Analyser un fichier texte")
    analyze_parser.add_argument("file", help="Chemin du fichier texte")
    analyze_parser.add_argument("--output", "-o", help="Fichier de sortie pour l'analyse")
    
    args = parser.parse_args()
    
    if args.command == "segment":
        output_files = segment_file(
            args.file,
            args.output_dir,
            args.max_chunk_size,
            not args.no_preserve_paragraphs,
            not args.no_preserve_sentences,
            not args.no_smart_segmentation,
            args.method
        )
        print(f"Segments créés: {len(output_files)}")
        for file in output_files:
            print(f"- {file}")
    
    elif args.command == "analyze":
        analysis = analyze_file(args.file, args.output)
        if not args.output:
            print(json.dumps(analysis, ensure_ascii=False, indent=2))
        else:
            print(f"Analyse enregistrée dans {args.output}")
    
    else:
        parser.print_help()
