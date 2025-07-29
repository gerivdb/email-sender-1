// Package modemanager définit l’interface et les structures de base pour la gestion centralisée des modes d’exécution ou de configuration documentaire.
package modemanager

import (
	"time"
)

// NavigationMode représente un mode d’exécution ou de configuration.
type NavigationMode string

// ModeConfig contient la configuration d’un mode donné.
type ModeConfig struct {
	Nom         NavigationMode         // Nom du mode
	Options     map[string]interface{} // Options spécifiques au mode
	Description string                 // Description du mode
}

// ModeTransition représente une transition entre deux modes.
type ModeTransition struct {
	De        NavigationMode     // Mode source
	Vers      NavigationMode     // Mode cible
	Timestamp time.Time          // Date et heure de la transition
	Options   *TransitionOptions // Options de transition utilisées
}

// TransitionOptions contient les options avancées pour une transition de mode.
type TransitionOptions struct {
	Animation   string                 // Type d’animation ou effet de transition
	Préférences map[string]interface{} // Préférences spécifiques à la transition
}

// ModeState représente l’état d’un mode à un instant donné.
type ModeState struct {
	Mode      NavigationMode         // Mode concerné
	État      map[string]interface{} // Données d’état sérialisées
	Timestamp time.Time              // Date de capture de l’état
}

// ModePreferences regroupe les préférences utilisateur liées aux modes.
type ModePreferences struct {
	Préférences map[string]interface{}
}

// ModeEventType définit le type d’événement lié aux modes.
type ModeEventType string

// ModeEventHandler est une fonction de gestion d’événement de mode.
type ModeEventHandler func(eventType ModeEventType, data map[string]interface{})

// ModeManager définit l’interface centrale de gestion des modes.
type ModeManager interface {
	// SwitchMode effectue un changement de mode simple.
	// Retourne une commande UI (tea.Cmd) pour la gestion asynchrone.
	SwitchMode(targetMode NavigationMode) interface{}

	// SwitchModeAdvanced effectue un changement de mode avec options avancées.
	// Retourne une commande UI (tea.Cmd) pour la gestion asynchrone.
	SwitchModeAdvanced(targetMode NavigationMode, options *TransitionOptions) interface{}

	// GetCurrentMode retourne le mode actuellement actif.
	GetCurrentMode() NavigationMode

	// GetModeConfig retourne la configuration d’un mode donné.
	GetModeConfig(mode NavigationMode) (*ModeConfig, error)

	// UpdateModeConfig met à jour la configuration d’un mode.
	UpdateModeConfig(mode NavigationMode, config *ModeConfig) error

	// GetModeState retourne l’état courant d’un mode.
	GetModeState(mode NavigationMode) (*ModeState, error)

	// RestoreState restaure un état de mode donné.
	// Retourne une commande UI (tea.Cmd) pour la gestion asynchrone.
	RestoreState(state *ModeState) interface{}

	// AddEventHandler ajoute un gestionnaire d’événement pour un mode.
	AddEventHandler(mode NavigationMode, handler ModeEventHandler) error

	// TriggerEvent déclenche un événement de mode.
	// Retourne une liste de commandes UI (tea.Cmd) à exécuter.
	TriggerEvent(eventType ModeEventType, data map[string]interface{}) []interface{}

	// GetAvailableModes retourne la liste des modes disponibles.
	GetAvailableModes() []NavigationMode

	// GetTransitionHistory retourne l’historique des transitions de mode.
	GetTransitionHistory() []ModeTransition

	// SetPreferences définit les préférences utilisateur liées aux modes.
	SetPreferences(prefs *ModePreferences)

	// GetPreferences retourne les préférences utilisateur liées aux modes.
	GetPreferences() *ModePreferences
}
