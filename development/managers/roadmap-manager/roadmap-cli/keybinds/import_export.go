// Package keybinds - Import/Export functionality for key binding configurations
package keybinds

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// KeyExporter handles exporting key binding configurations
type KeyExporter struct {
	manager *KeyConfigManager
}

// KeyImporter handles importing key binding configurations
type KeyImporter struct {
	manager *KeyConfigManager
}

// ExportFormat represents different export formats
type ExportFormat string

const (
	FormatJSON ExportFormat = "json"
	FormatYAML ExportFormat = "yaml"
	FormatTOML ExportFormat = "toml"
)

// ExportOptions configures the export process
type ExportOptions struct {
	Format          ExportFormat `json:"format"`
	IncludeMetadata bool         `json:"include_metadata"`
	IncludeDisabled bool         `json:"include_disabled"`
	Minify          bool         `json:"minify"`
	OutputPath      string       `json:"output_path"`
}

// ImportOptions configures the import process
type ImportOptions struct {
	OverwriteExisting bool   `json:"overwrite_existing"`
	ValidateBeforeImport bool `json:"validate_before_import"`
	CreateBackup      bool   `json:"create_backup"`
	MergeStrategy     string `json:"merge_strategy"` // "replace", "merge", "append"
}

// Template represents a predefined key binding template
type Template struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Description string            `json:"description"`
	Category    string            `json:"category"`
	KeyMaps     map[string]KeyMap `json:"keymaps"`
	Tags        []string          `json:"tags"`
	Author      string            `json:"author"`
	Version     string            `json:"version"`
	CreatedAt   time.Time         `json:"created_at"`
}

// NewKeyExporter creates a new key exporter
func NewKeyExporter(manager *KeyConfigManager) *KeyExporter {
	return &KeyExporter{
		manager: manager,
	}
}

// NewKeyImporter creates a new key importer
func NewKeyImporter(manager *KeyConfigManager) *KeyImporter {
	return &KeyImporter{
		manager: manager,
	}
}

// SaveConfig exports the current profile configuration to a file
func (ke *KeyExporter) SaveConfig(options ExportOptions) error {
	if ke.manager.currentProfile == nil {
		return fmt.Errorf("no current profile to export")
	}

	profile := ke.manager.currentProfile

	// Prepare export data
	exportData := ke.prepareExportData(profile, options)

	// Create output directory if needed
	outputDir := filepath.Dir(options.OutputPath)
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	switch options.Format {
	case FormatJSON:
		return ke.saveAsJSON(exportData, options)
	case FormatYAML:
		return ke.saveAsYAML(exportData, options)
	case FormatTOML:
		return ke.saveAsTOML(exportData, options)
	default:
		return fmt.Errorf("unsupported export format: %s", options.Format)
	}
}

// ExportProfile exports a specific profile
func (ke *KeyExporter) ExportProfile(profileID string, options ExportOptions) error {
	profile, exists := ke.manager.profiles[profileID]
	if !exists {
		return fmt.Errorf("profile with ID %s not found", profileID)
	}

	// Temporarily set current profile for export
	originalProfile := ke.manager.currentProfile
	ke.manager.currentProfile = profile
	defer func() {
		ke.manager.currentProfile = originalProfile
	}()

	return ke.SaveConfig(options)
}

// ExportTemplate creates a template from a profile
func (ke *KeyExporter) ExportTemplate(profileID string, templateInfo Template) error {
	profile, exists := ke.manager.profiles[profileID]
	if !exists {
		return fmt.Errorf("profile with ID %s not found", profileID)
	}

	template := Template{
		ID:          templateInfo.ID,
		Name:        templateInfo.Name,
		Description: templateInfo.Description,
		Category:    templateInfo.Category,
		KeyMaps:     profile.KeyMaps,
		Tags:        templateInfo.Tags,
		Author:      templateInfo.Author,
		Version:     templateInfo.Version,
		CreatedAt:   time.Now(),
	}

	templatesDir := filepath.Join(ke.manager.configDir, "templates")
	if err := os.MkdirAll(templatesDir, 0755); err != nil {
		return fmt.Errorf("failed to create templates directory: %w", err)
	}

	filename := filepath.Join(templatesDir, fmt.Sprintf("%s.json", template.ID))
	data, err := json.MarshalIndent(template, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal template: %w", err)
	}

	return os.WriteFile(filename, data, 0644)
}

