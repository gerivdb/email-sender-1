#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Tests unitaires pour les seuils d'acceptabilité des métriques composites.
"""

import unittest
import os
import json
import tempfile
from acceptability_thresholds import AcceptabilityThresholds, generate_default_config


class TestAcceptabilityThresholds(unittest.TestCase):
    """Tests pour la classe AcceptabilityThresholds."""
    
    def setUp(self):
        """Initialisation des données de test."""
        self.thresholds = AcceptabilityThresholds()
        
        # Créer des erreurs de test
        self.test_errors = {
            "total_error": 8.5,
            "components": {
                "mean": {"raw_error": 3.2},
                "variance": {"raw_error": 6.8},
                "skewness": {"raw_error": 12.5},
                "kurtosis": {"raw_error": 9.7}
            }
        }
    
    def test_default_thresholds(self):
        """Test des seuils par défaut."""
        # Vérifier que les seuils par défaut sont chargés correctement
        default_thresholds = self.thresholds.get_thresholds()
        
        self.assertIn("total_error", default_thresholds)
        self.assertIn("mean_error", default_thresholds)
        self.assertIn("variance_error", default_thresholds)
        self.assertIn("skewness_error", default_thresholds)
        self.assertIn("kurtosis_error", default_thresholds)
    
    def test_context_specific_thresholds(self):
        """Test des seuils spécifiques à un contexte."""
        # Vérifier que les seuils sont différents selon le contexte
        monitoring_thresholds = self.thresholds.get_thresholds("monitoring")
        stability_thresholds = self.thresholds.get_thresholds("stability")
        
        # Les seuils devraient être différents pour au moins une métrique
        self.assertNotEqual(monitoring_thresholds, stability_thresholds)
    
    def test_distribution_adjustment(self):
        """Test de l'ajustement des seuils en fonction du type de distribution."""
        # Obtenir les seuils de base
        base_thresholds = self.thresholds.get_thresholds("default")
        
        # Obtenir les seuils ajustés pour une distribution normale
        normal_thresholds = self.thresholds.get_thresholds("default", "normal")
        
        # Les seuils pour l'asymétrie et l'aplatissement devraient être plus élevés
        self.assertGreater(normal_thresholds["skewness_error"], base_thresholds["skewness_error"])
        self.assertGreater(normal_thresholds["kurtosis_error"], base_thresholds["kurtosis_error"])
    
    def test_evaluate_acceptability(self):
        """Test de l'évaluation de l'acceptabilité."""
        # Évaluer l'acceptabilité avec les erreurs de test
        acceptable, results = self.thresholds.evaluate_acceptability(self.test_errors, "monitoring")
        
        # Vérifier que les résultats sont cohérents
        self.assertIsInstance(acceptable, bool)
        self.assertIn("total_error", results)
        self.assertIn("mean", results)
        self.assertIn("variance", results)
        self.assertIn("skewness", results)
        self.assertIn("kurtosis", results)
    
    def test_detailed_evaluation(self):
        """Test de l'évaluation détaillée."""
        # Obtenir l'évaluation détaillée
        evaluation = self.thresholds.get_detailed_evaluation(self.test_errors, "monitoring")
        
        # Vérifier que l'évaluation contient les informations attendues
        self.assertIn("total_error", evaluation)
        self.assertIn("mean", evaluation)
        self.assertIn("variance", evaluation)
        self.assertIn("skewness", evaluation)
        self.assertIn("kurtosis", evaluation)
        self.assertIn("overall", evaluation)
        
        # Vérifier que chaque composante contient les détails attendus
        for component in ["total_error", "mean", "variance", "skewness", "kurtosis"]:
            self.assertIn("value", evaluation[component])
            self.assertIn("threshold", evaluation[component])
            self.assertIn("acceptable", evaluation[component])
            self.assertIn("level", evaluation[component])
    
    def test_acceptability_level(self):
        """Test de la détermination du niveau d'acceptabilité."""
        # Tester différents niveaux d'acceptabilité
        self.assertEqual(self.thresholds.get_acceptability_level(5.0, 10.0), "excellent")
        self.assertEqual(self.thresholds.get_acceptability_level(7.5, 10.0), "good")
        self.assertEqual(self.thresholds.get_acceptability_level(9.5, 10.0), "acceptable")
        self.assertEqual(self.thresholds.get_acceptability_level(12.0, 10.0), "poor")
        self.assertEqual(self.thresholds.get_acceptability_level(20.0, 10.0), "unacceptable")
    
    def test_custom_thresholds(self):
        """Test des seuils personnalisés."""
        # Créer un fichier temporaire pour les seuils personnalisés
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            # Définir des seuils personnalisés
            custom_thresholds = {
                "custom_context": {
                    "total_error": 5.0,
                    "mean_error": 2.0,
                    "variance_error": 3.0,
                    "skewness_error": 4.0,
                    "kurtosis_error": 5.0
                }
            }
            
            # Écrire les seuils dans le fichier
            json.dump(custom_thresholds, temp_file)
            temp_file_path = temp_file.name
        
        try:
            # Créer une instance avec les seuils personnalisés
            custom_thresholds_instance = AcceptabilityThresholds(temp_file_path)
            
            # Vérifier que les seuils personnalisés sont chargés correctement
            loaded_thresholds = custom_thresholds_instance.get_thresholds("custom_context")
            
            self.assertEqual(loaded_thresholds["total_error"], 5.0)
            self.assertEqual(loaded_thresholds["mean_error"], 2.0)
            self.assertEqual(loaded_thresholds["variance_error"], 3.0)
            self.assertEqual(loaded_thresholds["skewness_error"], 4.0)
            self.assertEqual(loaded_thresholds["kurtosis_error"], 5.0)
        finally:
            # Supprimer le fichier temporaire
            os.unlink(temp_file_path)
    
    def test_save_custom_thresholds(self):
        """Test de la sauvegarde des seuils personnalisés."""
        # Créer un fichier temporaire pour les seuils personnalisés
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
            temp_file_path = temp_file.name
        
        try:
            # Définir des seuils personnalisés
            custom_thresholds = {
                "custom_context": {
                    "total_error": 5.0,
                    "mean_error": 2.0,
                    "variance_error": 3.0,
                    "skewness_error": 4.0,
                    "kurtosis_error": 5.0
                }
            }
            
            # Sauvegarder les seuils
            success = self.thresholds.save_custom_thresholds(custom_thresholds, temp_file_path)
            
            # Vérifier que la sauvegarde a réussi
            self.assertTrue(success)
            
            # Vérifier que le fichier existe et contient les seuils
            with open(temp_file_path, 'r') as f:
                loaded_thresholds = json.load(f)
            
            self.assertEqual(loaded_thresholds, custom_thresholds)
        finally:
            # Supprimer le fichier temporaire
            os.unlink(temp_file_path)
    
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
            
            # Vérifier que le fichier existe et contient les seuils par défaut
            with open(temp_file_path, 'r') as f:
                loaded_thresholds = json.load(f)
            
            # Vérifier que les contextes attendus sont présents
            self.assertIn("monitoring", loaded_thresholds)
            self.assertIn("stability", loaded_thresholds)
            self.assertIn("anomaly_detection", loaded_thresholds)
            self.assertIn("characterization", loaded_thresholds)
            self.assertIn("default", loaded_thresholds)
        finally:
            # Supprimer le fichier temporaire
            os.unlink(temp_file_path)


if __name__ == "__main__":
    unittest.main()
