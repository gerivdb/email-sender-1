#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'initialisation pour le package langchain.

Ce module expose les classes et fonctions principales du package langchain.
"""

from src.langchain.chains import (
    BaseLLMChain,
    EmailGenerationChain,
    EmailAnalysisChain,
    BaseSequentialChain,
    EmailProcessingChain,
    BaseRouterChain,
    EmailResponseRouterChain
)

from src.langchain.agents import (
    BaseAgent,
    GitHubAnalysisAgent,
    ServerDiagnosticAgent,
    PerformanceAnalysisAgent
)

from src.langchain.tools import (
    GitHubTools,
    ServerDiagnosticTools,
    PerformanceAnalysisTools,
    CodeAnalysisTools,
    DocumentationTools,
    RecommendationTools
)

__all__ = [
    # Chains
    'BaseLLMChain',
    'EmailGenerationChain',
    'EmailAnalysisChain',
    'BaseSequentialChain',
    'EmailProcessingChain',
    'BaseRouterChain',
    'EmailResponseRouterChain',

    # Agents
    'BaseAgent',
    'GitHubAnalysisAgent',
    'ServerDiagnosticAgent',
    'PerformanceAnalysisAgent',

    # Tools
    'GitHubTools',
    'ServerDiagnosticTools',
    'PerformanceAnalysisTools',
    'CodeAnalysisTools',
    'DocumentationTools',
    'RecommendationTools'
]
