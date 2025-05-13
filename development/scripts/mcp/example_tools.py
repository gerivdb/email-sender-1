"""
Module d'exemples d'outils MCP.
Ce module fournit des exemples d'implémentation d'outils MCP.
"""

import os
import json
import datetime
from typing import List, Dict, Any, Optional

from tool_interfaces import MCPTool, ToolParameter, ToolResult, ToolRegistry


class EchoTool(MCPTool):
    """
    Outil simple qui renvoie le message fourni.
    """
    
    def __init__(self):
        """
        Initialise l'outil Echo.
        """
        super().__init__(
            name="echo",
            description="Renvoie le message fourni"
        )
        
        self.parameters = [
            ToolParameter(
                name="message",
                type_=str,
                description="Message à renvoyer",
                required=True
            ),
            ToolParameter(
                name="prefix",
                type_=str,
                description="Préfixe à ajouter au message",
                required=False,
                default=""
            )
        ]
    
    def execute(self, **kwargs) -> ToolResult:
        """
        Exécute l'outil Echo.
        
        Args:
            **kwargs: Paramètres de l'outil.
            
        Returns:
            Résultat de l'exécution.
        """
        # Valider les paramètres
        valid, error = self.validate_parameters(**kwargs)
        if not valid:
            return ToolResult.failure(error)
        
        # Récupérer les paramètres
        message = kwargs["message"]
        prefix = kwargs.get("prefix", "")
        
        # Construire le résultat
        result = f"{prefix}{message}"
        
        return ToolResult.success(result)


class FileReaderTool(MCPTool):
    """
    Outil pour lire le contenu d'un fichier.
    """
    
    def __init__(self):
        """
        Initialise l'outil FileReader.
        """
        super().__init__(
            name="file_reader",
            description="Lit le contenu d'un fichier"
        )
        
        self.parameters = [
            ToolParameter(
                name="file_path",
                type_=str,
                description="Chemin du fichier à lire",
                required=True
            ),
            ToolParameter(
                name="encoding",
                type_=str,
                description="Encodage du fichier",
                required=False,
                default="utf-8",
                enum=["utf-8", "ascii", "latin-1", "utf-16"]
            )
        ]
    
    def execute(self, **kwargs) -> ToolResult:
        """
        Exécute l'outil FileReader.
        
        Args:
            **kwargs: Paramètres de l'outil.
            
        Returns:
            Résultat de l'exécution.
        """
        # Valider les paramètres
        valid, error = self.validate_parameters(**kwargs)
        if not valid:
            return ToolResult.failure(error)
        
        # Récupérer les paramètres
        file_path = kwargs["file_path"]
        encoding = kwargs.get("encoding", "utf-8")
        
        # Vérifier que le fichier existe
        if not os.path.exists(file_path):
            return ToolResult.failure(f"Le fichier {file_path} n'existe pas")
        
        # Lire le fichier
        try:
            with open(file_path, "r", encoding=encoding) as f:
                content = f.read()
            
            # Ajouter des métadonnées
            metadata = {
                "file_path": file_path,
                "file_size": os.path.getsize(file_path),
                "file_modified": datetime.datetime.fromtimestamp(os.path.getmtime(file_path)).isoformat(),
                "encoding": encoding
            }
            
            return ToolResult.success(content, metadata=metadata)
        except Exception as e:
            return ToolResult.failure(f"Erreur lors de la lecture du fichier: {str(e)}")


