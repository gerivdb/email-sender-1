"""
Module définissant les interfaces de base pour les outils MCP.
Ce module fournit des classes abstraites et des interfaces pour les outils MCP.
"""

import abc
import json
import inspect
from typing import List, Dict, Any, Optional, Union, Callable, Type, TypeVar, Generic, Tuple


# Type générique pour les paramètres d'outil
T = TypeVar('T')


class ToolParameter:
    """
    Classe représentant un paramètre d'outil MCP.
    """

    def __init__(
        self,
        name: str,
        type_: Type,
        description: str,
        required: bool = True,
        default: Any = None,
        enum: Optional[List[Any]] = None
    ):
        """
        Initialise un paramètre d'outil.

        Args:
            name: Nom du paramètre.
            type_: Type du paramètre.
            description: Description du paramètre.
            required: Si le paramètre est requis.
            default: Valeur par défaut du paramètre.
            enum: Liste des valeurs possibles pour le paramètre.
        """
        self.name = name
        self.type = type_
        self.description = description
        self.required = required
        self.default = default
        self.enum = enum

    def validate(self, value: Any) -> bool:
        """
        Valide une valeur pour ce paramètre.

        Args:
            value: Valeur à valider.

        Returns:
            True si la valeur est valide, False sinon.
        """
        # Vérifier si la valeur est None
        if value is None:
            return not self.required

        # Vérifier le type
        if not isinstance(value, self.type):
            return False

        # Vérifier l'énumération
        if self.enum is not None and value not in self.enum:
            return False

        return True

    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit le paramètre en dictionnaire.

        Returns:
            Dictionnaire représentant le paramètre.
        """
        result = {
            "name": self.name,
            "type": self.type.__name__,
            "description": self.description,
            "required": self.required
        }

        if self.default is not None:
            result["default"] = self.default

        if self.enum is not None:
            result["enum"] = self.enum

        return result

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ToolParameter':
        """
        Crée un paramètre à partir d'un dictionnaire.

        Args:
            data: Dictionnaire représentant le paramètre.

        Returns:
            Paramètre créé.
        """
        # Convertir le type de chaîne en type Python
        type_name = data["type"]
        type_map = {
            "str": str,
            "int": int,
            "float": float,
            "bool": bool,
            "list": list,
            "dict": dict
        }

        type_ = type_map.get(type_name, str)

        return cls(
            name=data["name"],
            type_=type_,
            description=data["description"],
            required=data.get("required", True),
            default=data.get("default"),
            enum=data.get("enum")
        )

    def __repr__(self) -> str:
        """
        Représentation du paramètre.

        Returns:
            Représentation sous forme de chaîne.
        """
        return f"ToolParameter(name='{self.name}', type={self.type.__name__}, required={self.required})"


class ToolResult(Generic[T]):
    """
    Classe représentant le résultat d'un outil MCP.
    """

    def __init__(
        self,
        success: bool,
        data: Optional[T] = None,
        error: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ):
        """
        Initialise un résultat d'outil.

        Args:
            success: Si l'exécution a réussi.
            data: Données du résultat.
            error: Message d'erreur en cas d'échec.
            metadata: Métadonnées associées au résultat.
        """
        self.success = success
        self.data = data
        self.error = error
        self.metadata = metadata or {}

    @classmethod
    def success(cls, data: T, metadata: Optional[Dict[str, Any]] = None) -> 'ToolResult[T]':
        """
        Crée un résultat de succès.

        Args:
            data: Données du résultat.
            metadata: Métadonnées associées au résultat.

        Returns:
            Résultat de succès.
        """
        return cls(success=True, data=data, metadata=metadata)

    @classmethod
    def failure(cls, error: str, metadata: Optional[Dict[str, Any]] = None) -> 'ToolResult[T]':
        """
        Crée un résultat d'échec.

        Args:
            error: Message d'erreur.
            metadata: Métadonnées associées au résultat.

        Returns:
            Résultat d'échec.
        """
        return cls(success=False, error=error, metadata=metadata)

    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit le résultat en dictionnaire.

        Returns:
            Dictionnaire représentant le résultat.
        """
        result = {
            "success": self.success,
            "metadata": self.metadata
        }

        if self.success:
            result["data"] = self.data
        else:
            result["error"] = self.error

        return result

    def __repr__(self) -> str:
        """
        Représentation du résultat.

        Returns:
            Représentation sous forme de chaîne.
        """
        if self.success:
            return f"ToolResult(success=True, data={self.data})"
        else:
            return f"ToolResult(success=False, error='{self.error}')"


