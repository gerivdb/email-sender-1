#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour les critères de précision de l'aplatissement.
"""

from kurtosis_precision_criteria import (
    define_kurtosis_precision_criteria,
    define_kurtosis_error_thresholds_by_magnitude,
    define_kurtosis_error_thresholds_by_distribution_type,
    define_kurtosis_error_thresholds_by_sample_size
)

def main():
    """
    Fonction principale pour tester les critères de précision de l'aplatissement.
    """
    # Tester les critères de précision généraux
    print("=== Test des critères de précision généraux pour l'aplatissement ===")
    criteria = define_kurtosis_precision_criteria()
    
    print(f"Nom: {criteria['name']}")
    print(f"Description: {criteria['description']}")
    print(f"Seuil d'erreur relative: {criteria['relative_error_threshold']:.1%}")
    print(f"Niveau de confiance: {criteria['confidence_level']:.1%}")
    
    print("\nSeuils d'erreur absolue:")
    for quality, threshold in criteria['absolute_error_thresholds'].items():
        print(f"  {quality}: < {threshold:.1%}")
    
    print("\nCouverture de l'intervalle de confiance:")
    for quality, coverage in criteria['confidence_interval_coverage'].items():
        print(f"  {quality}: >= {coverage:.1%}")
    
    print("\nTailles d'échantillon minimales:")
    for quality, size in criteria['minimum_sample_sizes'].items():
        print(f"  {quality}: >= {size}")
    
    # Tester les seuils d'erreur en fonction de l'amplitude de l'aplatissement
    print("\n=== Test des seuils d'erreur en fonction de l'amplitude de l'aplatissement ===")
    for magnitude in ["low", "medium", "high"]:
        print(f"\nAmplitude de l'aplatissement: {magnitude}")
        thresholds = define_kurtosis_error_thresholds_by_magnitude(magnitude)
        
        for quality, threshold in thresholds.items():
            print(f"  {quality}: < {threshold:.1%}")
    
    # Tester les seuils d'erreur en fonction du type de distribution
    print("\n=== Test des seuils d'erreur en fonction du type de distribution ===")
    for dist_type in ["normal", "skewed", "multimodal", "heavy_tailed"]:
        print(f"\nType de distribution: {dist_type}")
        thresholds = define_kurtosis_error_thresholds_by_distribution_type(dist_type)
        
        for quality, threshold in thresholds.items():
            print(f"  {quality}: < {threshold:.1%}")
    
    # Tester les seuils d'erreur en fonction de la taille de l'échantillon
    print("\n=== Test des seuils d'erreur en fonction de la taille de l'échantillon ===")
    for sample_size in [50, 150, 300, 600, 1500]:
        print(f"\nTaille de l'échantillon: {sample_size}")
        thresholds = define_kurtosis_error_thresholds_by_sample_size(sample_size)
        
        for quality, threshold in thresholds.items():
            print(f"  {quality}: < {threshold:.1%}")
    
    print("\nTest terminé avec succès!")

if __name__ == "__main__":
    main()
