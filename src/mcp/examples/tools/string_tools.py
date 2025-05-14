#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant des outils de manipulation de chaînes pour le MCP.

Ce module contient des outils de manipulation de chaînes qui peuvent être découverts
et utilisés par le ToolsManager.
"""

import os
import sys
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.mcp.core.mcp.tools_manager import tool

@tool(description="Convertit une chaîne en majuscules")
def to_upper(text: str) -> str:
    """
    Convertit une chaîne en majuscules.
    
    Args:
        text (str): Chaîne à convertir
    
    Returns:
        str: Chaîne convertie en majuscules
    """
    return text.upper()

@tool(description="Convertit une chaîne en minuscules")
def to_lower(text: str) -> str:
    """
    Convertit une chaîne en minuscules.
    
    Args:
        text (str): Chaîne à convertir
    
    Returns:
        str: Chaîne convertie en minuscules
    """
    return text.lower()

@tool(name="reverse", description="Inverse une chaîne")
def reverse_string(text: str) -> str:
    """
    Inverse une chaîne.
    
    Args:
        text (str): Chaîne à inverser
    
    Returns:
        str: Chaîne inversée
    """
    return text[::-1]

@tool(description="Compte le nombre d'occurrences d'un caractère dans une chaîne")
def count_char(text: str, char: str) -> int:
    """
    Compte le nombre d'occurrences d'un caractère dans une chaîne.
    
    Args:
        text (str): Chaîne à analyser
        char (str): Caractère à compter
    
    Returns:
        int: Nombre d'occurrences
    """
    if len(char) != 1:
        raise ValueError("Le paramètre 'char' doit être un caractère unique")
    return text.count(char)
