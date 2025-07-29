//go:build unit
// +build unit

package modemanager

import (
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

// FakeModeManager est une implémentation factice de ModeManager pour les tests.
type FakeModeManager struct {
	currentMode    NavigationMode
	configs        map[NavigationMode]*ModeConfig
	transitions    []ModeTransition
	switchError    error
	getConfigError error
	knownModes     map[NavigationMode]bool
}

func NewFakeModeManager() *FakeModeManager {
	return &FakeModeManager{
		currentMode: "default",
		configs: map[NavigationMode]*ModeConfig{
			"default": {Nom: "default", Options: map[string]interface{}{"theme": "clair"}, Description: "Mode par défaut"},
			"edition": {Nom: "edition", Options: map[string]interface{}{"theme": "sombre"}, Description: "Mode édition"},
		},
		transitions: []ModeTransition{},
		knownModes: map[NavigationMode]bool{
			"default": true,
			"edition": true,
		},
	}
}

func (f *FakeModeManager) SwitchMode(targetMode NavigationMode) interface{} {
	if !f.knownModes[targetMode] {
		f.switchError = errors.New("mode inconnu")
		return nil
	}
	if f.currentMode == targetMode {
		f.switchError = errors.New("déjà dans ce mode")
		return nil
	}
	f.transitions = append(f.transitions, ModeTransition{
		De:        f.currentMode,
		Vers:      targetMode,
		Timestamp: time.Now(),
	})
	f.currentMode = targetMode
	f.switchError = nil
	return nil
}

func (f *FakeModeManager) SwitchModeAdvanced(targetMode NavigationMode, options *TransitionOptions) interface{} {
	return f.SwitchMode(targetMode)
}

func (f *FakeModeManager) GetCurrentMode() NavigationMode {
	return f.currentMode
}

func (f *FakeModeManager) GetModeConfig(mode NavigationMode) (*ModeConfig, error) {
	if f.getConfigError != nil {
		return nil, f.getConfigError
	}
	cfg, ok := f.configs[mode]
	if !ok {
		return nil, errors.New("config inconnue")
	}
	return cfg, nil
}

func (f *FakeModeManager) UpdateModeConfig(mode NavigationMode, config *ModeConfig) error {
	f.configs[mode] = config
	return nil
}

func (f *FakeModeManager) GetModeState(mode NavigationMode) (*ModeState, error) {
	return &ModeState{Mode: mode, État: map[string]interface{}{"dummy": true}, Timestamp: time.Now()}, nil
}

func (f *FakeModeManager) RestoreState(state *ModeState) interface{} {
	f.currentMode = state.Mode
	return nil
}

func (f *FakeModeManager) AddEventHandler(mode NavigationMode, handler ModeEventHandler) error {
	return nil
}

func (f *FakeModeManager) TriggerEvent(eventType ModeEventType, data map[string]interface{}) []interface{} {
	return nil
}

func (f *FakeModeManager) GetTransitionHistory() []ModeTransition {
	return f.transitions
}

// --- TESTS ---

// Test du changement de mode simple (SwitchMode)
func TestSwitchMode_Success(t *testing.T) {
	// On vérifie que le changement de mode fonctionne et que l’historique est mis à jour.
	mgr := NewFakeModeManager()
	mgr.SwitchMode("edition")
	assert.Equal(t, NavigationMode("edition"), mgr.GetCurrentMode())
	assert.Len(t, mgr.GetTransitionHistory(), 1)
	assert.Nil(t, mgr.switchError)
}

// Test du changement de mode vers un mode inconnu
func TestSwitchMode_UnknownMode(t *testing.T) {
	// On vérifie que le manager refuse un mode inconnu.
	mgr := NewFakeModeManager()
	mgr.SwitchMode("inconnu")
	assert.Equal(t, NavigationMode("default"), mgr.GetCurrentMode())
	assert.EqualError(t, mgr.switchError, "mode inconnu")
	assert.Len(t, mgr.GetTransitionHistory(), 0)
}

// Test du double switch sur le même mode
func TestSwitchMode_DoubleSwitch(t *testing.T) {
	// On vérifie que le manager refuse de repasser dans le même mode.
	mgr := NewFakeModeManager()
	mgr.SwitchMode("edition")
	mgr.SwitchMode("edition")
	assert.EqualError(t, mgr.switchError, "déjà dans ce mode")
	assert.Len(t, mgr.GetTransitionHistory(), 1)
}

// Test de récupération de configuration de mode existant
func TestGetModeConfig_Success(t *testing.T) {
	// On vérifie que la configuration d’un mode connu est bien retournée.
	mgr := NewFakeModeManager()
	cfg, err := mgr.GetModeConfig("edition")
	assert.NoError(t, err)
	assert.NotNil(t, cfg)
	assert.Equal(t, "edition", string(cfg.Nom))
}

// Test de récupération de configuration d’un mode inconnu
func TestGetModeConfig_Unknown(t *testing.T) {
	// On vérifie que la récupération d’une config inconnue retourne une erreur.
	mgr := NewFakeModeManager()
	cfg, err := mgr.GetModeConfig("inconnu")
	assert.Error(t, err)
	assert.Nil(t, cfg)
}

// Test de gestion de l’historique des transitions
func TestGetTransitionHistory(t *testing.T) {
	// On vérifie que l’historique des transitions est correct après plusieurs changements.
	mgr := NewFakeModeManager()
	mgr.SwitchMode("edition")
	mgr.SwitchMode("default")
	history := mgr.GetTransitionHistory()
	assert.Len(t, history, 2)
	assert.Equal(t, NavigationMode("default"), history[0].De)
	assert.Equal(t, NavigationMode("edition"), history[0].Vers)
	assert.Equal(t, NavigationMode("edition"), history[1].De)
	assert.Equal(t, NavigationMode("default"), history[1].Vers)
}
