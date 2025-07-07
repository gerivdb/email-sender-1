// Package keybinds - Key Configuration Manager
package keybinds

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// KeyConfigManager manages key binding configurations
type KeyConfigManager struct {
	configDir      string
	currentProfile *KeyProfile
	profiles       map[string]*KeyProfile
	events         []ConfigEvent
	maxEvents      int
}

// NewKeyConfigManager creates a new key configuration manager
func NewKeyConfigManager(configDir string) *KeyConfigManager {
	return &KeyConfigManager{
		configDir: configDir,
		profiles:  make(map[string]*KeyProfile),
		events:    make([]ConfigEvent, 0),
		maxEvents: 1000, // Keep last 1000 events
	}
}

// Initialize initializes the key configuration manager
func (kcm *KeyConfigManager) Initialize() error {
	// Ensure config directory exists
	if err := os.MkdirAll(kcm.configDir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	// Load existing profiles
	if err := kcm.loadProfiles(); err != nil {
		return fmt.Errorf("failed to load profiles: %w", err)
	}

	// Create default profile if none exist
	if len(kcm.profiles) == 0 {
		if err := kcm.createDefaultProfile(); err != nil {
			return fmt.Errorf("failed to create default profile: %w", err)
		}
	}

	// Set current profile to default if none set
	if kcm.currentProfile == nil {
		defaultProfile := kcm.findDefaultProfile()
		if defaultProfile != nil {
			kcm.currentProfile = defaultProfile
		}
	}

	return nil
}

// LoadProfile loads a key binding profile by ID
func (kcm *KeyConfigManager) LoadProfile(profileID string) error {
	profile, exists := kcm.profiles[profileID]
	if !exists {
		return fmt.Errorf("profile with ID %s not found", profileID)
	}

	// Validate profile before loading
	if err := kcm.validateProfile(profile); err != nil {
		return fmt.Errorf("profile validation failed: %w", err)
	}

	kcm.currentProfile = profile
	kcm.logEvent(ConfigEvent{
		Type:        "profile_loaded",
		ProfileID:   profileID,
		Timestamp:   time.Now(),
		Description: fmt.Sprintf("Profile '%s' loaded successfully", profile.Name),
	})

	return nil
}

// GetCurrentProfile returns the currently active profile
func (kcm *KeyConfigManager) GetCurrentProfile() *KeyProfile {
	return kcm.currentProfile
}

// CreateProfile creates a new key binding profile
func (kcm *KeyConfigManager) CreateProfile(name, description string) (*KeyProfile, error) {
	profileID := fmt.Sprintf("profile_%d", time.Now().Unix())

	profile := &KeyProfile{
		ID:          profileID,
		Name:        name,
		Description: description,
		IsDefault:   false,
		KeyMaps:     make(map[string]KeyMap),
		Metadata: ProfileMetadata{
			Version:     "1.0.0",
			Author:      "user",
			Tags:        []string{},
			Preferences: make(map[string]string),
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Add default keymap
	defaultKeyMap := DefaultKeyMap()
	profile.KeyMaps["default"] = defaultKeyMap

	kcm.profiles[profileID] = profile

	if err := kcm.saveProfile(profile); err != nil {
		return nil, fmt.Errorf("failed to save profile: %w", err)
	}

	kcm.logEvent(ConfigEvent{
		Type:        "profile_created",
		ProfileID:   profileID,
		Timestamp:   time.Now(),
		Description: fmt.Sprintf("Profile '%s' created", name),
	})

	return profile, nil
}

// UpdateProfile updates an existing profile
func (kcm *KeyConfigManager) UpdateProfile(profileID string, updates map[string]interface{}) error {
	profile, exists := kcm.profiles[profileID]
	if !exists {
		return fmt.Errorf("profile with ID %s not found", profileID)
	}

	oldProfile := *profile // Create copy for event logging

	// Apply updates
	if name, ok := updates["name"].(string); ok {
		profile.Name = name
	}
	if description, ok := updates["description"].(string); ok {
		profile.Description = description
	}
	if isDefault, ok := updates["is_default"].(bool); ok {
		if isDefault {
			// Set all other profiles as non-default
			for _, p := range kcm.profiles {
				p.IsDefault = false
			}
		}
		profile.IsDefault = isDefault
	}

	profile.UpdatedAt = time.Now()

	if err := kcm.saveProfile(profile); err != nil {
		return fmt.Errorf("failed to save profile: %w", err)
	}

	kcm.logEvent(ConfigEvent{
		Type:        "profile_updated",
		ProfileID:   profileID,
		OldValue:    oldProfile.Name,
		NewValue:    profile.Name,
		Timestamp:   time.Now(),
		Description: fmt.Sprintf("Profile '%s' updated", profile.Name),
	})

	return nil
}

// DeleteProfile deletes a profile
func (kcm *KeyConfigManager) DeleteProfile(profileID string) error {
	profile, exists := kcm.profiles[profileID]
	if !exists {
		return fmt.Errorf("profile with ID %s not found", profileID)
	}

	if profile.IsDefault {
		return fmt.Errorf("cannot delete default profile")
	}

	// Remove from memory
	delete(kcm.profiles, profileID)

	// Remove file
	filename := filepath.Join(kcm.configDir, fmt.Sprintf("%s.json", profileID))
	if err := os.Remove(filename); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to remove profile file: %w", err)
	}

	kcm.logEvent(ConfigEvent{
		Type:        "profile_deleted",
		ProfileID:   profileID,
		Timestamp:   time.Now(),
		Description: fmt.Sprintf("Profile '%s' deleted", profile.Name),
	})

	return nil
}

// ListProfiles returns all available profiles
func (kcm *KeyConfigManager) ListProfiles() []*KeyProfile {
	profiles := make([]*KeyProfile, 0, len(kcm.profiles))
	for _, profile := range kcm.profiles {
		profiles = append(profiles, profile)
	}
	return profiles
}

// UpdateKeyBinding updates a specific key binding in the current profile
func (kcm *KeyConfigManager) UpdateKeyBinding(keyMapName, bindingID string, updates map[string]interface{}) error {
	if kcm.currentProfile == nil {
		return fmt.Errorf("no current profile set")
	}

	keyMap, exists := kcm.currentProfile.KeyMaps[keyMapName]
	if !exists {
		return fmt.Errorf("keymap '%s' not found in current profile", keyMapName)
	}

	// Find the binding
	var bindingIndex = -1
	for i, binding := range keyMap.Bindings {
		if binding.ID == bindingID {
			bindingIndex = i
			break
		}
	}

	if bindingIndex == -1 {
		return fmt.Errorf("binding with ID '%s' not found in keymap '%s'", bindingID, keyMapName)
	}

	oldBinding := keyMap.Bindings[bindingIndex]

	// Apply updates
	if keyStr, ok := updates["key"].(string); ok {
		keyMap.Bindings[bindingIndex].Key = keyStr
	}
	if action, ok := updates["action"].(string); ok {
		keyMap.Bindings[bindingIndex].Action = action
	}
	if context, ok := updates["context"].(string); ok {
		keyMap.Bindings[bindingIndex].Context = context
	}
	if description, ok := updates["description"].(string); ok {
		keyMap.Bindings[bindingIndex].Description = description
	}
	if enabled, ok := updates["enabled"].(bool); ok {
		keyMap.Bindings[bindingIndex].Enabled = enabled
	}

	// Update keymap in profile
	keyMap.UpdatedAt = time.Now()
	kcm.currentProfile.KeyMaps[keyMapName] = keyMap
	kcm.currentProfile.UpdatedAt = time.Now()

	// Save profile
	if err := kcm.saveProfile(kcm.currentProfile); err != nil {
		return fmt.Errorf("failed to save profile: %w", err)
	}

	kcm.logEvent(ConfigEvent{
		Type:        "binding_updated",
		ProfileID:   kcm.currentProfile.ID,
		KeyMapName:  keyMapName,
		BindingID:   bindingID,
		OldValue:    oldBinding.Key,
		NewValue:    keyMap.Bindings[bindingIndex].Key,
		Timestamp:   time.Now(),
		Description: fmt.Sprintf("Key binding '%s' updated", bindingID),
	})

	return nil
}

// GetKeyBinding gets a specific key binding
func (kcm *KeyConfigManager) GetKeyBinding(keyMapName, bindingID string) (*KeyBinding, error) {
	if kcm.currentProfile == nil {
		return nil, fmt.Errorf("no current profile set")
	}

	keyMap, exists := kcm.currentProfile.KeyMaps[keyMapName]
	if !exists {
		return nil, fmt.Errorf("keymap '%s' not found in current profile", keyMapName)
	}

	for _, binding := range keyMap.Bindings {
		if binding.ID == bindingID {
			return &binding, nil
		}
	}

	return nil, fmt.Errorf("binding with ID '%s' not found in keymap '%s'", bindingID, keyMapName)
}

// GetKeyBindingsByContext returns all key bindings for a specific context
func (kcm *KeyConfigManager) GetKeyBindingsByContext(context string) ([]KeyBinding, error) {
	if kcm.currentProfile == nil {
		return nil, fmt.Errorf("no current profile set")
	}

	var bindings []KeyBinding

	for _, keyMap := range kcm.currentProfile.KeyMaps {
		for _, binding := range keyMap.Bindings {
			if binding.Context == context && binding.Enabled {
				bindings = append(bindings, binding)
			}
		}
	}

	return bindings, nil
}

// GetAllKeyBindings returns all key bindings from the current profile
func (kcm *KeyConfigManager) GetAllKeyBindings() ([]KeyBinding, error) {
	if kcm.currentProfile == nil {
		return nil, fmt.Errorf("no current profile set")
	}

	var bindings []KeyBinding

	for _, keyMap := range kcm.currentProfile.KeyMaps {
		for _, binding := range keyMap.Bindings {
			if binding.Enabled {
				bindings = append(bindings, binding)
			}
		}
	}

	return bindings, nil
}

// Private helper methods

func (kcm *KeyConfigManager) loadProfiles() error {
	files, err := filepath.Glob(filepath.Join(kcm.configDir, "*.json"))
	if err != nil {
		return err
	}

	for _, file := range files {
		profile, err := kcm.loadProfile(file)
		if err != nil {
			continue // Skip invalid profiles
		}
		kcm.profiles[profile.ID] = profile
	}

	return nil
}

func (kcm *KeyConfigManager) loadProfile(filename string) (*KeyProfile, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var profile KeyProfile
	if err := json.Unmarshal(data, &profile); err != nil {
		return nil, err
	}

	return &profile, nil
}

func (kcm *KeyConfigManager) saveProfile(profile *KeyProfile) error {
	filename := filepath.Join(kcm.configDir, fmt.Sprintf("%s.json", profile.ID))

	data, err := json.MarshalIndent(profile, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(filename, data, 0644)
}

func (kcm *KeyConfigManager) createDefaultProfile() error {
	profile, err := kcm.CreateProfile("Default", "Default key bindings for TaskMaster CLI")
	if err != nil {
		return err
	}

	profile.IsDefault = true
	return kcm.saveProfile(profile)
}

func (kcm *KeyConfigManager) findDefaultProfile() *KeyProfile {
	for _, profile := range kcm.profiles {
		if profile.IsDefault {
			return profile
		}
	}
	// If no default found, return first available
	for _, profile := range kcm.profiles {
		return profile
	}
	return nil
}

func (kcm *KeyConfigManager) validateProfile(profile *KeyProfile) error {
	if profile == nil {
		return fmt.Errorf("profile is nil")
	}

	if profile.ID == "" {
		return fmt.Errorf("profile ID cannot be empty")
	}

	if profile.Name == "" {
		return fmt.Errorf("profile name cannot be empty")
	}

	// Validate all key bindings
	for mapName, keyMap := range profile.KeyMaps {
		for _, binding := range keyMap.Bindings {
			if err := binding.Validate(); err != nil {
				return fmt.Errorf("invalid binding in keymap '%s': %w", mapName, err)
			}
		}
	}

	return nil
}

func (kcm *KeyConfigManager) logEvent(event ConfigEvent) {
	kcm.events = append(kcm.events, event)

	// Keep only the last maxEvents
	if len(kcm.events) > kcm.maxEvents {
		kcm.events = kcm.events[len(kcm.events)-kcm.maxEvents:]
	}
}

// GetEvents returns recent configuration events
func (kcm *KeyConfigManager) GetEvents(limit int) []ConfigEvent {
	if limit <= 0 || limit > len(kcm.events) {
		limit = len(kcm.events)
	}

	start := len(kcm.events) - limit
	return kcm.events[start:]
}
