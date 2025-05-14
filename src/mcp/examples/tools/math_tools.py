#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module contenant des outils mathématiques pour le MCP.

Ce module contient des outils mathématiques qui peuvent être découverts
et utilisés par le ToolsManager.
"""

import os
import sys
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.mcp.core.mcp.tools_manager import tool

@tool(description="Additionne deux nombres")
def add(a: int, b: int) -> int:
    """
    Additionne deux nombres.
    
    Args:
        a (int): Premier nombre
        b (int): Deuxième nombre
    
    Returns:
        int: Somme des deux nombres
    """
    return a + b

@tool(description="Soustrait deux nombres")
def subtract(a: int, b: int) -> int:
    """
    Soustrait deux nombres.
    
    Args:
        a (int): Premier nombre
        b (int): Deuxième nombre
    
    Returns:
        int: Différence des deux nombres
    """
    return a - b

@tool(name="multiply", description="Multiplie deux nombres")
def mul(a: int, b: int) -> int:
    """
    Multiplie deux nombres.
    
    Args:
        a (int): Premier nombre
        b (int): Deuxième nombre
    
    Returns:
        int: Produit des deux nombres
    """
    return a * b

@tool(description="Divise deux nombres")
def divide(a: float, b: float) -> float:
    """
    Divise deux nombres.
    
    Args:
        a (float): Numérateur
        b (float): Dénominateur
    
    Returns:
        float: Résultat de la division
    
    Raises:
        ZeroDivisionError: Si le dénominateur est zéro
    """
    if b == 0:
        raise ZeroDivisionError("Division par zéro")
    return a / b
