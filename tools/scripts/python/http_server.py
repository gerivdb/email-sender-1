#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Serveur HTTP simple pour tester l'accessibilité du port 8000.
"""

import http.server
import socketserver

PORT = 8000

class SimpleHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'Hello, world!')
    
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"result": 5}')

if __name__ == "__main__":
    print(f"Démarrage du serveur HTTP sur le port {PORT}...")
    with socketserver.TCPServer(("", PORT), SimpleHTTPRequestHandler) as httpd:
        print(f"Serveur en cours d'exécution sur le port {PORT}")
        httpd.serve_forever()