class MCPTool(abc.ABC):
    """
    Classe abstraite pour les outils MCP.
    """

    def __init__(self, name: str, description: str):
        """
        Initialise un outil MCP.

        Args:
            name: Nom de l'outil.
            description: Description de l'outil.
        """
        self.name = name
        self.description = description
        self.parameters: List[ToolParameter] = []

    @abc.abstractmethod
    def execute(self, **kwargs) -> ToolResult:
        """
        Exécute l'outil avec les paramètres fournis.

        Args:
            **kwargs: Paramètres de l'outil.

        Returns:
            Résultat de l'exécution.
        """
        pass

    def validate_parameters(self, **kwargs) -> Tuple[bool, Optional[str]]:
        """
        Valide les paramètres fournis.

        Args:
            **kwargs: Paramètres à valider.

        Returns:
            Tuple (valide, message d'erreur).
        """
        # Vérifier les paramètres requis
        for param in self.parameters:
            if param.required and param.name not in kwargs:
                return False, f"Paramètre requis manquant: {param.name}"

            if param.name in kwargs:
                value = kwargs[param.name]
                if not param.validate(value):
                    return False, f"Paramètre invalide: {param.name}"

        return True, None

    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit l'outil en dictionnaire.

        Returns:
            Dictionnaire représentant l'outil.
        """
        return {
            "name": self.name,
            "description": self.description,
            "parameters": [param.to_dict() for param in self.parameters]
        }

    def to_json_schema(self) -> Dict[str, Any]:
        """
        Convertit l'outil en schéma JSON.

        Returns:
            Schéma JSON représentant l'outil.
        """
        properties = {}
        required = []

        for param in self.parameters:
            # Convertir le type Python en type JSON Schema
            type_map = {
                str: "string",
                int: "integer",
                float: "number",
                bool: "boolean",
                list: "array",
                dict: "object"
            }

            json_type = type_map.get(param.type, "string")

            # Créer la propriété
            property_schema = {
                "type": json_type,
                "description": param.description
            }

            if param.enum is not None:
                property_schema["enum"] = param.enum

            if param.default is not None:
                property_schema["default"] = param.default

            properties[param.name] = property_schema

            if param.required:
                required.append(param.name)

        return {
            "type": "object",
            "properties": properties,
            "required": required
        }

    def __repr__(self) -> str:
        """
        Représentation de l'outil.

        Returns:
            Représentation sous forme de chaîne.
        """
        return f"MCPTool(name='{self.name}', parameters={len(self.parameters)})"


class ToolRegistry:
    """
    Registre des outils MCP disponibles.
    """

    def __init__(self):
        """
        Initialise le registre d'outils.
        """
        self.tools: Dict[str, MCPTool] = {}

    def register(self, tool: MCPTool) -> None:
        """
        Enregistre un outil dans le registre.

        Args:
            tool: Outil à enregistrer.
        """
        self.tools[tool.name] = tool

    def unregister(self, name: str) -> bool:
        """
        Désenregistre un outil du registre.

        Args:
            name: Nom de l'outil à désenregistrer.

        Returns:
            True si l'outil a été désenregistré, False sinon.
        """
        if name in self.tools:
            del self.tools[name]
            return True
        return False

    def get(self, name: str) -> Optional[MCPTool]:
        """
        Récupère un outil par son nom.

        Args:
            name: Nom de l'outil.

        Returns:
            Outil correspondant ou None si non trouvé.
        """
        return self.tools.get(name)

    def list_tools(self) -> List[str]:
        """
        Liste les noms des outils disponibles.

        Returns:
            Liste des noms d'outils.
        """
        return list(self.tools.keys())

    def get_tool_descriptions(self) -> List[Dict[str, Any]]:
        """
        Récupère les descriptions de tous les outils.

        Returns:
            Liste des descriptions d'outils.
        """
        return [tool.to_dict() for tool in self.tools.values()]

    def to_json_schema(self) -> Dict[str, Any]:
        """
        Convertit le registre en schéma JSON.

        Returns:
            Schéma JSON représentant le registre.
        """
        schemas = {}

        for name, tool in self.tools.items():
            schemas[name] = tool.to_json_schema()

        return {
            "type": "object",
            "properties": {
                "tool": {
                    "type": "string",
                    "enum": list(self.tools.keys()),
                    "description": "Nom de l'outil à exécuter"
                },
                "parameters": {
                    "type": "object",
                    "oneOf": list(schemas.values())
                }
            },
            "required": ["tool", "parameters"]
        }

    def __len__(self) -> int:
        """
        Retourne le nombre d'outils dans le registre.

        Returns:
            Nombre d'outils.
        """
        return len(self.tools)

    def __contains__(self, name: str) -> bool:
        """
        Vérifie si un outil est dans le registre.

        Args:
            name: Nom de l'outil.

        Returns:
            True si l'outil est dans le registre, False sinon.
        """
        return name in self.tools

    def __iter__(self):
        """
        Itère sur les outils du registre.

        Returns:
            Itérateur sur les outils.
        """
        return iter(self.tools.values())