class JsonParserTool(MCPTool):
    """
    Outil pour analyser une chaîne JSON.
    """
    
    def __init__(self):
        """
        Initialise l'outil JsonParser.
        """
        super().__init__(
            name="json_parser",
            description="Analyse une chaîne JSON"
        )
        
        self.parameters = [
            ToolParameter(
                name="json_string",
                type_=str,
                description="Chaîne JSON à analyser",
                required=True
            ),
            ToolParameter(
                name="extract_path",
                type_=str,
                description="Chemin à extraire (format: key1.key2[0].key3)",
                required=False
            )
        ]
    
    def execute(self, **kwargs) -> ToolResult:
        """
        Exécute l'outil JsonParser.
        
        Args:
            **kwargs: Paramètres de l'outil.
            
        Returns:
            Résultat de l'exécution.
        """
        # Valider les paramètres
        valid, error = self.validate_parameters(**kwargs)
        if not valid:
            return ToolResult.failure(error)
        
        # Récupérer les paramètres
        json_string = kwargs["json_string"]
        extract_path = kwargs.get("extract_path")
        
        # Analyser la chaîne JSON
        try:
            data = json.loads(json_string)
            
            # Extraire le chemin si spécifié
            if extract_path:
                result = self._extract_path(data, extract_path)
                if result is None:
                    return ToolResult.failure(f"Chemin {extract_path} non trouvé")
                return ToolResult.success(result)
            
            return ToolResult.success(data)
        except json.JSONDecodeError as e:
            return ToolResult.failure(f"Erreur d'analyse JSON: {str(e)}")
        except Exception as e:
            return ToolResult.failure(f"Erreur: {str(e)}")
    
    def _extract_path(self, data: Any, path: str) -> Any:
        """
        Extrait une valeur à partir d'un chemin.
        
        Args:
            data: Données JSON.
            path: Chemin à extraire.
            
        Returns:
            Valeur extraite ou None si non trouvée.
        """
        parts = []
        current = ""
        in_brackets = False
        
        # Parser le chemin
        for char in path:
            if char == "." and not in_brackets:
                parts.append(current)
                current = ""
            elif char == "[":
                parts.append(current)
                current = ""
                in_brackets = True
            elif char == "]":
                parts.append(int(current))
                current = ""
                in_brackets = False
            else:
                current += char
        
        if current:
            parts.append(current)
        
        # Extraire la valeur
        result = data
        for part in parts:
            if isinstance(result, dict) and part in result:
                result = result[part]
            elif isinstance(result, list) and isinstance(part, int) and 0 <= part < len(result):
                result = result[part]
            else:
                return None
        
        return result


def register_example_tools(registry: ToolRegistry) -> None:
    """
    Enregistre les outils d'exemple dans le registre.
    
    Args:
        registry: Registre d'outils.
    """
    registry.register(EchoTool())
    registry.register(FileReaderTool())
    registry.register(JsonParserTool())


if __name__ == "__main__":
    # Exemple d'utilisation
    registry = ToolRegistry()
    register_example_tools(registry)
    
    print(f"Outils disponibles: {registry.list_tools()}")
    
    # Exemple d'utilisation de l'outil Echo
    echo_tool = registry.get("echo")
    if echo_tool:
        result = echo_tool.execute(message="Hello, world!", prefix="Echo: ")
        print(f"Résultat de l'outil Echo: {result}")
    
    # Exemple d'utilisation de l'outil FileReader
    file_reader_tool = registry.get("file_reader")
    if file_reader_tool:
        # Remplacer par un chemin de fichier existant
        file_path = __file__
        result = file_reader_tool.execute(file_path=file_path)
        if result.success:
            print(f"Contenu du fichier (premiers 100 caractères): {result.data[:100]}...")
            print(f"Métadonnées: {result.metadata}")
        else:
            print(f"Erreur: {result.error}")
    
    # Exemple d'utilisation de l'outil JsonParser
    json_parser_tool = registry.get("json_parser")
    if json_parser_tool:
        json_string = '{"name": "John", "age": 30, "address": {"city": "New York", "zip": "10001"}, "hobbies": ["reading", "swimming"]}'
        result = json_parser_tool.execute(json_string=json_string, extract_path="address.city")
        if result.success:
            print(f"Valeur extraite: {result.data}")
        else:
            print(f"Erreur: {result.error}")
    
    # Exporter le schéma JSON
    schema = registry.to_json_schema()
    print(f"Schéma JSON: {json.dumps(schema, indent=2)}")
