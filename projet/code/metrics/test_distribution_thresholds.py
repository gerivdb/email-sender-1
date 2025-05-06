#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Tests pour le module de gestion des seuils adaptés par type de distribution.
"""

import os
import json
import unittest
import tempfile
from distribution_thresholds import DistributionThresholds, generate_default_config


class TestDistributionThresholds(unittest.TestCase):
    """
    Tests pour la classe DistributionThresholds.
    """
    
    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un fichier de configuration temporaire pour les tests
        self.temp_dir = tempfile.mkdtemp()
        self.temp_file_path = os.path.join(self.temp_dir, "test_distribution_thresholds.json")
        
        # Générer une configuration de test
        self.test_config = {
            "distribution_types": {
                "normal": {
                    "description": "Distribution normale de test",
                    "thresholds": {
                        "total_error": 10.0,
                        "mean_error": 5.0,
                        "variance_error": 5.0,
                        "skewness_error": 10.0,
                        "kurtosis_error": 15.0
                    },
                    "gmci_thresholds": {
                        "excellent": 0.9,
                        "veryGood": 0.8,
                        "good": 0.7,
                        "acceptable": 0.6,
                        "limited": 0.5
                    },
                    "sample_size": 30,
                    "detection_criteria": {
                        "skewness_range": [-0.5, 0.5],
                        "kurtosis_range": [2.5, 3.5]
                    }
                },
                "asymmetric": {
                    "description": "Distribution asymétrique de test",
                    "thresholds": {
                        "total_error": 15.0,
                        "mean_error": 8.0,
                        "variance_error": 8.0,
                        "skewness_error": 8.0,
                        "kurtosis_error": 12.0
                    },
                    "gmci_thresholds": {
                        "excellent": 0.95,
                        "veryGood": 0.85,
                        "good": 0.75,
                        "acceptable": 0.65,
                        "limited": 0.55
                    },
                    "sample_size": 50,
                    "detection_criteria": {
                        "skewness_range": [0.5, None]
                    }
                }
            },
            "contexts": {
                "monitoring": {
                    "description": "Contexte de surveillance de test",
                    "factors": {
                        "total_error": 1.5,
                        "mean_error": 0.8,
                        "variance_error": 1.0,
                        "skewness_error": 2.0,
                        "kurtosis_error": 2.0
                    }
                },
                "default": {
                    "description": "Contexte par défaut de test",
                    "factors": {
                        "total_error": 1.0,
                        "mean_error": 1.0,
                        "variance_error": 1.0,
                        "skewness_error": 1.0,
                        "kurtosis_error": 1.0
                    }
                }
            }
        }
        
        # Sauvegarder la configuration de test
        with open(self.temp_file_path, 'w', encoding='utf-8') as f:
            json.dump(self.test_config, f, indent=2)
        
        # Créer une instance avec la configuration de test
        self.thresholds = DistributionThresholds(self.temp_file_path)
    
    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le fichier de configuration temporaire
        if os.path.exists(self.temp_file_path):
            os.unlink(self.temp_file_path)
        
        # Supprimer le répertoire temporaire
        if os.path.exists(self.temp_dir):
            os.rmdir(self.temp_dir)
    
    def test_get_distribution_types(self):
        """Test de la récupération des types de distribution."""
        # Vérifier que les types de distribution sont correctement récupérés
        dist_types = self.thresholds.get_distribution_types()
        self.assertEqual(len(dist_types), 2)
        self.assertIn("normal", dist_types)
        self.assertIn("asymmetric", dist_types)
    
    def test_get_contexts(self):
        """Test de la récupération des contextes."""
        # Vérifier que les contextes sont correctement récupérés
        contexts = self.thresholds.get_contexts()
        self.assertEqual(len(contexts), 2)
        self.assertIn("monitoring", contexts)
        self.assertIn("default", contexts)
    
    def test_get_thresholds(self):
        """Test de la récupération des seuils."""
        # Vérifier que les seuils sont correctement récupérés pour un type de distribution et un contexte
        thresholds = self.thresholds.get_thresholds("normal", "default")
        self.assertEqual(thresholds["total_error"], 10.0)
        self.assertEqual(thresholds["mean_error"], 5.0)
        self.assertEqual(thresholds["variance_error"], 5.0)
        self.assertEqual(thresholds["skewness_error"], 10.0)
        self.assertEqual(thresholds["kurtosis_error"], 15.0)
        
        # Vérifier que les seuils sont correctement ajustés pour un contexte différent
        thresholds = self.thresholds.get_thresholds("normal", "monitoring")
        self.assertEqual(thresholds["total_error"], 15.0)  # 10.0 * 1.5
        self.assertEqual(thresholds["mean_error"], 4.0)    # 5.0 * 0.8
        self.assertEqual(thresholds["variance_error"], 5.0) # 5.0 * 1.0
        self.assertEqual(thresholds["skewness_error"], 20.0) # 10.0 * 2.0
        self.assertEqual(thresholds["kurtosis_error"], 30.0) # 15.0 * 2.0
    
    def test_get_gmci_thresholds(self):
        """Test de la récupération des seuils GMCI."""
        # Vérifier que les seuils GMCI sont correctement récupérés
        gmci_thresholds = self.thresholds.get_gmci_thresholds("normal")
        self.assertEqual(gmci_thresholds["excellent"], 0.9)
        self.assertEqual(gmci_thresholds["veryGood"], 0.8)
        self.assertEqual(gmci_thresholds["good"], 0.7)
        self.assertEqual(gmci_thresholds["acceptable"], 0.6)
        self.assertEqual(gmci_thresholds["limited"], 0.5)
    
    def test_get_sample_size(self):
        """Test de la récupération de la taille d'échantillon."""
        # Vérifier que la taille d'échantillon est correctement récupérée
        sample_size = self.thresholds.get_sample_size("normal")
        self.assertEqual(sample_size, 30)
        
        sample_size = self.thresholds.get_sample_size("asymmetric")
        self.assertEqual(sample_size, 50)
    
    def test_get_detection_criteria(self):
        """Test de la récupération des critères de détection."""
        # Vérifier que les critères de détection sont correctement récupérés
        criteria = self.thresholds.get_detection_criteria("normal")
        self.assertEqual(criteria["skewness_range"], [-0.5, 0.5])
        self.assertEqual(criteria["kurtosis_range"], [2.5, 3.5])
        
        criteria = self.thresholds.get_detection_criteria("asymmetric")
        self.assertEqual(criteria["skewness_range"], [0.5, None])
    
    def test_get_distribution_description(self):
        """Test de la récupération de la description d'un type de distribution."""
        # Vérifier que la description est correctement récupérée
        description = self.thresholds.get_distribution_description("normal")
        self.assertEqual(description, "Distribution normale de test")
    
    def test_get_context_description(self):
        """Test de la récupération de la description d'un contexte."""
        # Vérifier que la description est correctement récupérée
        description = self.thresholds.get_context_description("monitoring")
        self.assertEqual(description, "Contexte de surveillance de test")
    
    def test_update_distribution_type(self):
        """Test de la mise à jour d'un type de distribution."""
        # Mettre à jour un type de distribution existant
        new_config = {
            "description": "Distribution normale mise à jour",
            "thresholds": {
                "total_error": 12.0,
                "mean_error": 6.0,
                "variance_error": 6.0,
                "skewness_error": 12.0,
                "kurtosis_error": 18.0
            },
            "gmci_thresholds": {
                "excellent": 0.95,
                "veryGood": 0.85,
                "good": 0.75,
                "acceptable": 0.65,
                "limited": 0.55
            },
            "sample_size": 40,
            "detection_criteria": {
                "skewness_range": [-0.6, 0.6],
                "kurtosis_range": [2.4, 3.6]
            }
        }
        
        success = self.thresholds.update_distribution_type("normal", new_config)
        self.assertTrue(success)
        
        # Vérifier que la mise à jour a été effectuée
        thresholds = self.thresholds.get_thresholds("normal", "default")
        self.assertEqual(thresholds["total_error"], 12.0)
        self.assertEqual(thresholds["mean_error"], 6.0)
        
        description = self.thresholds.get_distribution_description("normal")
        self.assertEqual(description, "Distribution normale mise à jour")
    
    def test_update_context(self):
        """Test de la mise à jour d'un contexte."""
        # Mettre à jour un contexte existant
        new_config = {
            "description": "Contexte de surveillance mis à jour",
            "factors": {
                "total_error": 2.0,
                "mean_error": 1.0,
                "variance_error": 1.2,
                "skewness_error": 2.5,
                "kurtosis_error": 2.5
            }
        }
        
        success = self.thresholds.update_context("monitoring", new_config)
        self.assertTrue(success)
        
        # Vérifier que la mise à jour a été effectuée
        thresholds = self.thresholds.get_thresholds("normal", "monitoring")
        self.assertEqual(thresholds["total_error"], 20.0)  # 10.0 * 2.0
        self.assertEqual(thresholds["mean_error"], 5.0)    # 5.0 * 1.0
        
        description = self.thresholds.get_context_description("monitoring")
        self.assertEqual(description, "Contexte de surveillance mis à jour")
    
    def test_generate_default_config(self):
        """Test de la génération d'un fichier de configuration par défaut."""
        # Générer un fichier de configuration par défaut
        temp_file_path = os.path.join(self.temp_dir, "default_config.json")
        success = generate_default_config(temp_file_path)
        self.assertTrue(success)
        
        # Vérifier que le fichier a été créé
        self.assertTrue(os.path.exists(temp_file_path))
        
        # Vérifier que le fichier contient une configuration valide
        with open(temp_file_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
        
        self.assertIn("distribution_types", config)
        self.assertIn("contexts", config)
        
        # Vérifier que la configuration contient au moins les types de distribution de base
        dist_types = config["distribution_types"]
        self.assertIn("normal", dist_types)
        self.assertIn("quasiNormal", dist_types)
        self.assertIn("asymmetric", dist_types)
        self.assertIn("multimodal", dist_types)
        self.assertIn("leptokurtic", dist_types)
        
        # Vérifier que la configuration contient au moins les contextes de base
        contexts = config["contexts"]
        self.assertIn("default", contexts)
        self.assertIn("monitoring", contexts)
        self.assertIn("stability", contexts)
        self.assertIn("anomaly_detection", contexts)
        self.assertIn("characterization", contexts)


if __name__ == "__main__":
    unittest.main()
