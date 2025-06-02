// Package keybinds - Key Validator for conflict detection and resolution
package keybinds

import (
	"fmt"
	"strings"
	"time"
)

// KeyValidator provides key binding validation and conflict detection
type KeyValidator struct {
	manager *KeyConfigManager
}

// NewKeyValidator creates a new key validator
func NewKeyValidator(manager *KeyConfigManager) *KeyValidator {
	return &KeyValidator{
		manager: manager,
	}
}

// ValidateProfile validates an entire key profile for conflicts and issues
func (kv *KeyValidator) ValidateProfile(profile *KeyProfile) ValidationResult {
	result := ValidationResult{
		IsValid:     true,
		Conflicts:   []KeyConflict{},
		Warnings:    []string{},
		Suggestions: []string{},
		ValidatedAt: time.Now(),
	}

	// Check for conflicts within the profile
	conflicts := kv.findConflicts(profile)
	result.Conflicts = conflicts

	if len(conflicts) > 0 {
		result.IsValid = false
	}

	// Generate warnings and suggestions
	kv.generateWarnings(profile, &result)
	kv.generateSuggestions(profile, &result)

	return result
}

// CheckConflicts checks for key binding conflicts
func (kv *KeyValidator) CheckConflicts(profile *KeyProfile) []KeyConflict {
	return kv.findConflicts(profile)
}

// ValidateKeyBinding validates a single key binding
func (kv *KeyValidator) ValidateKeyBinding(binding KeyBinding, profile *KeyProfile) ValidationResult {
	result := ValidationResult{
		IsValid:     true,
		Conflicts:   []KeyConflict{},
		Warnings:    []string{},
		Suggestions: []string{},
		ValidatedAt: time.Now(),
	}

	// Basic validation
	if err := binding.Validate(); err != nil {
		result.IsValid = false
		result.Warnings = append(result.Warnings, err.Error())
		return result
	}

	// Check for conflicts with existing bindings
	conflicts := kv.findBindingConflicts(binding, profile)
	result.Conflicts = conflicts

	if len(conflicts) > 0 {
		result.IsValid = false
	}

	// Generate specific suggestions for this binding
	kv.generateBindingSuggestions(binding, &result)

	return result
}

// ResolveConflict attempts to resolve a key binding conflict
func (kv *KeyValidator) ResolveConflict(conflict KeyConflict, resolution string) error {
	switch resolution {
	case "disable_first":
		return kv.disableBinding(conflict.Binding1)
	case "disable_second":
		return kv.disableBinding(conflict.Binding2)
	case "modify_first":
		return kv.suggestAlternativeKey(conflict.Binding1)
	case "modify_second":
		return kv.suggestAlternativeKey(conflict.Binding2)
	default:
		return fmt.Errorf("unknown resolution strategy: %s", resolution)
	}
}

// ConflictType représente le type de conflit détecté
type ConflictType int

const (
	DuplicateKey ConflictType = iota
	ContextOverlap
	ModifierConflict
	ActionConflict
)

// KeyConflict représente un conflit entre deux bindings
type KeyConflict struct {
	Type        ConflictType
	Description string
	Binding1    KeyBinding
	Binding2    KeyBinding
	Context     string
	Severity    int
	Suggestion  string
}

// Private methods for conflict detection

func (kv *KeyValidator) findConflicts(profile *KeyProfile) []KeyConflict {
	conflicts := make([]KeyConflict, 0)

	for _, keyMap := range profile.KeyMaps {
		// Vérifier les conflits dans le même contexte
		conflicts = append(conflicts, kv.findContextConflicts(keyMap)...)

		// Vérifier les conflits entre contextes différents
		conflicts = append(conflicts, kv.findCrossContextConflicts(keyMap)...)
	}

	return conflicts
}

func (kv *KeyValidator) findContextConflicts(keyMap KeyMap) []KeyConflict {
	conflicts := make([]KeyConflict, 0)

	for i, b1 := range keyMap.Bindings {
		for j := i + 1; j < len(keyMap.Bindings); j++ {
			b2 := keyMap.Bindings[j]

			// Même contexte et même touche
			if b1.Context == b2.Context && b1.Key == b2.Key {
				conflicts = append(conflicts, KeyConflict{
					Type:        DuplicateKey,
					Description: fmt.Sprintf("Duplicate key '%s' in context '%s'", b1.Key, b1.Context),
					Binding1:    b1,
					Binding2:    b2,
					Context:     b1.Context,
					Severity:    2,
					Suggestion:  "Change one of the key bindings to a different key",
				})
			}
		}
	}

	return conflicts
}

