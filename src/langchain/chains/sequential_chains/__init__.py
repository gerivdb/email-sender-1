#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'initialisation pour les chaînes séquentielles.

Ce module expose les classes et fonctions principales du package sequential_chains.
"""

from .base_sequential_chain import BaseSequentialChain
from .email_processing_chain import EmailProcessingChain

__all__ = ['BaseSequentialChain', 'EmailProcessingChain']
