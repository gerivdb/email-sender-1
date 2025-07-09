# Interfaces IA mises à jour pour Jan

Ce document décrit les prototypes d'interface pour l'interaction avec les agents IA, adaptés à l'orchestration séquentielle via Jan et le ContextManager.

## Interface `Agent` (Go)
L'interface `Agent` définit les méthodes que tout agent IA doit implémenter pour être compatible avec l'orchestration Jan.
```go
package core

import (
    "context"
)

type Agent interface {
    // Process exécute la logique de l'agent.
    // Le 'ctx' Go context permet d'annuler l'opération.
    // Le 'agentContext' est un map[string]interface{} contenant le contexte spécifique à l'exécution actuelle de l'agent,
    // incluant l'historique de dialogue et les données du ContextManager.
    // Le 'input' est le message ou la tâche que l'agent doit traiter.
    // La fonction retourne le résultat de l'agent et une erreur si applicable.
    Process(ctx context.Context, agentContext map[string]interface{}, input string) (string, error)

    // GetName retourne le nom unique de l'agent.
    GetName() string

    // SetContextManager permet d'injecter une instance du ContextManager dans l'agent.
    SetContextManager(cm *ContextManager)
}
```

## Structure `ContextManager` (Go)
La structure `ContextManager` gère la mémoire partagée et l'historique des dialogues.
```go
package core

import (
    "sync"
)

type ContextManager struct {
    mu       sync.Mutex
    history  map[string][]string       // persona -> messages
    globalContext map[string]interface{} // Contexte global partagé
}

// NewContextManager initialise et retourne une nouvelle instance de ContextManager.
func NewContextManager() *ContextManager {
    return &ContextManager{
        history:      make(map[string][]string),
        globalContext: make(map[string]interface{}),
    }
}

// StoreDialogueHistory stocke un message dans l'historique de dialogue d'un persona spécifique.
func (cm *ContextManager) StoreDialogueHistory(persona, message string) {
    cm.mu.Lock()
    defer cm.mu.Unlock()
    cm.history[persona] = append(cm.history[persona], message)
}

// GetDialogueContext récupère les 'n' derniers messages de l'historique de dialogue d'un persona.
func (cm *ContextManager) GetDialogueContext(persona string, n int) []string {
    cm.mu.Lock()
    defer cm.mu.Unlock()
    h := cm.history[persona]
    if len(h) > n {
        return h[len(h)-n:]
    }
    return h
}

// GetGlobalContext récupère le contexte global partagé entre tous les personas.
func (cm *ContextManager) GetGlobalContext() map[string]interface{} {
    cm.mu.Lock()
    defer cm.mu.Unlock()
    // Retourne une copie pour éviter les modifications externes directes
    copyMap := make(map[string]interface{})
    for k, v := range cm.globalContext {
        copyMap[k] = v
    }
    return copyMap
}

// UpdateGlobalContext met à jour le contexte global partagé avec de nouvelles données.
func (cm *ContextManager) UpdateGlobalContext(key string, value interface{}) {
    cm.mu.Lock()
    defer cm.mu.Unlock()
    cm.globalContext[key] = value
}

// ClearDialogueHistory efface l'historique de dialogue d'un persona ou de tous les personas.
func (cm *ContextManager) ClearDialogueHistory(persona string) {
    cm.mu.Lock()
    defer cm.mu.Unlock()
    if persona == "" {
        // Effacer tout l'historique si persona est vide
        cm.history = make(map[string][]string)
    } else {
        delete(cm.history, persona)
    }
}
```

## Critères de Validation
- Le fichier `interfaces_maj_jan.md` est généré.
- Les prototypes d'interface sont clairement définis et incluent le `context.Context` et le contexte enrichi.
- La structure `ContextManager` et ses méthodes sont implémentées et documentées.
- Les interfaces sont prêtes pour l'intégration avec Jan.
