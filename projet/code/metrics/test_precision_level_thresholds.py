#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Tests unitaires pour les seuils généraux par niveau de précision.
"""

import unittest
import os
import json
import tempfile
from precision_level_thresholds import PrecisionLevelThresholds, generate_default_config


class TestPrecisionLevelThresholds(unittest.TestCase):
    """Tests pour la classe PrecisionLevelThresholds."""
    
    def setUp(self):
        """Initialisation des données de test."""
        self.precision_levels = PrecisionLevelThresholds()
    
    def test_default_precision_levels(self):
        """Test des niveaux de précision par défaut."""
        # Vérifier que les niveaux par défaut sont chargés correctement
        all_levels = self.precision_levels.get_all_precision_levels()
        
        self.assertIn("high", all_levels)
        self.assertIn("medium", all_levels)
        self.assertIn("low", all_levels)
        self.assertIn("minimal", all_levels)
        
        # Vérifier que chaque niveau contient les champs requis
        for level_name, level_config in all_levels.items():
            self.assertIn("description", level_config)
            self.assertIn("total_error", level_config)
            self.assertIn("mean_error", level_config)
            self.assertIn("variance_error", level_config)
            self.assertIn("skewness_error", level_config)
            self.assertIn("kurtosis_error", level_config)
            self.assertIn("confidence_interval", level_config)
    
    def test_get_precision_level(self):
        """Test de la récupération d'un niveau de précision."""
        # Récupérer un niveau existant
        high_level = self.precision_levels.get_precision_level("high")
        
        self.assertIsNotNone(high_level)
        self.assertIn("description", high_level)
        self.assertIn("total_error", high_level)
        
        # Récupérer un niveau inexistant (devrait retourner le niveau medium)
        unknown_level = self.precision_levels.get_precision_level("unknown")
        
        self.assertIsNotNone(unknown_level)
        self.assertEqual(unknown_level, self.precision_levels.get_precision_level("medium"))
    
    def test_add_custom_precision_level(self):
        """Test de l'ajout d'un niveau de précision personnalisé."""
        # Définir un niveau personnalisé
        custom_level = {
            "description": "Niveau personnalisé pour les tests",
            "total_error": 7.5,
            "mean_error": 5.0,
            "variance_error": 7.5,
            "skewness_error": 10.0,
            "kurtosis_error": 15.0,
            "confidence_interval": 0.97
        }
        
        # Ajouter le niveau personnalisé
        success = self.precision_levels.add_custom_precision_level("custom", custom_level)
        
        # Vérifier que l'ajout a réussi
        self.assertTrue(success)
        
        # Récupérer le niveau personnalisé
        retrieved_level = self.precision_levels.get_precision_level("custom")
        
        # Vérifier que le niveau récupéré correspond au niveau ajouté
        self.assertEqual(retrieved_level, custom_level)
    
    def test_add_invalid_custom_precision_level(self):
        """Test de l'ajout d'un niveau de précision personnalisé invalide."""
        # Définir un niveau personnalisé invalide (champ manquant)
        invalid_level = {
            "description": "Niveau personnalisé invalide",
            "total_error": 7.5,
            "mean_error": 5.0
            # Champs manquants
        }
        
        # Tenter d'ajouter le niveau personnalisé
        success = self.precision_levels.add_custom_precision_level("invalid", invalid_level)
        
        # Vérifier que l'ajout a échoué
        self.assertFalse(success)
    
    def test_save_custom_levels(self):
        """Test de la sauvegarde des niveaux de précision personnalisés."""
        # Créer un fichier temporaire pour les niveaux personnalisés
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file_path = temp_file.name
        
        try:
            # Définir un niveau personnalisé
            custom_level = {
                "description": "Niveau personnalisé pour les tests",
                "total_error": 7.5,
                "mean_error": 5.0,
                "variance_error": 7.5,
                "skewness_error": 10.0,
                "kurtosis_error": 15.0,
                "confidence_interval": 0.97
            }
            
            # Ajouter le niveau personnalisé
            self.precision_levels.add_custom_precision_level("custom", custom_level)
            
            # Sauvegarder les niveaux personnalisés
            success = self.precision_levels.save_custom_levels(temp_file_path)
            
            # Vérifier que la sauvegarde a réussi
            self.assertTrue(success)
            
            # Vérifier que le fichier existe et contient les niveaux personnalisés
            with open(temp_file_path, 'r') as f:
                loaded_levels = json.load(f)
            
            self.assertIn("custom", loaded_levels)
            self.assertEqual(loaded_levels["custom"], custom_level)
        finally:
            # Supprimer le fichier temporaire
            os.unlink(temp_file_path)
    
    def test_get_thresholds_for_context(self):
        """Test de la récupération des seuils pour un contexte donné."""
        # Récupérer les seuils pour différents contextes
        monitoring_thresholds = self.precision_levels.get_thresholds_for_context("medium", "monitoring")
        stability_thresholds = self.precision_levels.get_thresholds_for_context("medium", "stability")
        
        # Vérifier que les seuils sont différents selon le contexte
        self.assertNotEqual(monitoring_thresholds, stability_thresholds)
        
        # Vérifier que les seuils contiennent les métriques attendues
        for thresholds in [monitoring_thresholds, stability_thresholds]:
            self.assertIn("total_error", thresholds)
            self.assertIn("mean_error", thresholds)
            self.assertIn("variance_error", thresholds)
            self.assertIn("skewness_error", thresholds)
            self.assertIn("kurtosis_error", thresholds)
    
    def test_get_confidence_interval(self):
        """Test de la récupération de l'intervalle de confiance."""
        # Récupérer l'intervalle de confiance pour différents niveaux
        high_confidence = self.precision_levels.get_confidence_interval("high")
        medium_confidence = self.precision_levels.get_confidence_interval("medium")
        low_confidence = self.precision_levels.get_confidence_interval("low")
        
        # Vérifier que les intervalles de confiance sont cohérents
        self.assertGreater(high_confidence, medium_confidence)
        self.assertGreater(medium_confidence, low_confidence)
    
    def test_get_sample_size_recommendation(self):
        """Test de la recommandation de taille d'échantillon."""
        # Récupérer les recommandations pour différents niveaux et types de distribution
        high_normal = self.precision_levels.get_sample_size_recommendation("high", "normal")
        medium_normal = self.precision_levels.get_sample_size_recommendation("medium", "normal")
        high_asymmetric = self.precision_levels.get_sample_size_recommendation("high", "asymmetric")
        
        # Vérifier que les recommandations sont cohérentes
        self.assertGreater(high_normal, medium_normal)
        self.assertGreater(high_asymmetric, high_normal)
    
    def test_get_bin_count_recommendation(self):
        """Test de la recommandation de nombre de bins."""
        # Récupérer les recommandations pour différents niveaux et tailles d'échantillon
        high_small = self.precision_levels.get_bin_count_recommendation("high", 100)
        high_large = self.precision_levels.get_bin_count_recommendation("high", 1000)
        medium_small = self.precision_levels.get_bin_count_recommendation("medium", 100)
        
        # Vérifier que les recommandations sont cohérentes
        self.assertGreater(high_large, high_small)
        self.assertGreater(high_small, medium_small)
    
    def test_generate_default_config(self):
        """Test de la génération du fichier de configuration par défaut."""
        # Créer un fichier temporaire pour la configuration
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file_path = temp_file.name
        
        try:
            # Générer la configuration par défaut
            success = generate_default_config(temp_file_path)
            
            # Vérifier que la génération a réussi
            self.assertTrue(success)
            
            # Vérifier que le fichier existe et contient les niveaux par défaut
            with open(temp_file_path, 'r') as f:
                loaded_levels = json.load(f)
            
            # Vérifier que les niveaux attendus sont présents
            self.assertIn("high", loaded_levels)
            self.assertIn("medium", loaded_levels)
            self.assertIn("low", loaded_levels)
            self.assertIn("minimal", loaded_levels)
        finally:
            # Supprimer le fichier temporaire
            os.unlink(temp_file_path)


if __name__ == "__main__":
    unittest.main()
