"""
Script de test pour les interfaces d'outils MCP.
"""

import unittest
from tool_interfaces import ToolParameter, ToolResult, MCPTool, ToolRegistry


class TestToolParameter(unittest.TestCase):
    """
    Tests pour la classe ToolParameter.
    """
    
    def test_initialization(self):
        """
        Teste l'initialisation d'un paramètre d'outil.
        """
        # Paramètre requis
        param1 = ToolParameter(
            name="param1",
            type_=str,
            description="Description du paramètre 1",
            required=True
        )
        self.assertEqual(param1.name, "param1")
        self.assertEqual(param1.type, str)
        self.assertEqual(param1.description, "Description du paramètre 1")
        self.assertTrue(param1.required)
        self.assertIsNone(param1.default)
        self.assertIsNone(param1.enum)
        
        # Paramètre optionnel avec valeur par défaut
        param2 = ToolParameter(
            name="param2",
            type_=int,
            description="Description du paramètre 2",
            required=False,
            default=42
        )
        self.assertEqual(param2.name, "param2")
        self.assertEqual(param2.type, int)
        self.assertEqual(param2.description, "Description du paramètre 2")
        self.assertFalse(param2.required)
        self.assertEqual(param2.default, 42)
        self.assertIsNone(param2.enum)
        
        # Paramètre avec énumération
        param3 = ToolParameter(
            name="param3",
            type_=str,
            description="Description du paramètre 3",
            required=True,
            enum=["option1", "option2", "option3"]
        )
        self.assertEqual(param3.name, "param3")
        self.assertEqual(param3.type, str)
        self.assertEqual(param3.description, "Description du paramètre 3")
        self.assertTrue(param3.required)
        self.assertIsNone(param3.default)
        self.assertEqual(param3.enum, ["option1", "option2", "option3"])
    
    def test_validate(self):
        """
        Teste la validation des valeurs de paramètres.
        """
        # Paramètre requis
        param1 = ToolParameter(
            name="param1",
            type_=str,
            description="Description du paramètre 1",
            required=True
        )
        self.assertTrue(param1.validate("valeur"))
        self.assertFalse(param1.validate(None))
        self.assertFalse(param1.validate(42))  # Type incorrect
        
        # Paramètre optionnel
        param2 = ToolParameter(
            name="param2",
            type_=int,
            description="Description du paramètre 2",
            required=False
        )
        self.assertTrue(param2.validate(42))
        self.assertTrue(param2.validate(None))  # Optionnel, donc None est valide
        self.assertFalse(param2.validate("42"))  # Type incorrect
        
        # Paramètre avec énumération
        param3 = ToolParameter(
            name="param3",
            type_=str,
            description="Description du paramètre 3",
            required=True,
            enum=["option1", "option2", "option3"]
        )
        self.assertTrue(param3.validate("option1"))
        self.assertFalse(param3.validate("option4"))  # Valeur non dans l'énumération
        self.assertFalse(param3.validate(42))  # Type incorrect
    
    def test_to_dict(self):
        """
        Teste la conversion en dictionnaire.
        """
        param = ToolParameter(
            name="param",
            type_=str,
            description="Description du paramètre",
            required=True,
            default="default",
            enum=["option1", "option2"]
        )
        
        data = param.to_dict()
        self.assertEqual(data["name"], "param")
        self.assertEqual(data["type"], "str")
        self.assertEqual(data["description"], "Description du paramètre")
        self.assertTrue(data["required"])
        self.assertEqual(data["default"], "default")
        self.assertEqual(data["enum"], ["option1", "option2"])
    
    def test_from_dict(self):
        """
        Teste la création à partir d'un dictionnaire.
        """
        data = {
            "name": "param",
            "type": "str",
            "description": "Description du paramètre",
            "required": True,
            "default": "default",
            "enum": ["option1", "option2"]
        }
        
        param = ToolParameter.from_dict(data)
        self.assertEqual(param.name, "param")
        self.assertEqual(param.type, str)
        self.assertEqual(param.description, "Description du paramètre")
        self.assertTrue(param.required)
        self.assertEqual(param.default, "default")
        self.assertEqual(param.enum, ["option1", "option2"])


