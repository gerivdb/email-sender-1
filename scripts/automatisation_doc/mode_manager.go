// SPDX-License-Identifier: MIT
// ModeManager Roo — Gestion centralisée des modes d’exécution documentaire
package automatisation_doc

import (
	"fmt"
	"sync"
	"time"
)

// Types de base
type NavigationMode string
type ModeEventType string

type ModeConfig struct {
	Mode    NavigationMode
	Enabled bool
	Options map[string]interface{}
}

type ModeState struct {
	Mode      NavigationMode
	Timestamp time.Time
	Data      map[string]interface{}
}

type ModeTransition struct {
	From      NavigationMode
	To        NavigationMode
	Timestamp time.Time
}

type ModePreferences struct {
	DefaultMode NavigationMode
	HistorySize int
}

type ModeMetrics struct {
	TotalTransitions int
	TransitionCounts map[NavigationMode]int
	ErrorCounts      map[string]int
	LastMetricsReset time.Time
}

type ModeEvent struct {
	Type      ModeEventType
	Mode      NavigationMode
	Data      map[string]interface{}
	Timestamp time.Time
	Source    string
}

type ModeEventHandler func(event ModeEvent) interface{}

// ModeManager Roo
type ModeManager struct {
	currentMode     NavigationMode
	modes           map[NavigationMode]*ModeConfig
	stateHistory    map[NavigationMode]*ModeState
	transitionQueue []ModeTransition
	mutex           sync.RWMutex
	eventHandlers   map[NavigationMode][]ModeEventHandler
	preferences     *ModePreferences
	metrics         *ModeMetrics
}

// Initialisation
func NewModeManager() *ModeManager {
	mm := &ModeManager{
		currentMode:     "normal",
		modes:           make(map[NavigationMode]*ModeConfig),
		stateHistory:    make(map[NavigationMode]*ModeState),
		transitionQueue: make([]ModeTransition, 0),
		eventHandlers:   make(map[NavigationMode][]ModeEventHandler),
		preferences:     &ModePreferences{DefaultMode: "normal", HistorySize: 10},
		metrics:         &ModeMetrics{TransitionCounts: make(map[NavigationMode]int), ErrorCounts: make(map[string]int), LastMetricsReset: time.Now()},
	}
	mm.modes["normal"] = &ModeConfig{Mode: "normal", Enabled: true}
	return mm
}

// Changement de mode
func (mm *ModeManager) SwitchMode(targetMode NavigationMode) error {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()
	if _, ok := mm.modes[targetMode]; !ok {
		return fmt.Errorf("mode inconnu: %s", targetMode)
	}
	if mm.currentMode == targetMode {
		return nil
	}
	mm.transitionQueue = append(mm.transitionQueue, ModeTransition{From: mm.currentMode, To: targetMode, Timestamp: time.Now()})
	mm.metrics.TotalTransitions++
	mm.metrics.TransitionCounts[targetMode]++
	mm.currentMode = targetMode
	return nil
}

func (mm *ModeManager) SwitchModeAdvanced(targetMode NavigationMode, options map[string]interface{}) error {
	// Extension: gestion avancée, audit, reporting
	return mm.SwitchMode(targetMode)
}

// Gestion des configurations
func (mm *ModeManager) GetCurrentMode() NavigationMode {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()
	return mm.currentMode
}

func (mm *ModeManager) GetModeConfig(mode NavigationMode) (*ModeConfig, error) {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()
	config, ok := mm.modes[mode]
	if !ok {
		return nil, fmt.Errorf("config introuvable: %s", mode)
	}
	return config, nil
}

func (mm *ModeManager) UpdateModeConfig(mode NavigationMode, config *ModeConfig) error {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()
	if config == nil {
		return fmt.Errorf("config nil")
	}
	config.Mode = mode
	mm.modes[mode] = config
	return nil
}

// Gestion des états
func (mm *ModeManager) GetModeState(mode NavigationMode) (*ModeState, error) {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()
	state, ok := mm.stateHistory[mode]
	if !ok {
		return nil, fmt.Errorf("état introuvable: %s", mode)
	}
	return state, nil
}

func (mm *ModeManager) RestoreState(state *ModeState) error {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()
	if state == nil {
		return fmt.Errorf("état nil")
	}
	mm.stateHistory[state.Mode] = state
	return nil
}

// Gestion des événements
func (mm *ModeManager) AddEventHandler(mode NavigationMode, handler ModeEventHandler) error {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()
	mm.eventHandlers[mode] = append(mm.eventHandlers[mode], handler)
	return nil
}

func (mm *ModeManager) TriggerEvent(eventType ModeEventType, data map[string]interface{}) []interface{} {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()
	handlers := mm.eventHandlers[mm.currentMode]
	event := ModeEvent{Type: eventType, Mode: mm.currentMode, Data: data, Timestamp: time.Now(), Source: "mode_manager"}
	results := make([]interface{}, 0, len(handlers))
	for _, h := range handlers {
		results = append(results, h(event))
	}
	return results
}

// Modes disponibles et historique
func (mm *ModeManager) GetAvailableModes() []NavigationMode {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()
	modes := make([]NavigationMode, 0, len(mm.modes))
	for mode, config := range mm.modes {
		if config.Enabled {
			modes = append(modes, mode)
		}
	}
	return modes
}

func (mm *ModeManager) GetTransitionHistory() []ModeTransition {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()
	history := make([]ModeTransition, len(mm.transitionQueue))
	copy(history, mm.transitionQueue)
	return history
}

// Préférences utilisateur
func (mm *ModeManager) SetPreferences(prefs *ModePreferences) {
	mm.mutex.Lock()
	defer mm.mutex.Unlock()
	mm.preferences = prefs
}

func (mm *ModeManager) GetPreferences() *ModePreferences {
	mm.mutex.RLock()
	defer mm.mutex.RUnlock()
	return mm.preferences
}

// Métriques
func (mm *ModeManager) ResetMetrics() {
	mm.metrics.TotalTransitions = 0
	mm.metrics.TransitionCounts = make(map[NavigationMode]int)
	mm.metrics.ErrorCounts = make(map[string]int)
	mm.metrics.LastMetricsReset = time.Now()
}
