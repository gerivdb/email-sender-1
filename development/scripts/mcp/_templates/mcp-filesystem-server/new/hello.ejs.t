---
to: <%= h.projectPath() %>/development/scripts/mcp/servers/filesystem_server.py
---
"""
Serveur MCP pour le système de fichiers.
Ce serveur fournit des fonctionnalités pour accéder au système de fichiers.
"""

import os
import sys
import json
import time
import logging
import base64
from typing import List, Dict, Any, Optional, Union, Tuple
from flask import Flask, request, jsonify, Response, send_file
from werkzeug.utils import secure_filename

# Configurer le logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger('filesystem-server')

# Créer l'application Flask
app = Flask(__name__)

# Configuration
CONFIG = {
    'port': <%= port || 5001 %>,
    'host': '<%= host || "0.0.0.0" %>',
    'debug': <%= debug || false %>,
    'root_dir': '<%= root_dir || "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1" %>',
    'allowed_extensions': ['txt', 'md', 'json', 'yaml', 'yml', 'py', 'js', 'html', 'css', 'ps1']
}


@app.route('/health', methods=['GET'])
def health_check():
    """
    Endpoint pour vérifier l'état du serveur.
    """
    return jsonify({
        'status': 'ok',
        'server': 'filesystem',
        'timestamp': time.time()
    })


@app.route('/info', methods=['GET'])
def server_info():
    """
    Endpoint pour obtenir des informations sur le serveur.
    """
    return jsonify({
        'name': 'filesystem',
        'description': 'Serveur MCP pour le système de fichiers',
        'version': '1.0.0',
        'config': {
            'port': CONFIG['port'],
            'host': CONFIG['host'],
            'debug': CONFIG['debug'],
            'root_dir': CONFIG['root_dir'],
            'allowed_extensions': CONFIG['allowed_extensions']
        }
    })


@app.route('/files', methods=['GET'])
def list_files():
    """
    Liste les fichiers dans un répertoire.
    
    Query parameters:
        path: Chemin relatif au répertoire racine.
        recursive: Si True, liste les fichiers de manière récursive.
    """
    path = request.args.get('path', '')
    recursive = request.args.get('recursive', 'false').lower() == 'true'
    
    # Construire le chemin absolu
    abs_path = os.path.join(CONFIG['root_dir'], path)
    
    # Vérifier si le chemin existe
    if not os.path.exists(abs_path):
        return jsonify({
            'status': 'error',
            'message': f"Le chemin '{path}' n'existe pas"
        }), 404
    
    # Vérifier si le chemin est un répertoire
    if not os.path.isdir(abs_path):
        return jsonify({
            'status': 'error',
            'message': f"Le chemin '{path}' n'est pas un répertoire"
        }), 400
    
    # Lister les fichiers
    files = []
    if recursive:
        for root, dirs, filenames in os.walk(abs_path):
            for filename in filenames:
                file_path = os.path.join(root, filename)
                rel_path = os.path.relpath(file_path, CONFIG['root_dir'])
                files.append({
                    'name': filename,
                    'path': rel_path,
                    'size': os.path.getsize(file_path),
                    'modified': os.path.getmtime(file_path),
                    'is_dir': False
                })
            for dirname in dirs:
                dir_path = os.path.join(root, dirname)
                rel_path = os.path.relpath(dir_path, CONFIG['root_dir'])
                files.append({
                    'name': dirname,
                    'path': rel_path,
                    'modified': os.path.getmtime(dir_path),
                    'is_dir': True
                })
    else:
        for item in os.listdir(abs_path):
            item_path = os.path.join(abs_path, item)
            rel_path = os.path.relpath(item_path, CONFIG['root_dir'])
            if os.path.isdir(item_path):
                files.append({
                    'name': item,
                    'path': rel_path,
                    'modified': os.path.getmtime(item_path),
                    'is_dir': True
                })
            else:
                files.append({
                    'name': item,
                    'path': rel_path,
                    'size': os.path.getsize(item_path),
                    'modified': os.path.getmtime(item_path),
                    'is_dir': False
                })
    
    return jsonify({
        'status': 'success',
        'path': path,
        'files': files
    })


@app.route('/files/<path:file_path>', methods=['GET'])
def get_file(file_path):
    """
    Récupère le contenu d'un fichier.
    
    Path parameters:
        file_path: Chemin relatif au fichier.
        
    Query parameters:
        format: Format de retour (text, binary, base64).
    """
    format_type = request.args.get('format', 'text')
    
    # Construire le chemin absolu
    abs_path = os.path.join(CONFIG['root_dir'], file_path)
    
    # Vérifier si le fichier existe
    if not os.path.exists(abs_path):
        return jsonify({
            'status': 'error',
            'message': f"Le fichier '{file_path}' n'existe pas"
        }), 404
    
    # Vérifier si le chemin est un fichier
    if not os.path.isfile(abs_path):
        return jsonify({
            'status': 'error',
            'message': f"Le chemin '{file_path}' n'est pas un fichier"
        }), 400
    
    # Récupérer le contenu du fichier
    if format_type == 'binary':
        return send_file(abs_path)
    elif format_type == 'base64':
        with open(abs_path, 'rb') as f:
            content = base64.b64encode(f.read()).decode('utf-8')
        return jsonify({
            'status': 'success',
            'path': file_path,
            'content': content,
            'encoding': 'base64'
        })
    else:  # text
        try:
            with open(abs_path, 'r', encoding='utf-8') as f:
                content = f.read()
            return jsonify({
                'status': 'success',
                'path': file_path,
                'content': content,
                'encoding': 'utf-8'
            })
        except UnicodeDecodeError:
            # Si le fichier n'est pas en UTF-8, retourner en base64
            with open(abs_path, 'rb') as f:
                content = base64.b64encode(f.read()).decode('utf-8')
            return jsonify({
                'status': 'success',
                'path': file_path,
                'content': content,
                'encoding': 'base64'
            })


