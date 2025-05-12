#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour tester les performances
Version: 1.0
Date: 2025-05-15
"""

import time
import random
from typing import List, Dict, Any, Callable
from approximate_expressions import get_approximate_expressions
from textual_numbers import get_textual_numbers
from time_units import get_time_units
from tag_normalizer import TagNormalizer


def generate_test_data(count: int = 100) -> List[str]:
    """
    Générer des données de test
    
    Args:
        count: Nombre de tags à générer
        
    Returns:
        Une liste de tags
    """
    # Modèles de tags
    templates = [
        "Projet de {number} {unit}",
        "Project of {number} {unit}",
        "Tâche de {number} {unit} {approximation}",
        "Task of {number} {unit} {approximation}",
        "Réunion de {number} {unit} et {number2} {unit2}",
        "Meeting of {number} {unit} and {number2} {unit2}",
        "{approximation} {number} {unit} de travail",
        "{approximation} {number} {unit} of work",
    ]
    
    # Nombres
    numbers_fr = ["un", "deux", "trois", "quatre", "cinq", "dix", "vingt", "trente", "quarante", "cinquante"]
    numbers_en = ["one", "two", "three", "four", "five", "ten", "twenty", "thirty", "forty", "fifty"]
    
    # Unités de temps
    units_fr = ["jour", "jours", "heure", "heures", "minute", "minutes", "semaine", "semaines", "mois", "année", "années"]
    units_en = ["day", "days", "hour", "hours", "minute", "minutes", "week", "weeks", "month", "months", "year", "years"]
    
    # Approximations
    approximations_fr = ["environ", "approximativement", "presque", "à peu près"]
    approximations_en = ["about", "approximately", "nearly", "almost"]
    
    # Générer les tags
    tags = []
    
    for _ in range(count):
        template = random.choice(templates)
        
        if "Project" in template or "Task" in template or "Meeting" in template:
            # Tag en anglais
            number = random.choice(numbers_en)
            unit = random.choice(units_en)
            number2 = random.choice(numbers_en)
            unit2 = random.choice(units_en)
            approximation = random.choice(approximations_en)
        else:
            # Tag en français
            number = random.choice(numbers_fr)
            unit = random.choice(units_fr)
            number2 = random.choice(numbers_fr)
            unit2 = random.choice(units_fr)
            approximation = random.choice(approximations_fr)
        
        # Remplacer les variables dans le template
        tag = template.format(
            number=number,
            unit=unit,
            number2=number2,
            unit2=unit2,
            approximation=approximation,
        )
        
        tags.append(tag)
    
    return tags


def measure_performance(func: Callable, args: List[Any], iterations: int = 10) -> Dict[str, float]:
    """
    Mesurer les performances d'une fonction
    
    Args:
        func: Fonction à mesurer
        args: Arguments de la fonction
        iterations: Nombre d'itérations
        
    Returns:
        Un dictionnaire contenant les mesures de performance
    """
    # Mesures
    total_time = 0
    min_time = float("inf")
    max_time = 0
    
    # Exécuter la fonction plusieurs fois
    for _ in range(iterations):
        start_time = time.time()
        func(*args)
        end_time = time.time()
        
        execution_time = end_time - start_time
        total_time += execution_time
        
        if execution_time < min_time:
            min_time = execution_time
        
        if execution_time > max_time:
            max_time = execution_time
    
    # Calculer les statistiques
    avg_time = total_time / iterations
    
    return {
        "total_time": total_time,
        "avg_time": avg_time,
        "min_time": min_time,
        "max_time": max_time,
        "iterations": iterations,
    }


def main():
    """Fonction principale"""
    # Générer des données de test
    tags = generate_test_data(100)
    
    # Mesurer les performances de la normalisation des tags
    normalizer = TagNormalizer()
    
    # Mesurer les performances de la normalisation des tags
    print("=== Performances de la normalisation des tags ===")
    
    performance = measure_performance(
        func=lambda tags: [normalizer.normalize_tag(tag) for tag in tags],
        args=[tags],
        iterations=10,
    )
    
    print(f"Temps total: {performance['total_time']:.4f} secondes")
    print(f"Temps moyen: {performance['avg_time']:.4f} secondes")
    print(f"Temps minimum: {performance['min_time']:.4f} secondes")
    print(f"Temps maximum: {performance['max_time']:.4f} secondes")
    print(f"Nombre d'itérations: {performance['iterations']}")
    print(f"Nombre de tags: {len(tags)}")
    print(f"Temps moyen par tag: {performance['avg_time'] / len(tags):.6f} secondes")


if __name__ == "__main__":
    main()
