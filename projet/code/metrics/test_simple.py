#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test très simple pour vérifier l'environnement d'exécution.
"""

print("Début du test simple...")

# Importer scikit-learn
try:
    from sklearn.datasets import make_blobs
    print("make_blobs importé avec succès.")
    
    # Générer des données simples
    result = make_blobs(n_samples=10, n_features=2, centers=2, random_state=42)
    print(f"Type de résultat: {type(result)}")
    print(f"Longueur du résultat: {len(result)}")
    
    # Extraire les données
    if len(result) == 3:
        X, y, centers = result
        print(f"Forme de X: {X.shape}")
        print(f"Forme de y: {y.shape}")
        print(f"Forme des centres: {centers.shape}")
    else:
        X, y = result
        print(f"Forme de X: {X.shape}")
        print(f"Forme de y: {y.shape}")
        
except Exception as e:
    print(f"Erreur lors de l'utilisation de make_blobs: {e}")

print("Test simple terminé.")
