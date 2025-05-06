#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour les seuils d'erreur des mesures de forme.
"""

from shape_error_thresholds import (
    define_shape_error_thresholds,
    define_shape_error_thresholds_for_histogram
)

def main():
    """
    Fonction principale pour tester les seuils d'erreur des mesures de forme.
    """
    # Tester les seuils d'erreur pour l'asymétrie
    print("=== Test des seuils d'erreur pour l'asymétrie ===")
    
    # Tester pour différents types de distribution et tailles d'échantillon
    for dist_type in ["normal", "skewed"]:
        for sample_size in [50, 200, 1000]:
            print(f"\nType de distribution: {dist_type}, Taille d'échantillon: {sample_size}")
            thresholds = define_shape_error_thresholds("skewness", dist_type, sample_size)
            
            for quality, threshold in thresholds.items():
                print(f"  {quality}: < {threshold:.1%}")
    
    # Tester les seuils d'erreur pour l'aplatissement
    print("\n=== Test des seuils d'erreur pour l'aplatissement ===")
    
    # Tester pour différents types de distribution et tailles d'échantillon
    for dist_type in ["normal", "heavy_tailed"]:
        for sample_size in [50, 200, 1000]:
            print(f"\nType de distribution: {dist_type}, Taille d'échantillon: {sample_size}")
            thresholds = define_shape_error_thresholds("kurtosis", dist_type, sample_size)
            
            for quality, threshold in thresholds.items():
                print(f"  {quality}: < {threshold:.1%}")
    
    # Tester les seuils d'erreur pour l'asymétrie estimée à partir d'histogrammes
    print("\n=== Test des seuils d'erreur pour l'asymétrie (histogrammes) ===")
    
    # Tester pour différents types de distribution et nombres de bins
    for dist_type in ["normal", "skewed"]:
        for bin_count in [20, 75, 150]:
            print(f"\nType de distribution: {dist_type}, Nombre de bins: {bin_count}")
            thresholds = define_shape_error_thresholds_for_histogram("skewness", dist_type, bin_count)
            
            for quality, threshold in thresholds.items():
                print(f"  {quality}: < {threshold:.1%}")
    
    # Tester les seuils d'erreur pour l'aplatissement estimé à partir d'histogrammes
    print("\n=== Test des seuils d'erreur pour l'aplatissement (histogrammes) ===")
    
    # Tester pour différents types de distribution et nombres de bins
    for dist_type in ["normal", "heavy_tailed"]:
        for bin_count in [20, 75, 150]:
            print(f"\nType de distribution: {dist_type}, Nombre de bins: {bin_count}")
            thresholds = define_shape_error_thresholds_for_histogram("kurtosis", dist_type, bin_count)
            
            for quality, threshold in thresholds.items():
                print(f"  {quality}: < {threshold:.1%}")
    
    print("\nTest terminé avec succès!")

if __name__ == "__main__":
    main()
