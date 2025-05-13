---
to: <%= h.projectPath() %>/development/scripts/mcp/memories/<%= name %>.py
---
"""
Mémoire MCP <%= name %>.
<%= description || 'Cette mémoire fournit des fonctionnalités pour le MCP.' %>
"""

import os
import json
import time
import hashlib
from typing import List, Dict, Any, Optional, Union, Tuple
from datetime import datetime

<% if dependencies && dependencies.length > 0 -%>
<% dependencies.forEach(function(dep) { -%>
from <%= dep %> import *
<% }) -%>
<% } -%>


class <%= h.changeCase.pascal(name) %>Memory:
    """
    Mémoire <%= h.changeCase.sentence(name) %>.
    """
    
    def __init__(self<% if options && options.length > 0 -%>, <% options.forEach(function(opt, i) { -%><%= opt.name %>: <%= opt.type %><%= opt.default ? ` = ${opt.default}` : '' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%><% } -%>):
        """
        Initialise la mémoire <%= h.changeCase.sentence(name) %>.
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
        self.memories: Dict[str, Dict[str, Any]] = {}
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
        # TODO: Implémenter <%= method.name %>
        pass
    <% }) -%>
    <% } -%>
    
    def add_memory(self, content: str, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        Ajoute une mémoire.
        
        Args:
            content: Contenu de la mémoire.
            metadata: Métadonnées associées à la mémoire.
            
        Returns:
            Identifiant de la mémoire.
        """
        # Générer un identifiant unique
        memory_id = self._generate_id(content)
        
        # Créer la mémoire
        memory = {
            "id": memory_id,
            "content": content,
            "metadata": metadata or {},
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
        
        # Ajouter la mémoire
        self.memories[memory_id] = memory
        
        return memory_id
    
    def get_memory(self, memory_id: str) -> Optional[Dict[str, Any]]:
        """
        Récupère une mémoire.
        
        Args:
            memory_id: Identifiant de la mémoire.
            
        Returns:
            Mémoire ou None si non trouvée.
        """
        return self.memories.get(memory_id)
    
    def update_memory(self, memory_id: str, content: Optional[str] = None, metadata: Optional[Dict[str, Any]] = None) -> bool:
        """
        Met à jour une mémoire.
        
        Args:
            memory_id: Identifiant de la mémoire.
            content: Nouveau contenu de la mémoire.
            metadata: Nouvelles métadonnées de la mémoire.
            
        Returns:
            True si la mémoire a été mise à jour, False sinon.
        """
        # Vérifier si la mémoire existe
        if memory_id not in self.memories:
            return False
        
        # Mettre à jour la mémoire
        if content is not None:
            self.memories[memory_id]["content"] = content
        
        if metadata is not None:
            self.memories[memory_id]["metadata"].update(metadata)
        
        # Mettre à jour la date de mise à jour
        self.memories[memory_id]["updated_at"] = datetime.now().isoformat()
        
        return True
    
    def delete_memory(self, memory_id: str) -> bool:
        """
        Supprime une mémoire.
        
        Args:
            memory_id: Identifiant de la mémoire.
            
        Returns:
            True si la mémoire a été supprimée, False sinon.
        """
        if memory_id in self.memories:
            del self.memories[memory_id]
            return True
        return False
    
    def list_memories(self, filter_func: Optional[callable] = None) -> List[Dict[str, Any]]:
        """
        Liste les mémoires.
        
        Args:
            filter_func: Fonction de filtrage.
            
        Returns:
            Liste des mémoires.
        """
        if filter_func:
            return [memory for memory in self.memories.values() if filter_func(memory)]
        return list(self.memories.values())
    
    def _generate_id(self, content: str) -> str:
        """
        Génère un identifiant unique pour une mémoire.
        
        Args:
            content: Contenu de la mémoire.
            
        Returns:
            Identifiant unique.
        """
        # Générer un hash du contenu
        hash_obj = hashlib.md5(content.encode())
        hash_hex = hash_obj.hexdigest()
        
        # Générer un timestamp
        timestamp = int(time.time())
        
        # Combiner le hash et le timestamp
        return f"mem_{hash_hex[:10]}_{timestamp}"


def create_memory(<% if options && options.length > 0 -%><% options.forEach(function(opt, i) { -%><%= opt.name %>: <%= opt.type %><%= opt.default ? ` = ${opt.default}` : '' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%><% } -%>) -> <%= h.changeCase.pascal(name) %>Memory:
    """
    Crée une instance de la mémoire <%= h.changeCase.sentence(name) %>.
    <% if options && options.length > 0 -%>
    
    Args:
    <% options.forEach(function(opt) { -%>
        <%= opt.name %>: <%= opt.description || `Paramètre ${opt.name}.` %>
    <% }) -%>
    <% } -%>
    
    Returns:
        Instance de la mémoire <%= h.changeCase.sentence(name) %>.
    """
    return <%= h.changeCase.pascal(name) %>Memory(<% if options && options.length > 0 -%><% options.forEach(function(opt, i) { -%><%= opt.name %><%= i < options.length - 1 ? ', ' : '' %><% }) -%><% } -%>)


<% if includeTest -%>
def test_<%= name %>_memory():
    """
    Test pour la mémoire <%= h.changeCase.sentence(name) %>.
    """
    # Créer la mémoire
    memory = create_memory(<% if options && options.length > 0 -%><% options.forEach(function(opt, i) { -%><%= opt.default || 'None' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%><% } -%>)
    
    # Ajouter une mémoire
    memory_id = memory.add_memory("Test memory", {"source": "test"})
    print(f"Mémoire ajoutée avec l'ID: {memory_id}")
    
    # Récupérer la mémoire
    mem = memory.get_memory(memory_id)
    print(f"Contenu: {mem['content']}")
    print(f"Métadonnées: {mem['metadata']}")
    
    # Mettre à jour la mémoire
    memory.update_memory(memory_id, "Updated memory", {"updated": True})
    mem = memory.get_memory(memory_id)
    print(f"Contenu mis à jour: {mem['content']}")
    print(f"Métadonnées mises à jour: {mem['metadata']}")
    
    # Lister les mémoires
    memories = memory.list_memories()
    print(f"Nombre de mémoires: {len(memories)}")
    
    # Supprimer la mémoire
    memory.delete_memory(memory_id)
    print(f"Mémoire supprimée: {memory.get_memory(memory_id) is None}")


if __name__ == "__main__":
    test_<%= name %>_memory()
<% } -%>
