#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour détecter les nombres écrits en toutes lettres
Version: 1.0
Date: 2025-05-15
"""

import re
import json
from typing import Dict, List, Optional, Union, Any


class TextualNumber:
    """Classe pour représenter un nombre écrit en toutes lettres"""

    def __init__(
        self,
        textual_number: str,
        numeric_value: int,
        start_index: int,
        length: int,
    ):
        self.textual_number = textual_number
        self.numeric_value = numeric_value
        self.start_index = start_index
        self.length = length

    def to_dict(self) -> Dict[str, Any]:
        """Convertir l'objet en dictionnaire"""
        return {
            "TextualNumber": self.textual_number,
            "NumericValue": self.numeric_value,
            "StartIndex": self.start_index,
            "Length": self.length,
        }

    def __str__(self) -> str:
        """Représentation sous forme de chaîne"""
        return json.dumps(self.to_dict(), indent=2)


# Dictionnaires des nombres en français et en anglais
french_numbers = {
    "zéro": 0, "zero": 0,
    "un": 1, "une": 1,
    "deux": 2,
    "trois": 3,
    "quatre": 4,
    "cinq": 5,
    "six": 6,
    "sept": 7,
    "huit": 8,
    "neuf": 9,
    "dix": 10,
    "onze": 11,
    "douze": 12,
    "treize": 13,
    "quatorze": 14,
    "quinze": 15,
    "seize": 16,
    "dix-sept": 17, "dix sept": 17,
    "dix-huit": 18, "dix huit": 18,
    "dix-neuf": 19, "dix neuf": 19,
    "vingt": 20,
    "vingt et un": 21, "vingt-et-un": 21,
    "trente": 30,
    "quarante": 40,
    "cinquante": 50,
    "soixante": 60,
    "soixante-dix": 70, "soixante dix": 70,
    "quatre-vingt": 80, "quatre vingt": 80, "quatre-vingts": 80, "quatre vingts": 80,
    "quatre-vingt-dix": 90, "quatre vingt dix": 90,
    "cent": 100,
    "mille": 1000,
    "million": 1000000,
    "milliard": 1000000000,
}

english_numbers = {
    "zero": 0,
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
    "eleven": 11,
    "twelve": 12,
    "thirteen": 13,
    "fourteen": 14,
    "fifteen": 15,
    "sixteen": 16,
    "seventeen": 17,
    "eighteen": 18,
    "nineteen": 19,
    "twenty": 20,
    "thirty": 30,
    "forty": 40,
    "fifty": 50,
    "sixty": 60,
    "seventy": 70,
    "eighty": 80,
    "ninety": 90,
    "hundred": 100,
    "thousand": 1000,
    "million": 1000000,
    "billion": 1000000000,
}


def get_textual_numbers(text: str, language: str = "Auto") -> List[TextualNumber]:
    """
    Détecter les nombres écrits en toutes lettres dans un texte
    
    Args:
        text: Le texte à analyser
        language: La langue du texte ("Auto", "French", "English")
        
    Returns:
        Une liste d'objets TextualNumber
    """
    # Déterminer la langue si Auto est spécifié
    if language == "Auto":
        french_words = 0
        english_words = 0
        
        # Normaliser le texte
        normalized_text = re.sub(r'[.,;:!?]', '', text.lower())
        normalized_text = re.sub(r'-', ' ', normalized_text)
        normalized_text = re.sub(r'\s+', ' ', normalized_text)
        
        words = normalized_text.split()
        
        for word in words:
            if word in french_numbers:
                french_words += 1
            if word in english_numbers:
                english_words += 1
        
        # Déterminer la langue en fonction du nombre de mots reconnus
        if french_words > english_words:
            language = "French"
        else:
            language = "English"
    
    # Normaliser le texte
    normalized_text = re.sub(r'[.,;:!?]', '', text.lower())
    normalized_text = re.sub(r'-', ' ', normalized_text)
    normalized_text = re.sub(r'\s+', ' ', normalized_text)
    
    # Résultats
    results = []
    
    # Dictionnaire à utiliser
    number_dict = french_numbers if language == "French" else english_numbers
    
    # Diviser le texte en mots
    words = normalized_text.split()
    
    # Parcourir tous les mots du texte
    for word in words:
        if word in number_dict:
            # Trouver la position du mot dans le texte original
            start_index = normalized_text.find(word)
            
            results.append(
                TextualNumber(
                    textual_number=word,
                    numeric_value=number_dict[word],
                    start_index=start_index,
                    length=len(word),
                )
            )
    
    # Trier les résultats par position dans le texte
    results.sort(key=lambda x: x.start_index)
    
    return results


def main():
    """Fonction principale"""
    # Textes à tester
    text1 = "La première tâche prendra vingt jours."
    text2 = "The first task will take twenty days."
    
    # Tester la fonction
    print(f"Texte 1: {text1}")
    results1 = get_textual_numbers(text1, "French")
    if results1:
        print(f"Résultats trouvés: {len(results1)}")
        for result in results1:
            print(result)
    else:
        print("Aucun résultat trouvé")
    
    print(f"\nTexte 2: {text2}")
    results2 = get_textual_numbers(text2, "English")
    if results2:
        print(f"Résultats trouvés: {len(results2)}")
        for result in results2:
            print(result)
    else:
        print("Aucun résultat trouvé")


if __name__ == "__main__":
    main()
