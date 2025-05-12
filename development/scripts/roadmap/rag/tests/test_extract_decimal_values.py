#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de test pour l'extraction des valeurs d'estimation décimales
Version: 1.0
Date: 2025-05-15
"""

import os
import sys
import unittest

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Importer le module à tester
from metadata.extract_decimal_values import extract_decimal_values


class TestExtractDecimalValues(unittest.TestCase):
    """
    Tests pour la fonction extract_decimal_values
    """
    
    def test_extract_decimal_values_with_comma(self):
        """
        Test avec des valeurs décimales avec virgule
        """
        text = "Cette tâche prendra environ 3,5 jours."
        results = extract_decimal_values(text)
        
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['value'], 3.5)
        self.assertEqual(results[0]['unit'], 'jour')
        self.assertEqual(results[0]['hours_value'], 28.0)
        self.assertEqual(results[0]['category'], 'approximate')
    
    def test_extract_decimal_values_with_point(self):
        """
        Test avec des valeurs décimales avec point
        """
        text = "Le développement durera à peu près 2.5 semaines."
        results = extract_decimal_values(text)
        
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['value'], 2.5)
        self.assertEqual(results[0]['unit'], 'semaine')
        self.assertEqual(results[0]['hours_value'], 100.0)
        self.assertEqual(results[0]['category'], 'approximate')
    
    def test_extract_decimal_values_with_hours(self):
        """
        Test avec des valeurs décimales avec des heures
        """
        text = "La mise en place devrait prendre plus ou moins 5,5 heures."
        results = extract_decimal_values(text)
        
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['value'], 5.5)
        self.assertEqual(results[0]['unit'], 'heure')
        self.assertEqual(results[0]['hours_value'], 5.5)
        self.assertEqual(results[0]['category'], 'approximate')
    
    def test_extract_decimal_values_with_multiple_values(self):
        """
        Test avec plusieurs valeurs décimales
        """
        text = """
        Cette tâche prendra environ 3,5 jours.
        Le développement durera à peu près 2.5 semaines.
        La mise en place devrait prendre plus ou moins 5,5 heures.
        Cette fonctionnalité nécessitera autour de 10.25 jours de travail.
        Le temps de développement est estimé à 4,75 jours.
        """
        results = extract_decimal_values(text)
        
        self.assertEqual(len(results), 5)
        
        # Vérifier que les valeurs sont correctement extraites
        values = [result['value'] for result in results]
        self.assertIn(3.5, values)
        self.assertIn(2.5, values)
        self.assertIn(5.5, values)
        self.assertIn(10.25, values)
        self.assertIn(4.75, values)
        
        # Vérifier que les unités sont correctement extraites
        units = [result['unit'] for result in results]
        self.assertIn('jour', units)
        self.assertIn('semaine', units)
        self.assertIn('heure', units)


if __name__ == '__main__':
    unittest.main()
