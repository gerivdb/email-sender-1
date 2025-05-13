---
to: <%= h.projectPath() %>/development/scripts/mcp/servers/github_server.py
---
"""
Serveur MCP pour GitHub.
Ce serveur fournit des fonctionnalités pour accéder à GitHub.
"""

import os
import sys
import json
import time
import logging
import base64
import requests
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
logger = logging.getLogger('github-server')

# Créer l'application Flask
app = Flask(__name__)

# Configuration
CONFIG = {
    'port': <%= port || 5002 %>,
    'host': '<%= host || "0.0.0.0" %>',
    'debug': <%= debug || false %>,
    'github_api_url': 'https://api.github.com',
    'github_token': os.environ.get('GITHUB_TOKEN', '<%= github_token || "" %>')
}


@app.route('/health', methods=['GET'])
def health_check():
    """
    Endpoint pour vérifier l'état du serveur.
    """
    return jsonify({
        'status': 'ok',
        'server': 'github',
        'timestamp': time.time()
    })


@app.route('/info', methods=['GET'])
def server_info():
    """
    Endpoint pour obtenir des informations sur le serveur.
    """
    return jsonify({
        'name': 'github',
        'description': 'Serveur MCP pour GitHub',
        'version': '1.0.0',
        'config': {
            'port': CONFIG['port'],
            'host': CONFIG['host'],
            'debug': CONFIG['debug'],
            'github_api_url': CONFIG['github_api_url'],
            'github_token': CONFIG['github_token'] and '***'
        }
    })


@app.route('/repos', methods=['GET'])
def list_repos():
    """
    Liste les dépôts GitHub.
    
    Query parameters:
        username: Nom d'utilisateur GitHub.
        org: Organisation GitHub.
        visibility: Visibilité des dépôts (all, public, private).
    """
    username = request.args.get('username')
    org = request.args.get('org')
    visibility = request.args.get('visibility', 'all')
    
    if not username and not org:
        return jsonify({
            'status': 'error',
            'message': "Le paramètre 'username' ou 'org' est requis"
        }), 400
    
    # Construire l'URL
    if org:
        url = f"{CONFIG['github_api_url']}/orgs/{org}/repos"
    else:
        url = f"{CONFIG['github_api_url']}/users/{username}/repos"
    
    # Construire les paramètres
    params = {
        'type': visibility,
        'per_page': 100
    }
    
    # Construire les en-têtes
    headers = {
        'Accept': 'application/vnd.github.v3+json'
    }
    
    if CONFIG['github_token']:
        headers['Authorization'] = f"token {CONFIG['github_token']}"
    
    # Effectuer la requête
    try:
        response = requests.get(url, params=params, headers=headers)
        response.raise_for_status()
        
        repos = response.json()
        
        return jsonify({
            'status': 'success',
            'repos': repos
        })
    except requests.exceptions.RequestException as e:
        return jsonify({
            'status': 'error',
            'message': f"Erreur lors de la récupération des dépôts: {str(e)}"
        }), 500


@app.route('/repos/<owner>/<repo>', methods=['GET'])
def get_repo(owner, repo):
    """
    Récupère les informations d'un dépôt GitHub.
    
    Path parameters:
        owner: Propriétaire du dépôt.
        repo: Nom du dépôt.
    """
    # Construire l'URL
    url = f"{CONFIG['github_api_url']}/repos/{owner}/{repo}"
    
    # Construire les en-têtes
    headers = {
        'Accept': 'application/vnd.github.v3+json'
    }
    
    if CONFIG['github_token']:
        headers['Authorization'] = f"token {CONFIG['github_token']}"
    
    # Effectuer la requête
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        repo_info = response.json()
        
        return jsonify({
            'status': 'success',
            'repo': repo_info
        })
    except requests.exceptions.RequestException as e:
        return jsonify({
            'status': 'error',
            'message': f"Erreur lors de la récupération du dépôt: {str(e)}"
        }), 500


@app.route('/repos/<owner>/<repo>/contents/<path:file_path>', methods=['GET'])
def get_content(owner, repo, file_path):
    """
    Récupère le contenu d'un fichier dans un dépôt GitHub.
    
    Path parameters:
        owner: Propriétaire du dépôt.
        repo: Nom du dépôt.
        file_path: Chemin du fichier.
        
    Query parameters:
        ref: Référence (branche, tag, commit).
    """
    ref = request.args.get('ref')
    
    # Construire l'URL
    url = f"{CONFIG['github_api_url']}/repos/{owner}/{repo}/contents/{file_path}"
    
    # Construire les paramètres
    params = {}
    if ref:
        params['ref'] = ref
    
    # Construire les en-têtes
    headers = {
        'Accept': 'application/vnd.github.v3+json'
    }
    
    if CONFIG['github_token']:
        headers['Authorization'] = f"token {CONFIG['github_token']}"
    
    # Effectuer la requête
    try:
        response = requests.get(url, params=params, headers=headers)
        response.raise_for_status()
        
        content_info = response.json()
        
        # Si c'est un répertoire, retourner la liste des fichiers
        if isinstance(content_info, list):
            return jsonify({
                'status': 'success',
                'path': file_path,
                'type': 'directory',
                'contents': content_info
            })
        
        # Si c'est un fichier, retourner le contenu
        if content_info['type'] == 'file':
            content = base64.b64decode(content_info['content']).decode('utf-8')
            return jsonify({
                'status': 'success',
                'path': file_path,
                'type': 'file',
                'content': content,
                'encoding': 'utf-8',
                'sha': content_info['sha']
            })
        
        # Autre type (symlink, submodule)
        return jsonify({
            'status': 'success',
            'path': file_path,
            'type': content_info['type'],
            'content': content_info
        })
    except requests.exceptions.RequestException as e:
        return jsonify({
            'status': 'error',
            'message': f"Erreur lors de la récupération du contenu: {str(e)}"
        }), 500