func (kv *KeyValidator) findCrossContextConflicts(keyMap KeyMap) []KeyConflict {
	conflicts := make([]KeyConflict, 0)

	for i, b1 := range keyMap.Bindings {
		for j := i + 1; j < len(keyMap.Bindings); j++ {
			b2 := keyMap.Bindings[j]

			// Différent contexte mais même touche
			if b1.Context != b2.Context && b1.Key == b2.Key {
				// Vérifier si les contextes peuvent se chevaucher
				if kv.contextsOverlap(b1.Context, b2.Context) {
					conflicts = append(conflicts, KeyConflict{
						Type: ContextOverlap,
						Description: fmt.Sprintf("Key '%s' used in overlapping contexts '%s' and '%s'",
							b1.Key, b1.Context, b2.Context),
						Binding1:   b1,
						Binding2:   b2,
						Context:    fmt.Sprintf("%s, %s", b1.Context, b2.Context),
						Severity:   1,
						Suggestion: "Consider using different keys for overlapping contexts",
					})
				}
			}
		}
	}

	return conflicts
}

// contextsOverlap vérifie si deux contextes peuvent se chevaucher
func (kv *KeyValidator) contextsOverlap(context1, context2 string) bool {
	// Si l'un des contextes est "global", il chevauche tout
	if context1 == "global" || context2 == "global" {
		return true
	}

	// Vérifier les hiérarchies de contextes
	parts1 := strings.Split(context1, ".")
	parts2 := strings.Split(context2, ".")

	// Si un contexte est un parent de l'autre
	return strings.HasPrefix(context1, context2) || strings.HasPrefix(context2, context1)
}

func (kv *KeyValidator) findBindingConflicts(binding KeyBinding, profile *KeyProfile) []KeyConflict {
	var conflicts []KeyConflict

	for _, keyMap := range profile.KeyMaps {
		for _, existingBinding := range keyMap.Bindings {
			if !existingBinding.Enabled || existingBinding.ID == binding.ID {
				continue
			}

			if kv.hasConflict(binding, existingBinding) {
				conflict := KeyConflict{
					Key:        binding.Key,
					Context:    binding.Context,
					Binding1:   binding,
					Binding2:   existingBinding,
					Severity:   kv.determineSeverity(binding, existingBinding),
					Resolution: kv.suggestResolution(binding, existingBinding),
				}
				conflicts = append(conflicts, conflict)
			}
		}
	}

	return conflicts
}

func (kv *KeyValidator) findGlobalContextConflicts(profile *KeyProfile) []KeyConflict {
	var conflicts []KeyConflict
	globalBindings := make(map[string]KeyBinding)
	contextBindings := make(map[string][]KeyBinding)

	// Collect global and context-specific bindings
	for _, keyMap := range profile.KeyMaps {
		for _, binding := range keyMap.Bindings {
			if !binding.Enabled {
				continue
			}

			if binding.Context == string(ContextGlobal) {
				globalBindings[binding.Key] = binding
			} else {
				contextBindings[binding.Key] = append(contextBindings[binding.Key], binding)
			}
		}
	}

	// Check for conflicts between global and context-specific bindings
	for globalKey, globalBinding := range globalBindings {
		if contextBindingsList, exists := contextBindings[globalKey]; exists {
			for _, contextBinding := range contextBindingsList {
				// This is a potential conflict - global binding might override context-specific
				conflict := KeyConflict{
					Key:        globalKey,
					Context:    "global vs " + contextBinding.Context,
					Binding1:   globalBinding,
					Binding2:   contextBinding,
					Severity:   "warning", // Usually not as severe as direct conflicts
					Resolution: "Consider making global binding context-specific or use different keys",
				}
				conflicts = append(conflicts, conflict)
			}
		}
	}

	return conflicts
}

func (kv *KeyValidator) hasConflict(binding1, binding2 KeyBinding) bool {
	// Same key in same context is a conflict
	if binding1.Key == binding2.Key && binding1.Context == binding2.Context {
		return true
	}

	// Same key where one is global and other is context-specific
	if binding1.Key == binding2.Key {
		if binding1.Context == string(ContextGlobal) || binding2.Context == string(ContextGlobal) {
			return true
		}
	}

	return false
}

func (kv *KeyValidator) determineSeverity(binding1, binding2 KeyBinding) string {
	// Same key, same context = error
	if binding1.Key == binding2.Key && binding1.Context == binding2.Context {
		return "error"
	}

	// Same key, one global, one context-specific = warning
	if binding1.Key == binding2.Key {
		if binding1.Context == string(ContextGlobal) || binding2.Context == string(ContextGlobal) {
			return "warning"
		}
	}

	return "info"
}

func (kv *KeyValidator) suggestResolution(binding1, binding2 KeyBinding) string {
	// If one is more critical than the other
	if kv.isSystemCritical(binding1) && !kv.isSystemCritical(binding2) {
		return "Disable or modify the second binding (less critical)"
	}
	if kv.isSystemCritical(binding2) && !kv.isSystemCritical(binding1) {
		return "Disable or modify the first binding (less critical)"
	}

	// If contexts are different, suggest making one more specific
	if binding1.Context != binding2.Context {
		return "Consider using more specific contexts or different keys"
	}

	// Default suggestion
	return "Modify one of the bindings to use a different key combination"
}

