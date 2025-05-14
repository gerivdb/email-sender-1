#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour l'architecture cognitive des roadmaps.

Ce module contient les tests unitaires pour l'architecture cognitive des roadmaps.
"""

import sys
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.mcp.core.roadmap import (
    CognitiveNode, Cosmos, Galaxy, StellarSystem,
    Planet, Continent, Region, City, District, Street, Building,
    HierarchyLevel, NodeStatus
)

class TestCognitiveNode(unittest.TestCase):
    """Tests pour la classe CognitiveNode."""

    def test_init(self):
        """Teste l'initialisation d'un nœud cognitif."""
        # Créer un nœud avec des valeurs par défaut
        node = CognitiveNode(
            name="Test Node",
            level=HierarchyLevel.COSMOS
        )

        # Vérifier les valeurs
        self.assertEqual(node.name, "Test Node")
        self.assertEqual(node.level, HierarchyLevel.COSMOS)
        self.assertEqual(node.description, "")
        self.assertIsNotNone(node.node_id)
        self.assertIsInstance(node.metadata, dict)
        self.assertEqual(node.status, NodeStatus.PLANNED)
        self.assertIsNone(node.parent_id)
        self.assertEqual(node.children_ids, set())

        # Vérifier les métadonnées par défaut
        self.assertIn("created_at", node.metadata)
        self.assertIn("updated_at", node.metadata)
        self.assertEqual(node.metadata["created_at"], node.metadata["updated_at"])

    def test_init_with_values(self):
        """Teste l'initialisation d'un nœud cognitif avec des valeurs spécifiques."""
        # Créer un nœud avec des valeurs spécifiques
        node_id = "test-id"
        metadata = {"type": "test", "tags": ["unit", "test"]}

        node = CognitiveNode(
            name="Test Node",
            level=HierarchyLevel.COSMOS,
            description="Test description",
            node_id=node_id,
            metadata=metadata,
            status=NodeStatus.IN_PROGRESS,
            parent_id="parent-id"
        )

        # Vérifier les valeurs
        self.assertEqual(node.name, "Test Node")
        self.assertEqual(node.level, HierarchyLevel.COSMOS)
        self.assertEqual(node.description, "Test description")
        self.assertEqual(node.node_id, node_id)
        self.assertEqual(node.metadata["type"], "test")
        self.assertEqual(node.metadata["tags"], ["unit", "test"])
        self.assertEqual(node.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(node.parent_id, "parent-id")

    def test_to_dict(self):
        """Teste la conversion d'un nœud cognitif en dictionnaire."""
        # Créer un nœud
        node = CognitiveNode(
            name="Test Node",
            level=HierarchyLevel.COSMOS,
            description="Test description",
            node_id="test-id",
            metadata={"type": "test"},
            status=NodeStatus.IN_PROGRESS,
            parent_id="parent-id"
        )

        # Ajouter un enfant
        node.add_child("child-id")

        # Convertir en dictionnaire
        data = node.to_dict()

        # Vérifier les valeurs
        self.assertEqual(data["name"], "Test Node")
        self.assertEqual(data["level"], "COSMOS")
        self.assertEqual(data["level_value"], HierarchyLevel.COSMOS.value)
        self.assertEqual(data["description"], "Test description")
        self.assertEqual(data["node_id"], "test-id")
        self.assertEqual(data["metadata"]["type"], "test")
        self.assertEqual(data["status"], "IN_PROGRESS")
        self.assertEqual(data["parent_id"], "parent-id")
        self.assertEqual(data["children_ids"], ["child-id"])

    def test_from_dict(self):
        """Teste la création d'un nœud cognitif à partir d'un dictionnaire."""
        # Créer un dictionnaire
        data = {
            "name": "Test Node",
            "level": "COSMOS",
            "level_value": HierarchyLevel.COSMOS.value,
            "description": "Test description",
            "node_id": "test-id",
            "metadata": {"type": "test"},
            "status": "IN_PROGRESS",
            "parent_id": "parent-id",
            "children_ids": ["child-id"]
        }

        # Créer un nœud à partir du dictionnaire
        node = CognitiveNode.from_dict(data)

        # Vérifier les valeurs
        self.assertEqual(node.name, "Test Node")
        self.assertEqual(node.level, HierarchyLevel.COSMOS)
        self.assertEqual(node.description, "Test description")
        self.assertEqual(node.node_id, "test-id")
        self.assertEqual(node.metadata["type"], "test")
        self.assertEqual(node.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(node.parent_id, "parent-id")
        self.assertEqual(node.children_ids, {"child-id"})

    def test_add_child(self):
        """Teste l'ajout d'un enfant à un nœud cognitif."""
        # Créer un nœud
        node = CognitiveNode(
            name="Test Node",
            level=HierarchyLevel.COSMOS
        )

        # Enregistrer la date de mise à jour initiale
        initial_updated_at = node.metadata["updated_at"]

        # Attendre un peu pour s'assurer que la date de mise à jour change
        import time
        time.sleep(0.001)

        # Ajouter un enfant
        node.add_child("child-id")

        # Vérifier que l'enfant a été ajouté
        self.assertIn("child-id", node.children_ids)

        # Vérifier que la date de mise à jour a été mise à jour
        self.assertNotEqual(node.metadata["updated_at"], initial_updated_at)

    def test_remove_child(self):
        """Teste la suppression d'un enfant d'un nœud cognitif."""
        # Créer un nœud
        node = CognitiveNode(
            name="Test Node",
            level=HierarchyLevel.COSMOS
        )

        # Ajouter un enfant
        node.add_child("child-id")

        # Enregistrer la date de mise à jour initiale
        initial_updated_at = node.metadata["updated_at"]

        # Attendre un peu pour s'assurer que la date de mise à jour change
        import time
        time.sleep(0.001)

        # Supprimer l'enfant
        success = node.remove_child("child-id")

        # Vérifier que l'enfant a été supprimé
        self.assertTrue(success)
        self.assertNotIn("child-id", node.children_ids)

        # Vérifier que la date de mise à jour a été mise à jour
        self.assertNotEqual(node.metadata["updated_at"], initial_updated_at)

        # Essayer de supprimer un enfant inexistant
        success = node.remove_child("nonexistent")

        # Vérifier que la suppression a échoué
        self.assertFalse(success)

    def test_update_status(self):
        """Teste la mise à jour du statut d'un nœud cognitif."""
        # Créer un nœud
        node = CognitiveNode(
            name="Test Node",
            level=HierarchyLevel.COSMOS
        )

        # Enregistrer la date de mise à jour initiale
        initial_updated_at = node.metadata["updated_at"]

        # Attendre un peu pour s'assurer que la date de mise à jour change
        import time
        time.sleep(0.001)

        # Mettre à jour le statut
        node.update_status(NodeStatus.IN_PROGRESS)

        # Vérifier que le statut a été mis à jour
        self.assertEqual(node.status, NodeStatus.IN_PROGRESS)

        # Vérifier que la date de mise à jour a été mise à jour
        self.assertNotEqual(node.metadata["updated_at"], initial_updated_at)

        # Vérifier que la date de mise à jour du statut a été ajoutée
        self.assertIn("status_updated_at", node.metadata)
        self.assertEqual(node.metadata["status_updated_at"], node.metadata["updated_at"])

    def test_update_metadata(self):
        """Teste la mise à jour des métadonnées d'un nœud cognitif."""
        # Créer un nœud
        node = CognitiveNode(
            name="Test Node",
            level=HierarchyLevel.COSMOS,
            metadata={"type": "test"}
        )

        # Enregistrer la date de mise à jour initiale
        initial_updated_at = node.metadata["updated_at"]

        # Attendre un peu pour s'assurer que la date de mise à jour change
        import time
        time.sleep(0.001)

        # Mettre à jour les métadonnées
        node.update_metadata({"tags": ["unit", "test"]})

        # Vérifier que les métadonnées ont été mises à jour
        self.assertEqual(node.metadata["type"], "test")  # La valeur existante est conservée
        self.assertEqual(node.metadata["tags"], ["unit", "test"])  # La nouvelle valeur est ajoutée

        # Vérifier que la date de mise à jour a été mise à jour
        self.assertNotEqual(node.metadata["updated_at"], initial_updated_at)

class TestCosmos(unittest.TestCase):
    """Tests pour la classe Cosmos."""

    def test_init(self):
        """Teste l'initialisation d'un nœud COSMOS."""
        # Créer un COSMOS
        cosmos = Cosmos(
            name="Test Cosmos",
            description="Test description",
            node_id="cosmos-id",
            metadata={"version": "1.0"},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(cosmos.name, "Test Cosmos")
        self.assertEqual(cosmos.level, HierarchyLevel.COSMOS)
        self.assertEqual(cosmos.description, "Test description")
        self.assertEqual(cosmos.node_id, "cosmos-id")
        self.assertEqual(cosmos.metadata["version"], "1.0")
        self.assertEqual(cosmos.metadata["type"], "cosmos")
        self.assertEqual(cosmos.status, NodeStatus.IN_PROGRESS)
        self.assertIsNone(cosmos.parent_id)

class TestGalaxy(unittest.TestCase):
    """Tests pour la classe Galaxy."""

    def test_init(self):
        """Teste l'initialisation d'un nœud GALAXIE."""
        # Créer une GALAXIE
        galaxy = Galaxy(
            name="Test Galaxy",
            cosmos_id="cosmos-id",
            description="Test description",
            node_id="galaxy-id",
            metadata={"priority": "high"},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(galaxy.name, "Test Galaxy")
        self.assertEqual(galaxy.level, HierarchyLevel.GALAXIES)
        self.assertEqual(galaxy.description, "Test description")
        self.assertEqual(galaxy.node_id, "galaxy-id")
        self.assertEqual(galaxy.metadata["priority"], "high")
        self.assertEqual(galaxy.metadata["type"], "galaxy")
        self.assertEqual(galaxy.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(galaxy.parent_id, "cosmos-id")

class TestStellarSystem(unittest.TestCase):
    """Tests pour la classe StellarSystem."""

    def test_init(self):
        """Teste l'initialisation d'un nœud SYSTEME STELLAIRE."""
        # Créer un SYSTEME STELLAIRE
        system = StellarSystem(
            name="Test System",
            galaxy_id="galaxy-id",
            description="Test description",
            node_id="system-id",
            metadata={"status": "in_progress"},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(system.name, "Test System")
        self.assertEqual(system.level, HierarchyLevel.SYSTEMES)
        self.assertEqual(system.description, "Test description")
        self.assertEqual(system.node_id, "system-id")
        self.assertEqual(system.metadata["status"], "in_progress")
        self.assertEqual(system.metadata["type"], "stellar_system")
        self.assertEqual(system.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(system.parent_id, "galaxy-id")

class TestPlanet(unittest.TestCase):
    """Tests pour la classe Planet."""

    def test_init(self):
        """Teste l'initialisation d'un nœud PLANETE."""
        # Créer une PLANETE
        planet = Planet(
            name="Test Planet",
            system_id="system-id",
            description="Test description",
            node_id="planet-id",
            metadata={"priority": "high"},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(planet.name, "Test Planet")
        self.assertEqual(planet.level, HierarchyLevel.PLANETES)
        self.assertEqual(planet.description, "Test description")
        self.assertEqual(planet.node_id, "planet-id")
        self.assertEqual(planet.metadata["priority"], "high")
        self.assertEqual(planet.metadata["type"], "planet")
        self.assertEqual(planet.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(planet.parent_id, "system-id")

class TestContinent(unittest.TestCase):
    """Tests pour la classe Continent."""

    def test_init(self):
        """Teste l'initialisation d'un nœud CONTINENT."""
        # Créer un CONTINENT
        continent = Continent(
            name="Test Continent",
            planet_id="planet-id",
            description="Test description",
            node_id="continent-id",
            metadata={"category": "backend"},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(continent.name, "Test Continent")
        self.assertEqual(continent.level, HierarchyLevel.CONTINENTS)
        self.assertEqual(continent.description, "Test description")
        self.assertEqual(continent.node_id, "continent-id")
        self.assertEqual(continent.metadata["category"], "backend")
        self.assertEqual(continent.metadata["type"], "continent")
        self.assertEqual(continent.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(continent.parent_id, "planet-id")

class TestRegion(unittest.TestCase):
    """Tests pour la classe Region."""

    def test_init(self):
        """Teste l'initialisation d'un nœud REGION."""
        # Créer une REGION
        region = Region(
            name="Test Region",
            continent_id="continent-id",
            description="Test description",
            node_id="region-id",
            metadata={"complexity": "medium"},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(region.name, "Test Region")
        self.assertEqual(region.level, HierarchyLevel.REGIONS)
        self.assertEqual(region.description, "Test description")
        self.assertEqual(region.node_id, "region-id")
        self.assertEqual(region.metadata["complexity"], "medium")
        self.assertEqual(region.metadata["type"], "region")
        self.assertEqual(region.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(region.parent_id, "continent-id")

class TestCity(unittest.TestCase):
    """Tests pour la classe City."""

    def test_init(self):
        """Teste l'initialisation d'un nœud VILLE."""
        # Créer une VILLE
        city = City(
            name="Test City",
            region_id="region-id",
            description="Test description",
            node_id="city-id",
            metadata={"importance": "high"},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(city.name, "Test City")
        self.assertEqual(city.level, HierarchyLevel.VILLES)
        self.assertEqual(city.description, "Test description")
        self.assertEqual(city.node_id, "city-id")
        self.assertEqual(city.metadata["importance"], "high")
        self.assertEqual(city.metadata["type"], "city")
        self.assertEqual(city.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(city.parent_id, "region-id")

class TestDistrict(unittest.TestCase):
    """Tests pour la classe District."""

    def test_init(self):
        """Teste l'initialisation d'un nœud QUARTIER."""
        # Créer un QUARTIER
        district = District(
            name="Test District",
            city_id="city-id",
            description="Test description",
            node_id="district-id",
            metadata={"type_code": "residential"},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(district.name, "Test District")
        self.assertEqual(district.level, HierarchyLevel.QUARTIERS)
        self.assertEqual(district.description, "Test description")
        self.assertEqual(district.node_id, "district-id")
        self.assertEqual(district.metadata["type_code"], "residential")
        self.assertEqual(district.metadata["type"], "district")
        self.assertEqual(district.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(district.parent_id, "city-id")

class TestStreet(unittest.TestCase):
    """Tests pour la classe Street."""

    def test_init(self):
        """Teste l'initialisation d'un nœud RUE."""
        # Créer une RUE
        street = Street(
            name="Test Street",
            district_id="district-id",
            description="Test description",
            node_id="street-id",
            metadata={"length": "short"},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(street.name, "Test Street")
        self.assertEqual(street.level, HierarchyLevel.RUES)
        self.assertEqual(street.description, "Test description")
        self.assertEqual(street.node_id, "street-id")
        self.assertEqual(street.metadata["length"], "short")
        self.assertEqual(street.metadata["type"], "street")
        self.assertEqual(street.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(street.parent_id, "district-id")

class TestBuilding(unittest.TestCase):
    """Tests pour la classe Building."""

    def test_init(self):
        """Teste l'initialisation d'un nœud BATIMENT."""
        # Créer un BATIMENT
        building = Building(
            name="Test Building",
            street_id="street-id",
            description="Test description",
            node_id="building-id",
            metadata={"floors": 5},
            status=NodeStatus.IN_PROGRESS
        )

        # Vérifier les valeurs
        self.assertEqual(building.name, "Test Building")
        self.assertEqual(building.level, HierarchyLevel.BATIMENTS)
        self.assertEqual(building.description, "Test description")
        self.assertEqual(building.node_id, "building-id")
        self.assertEqual(building.metadata["floors"], 5)
        self.assertEqual(building.metadata["type"], "building")
        self.assertEqual(building.status, NodeStatus.IN_PROGRESS)
        self.assertEqual(building.parent_id, "street-id")

if __name__ == "__main__":
    unittest.main()