// LoadPresets loads predefined key binding templates
func (ki *KeyImporter) LoadPresets() ([]Template, error) {
	templatesDir := filepath.Join(ki.manager.configDir, "templates")
	
	files, err := filepath.Glob(filepath.Join(templatesDir, "*.json"))
	if err != nil {
		return nil, fmt.Errorf("failed to find template files: %w", err)
	}

	var templates []Template
	for _, file := range files {
		template, err := ki.loadTemplate(file)
		if err != nil {
			continue // Skip invalid templates
		}
		templates = append(templates, template)
	}

	return templates, nil
}

// ImportProfile imports a profile from a file
func (ki *KeyImporter) ImportProfile(filePath string, options ImportOptions) (*KeyProfile, error) {
	// Read file
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read import file: %w", err)
	}

	// Parse profile
	var profile KeyProfile
	if err := json.Unmarshal(data, &profile); err != nil {
		return nil, fmt.Errorf("failed to parse profile data: %w", err)
	}

	// Validate if requested
	if options.ValidateBeforeImport {
		validator := NewKeyValidator(ki.manager)
		result := validator.ValidateProfile(&profile)
		if !result.IsValid {
			return nil, fmt.Errorf("profile validation failed: %d conflicts found", len(result.Conflicts))
		}
	}

	// Create backup if requested
	if options.CreateBackup {
		if err := ki.createBackup(); err != nil {
			return nil, fmt.Errorf("failed to create backup: %w", err)
		}
	}

	// Handle existing profile
	if existingProfile, exists := ki.manager.profiles[profile.ID]; exists {
		if !options.OverwriteExisting {
			return nil, fmt.Errorf("profile with ID %s already exists", profile.ID)
		}

		// Apply merge strategy
		switch options.MergeStrategy {
		case "replace":
			// Replace completely (default behavior)
		case "merge":
			profile = ki.mergeProfiles(existingProfile, &profile)
		case "append":
			profile = ki.appendBindings(existingProfile, &profile)
		}
	}

	// Update timestamps
	profile.UpdatedAt = time.Now()
	if profile.CreatedAt.IsZero() {
		profile.CreatedAt = time.Now()
	}

	// Save profile
	ki.manager.profiles[profile.ID] = &profile
	if err := ki.manager.saveProfile(&profile); err != nil {
		return nil, fmt.Errorf("failed to save imported profile: %w", err)
	}

	return &profile, nil
}