@app.route('/repos/<owner>/<repo>/branches', methods=['GET'])
def list_branches(owner, repo):
    """
    Liste les branches d'un dépôt GitHub.
    
    Path parameters:
        owner: Propriétaire du dépôt.
        repo: Nom du dépôt.
    """
    # Construire l'URL
    url = f"{CONFIG['github_api_url']}/repos/{owner}/{repo}/branches"
    
    # Construire les en-têtes
    headers = {
        'Accept': 'application/vnd.github.v3+json'
    }
    
    if CONFIG['github_token']:
        headers['Authorization'] = f"token {CONFIG['github_token']}"
    
    # Effectuer la requête
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        branches = response.json()
        
        return jsonify({
            'status': 'success',
            'branches': branches
        })
    except requests.exceptions.RequestException as e:
        return jsonify({
            'status': 'error',
            'message': f"Erreur lors de la récupération des branches: {str(e)}"
        }), 500


@app.route('/repos/<owner>/<repo>/commits', methods=['GET'])
def list_commits(owner, repo):
    """
    Liste les commits d'un dépôt GitHub.
    
    Path parameters:
        owner: Propriétaire du dépôt.
        repo: Nom du dépôt.
        
    Query parameters:
        sha: SHA ou nom de branche.
        path: Chemin du fichier.
        author: Auteur du commit.
        since: Date de début (ISO 8601).
        until: Date de fin (ISO 8601).
    """
    sha = request.args.get('sha')
    path = request.args.get('path')
    author = request.args.get('author')
    since = request.args.get('since')
    until = request.args.get('until')
    
    # Construire l'URL
    url = f"{CONFIG['github_api_url']}/repos/{owner}/{repo}/commits"
    
    # Construire les paramètres
    params = {}
    if sha:
        params['sha'] = sha
    if path:
        params['path'] = path
    if author:
        params['author'] = author
    if since:
        params['since'] = since
    if until:
        params['until'] = until
    
    # Construire les en-têtes
    headers = {
        'Accept': 'application/vnd.github.v3+json'
    }
    
    if CONFIG['github_token']:
        headers['Authorization'] = f"token {CONFIG['github_token']}"
    
    # Effectuer la requête
    try:
        response = requests.get(url, params=params, headers=headers)
        response.raise_for_status()
        
        commits = response.json()
        
        return jsonify({
            'status': 'success',
            'commits': commits
        })
    except requests.exceptions.RequestException as e:
        return jsonify({
            'status': 'error',
            'message': f"Erreur lors de la récupération des commits: {str(e)}"
        }), 500


@app.route('/search/code', methods=['GET'])
def search_code():
    """
    Recherche du code sur GitHub.
    
    Query parameters:
        q: Requête de recherche.
        sort: Tri des résultats (indexed, best-match).
        order: Ordre de tri (asc, desc).
    """
    q = request.args.get('q')
    sort = request.args.get('sort', 'best-match')
    order = request.args.get('order', 'desc')
    
    if not q:
        return jsonify({
            'status': 'error',
            'message': "Le paramètre 'q' est requis"
        }), 400
    
    # Construire l'URL
    url = f"{CONFIG['github_api_url']}/search/code"
    
    # Construire les paramètres
    params = {
        'q': q,
        'sort': sort,
        'order': order
    }
    
    # Construire les en-têtes
    headers = {
        'Accept': 'application/vnd.github.v3+json'
    }
    
    if CONFIG['github_token']:
        headers['Authorization'] = f"token {CONFIG['github_token']}"
    
    # Effectuer la requête
    try:
        response = requests.get(url, params=params, headers=headers)
        response.raise_for_status()
        
        search_results = response.json()
        
        return jsonify({
            'status': 'success',
            'query': q,
            'results': search_results
        })
    except requests.exceptions.RequestException as e:
        return jsonify({
            'status': 'error',
            'message': f"Erreur lors de la recherche de code: {str(e)}"
        }), 500


def run_server():
    """
    Démarre le serveur.
    """
    logger.info(f"Démarrage du serveur GitHub sur {CONFIG['host']}:{CONFIG['port']}")
    app.run(
        host=CONFIG['host'],
        port=CONFIG['port'],
        debug=CONFIG['debug']
    )


if __name__ == "__main__":
    run_server()
