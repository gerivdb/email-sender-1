#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test minimal pour vérifier l'environnement d'exécution.
"""

print("Début du test minimal...")

# Importer numpy
try:
    import numpy as np
    print("numpy importé avec succès.")
    
    # Créer un tableau simple
    arr = np.array([1, 2, 3, 4, 5])
    print(f"Tableau créé: {arr}")
    print(f"Forme du tableau: {arr.shape}")
    print(f"Moyenne du tableau: {np.mean(arr)}")
    
except Exception as e:
    print(f"Erreur lors de l'utilisation de numpy: {e}")

print("Test minimal terminé.")