class TestToolResult(unittest.TestCase):
    """
    Tests pour la classe ToolResult.
    """
    
    def test_initialization(self):
        """
        Teste l'initialisation d'un résultat d'outil.
        """
        # Résultat de succès
        result1 = ToolResult(
            success=True,
            data="Données de résultat",
            metadata={"key": "value"}
        )
        self.assertTrue(result1.success)
        self.assertEqual(result1.data, "Données de résultat")
        self.assertIsNone(result1.error)
        self.assertEqual(result1.metadata, {"key": "value"})
        
        # Résultat d'échec
        result2 = ToolResult(
            success=False,
            error="Message d'erreur",
            metadata={"key": "value"}
        )
        self.assertFalse(result2.success)
        self.assertIsNone(result2.data)
        self.assertEqual(result2.error, "Message d'erreur")
        self.assertEqual(result2.metadata, {"key": "value"})
    
    def test_factory_methods(self):
        """
        Teste les méthodes de fabrique.
        """
        # Méthode success
        result1 = ToolResult.success("Données de résultat", {"key": "value"})
        self.assertTrue(result1.success)
        self.assertEqual(result1.data, "Données de résultat")
        self.assertIsNone(result1.error)
        self.assertEqual(result1.metadata, {"key": "value"})
        
        # Méthode failure
        result2 = ToolResult.failure("Message d'erreur", {"key": "value"})
        self.assertFalse(result2.success)
        self.assertIsNone(result2.data)
        self.assertEqual(result2.error, "Message d'erreur")
        self.assertEqual(result2.metadata, {"key": "value"})
    
    def test_to_dict(self):
        """
        Teste la conversion en dictionnaire.
        """
        # Résultat de succès
        result1 = ToolResult.success("Données de résultat", {"key": "value"})
        data1 = result1.to_dict()
        self.assertTrue(data1["success"])
        self.assertEqual(data1["data"], "Données de résultat")
        self.assertEqual(data1["metadata"], {"key": "value"})
        
        # Résultat d'échec
        result2 = ToolResult.failure("Message d'erreur", {"key": "value"})
        data2 = result2.to_dict()
        self.assertFalse(data2["success"])
        self.assertEqual(data2["error"], "Message d'erreur")
        self.assertEqual(data2["metadata"], {"key": "value"})


class MockTool(MCPTool):
    """
    Outil fictif pour les tests.
    """
    
    def __init__(self):
        """
        Initialise l'outil fictif.
        """
        super().__init__(
            name="mock_tool",
            description="Outil fictif pour les tests"
        )
        
        self.parameters = [
            ToolParameter(
                name="param1",
                type_=str,
                description="Paramètre 1",
                required=True
            ),
            ToolParameter(
                name="param2",
                type_=int,
                description="Paramètre 2",
                required=False,
                default=42
            )
        ]
    
    def execute(self, **kwargs):
        """
        Exécute l'outil fictif.
        """
        valid, error = self.validate_parameters(**kwargs)
        if not valid:
            return ToolResult.failure(error)
        
        param1 = kwargs["param1"]
        param2 = kwargs.get("param2", 42)
        
        return ToolResult.success(f"{param1} - {param2}")


