#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'outils MCP pour la gestion de documents.

Ce module contient les outils MCP pour récupérer, rechercher et lire des documents.
"""

from . import fetch_documentation
from . import search_documentation
from . import read_file

__all__ = [
    "fetch_documentation",
    "search_documentation",
    "read_file"
]
