#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'initialisation pour les chaînes Langchain.

Ce module expose les classes et fonctions principales du package chains.
"""

from src.langchain.chains.llm_chains import BaseLLMChain, EmailGenerationChain, EmailAnalysisChain
from src.langchain.chains.sequential_chains import BaseSequentialChain, EmailProcessingChain
from src.langchain.chains.router_chains import BaseRouterChain, EmailResponseRouterChain

__all__ = [
    'BaseLLMChain',
    'EmailGenerationChain',
    'EmailAnalysisChain',
    'BaseSequentialChain',
    'EmailProcessingChain',
    'BaseRouterChain',
    'EmailResponseRouterChain'
]