func (kv *KeyValidator) isSystemCritical(binding KeyBinding) bool {
	criticalActions := []string{
		string(ActionQuit),
		string(ActionSave),
		string(ActionUndo),
		string(ActionRedo),
		string(ActionHelp),
	}

	for _, action := range criticalActions {
		if binding.Action == action {
			return true
		}
	}

	return false
}

func (kv *KeyValidator) generateWarnings(profile *KeyProfile, result *ValidationResult) {
	// Check for missing essential bindings
	essentialActions := []KeyAction{
		ActionQuit,
		ActionSave,
		ActionHelp,
		ActionNavigateUp,
		ActionNavigateDown,
	}

	existingActions := make(map[string]bool)
	for _, keyMap := range profile.KeyMaps {
		for _, binding := range keyMap.Bindings {
			if binding.Enabled {
				existingActions[binding.Action] = true
			}
		}
	}

	for _, action := range essentialActions {
		if !existingActions[string(action)] {
			result.Warnings = append(result.Warnings,
				fmt.Sprintf("Missing essential key binding for action: %s", action))
		}
	}

	// Check for complex key combinations that might be hard to use
	for _, keyMap := range profile.KeyMaps {
		for _, binding := range keyMap.Bindings {
			if binding.Enabled && kv.isComplexKeyCombination(binding.Key) {
				result.Warnings = append(result.Warnings,
					fmt.Sprintf("Complex key combination '%s' for binding '%s' may be difficult to use",
						binding.Key, binding.ID))
			}
		}
	}
}

func (kv *KeyValidator) generateSuggestions(profile *KeyProfile, result *ValidationResult) {
	// Suggest common key binding patterns
	result.Suggestions = append(result.Suggestions,
		"Consider using consistent patterns (e.g., Ctrl+ for application actions, Alt+ for view actions)")

	// Suggest grouping related functions
	result.Suggestions = append(result.Suggestions,
		"Group related functions with similar key prefixes (e.g., all panel actions with Ctrl+Shift+)")

	// Suggest accessibility considerations
	result.Suggestions = append(result.Suggestions,
		"Ensure key bindings are accessible and don't conflict with system shortcuts")
}

func (kv *KeyValidator) generateBindingSuggestions(binding KeyBinding, result *ValidationResult) {
	// Suggest alternative keys if current one is commonly used
	commonKeys := []string{"ctrl+c", "ctrl+v", "ctrl+x", "ctrl+a", "ctrl+z", "ctrl+y"}
	for _, commonKey := range commonKeys {
		if strings.ToLower(binding.Key) == commonKey {
			result.Suggestions = append(result.Suggestions,
				fmt.Sprintf("Key '%s' is commonly used by other applications. Consider using a different combination.", binding.Key))
			break
		}
	}

	// Suggest context-specific vs global
	if binding.Context == string(ContextGlobal) {
		result.Suggestions = append(result.Suggestions,
			"Consider if this action should be global or context-specific")
	}
}

func (kv *KeyValidator) isComplexKeyCombination(key string) bool {
	// Count modifiers (ctrl, alt, shift)
	modifiers := 0
	lowerKey := strings.ToLower(key)

	if strings.Contains(lowerKey, "ctrl") {
		modifiers++
	}
	if strings.Contains(lowerKey, "alt") {
		modifiers++
	}
	if strings.Contains(lowerKey, "shift") {
		modifiers++
	}

	// Consider 3 or more modifiers as complex
	return modifiers >= 3
}

func (kv *KeyValidator) disableBinding(binding KeyBinding) error {
	if kv.manager.currentProfile == nil {
		return fmt.Errorf("no current profile set")
	}

	// Find and disable the binding
	for keyMapName, keyMap := range kv.manager.currentProfile.KeyMaps {
		for i, b := range keyMap.Bindings {
			if b.ID == binding.ID {
				keyMap.Bindings[i].Enabled = false
				kv.manager.currentProfile.KeyMaps[keyMapName] = keyMap
				kv.manager.currentProfile.UpdatedAt = time.Now()
				return kv.manager.saveProfile(kv.manager.currentProfile)
			}
		}
	}

	return fmt.Errorf("binding not found: %s", binding.ID)
}

func (kv *KeyValidator) suggestAlternativeKey(binding KeyBinding) error {
	// This would suggest alternative keys based on availability
	// For now, just return an informational error
	return fmt.Errorf("suggestion: consider using an alternative key for binding '%s' (current: %s)",
		binding.ID, binding.Key)
}