@app.route('/files/<path:file_path>', methods=['PUT'])
def update_file(file_path):
    """
    Met à jour le contenu d'un fichier.
    
    Path parameters:
        file_path: Chemin relatif au fichier.
        
    Body:
        content: Contenu du fichier.
        encoding: Encodage du contenu (utf-8, base64).
    """
    data = request.json
    
    if 'content' not in data:
        return jsonify({
            'status': 'error',
            'message': "Le paramètre 'content' est requis"
        }), 400
    
    content = data['content']
    encoding = data.get('encoding', 'utf-8')
    
    # Construire le chemin absolu
    abs_path = os.path.join(CONFIG['root_dir'], file_path)
    
    # Vérifier si le répertoire parent existe
    parent_dir = os.path.dirname(abs_path)
    if not os.path.exists(parent_dir):
        os.makedirs(parent_dir)
    
    # Écrire le contenu dans le fichier
    try:
        if encoding == 'base64':
            with open(abs_path, 'wb') as f:
                f.write(base64.b64decode(content))
        else:  # utf-8
            with open(abs_path, 'w', encoding='utf-8') as f:
                f.write(content)
        
        return jsonify({
            'status': 'success',
            'path': file_path,
            'message': f"Le fichier '{file_path}' a été mis à jour"
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f"Erreur lors de la mise à jour du fichier: {str(e)}"
        }), 500


@app.route('/files/<path:file_path>', methods=['DELETE'])
def delete_file(file_path):
    """
    Supprime un fichier.
    
    Path parameters:
        file_path: Chemin relatif au fichier.
    """
    # Construire le chemin absolu
    abs_path = os.path.join(CONFIG['root_dir'], file_path)
    
    # Vérifier si le fichier existe
    if not os.path.exists(abs_path):
        return jsonify({
            'status': 'error',
            'message': f"Le fichier '{file_path}' n'existe pas"
        }), 404
    
    # Supprimer le fichier
    try:
        if os.path.isdir(abs_path):
            os.rmdir(abs_path)
        else:
            os.remove(abs_path)
        
        return jsonify({
            'status': 'success',
            'path': file_path,
            'message': f"Le fichier '{file_path}' a été supprimé"
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f"Erreur lors de la suppression du fichier: {str(e)}"
        }), 500


@app.route('/search', methods=['GET'])
def search_files():
    """
    Recherche des fichiers.
    
    Query parameters:
        query: Terme de recherche.
        path: Chemin relatif au répertoire racine.
        extensions: Extensions de fichiers à rechercher (séparées par des virgules).
    """
    query = request.args.get('query', '')
    path = request.args.get('path', '')
    extensions = request.args.get('extensions', '')
    
    if not query:
        return jsonify({
            'status': 'error',
            'message': "Le paramètre 'query' est requis"
        }), 400
    
    # Construire le chemin absolu
    abs_path = os.path.join(CONFIG['root_dir'], path)
    
    # Vérifier si le chemin existe
    if not os.path.exists(abs_path):
        return jsonify({
            'status': 'error',
            'message': f"Le chemin '{path}' n'existe pas"
        }), 404
    
    # Vérifier si le chemin est un répertoire
    if not os.path.isdir(abs_path):
        return jsonify({
            'status': 'error',
            'message': f"Le chemin '{path}' n'est pas un répertoire"
        }), 400
    
    # Filtrer les extensions
    if extensions:
        allowed_extensions = extensions.split(',')
    else:
        allowed_extensions = CONFIG['allowed_extensions']
    
    # Rechercher les fichiers
    results = []
    for root, dirs, filenames in os.walk(abs_path):
        for filename in filenames:
            if '.' in filename and filename.split('.')[-1] in allowed_extensions:
                file_path = os.path.join(root, filename)
                rel_path = os.path.relpath(file_path, CONFIG['root_dir'])
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    if query.lower() in content.lower() or query.lower() in filename.lower():
                        results.append({
                            'name': filename,
                            'path': rel_path,
                            'size': os.path.getsize(file_path),
                            'modified': os.path.getmtime(file_path)
                        })
                except:
                    # Ignorer les fichiers qui ne peuvent pas être lus
                    pass
    
    return jsonify({
        'status': 'success',
        'query': query,
        'path': path,
        'results': results
    })


def run_server():
    """
    Démarre le serveur.
    """
    logger.info(f"Démarrage du serveur filesystem sur {CONFIG['host']}:{CONFIG['port']}")
    app.run(
        host=CONFIG['host'],
        port=CONFIG['port'],
        debug=CONFIG['debug']
    )


if __name__ == "__main__":
    run_server()