// ImportTemplate imports a template and creates a new profile from it
func (ki *KeyImporter) ImportTemplate(templateID string, profileName string) (*KeyProfile, error) {
	templates, err := ki.LoadPresets()
	if err != nil {
		return nil, fmt.Errorf("failed to load templates: %w", err)
	}

	var selectedTemplate *Template
	for _, template := range templates {
		if template.ID == templateID {
			selectedTemplate = &template
			break
		}
	}

	if selectedTemplate == nil {
		return nil, fmt.Errorf("template with ID %s not found", templateID)
	}

	// Create new profile from template
	profileID := fmt.Sprintf("profile_%d", time.Now().Unix())
	profile := &KeyProfile{
		ID:          profileID,
		Name:        profileName,
		Description: fmt.Sprintf("Profile created from template: %s", selectedTemplate.Name),
		IsDefault:   false,
		KeyMaps:     selectedTemplate.KeyMaps,
		Metadata: ProfileMetadata{
			Version:     selectedTemplate.Version,
			Author:      selectedTemplate.Author,
			Tags:        selectedTemplate.Tags,
			Preferences: make(map[string]string),
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	ki.manager.profiles[profileID] = profile
	if err := ki.manager.saveProfile(profile); err != nil {
		return nil, fmt.Errorf("failed to save profile from template: %w", err)
	}

	return profile, nil
}

// CreateDefaultTemplates creates default templates for common use cases
func (ki *KeyImporter) CreateDefaultTemplates() error {
	templates := []Template{
		{
			ID:          "vim_style",
			Name:        "Vim-style Navigation",
			Description: "Vim-inspired key bindings for navigation",
			Category:    "editor",
			KeyMaps:     ki.createVimStyleKeyMap(),
			Tags:        []string{"vim", "editor", "navigation"},
			Author:      "system",
			Version:     "1.0.0",
			CreatedAt:   time.Now(),
		},
		{
			ID:          "minimal",
			Name:        "Minimal Key Bindings",
			Description: "Essential key bindings only",
			Category:    "minimal",
			KeyMaps:     ki.createMinimalKeyMap(),
			Tags:        []string{"minimal", "basic"},
			Author:      "system",
			Version:     "1.0.0",
			CreatedAt:   time.Now(),
		},
		{
			ID:          "accessibility",
			Name:        "Accessibility Optimized",
			Description: "Key bindings optimized for accessibility",
			Category:    "accessibility",
			KeyMaps:     ki.createAccessibilityKeyMap(),
			Tags:        []string{"accessibility", "a11y"},
			Author:      "system",
			Version:     "1.0.0",
			CreatedAt:   time.Now(),
		},
	}

	for _, template := range templates {
		if err := ki.saveTemplate(template); err != nil {
			return fmt.Errorf("failed to save template %s: %w", template.ID, err)
		}
	}

	return nil
}

// Private helper methods

func (ke *KeyExporter) prepareExportData(profile *KeyProfile, options ExportOptions) map[string]interface{} {
	data := make(map[string]interface{})

	// Copy basic profile info
	data["id"] = profile.ID
	data["name"] = profile.Name
	data["description"] = profile.Description
	data["is_default"] = profile.IsDefault

	// Filter keymaps based on options
	filteredKeyMaps := make(map[string]KeyMap)
	for name, keyMap := range profile.KeyMaps {
		filteredBindings := []KeyBinding{}
		for _, binding := range keyMap.Bindings {
			if binding.Enabled || options.IncludeDisabled {
				filteredBindings = append(filteredBindings, binding)
			}
		}
		
		if len(filteredBindings) > 0 {
			keyMap.Bindings = filteredBindings
			filteredKeyMaps[name] = keyMap
		}
	}
	data["keymaps"] = filteredKeyMaps

	// Include metadata if requested
	if options.IncludeMetadata {
		data["metadata"] = profile.Metadata
		data["created_at"] = profile.CreatedAt
		data["updated_at"] = profile.UpdatedAt
	}

	return data
}

func (ke *KeyExporter) saveAsJSON(data map[string]interface{}, options ExportOptions) error {
	var jsonData []byte
	var err error

	if options.Minify {
		jsonData, err = json.Marshal(data)
	} else {
		jsonData, err = json.MarshalIndent(data, "", "  ")
	}

	if err != nil {
		return fmt.Errorf("failed to marshal JSON: %w", err)
	}

	return os.WriteFile(options.OutputPath, jsonData, 0644)
}

func (ke *KeyExporter) saveAsYAML(data map[string]interface{}, options ExportOptions) error {
	// For now, return error since we need yaml package
	return fmt.Errorf("YAML export not implemented - requires yaml package")
}

func (ke *KeyExporter) saveAsTOML(data map[string]interface{}, options ExportOptions) error {
	// For now, return error since we need toml package
	return fmt.Errorf("TOML export not implemented - requires toml package")
}

func (ki *KeyImporter) loadTemplate(filename string) (Template, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return Template{}, err
	}

	var template Template
	if err := json.Unmarshal(data, &template); err != nil {
		return Template{}, err
	}

	return template, nil
}

func (ki *KeyImporter) saveTemplate(template Template) error {
	templatesDir := filepath.Join(ki.manager.configDir, "templates")
	if err := os.MkdirAll(templatesDir, 0755); err != nil {
		return err
	}

	filename := filepath.Join(templatesDir, fmt.Sprintf("%s.json", template.ID))
	data, err := json.MarshalIndent(template, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(filename, data, 0644)
}

func (ki *KeyImporter) createBackup() error {
	backupDir := filepath.Join(ki.manager.configDir, "backups")
	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return err
	}

	timestamp := time.Now().Format("20060102_150405")
	backupPath := filepath.Join(backupDir, fmt.Sprintf("backup_%s", timestamp))

	// Copy all profile files to backup directory
	for _, profile := range ki.manager.profiles {
		sourceFile := filepath.Join(ki.manager.configDir, fmt.Sprintf("%s.json", profile.ID))
		backupFile := filepath.Join(backupPath, fmt.Sprintf("%s.json", profile.ID))

		if err := os.MkdirAll(filepath.Dir(backupFile), 0755); err != nil {
			return err
		}

		data, err := os.ReadFile(sourceFile)
		if err != nil {
			continue // Skip if file doesn't exist
		}

		if err := os.WriteFile(backupFile, data, 0644); err != nil {
			return err
		}
	}

	return nil
}

func (ki *KeyImporter) mergeProfiles(existing *KeyProfile, imported *KeyProfile) KeyProfile {
	merged := *existing

	// Merge keymaps
	for name, importedKeyMap := range imported.KeyMaps {
		if existingKeyMap, exists := merged.KeyMaps[name]; exists {
			// Merge bindings
			bindingMap := make(map[string]KeyBinding)
			
			// Add existing bindings
			for _, binding := range existingKeyMap.Bindings {
				bindingMap[binding.ID] = binding
			}
			
			// Add/override with imported bindings
			for _, binding := range importedKeyMap.Bindings {
				bindingMap[binding.ID] = binding
			}
			
			// Convert back to slice
			mergedBindings := make([]KeyBinding, 0, len(bindingMap))
			for _, binding := range bindingMap {
				mergedBindings = append(mergedBindings, binding)
			}
			
			existingKeyMap.Bindings = mergedBindings
			existingKeyMap.UpdatedAt = time.Now()
			merged.KeyMaps[name] = existingKeyMap
		} else {
			// Add new keymap
			merged.KeyMaps[name] = importedKeyMap
		}
	}

	merged.UpdatedAt = time.Now()
	return merged
}

func (ki *KeyImporter) appendBindings(existing *KeyProfile, imported *KeyProfile) KeyProfile {
	merged := *existing

	// Append bindings to existing keymaps
	for name, importedKeyMap := range imported.KeyMaps {
		if existingKeyMap, exists := merged.KeyMaps[name]; exists {
			// Append bindings with unique IDs
			for _, binding := range importedKeyMap.Bindings {
				// Ensure unique ID
				originalID := binding.ID
				counter := 1
				for ki.bindingExists(existingKeyMap.Bindings, binding.ID) {
					binding.ID = fmt.Sprintf("%s_%d", originalID, counter)
					counter++
				}
				existingKeyMap.Bindings = append(existingKeyMap.Bindings, binding)
			}
			existingKeyMap.UpdatedAt = time.Now()
			merged.KeyMaps[name] = existingKeyMap
		} else {
			// Add new keymap
			merged.KeyMaps[name] = importedKeyMap
		}
	}

	merged.UpdatedAt = time.Now()
	return merged
}

func (ki *KeyImporter) bindingExists(bindings []KeyBinding, id string) bool {
	for _, binding := range bindings {
		if binding.ID == id {
			return true
		}
	}
	return false
}

// Template creation methods

func (ki *KeyImporter) createVimStyleKeyMap() map[string]KeyMap {
	return map[string]KeyMap{
		"default": {
			Name:        "vim_style",
			Version:     "1.0.0",
			Description: "Vim-style navigation key bindings",
			Bindings: []KeyBinding{
				{ID: "nav_up", Key: "k", Action: string(ActionNavigateUp), Context: string(ContextGlobal), Description: "Navigate up (vim-style)", Enabled: true},
				{ID: "nav_down", Key: "j", Action: string(ActionNavigateDown), Context: string(ContextGlobal), Description: "Navigate down (vim-style)", Enabled: true},
				{ID: "nav_left", Key: "h", Action: string(ActionNavigateLeft), Context: string(ContextGlobal), Description: "Navigate left (vim-style)", Enabled: true},
				{ID: "nav_right", Key: "l", Action: string(ActionNavigateRight), Context: string(ContextGlobal), Description: "Navigate right (vim-style)", Enabled: true},
				{ID: "nav_home", Key: "gg", Action: string(ActionNavigateHome), Context: string(ContextGlobal), Description: "Go to beginning (vim-style)", Enabled: true},
				{ID: "nav_end", Key: "G", Action: string(ActionNavigateEnd), Context: string(ContextGlobal), Description: "Go to end (vim-style)", Enabled: true},
				{ID: "quit", Key: ":q", Action: string(ActionQuit), Context: string(ContextGlobal), Description: "Quit (vim-style)", Enabled: true},
			},
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
	}
}

func (ki *KeyImporter) createMinimalKeyMap() map[string]KeyMap {
	return map[string]KeyMap{
		"default": {
			Name:        "minimal",
			Version:     "1.0.0",
			Description: "Minimal essential key bindings",
			Bindings: []KeyBinding{
				{ID: "nav_up", Key: "up", Action: string(ActionNavigateUp), Context: string(ContextGlobal), Description: "Navigate up", Enabled: true},
				{ID: "nav_down", Key: "down", Action: string(ActionNavigateDown), Context: string(ContextGlobal), Description: "Navigate down", Enabled: true},
				{ID: "save", Key: "ctrl+s", Action: string(ActionSave), Context: string(ContextGlobal), Description: "Save", Enabled: true},
				{ID: "help", Key: "F1", Action: string(ActionHelp), Context: string(ContextGlobal), Description: "Help", Enabled: true},
				{ID: "quit", Key: "escape", Action: string(ActionQuit), Context: string(ContextGlobal), Description: "Quit", Enabled: true},
			},
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
	}
}

func (ki *KeyImporter) createAccessibilityKeyMap() map[string]KeyMap {
	return map[string]KeyMap{
		"default": {
			Name:        "accessibility",
			Version:     "1.0.0",
			Description: "Accessibility-optimized key bindings",
			Bindings: []KeyBinding{
				{ID: "nav_up", Key: "alt+up", Action: string(ActionNavigateUp), Context: string(ContextGlobal), Description: "Navigate up (accessible)", Enabled: true},
				{ID: "nav_down", Key: "alt+down", Action: string(ActionNavigateDown), Context: string(ContextGlobal), Description: "Navigate down (accessible)", Enabled: true},
				{ID: "nav_left", Key: "alt+left", Action: string(ActionNavigateLeft), Context: string(ContextGlobal), Description: "Navigate left (accessible)", Enabled: true},
				{ID: "nav_right", Key: "alt+right", Action: string(ActionNavigateRight), Context: string(ContextGlobal), Description: "Navigate right (accessible)", Enabled: true},
				{ID: "help", Key: "ctrl+F1", Action: string(ActionHelp), Context: string(ContextGlobal), Description: "Help (accessible)", Enabled: true},
				{ID: "save", Key: "ctrl+alt+s", Action: string(ActionSave), Context: string(ContextGlobal), Description: "Save (accessible)", Enabled: true},
			},
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
	}
}
