#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'initialisation pour les LLMChains.

Ce module expose les classes et fonctions principales du package llm_chains.
"""

from .base_llm_chain import BaseLLMChain
from .email_generation_chain import EmailGenerationChain
from .email_analysis_chain import EmailAnalysisChain

__all__ = ['BaseLLMChain', 'EmailGenerationChain', 'EmailAnalysisChain']
