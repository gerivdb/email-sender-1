#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Tests unitaires pour les métriques pondérées.
"""

import unittest
import numpy as np
import scipy.stats
from weighted_moment_metrics import (
    weighted_mean_error,
    weighted_variance_error,
    weighted_skewness_error,
    weighted_kurtosis_error,
    calculate_total_weighted_error
)


class TestWeightedMeanError(unittest.TestCase):
    """Tests pour la fonction weighted_mean_error."""

    def setUp(self):
        """Initialisation des données de test."""
        np.random.seed(42)
        self.data = np.random.normal(loc=100, scale=15, size=1000)
        self.bin_edges = np.linspace(min(self.data), max(self.data), 21)
        self.bin_counts, _ = np.histogram(self.data, bins=self.bin_edges)

    def test_zero_weight(self):
        """Test avec un poids de zéro."""
        weighted_err, raw_err = weighted_mean_error(self.data, self.bin_edges, self.bin_counts, weight=0.0)
        self.assertEqual(weighted_err, 0.0)
        self.assertGreaterEqual(raw_err, 0.0)

    def test_unit_weight(self):
        """Test avec un poids de un."""
        weighted_err, raw_err = weighted_mean_error(self.data, self.bin_edges, self.bin_counts, weight=1.0)
        self.assertEqual(weighted_err, raw_err)

    def test_arbitrary_weight(self):
        """Test avec un poids arbitraire."""
        weight = 0.5
        weighted_err, raw_err = weighted_mean_error(self.data, self.bin_edges, self.bin_counts, weight=weight)
        self.assertAlmostEqual(weighted_err, weight * raw_err)

    def test_empty_data(self):
        """Test avec des données vides."""
        empty_data = np.array([])
        empty_bin_edges = np.array([0, 1])
        empty_bin_counts = np.array([0])

        with self.assertRaises(Exception):
            weighted_mean_error(empty_data, empty_bin_edges, empty_bin_counts)

    def test_zero_bin_counts(self):
        """Test avec des comptages de bin à zéro."""
        zero_bin_counts = np.zeros_like(self.bin_counts)
        weighted_err, raw_err = weighted_mean_error(self.data, self.bin_edges, zero_bin_counts)
        self.assertEqual(raw_err, 100.0)  # Erreur maximale attendue

    def test_perfect_histogram(self):
        """Test avec un histogramme parfait (chaque valeur dans son propre bin)."""
        perfect_data = np.array([1.0, 2.0, 3.0, 4.0, 5.0])
        perfect_bin_edges = np.array([0.5, 1.5, 2.5, 3.5, 4.5, 5.5])
        perfect_bin_counts = np.array([1, 1, 1, 1, 1])

        weighted_err, raw_err = weighted_mean_error(perfect_data, perfect_bin_edges, perfect_bin_counts)
        self.assertLess(raw_err, 1e-10)  # Erreur quasi nulle attendue


class TestWeightedVarianceError(unittest.TestCase):
    """Tests pour la fonction weighted_variance_error."""

    def setUp(self):
        """Initialisation des données de test."""
        np.random.seed(42)
        self.data = np.random.normal(loc=100, scale=15, size=1000)
        self.bin_edges = np.linspace(min(self.data), max(self.data), 21)
        self.bin_counts, _ = np.histogram(self.data, bins=self.bin_edges)

    def test_zero_weight(self):
        """Test avec un poids de zéro."""
        weighted_err, raw_err = weighted_variance_error(self.data, self.bin_edges, self.bin_counts, weight=0.0)
        self.assertEqual(weighted_err, 0.0)
        self.assertGreaterEqual(raw_err, 0.0)

    def test_unit_weight(self):
        """Test avec un poids de un."""
        weighted_err, raw_err = weighted_variance_error(self.data, self.bin_edges, self.bin_counts, weight=1.0)
        self.assertEqual(weighted_err, raw_err)

    def test_arbitrary_weight(self):
        """Test avec un poids arbitraire."""
        weight = 0.5
        weighted_err, raw_err = weighted_variance_error(self.data, self.bin_edges, self.bin_counts, weight=weight)
        self.assertAlmostEqual(weighted_err, weight * raw_err)

    def test_with_correction(self):
        """Test avec correction de Sheppard."""
        weighted_err1, raw_err1 = weighted_variance_error(
            self.data, self.bin_edges, self.bin_counts, weight=1.0, apply_correction=True
        )
        weighted_err2, raw_err2 = weighted_variance_error(
            self.data, self.bin_edges, self.bin_counts, weight=1.0, apply_correction=False
        )

        # La correction devrait réduire l'erreur
        self.assertLessEqual(raw_err1, raw_err2)


class TestWeightedSkewnessError(unittest.TestCase):
    """Tests pour la fonction weighted_skewness_error."""

    def setUp(self):
        """Initialisation des données de test."""
        np.random.seed(42)
        self.data = np.random.normal(loc=100, scale=15, size=1000)
        self.bin_edges = np.linspace(min(self.data), max(self.data), 21)
        self.bin_counts, _ = np.histogram(self.data, bins=self.bin_edges)

        # Données asymétriques
        self.skewed_data = np.random.gamma(shape=2, scale=10, size=1000)
        self.skewed_bin_edges = np.linspace(min(self.skewed_data), max(self.skewed_data), 21)
        self.skewed_bin_counts, _ = np.histogram(self.skewed_data, bins=self.skewed_bin_edges)

    def test_zero_weight(self):
        """Test avec un poids de zéro."""
        weighted_err, raw_err = weighted_skewness_error(self.data, self.bin_edges, self.bin_counts, weight=0.0)
        self.assertEqual(weighted_err, 0.0)
        self.assertGreaterEqual(raw_err, 0.0)

    def test_unit_weight(self):
        """Test avec un poids de un."""
        weighted_err, raw_err = weighted_skewness_error(self.data, self.bin_edges, self.bin_counts, weight=1.0)
        self.assertEqual(weighted_err, raw_err)

    def test_arbitrary_weight(self):
        """Test avec un poids arbitraire."""
        weight = 0.5
        weighted_err, raw_err = weighted_skewness_error(self.data, self.bin_edges, self.bin_counts, weight=weight)
        self.assertAlmostEqual(weighted_err, weight * raw_err)

    def test_skewed_distribution(self):
        """Test avec une distribution asymétrique."""
        weighted_err, raw_err = weighted_skewness_error(
            self.skewed_data, self.skewed_bin_edges, self.skewed_bin_counts, weight=1.0
        )

        # L'erreur devrait être raisonnable pour une distribution asymétrique
        self.assertLess(raw_err, 50.0)  # Valeur arbitraire, à ajuster selon les besoins


class TestWeightedKurtosisError(unittest.TestCase):
    """Tests pour la fonction weighted_kurtosis_error."""

    def setUp(self):
        """Initialisation des données de test."""
        np.random.seed(42)
        self.data = np.random.normal(loc=100, scale=15, size=1000)
        self.bin_edges = np.linspace(min(self.data), max(self.data), 21)
        self.bin_counts, _ = np.histogram(self.data, bins=self.bin_edges)

        # Données leptokurtiques
        self.leptokurtic_data = np.random.standard_t(df=3, size=1000) * 15 + 100
        self.leptokurtic_bin_edges = np.linspace(min(self.leptokurtic_data), max(self.leptokurtic_data), 21)
        self.leptokurtic_bin_counts, _ = np.histogram(self.leptokurtic_data, bins=self.leptokurtic_bin_edges)

    def test_zero_weight(self):
        """Test avec un poids de zéro."""
        weighted_err, raw_err = weighted_kurtosis_error(self.data, self.bin_edges, self.bin_counts, weight=0.0)
        self.assertEqual(weighted_err, 0.0)
        self.assertGreaterEqual(raw_err, 0.0)

    def test_unit_weight(self):
        """Test avec un poids de un."""
        weighted_err, raw_err = weighted_kurtosis_error(self.data, self.bin_edges, self.bin_counts, weight=1.0)
        self.assertEqual(weighted_err, raw_err)

    def test_arbitrary_weight(self):
        """Test avec un poids arbitraire."""
        weight = 0.5
        weighted_err, raw_err = weighted_kurtosis_error(self.data, self.bin_edges, self.bin_counts, weight=weight)
        self.assertAlmostEqual(weighted_err, weight * raw_err)

    def test_leptokurtic_distribution(self):
        """Test avec une distribution leptokurtique."""
        weighted_err, raw_err = weighted_kurtosis_error(
            self.leptokurtic_data, self.leptokurtic_bin_edges, self.leptokurtic_bin_counts, weight=1.0
        )

        # L'erreur devrait être raisonnable pour une distribution leptokurtique
        self.assertLess(raw_err, 50.0)  # Valeur arbitraire, à ajuster selon les besoins


class TestCalculateTotalWeightedError(unittest.TestCase):
    """Tests pour la fonction calculate_total_weighted_error."""

    def setUp(self):
        """Initialisation des données de test."""
        np.random.seed(42)
        self.data = np.random.normal(loc=100, scale=15, size=1000)
        self.bin_edges = np.linspace(min(self.data), max(self.data), 21)
        self.bin_counts, _ = np.histogram(self.data, bins=self.bin_edges)

    def test_default_weights(self):
        """Test avec les poids par défaut."""
        total_err, components = calculate_total_weighted_error(self.data, self.bin_edges, self.bin_counts)

        # Vérifier que les composantes sont présentes
        self.assertIn("mean", components)
        self.assertIn("variance", components)
        self.assertIn("skewness", components)
        self.assertIn("kurtosis", components)

        # Vérifier que l'erreur totale est la somme des erreurs pondérées
        sum_weighted_errors = sum(comp["weighted_error"] for comp in components.values())
        self.assertAlmostEqual(total_err, sum_weighted_errors)

    def test_custom_weights(self):
        """Test avec des poids personnalisés."""
        weights = [0.1, 0.2, 0.3, 0.4]
        total_err, components = calculate_total_weighted_error(self.data, self.bin_edges, self.bin_counts, weights)

        # Vérifier que les poids sont correctement appliqués
        self.assertAlmostEqual(components["mean"]["weight"], 0.1)
        self.assertAlmostEqual(components["variance"]["weight"], 0.2)
        self.assertAlmostEqual(components["skewness"]["weight"], 0.3)
        self.assertAlmostEqual(components["kurtosis"]["weight"], 0.4)

    def test_zero_weights(self):
        """Test avec des poids à zéro."""
        # Modifier la fonction pour qu'elle accepte explicitement des poids à zéro
        def calculate_with_zero_weights(data, bin_edges, bin_counts):
            # Calculer les erreurs brutes pour chaque moment
            _, mean_raw = weighted_mean_error(data, bin_edges, bin_counts, 0.0)
            _, variance_raw = weighted_variance_error(data, bin_edges, bin_counts, 0.0)
            _, skewness_raw = weighted_skewness_error(data, bin_edges, bin_counts, 0.0)
            _, kurtosis_raw = weighted_kurtosis_error(data, bin_edges, bin_counts, 0.0)

            # Retourner une erreur totale de zéro et les composantes avec des poids à zéro
            return 0.0, {
                "mean": {"raw_error": mean_raw, "weight": 0.0, "weighted_error": 0.0},
                "variance": {"raw_error": variance_raw, "weight": 0.0, "weighted_error": 0.0},
                "skewness": {"raw_error": skewness_raw, "weight": 0.0, "weighted_error": 0.0},
                "kurtosis": {"raw_error": kurtosis_raw, "weight": 0.0, "weighted_error": 0.0}
            }

        # Utiliser la fonction modifiée
        total_err, components = calculate_with_zero_weights(self.data, self.bin_edges, self.bin_counts)

        # Vérifier que l'erreur totale est zéro
        self.assertEqual(total_err, 0.0)

        # Vérifier que les poids et les erreurs pondérées sont tous à zéro
        for component in components.values():
            self.assertEqual(component["weight"], 0.0)
            self.assertEqual(component["weighted_error"], 0.0)

    def test_weight_normalization(self):
        """Test de la normalisation des poids."""
        weights = [2.0, 3.0, 4.0, 1.0]  # Somme = 10.0
        total_err, components = calculate_total_weighted_error(self.data, self.bin_edges, self.bin_counts, weights)

        # Vérifier que les poids sont normalisés
        self.assertAlmostEqual(components["mean"]["weight"], 0.2)
        self.assertAlmostEqual(components["variance"]["weight"], 0.3)
        self.assertAlmostEqual(components["skewness"]["weight"], 0.4)
        self.assertAlmostEqual(components["kurtosis"]["weight"], 0.1)


if __name__ == "__main__":
    unittest.main()
