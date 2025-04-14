#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le module format_roadmap_text.py
"""

import os
import sys
import unittest
import tempfile
from pathlib import Path

# Importer le module à tester
import format_roadmap_text_corrected as frt


class TestFormatRoadmapText(unittest.TestCase):
    """Tests pour le module format_roadmap_text.py"""

    def setUp(self):
        """Initialisation avant chaque test"""
        # Créer un fichier temporaire pour les tests
        self.temp_file = tempfile.NamedTemporaryFile(delete=False, mode='w+', encoding='utf-8')
        self.temp_file.write("# Roadmap de test\n\n## Section 1\n**Complexite**: Moyenne\n**Temps estime**: 1 semaine\n**Progression**: 50%\n\n## Section 2\n**Complexite**: Facile\n**Temps estime**: 2 jours\n**Progression**: 0%\n")
        self.temp_file.close()

    def tearDown(self):
        """Nettoyage après chaque test"""
        # Supprimer le fichier temporaire
        if os.path.exists(self.temp_file.name):
            os.unlink(self.temp_file.name)

    def test_get_indentation_level(self):
        """Test de la fonction get_indentation_level"""
        # Test avec différents niveaux d'indentation
        self.assertEqual(frt.get_indentation_level("Pas d'indentation"), 0)
        self.assertEqual(frt.get_indentation_level("  Indentation de 2 espaces"), 1)
        self.assertEqual(frt.get_indentation_level("    Indentation de 4 espaces"), 2)
        self.assertEqual(frt.get_indentation_level("\tIndentation avec tabulation"), 2)
        self.assertEqual(frt.get_indentation_level("  \tMixte espaces et tabulation"), 3)

    def test_format_line_by_indentation(self):
        """Test de la fonction format_line_by_indentation"""
        # Test avec différents niveaux d'indentation
        self.assertEqual(frt.format_line_by_indentation("Tâche principale", 0), "- [ ] Tâche principale")
        self.assertEqual(frt.format_line_by_indentation("Sous-tâche", 1), "  - [ ] Sous-tâche")
        self.assertEqual(frt.format_line_by_indentation("Sous-sous-tâche", 2), "    - [ ] Sous-sous-tâche")

        # Test avec des lignes déjà formatées
        self.assertEqual(frt.format_line_by_indentation("- [ ] Déjà formatée", 0), "- [ ] Déjà formatée")
        self.assertEqual(frt.format_line_by_indentation("  - [ ] Déjà formatée", 1), "  - [ ] Déjà formatée")

    def test_format_text_to_roadmap(self):
        """Test de la fonction format_text_to_roadmap"""
        # Texte d'entrée
        input_text = """Titre de la section

Tâche 1
  Sous-tâche 1.1
  Sous-tâche 1.2

Tâche 2
  Sous-tâche 2.1
  Sous-tâche 2.2"""

        # Résultat attendu
        expected_output = """## Titre de test
**Complexite**: Moyenne
**Temps estime**: 1-2 jours
**Progression**: 0%
- [ ] Titre de la section
- [ ] Tâche 1
  - [ ] Sous-tâche 1.1
  - [ ] Sous-tâche 1.2
- [ ] Tâche 2
  - [ ] Sous-tâche 2.1
  - [ ] Sous-tâche 2.2
"""

        # Appel de la fonction
        result = frt.format_text_to_roadmap(input_text, "Titre de test", "Moyenne", "1-2 jours")

        # Vérification du résultat
        self.assertEqual(result, expected_output)

    def test_insert_section_in_roadmap(self):
        """Test de la fonction insert_section_in_roadmap"""
        # Contenu de la section à insérer
        section_content = """## Nouvelle section
**Complexite**: Élevée
**Temps estime**: 3 jours
**Progression**: 0%
- [ ] Tâche 1
- [ ] Tâche 2
  - [ ] Sous-tâche 2.1
  - [ ] Sous-tâche 2.2
"""

        # Insérer la section dans le fichier temporaire
        result = frt.insert_section_in_roadmap(self.temp_file.name, section_content, 1)

        # Vérifier que l'insertion a réussi
        self.assertTrue(result)

        # Lire le contenu du fichier
        with open(self.temp_file.name, 'r', encoding='utf-8') as f:
            content = f.read()

        # Vérifier que la section a été insérée au bon endroit
        self.assertIn("## Nouvelle section", content)
        self.assertIn("**Complexite**: Élevée", content)

        # Vérifier l'ordre des sections
        sections = content.split("## ")
        self.assertEqual(len(sections), 4)  # 1 pour l'en-tête + 3 sections
        self.assertIn("Section 1", sections[1])
        self.assertIn("Nouvelle section", sections[2])
        self.assertIn("Section 2", sections[3])

    def test_insert_section_at_end(self):
        """Test de l'insertion d'une section à la fin du fichier"""
        # Contenu de la section à insérer
        section_content = """## Section finale
**Complexite**: Facile
**Temps estime**: 1 jour
**Progression**: 0%
- [ ] Tâche finale
"""

        # Insérer la section à la fin du fichier (section_number = 0)
        result = frt.insert_section_in_roadmap(self.temp_file.name, section_content, 0)

        # Vérifier que l'insertion a réussi
        self.assertTrue(result)

        # Lire le contenu du fichier
        with open(self.temp_file.name, 'r', encoding='utf-8') as f:
            content = f.read()

        # Vérifier que la section a été ajoutée à la fin
        self.assertTrue(content.endswith(section_content))


if __name__ == '__main__':
    unittest.main()
