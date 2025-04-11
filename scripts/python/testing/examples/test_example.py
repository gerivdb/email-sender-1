#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple de tests pour démontrer l'utilisation de TestOmnibus.
"""

import unittest

class TestExampleSuccess(unittest.TestCase):
    """Classe de test avec des tests qui réussissent."""
    
    def test_addition(self):
        """Test d'addition simple."""
        self.assertEqual(1 + 1, 2)
    
    def test_subtraction(self):
        """Test de soustraction simple."""
        self.assertEqual(3 - 1, 2)
    
    def test_multiplication(self):
        """Test de multiplication simple."""
        self.assertEqual(2 * 2, 4)
    
    def test_division(self):
        """Test de division simple."""
        self.assertEqual(4 / 2, 2)

class TestExampleFailure(unittest.TestCase):
    """Classe de test avec des tests qui échouent."""
    
    def test_failing_equality(self):
        """Test d'égalité qui échoue."""
        self.assertEqual(1 + 1, 3, "1 + 1 devrait être égal à 2, pas à 3")
    
    def test_failing_true(self):
        """Test de vérité qui échoue."""
        self.assertTrue(False, "Cette assertion devrait échouer")
    
    def test_failing_exception(self):
        """Test d'exception qui échoue."""
        with self.assertRaises(ValueError):
            # Ceci ne lève pas d'exception ValueError
            x = 1 + 1

class TestExampleError(unittest.TestCase):
    """Classe de test avec des tests qui génèrent des erreurs."""
    
    def test_zero_division_error(self):
        """Test qui génère une erreur de division par zéro."""
        return 1 / 0
    
    def test_type_error(self):
        """Test qui génère une erreur de type."""
        return "string" + 1
    
    def test_name_error(self):
        """Test qui génère une erreur de nom."""
        return undefined_variable

if __name__ == "__main__":
    unittest.main()