class TestMCPTool(unittest.TestCase):
    """
    Tests pour la classe MCPTool.
    """
    
    def test_initialization(self):
        """
        Teste l'initialisation d'un outil MCP.
        """
        tool = MockTool()
        self.assertEqual(tool.name, "mock_tool")
        self.assertEqual(tool.description, "Outil fictif pour les tests")
        self.assertEqual(len(tool.parameters), 2)
    
    def test_validate_parameters(self):
        """
        Teste la validation des paramètres.
        """
        tool = MockTool()
        
        # Paramètres valides
        valid, error = tool.validate_parameters(param1="valeur", param2=42)
        self.assertTrue(valid)
        self.assertIsNone(error)
        
        # Paramètre requis manquant
        valid, error = tool.validate_parameters(param2=42)
        self.assertFalse(valid)
        self.assertIn("param1", error)
        
        # Paramètre avec type incorrect
        valid, error = tool.validate_parameters(param1="valeur", param2="42")
        self.assertFalse(valid)
        self.assertIn("param2", error)
    
    def test_execute(self):
        """
        Teste l'exécution d'un outil.
        """
        tool = MockTool()
        
        # Exécution avec paramètres valides
        result1 = tool.execute(param1="valeur", param2=42)
        self.assertTrue(result1.success)
        self.assertEqual(result1.data, "valeur - 42")
        
        # Exécution avec paramètre optionnel omis
        result2 = tool.execute(param1="valeur")
        self.assertTrue(result2.success)
        self.assertEqual(result2.data, "valeur - 42")
        
        # Exécution avec paramètres invalides
        result3 = tool.execute(param2=42)
        self.assertFalse(result3.success)
        self.assertIn("param1", result3.error)
    
    def test_to_dict(self):
        """
        Teste la conversion en dictionnaire.
        """
        tool = MockTool()
        data = tool.to_dict()
        
        self.assertEqual(data["name"], "mock_tool")
        self.assertEqual(data["description"], "Outil fictif pour les tests")
        self.assertEqual(len(data["parameters"]), 2)
    
    def test_to_json_schema(self):
        """
        Teste la conversion en schéma JSON.
        """
        tool = MockTool()
        schema = tool.to_json_schema()
        
        self.assertEqual(schema["type"], "object")
        self.assertIn("properties", schema)
        self.assertIn("param1", schema["properties"])
        self.assertIn("param2", schema["properties"])
        self.assertIn("required", schema)
        self.assertIn("param1", schema["required"])


class TestToolRegistry(unittest.TestCase):
    """
    Tests pour la classe ToolRegistry.
    """
    
    def test_initialization(self):
        """
        Teste l'initialisation d'un registre d'outils.
        """
        registry = ToolRegistry()
        self.assertEqual(len(registry), 0)
    
    def test_register_unregister(self):
        """
        Teste l'enregistrement et le désenregistrement d'outils.
        """
        registry = ToolRegistry()
        tool = MockTool()
        
        # Enregistrer un outil
        registry.register(tool)
        self.assertEqual(len(registry), 1)
        self.assertIn("mock_tool", registry)
        
        # Désenregistrer un outil
        result = registry.unregister("mock_tool")
        self.assertTrue(result)
        self.assertEqual(len(registry), 0)
        self.assertNotIn("mock_tool", registry)
        
        # Désenregistrer un outil inexistant
        result = registry.unregister("inexistant")
        self.assertFalse(result)
    
    def test_get(self):
        """
        Teste la récupération d'un outil.
        """
        registry = ToolRegistry()
        tool = MockTool()
        
        registry.register(tool)
        
        # Récupérer un outil existant
        retrieved_tool = registry.get("mock_tool")
        self.assertIsNotNone(retrieved_tool)
        self.assertEqual(retrieved_tool.name, "mock_tool")
        
        # Récupérer un outil inexistant
        retrieved_tool = registry.get("inexistant")
        self.assertIsNone(retrieved_tool)
    
    def test_list_tools(self):
        """
        Teste la liste des outils disponibles.
        """
        registry = ToolRegistry()
        tool1 = MockTool()
        tool2 = MockTool()
        tool2.name = "mock_tool_2"
        
        registry.register(tool1)
        registry.register(tool2)
        
        tools = registry.list_tools()
        self.assertEqual(len(tools), 2)
        self.assertIn("mock_tool", tools)
        self.assertIn("mock_tool_2", tools)
    
    def test_get_tool_descriptions(self):
        """
        Teste la récupération des descriptions d'outils.
        """
        registry = ToolRegistry()
        tool = MockTool()
        
        registry.register(tool)
        
        descriptions = registry.get_tool_descriptions()
        self.assertEqual(len(descriptions), 1)
        self.assertEqual(descriptions[0]["name"], "mock_tool")
    
    def test_to_json_schema(self):
        """
        Teste la conversion en schéma JSON.
        """
        registry = ToolRegistry()
        tool = MockTool()
        
        registry.register(tool)
        
        schema = registry.to_json_schema()
        self.assertEqual(schema["type"], "object")
        self.assertIn("properties", schema)
        self.assertIn("tool", schema["properties"])
        self.assertIn("parameters", schema["properties"])
        self.assertIn("enum", schema["properties"]["tool"])
        self.assertIn("mock_tool", schema["properties"]["tool"]["enum"])


if __name__ == "__main__":
    unittest.main()
