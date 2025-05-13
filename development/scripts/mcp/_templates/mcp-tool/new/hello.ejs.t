---
to: <%= h.projectPath() %>/development/scripts/mcp/tools/<%= name %>.py
---
"""
Outil MCP <%= name %>.
<%= description || 'Cet outil fournit des fonctionnalités pour le MCP.' %>
"""

import os
import json
import logging
from typing import List, Dict, Any, Optional, Union, Tuple

<% if dependencies && dependencies.length > 0 -%>
<% dependencies.forEach(function(dep) { -%>
from <%= dep %> import *
<% }) -%>
<% } -%>

# Configurer le logging
logger = logging.getLogger('mcp.tools.<%= name %>')


class <%= h.changeCase.pascal(name) %>Tool:
    """
    Outil <%= h.changeCase.sentence(name) %>.
    """
    
    def __init__(self<% if options && options.length > 0 -%>, <% options.forEach(function(opt, i) { -%><%= opt.name %>: <%= opt.type %><%= opt.default ? ` = ${opt.default}` : '' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%><% } -%>):
        """
        Initialise l'outil <%= h.changeCase.sentence(name) %>.
        <% if options && options.length > 0 -%>
        
        Args:
        <% options.forEach(function(opt) { -%>
            <%= opt.name %>: <%= opt.description || `Paramètre ${opt.name}.` %>
        <% }) -%>
        <% } -%>
        """
        <% if options && options.length > 0 -%>
        <% options.forEach(function(opt) { -%>
        self.<%= opt.name %> = <%= opt.name %>
        <% }) -%>
        <% } -%>
        logger.info(f"Outil <%= h.changeCase.sentence(name) %> initialisé")
    <% if methods && methods.length > 0 -%>
    <% methods.forEach(function(method) { -%>
    
    def <%= method.name %>(self<% if method.params && method.params.length > 0 -%>, <% method.params.forEach(function(param, i) { -%><%= param.name %>: <%= param.type %><%= param.default ? ` = ${param.default}` : '' %><%= i < method.params.length - 1 ? ', ' : '' %><% }) -%><% } -%>) -> <%= method.returnType || 'None' %>:
        """
        <%= method.description || `Méthode ${method.name}.` %>
        <% if method.params && method.params.length > 0 -%>
        
        Args:
        <% method.params.forEach(function(param) { -%>
            <%= param.name %>: <%= param.description || `Paramètre ${param.name}.` %>
        <% }) -%>
        <% } -%>
        <% if method.returnType && method.returnType !== 'None' -%>
        
        Returns:
            <%= method.returnDescription || `Résultat de ${method.name}.` %>
        <% } -%>
        """
        logger.debug(f"Exécution de <%= method.name %>")
        # TODO: Implémenter <%= method.name %>
        pass
    <% }) -%>
    <% } -%>
    
    def get_tool_info(self) -> Dict[str, Any]:
        """
        Récupère les informations sur l'outil.
        
        Returns:
            Dictionnaire contenant les informations sur l'outil.
        """
        return {
            "name": "<%= name %>",
            "description": "<%= description || 'Outil MCP' %>",
            "version": "1.0.0",
            <% if methods && methods.length > 0 -%>
            "methods": [
                <% methods.forEach(function(method, i) { -%>
                {
                    "name": "<%= method.name %>",
                    "description": "<%= method.description || `Méthode ${method.name}` %>"
                }<%= i < methods.length - 1 ? ',' : '' %>
                <% }) -%>
            ]
            <% } else { -%>
            "methods": []
            <% } -%>
        }


def create_tool(<% if options && options.length > 0 -%><% options.forEach(function(opt, i) { -%><%= opt.name %>: <%= opt.type %><%= opt.default ? ` = ${opt.default}` : '' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%><% } -%>) -> <%= h.changeCase.pascal(name) %>Tool:
    """
    Crée une instance de l'outil <%= h.changeCase.sentence(name) %>.
    <% if options && options.length > 0 -%>
    
    Args:
    <% options.forEach(function(opt) { -%>
        <%= opt.name %>: <%= opt.description || `Paramètre ${opt.name}.` %>
    <% }) -%>
    <% } -%>
    
    Returns:
        Instance de l'outil <%= h.changeCase.sentence(name) %>.
    """
    return <%= h.changeCase.pascal(name) %>Tool(<% if options && options.length > 0 -%><% options.forEach(function(opt, i) { -%><%= opt.name %><%= i < options.length - 1 ? ', ' : '' %><% }) -%><% } -%>)


<% if includeTest -%>
def test_<%= name %>_tool():
    """
    Test pour l'outil <%= h.changeCase.sentence(name) %>.
    """
    # Créer l'outil
    tool = create_tool(<% if options && options.length > 0 -%><% options.forEach(function(opt, i) { -%><%= opt.default || 'None' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%><% } -%>)
    
    # Récupérer les informations sur l'outil
    info = tool.get_tool_info()
    print(f"Outil: {info['name']}")
    print(f"Description: {info['description']}")
    print(f"Version: {info['version']}")
    print(f"Méthodes: {len(info['methods'])}")
    
    # TODO: Tester les méthodes de l'outil


if __name__ == "__main__":
    test_<%= name %>_tool()
<% } -%>
