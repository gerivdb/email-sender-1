package core

import (
	"context"
	"fmt"
	"sync"
)

// ContextManager gère la mémoire partagée et l'historique des dialogues pour l'orchestration IA.
type ContextManager struct {
	mu            sync.Mutex
	history       map[string][]string    // persona -> messages
	globalContext map[string]interface{} // Contexte global partagé
}

// NewContextManager initialise et retourne une nouvelle instance de ContextManager.
func NewContextManager() *ContextManager {
	return &ContextManager{
		history:       make(map[string][]string),
		globalContext: make(map[string]interface{}),
	}
}

// StoreDialogueHistory stocke un message dans l'historique de dialogue d'un persona spécifique.
func (cm *ContextManager) StoreDialogueHistory(persona, message string) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	cm.history[persona] = append(cm.history[persona], message)
	fmt.Printf("[ContextManager] Stored message for persona '%s': %s\n", persona, message)
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
	fmt.Printf("[ContextManager] Updated global context: %s = %v\n", key, value)
}

// ClearDialogueHistory efface l'historique de dialogue d'un persona ou de tous les personas.
func (cm *ContextManager) ClearDialogueHistory(persona string) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	if persona == "" {
		// Effacer tout l'historique si persona est vide
		cm.history = make(map[string][]string)
		fmt.Println("[ContextManager] Cleared all dialogue history.")
	} else {
		delete(cm.history, persona)
		fmt.Printf("[ContextManager] Cleared dialogue history for persona '%s'.\n", persona)
	}
}

// Agent Interface (pour référence et cohérence avec le plan)
// Cette interface serait implémentée par les agents IA réels.
type Agent interface {
	Process(ctx context.Context, agentContext map[string]interface{}, input string) (string, error)
	GetName() string
	SetContextManager(cm *ContextManager)
}
