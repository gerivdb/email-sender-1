---
to: <%= h.projectPath() %>/development/scripts/mcp/servers/<%= name %>_server.py
---
"""
Serveur MCP <%= name %>.
<%= description || 'Ce serveur fournit des fonctionnalités MCP.' %>
"""

import os
import sys
import json
import time
import logging
from typing import List, Dict, Any, Optional, Union, Tuple
from flask import Flask, request, jsonify, Response

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger('<%= name %>-server')

# Créer l'application Flask
app = Flask(__name__)

# Configuration
CONFIG = {
    'port': <%= port || 5000 %>,
    'host': '<%= host || "0.0.0.0" %>',
    'debug': <%= debug || false %>,
    <% if config && Object.keys(config).length > 0 -%>
    <% Object.keys(config).forEach(function(key, i) { -%>
    '<%= key %>': <%= JSON.stringify(config[key]) %><%= i < Object.keys(config).length - 1 ? ',' : '' %>
    <% }) -%>
    <% } -%>
}


@app.route('/health', methods=['GET'])
def health_check():
    """
    Endpoint pour vérifier l'état du serveur.
    """
    return jsonify({
        'status': 'ok',
        'server': '<%= name %>',
        'timestamp': time.time()
    })


@app.route('/info', methods=['GET'])
def server_info():
    """
    Endpoint pour obtenir des informations sur le serveur.
    """
    return jsonify({
        'name': '<%= name %>',
        'description': '<%= description || "Serveur MCP" %>',
        'version': '1.0.0',
        'config': {k: v for k, v in CONFIG.items() if k != 'api_key'}
    })

<% if endpoints && endpoints.length > 0 -%>
<% endpoints.forEach(function(endpoint) { -%>

@app.route('<%= endpoint.path %>', methods=['<%= endpoint.method %>'])
def <%= endpoint.name %>(<%- endpoint.params ? endpoint.params.join(', ') : '' %>):
    """
    <%= endpoint.description || `Endpoint ${endpoint.path}` %>
    """
    <% if endpoint.method === 'POST' -%>
    data = request.json
    <% } -%>
    # TODO: Implémenter la logique pour <%= endpoint.name %>
    return jsonify({
        'status': 'success',
        'message': 'Not implemented yet'
    })
<% }) -%>
<% } -%>


def run_server():
    """
    Démarre le serveur.
    """
    logger.info(f"Démarrage du serveur <%= name %> sur {CONFIG['host']}:{CONFIG['port']}")
    app.run(
        host=CONFIG['host'],
        port=CONFIG['port'],
        debug=CONFIG['debug']
    )


if __name__ == "__main__":
    run_server()
