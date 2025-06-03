// Package panels - Context preservation and session management
package panels

import (
	"bytes"
	"compress/gzip"
	"compress/zlib"
	"crypto/md5"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

// ContextState represents the complete state of the panel system
type ContextState struct {
	Version           string                         `json:"version"`
	Timestamp         time.Time                      `json:"timestamp"`
	ActivePanel       PanelID                        `json:"activePanel"`
	Panels            map[PanelID]*PanelData         `json:"panels"`
	Layout            LayoutConfig                   `json:"layout"`
	NavigationHistory []PanelID                      `json:"navigationHistory"`
	Shortcuts         map[string]PanelID             `json:"shortcuts"`
	MinimizedPanels   map[PanelID]*MinimizedState    `json:"minimizedPanels"`
	FloatingPanels    map[PanelID]*FloatingPanelData `json:"floatingPanels"`
	ZOrderStack       []PanelID                      `json:"zOrderStack"`
	WindowSize        Size                           `json:"windowSize"`
	Checksum          string                         `json:"checksum"`
}

// PanelData represents serializable panel data
type PanelData struct {
	ID          PanelID     `json:"id"`
	Title       string      `json:"title"`
	Position    Position    `json:"position"`
	Size        Size        `json:"size"`
	Visible     bool        `json:"visible"`
	Minimized   bool        `json:"minimized"`
	ZOrder      int         `json:"zOrder"`
	Resizable   bool        `json:"resizable"`
	Movable     bool        `json:"movable"`
	CreatedAt   time.Time   `json:"createdAt"`
	LastActive  time.Time   `json:"lastActive"`
	ContentType string      `json:"contentType"`
	ContentData interface{} `json:"contentData,omitempty"`
}

// FloatingPanelData represents serializable floating panel data
type FloatingPanelData struct {
	PanelData *PanelData `json:"panelData"`
	ZIndex    int        `json:"zIndex"`
	Shadow    bool       `json:"shadow"`
	Modal     bool       `json:"modal"`
}

// ContextManager manages state persistence and restoration
type ContextManager struct {
	baseDir           string
	maxSnapshots      int
	compressionLevel  int
	encryptionEnabled bool
	encryptionKey     []byte
	autoSaveInterval  time.Duration
	lastSaveTime      time.Time
	isDirty           bool
}

// NewContextManager creates a new context manager
func NewContextManager(baseDir string) *ContextManager {
	return &ContextManager{
		baseDir:           baseDir,
		maxSnapshots:      50,
		compressionLevel:  6,
		encryptionEnabled: false,
		autoSaveInterval:  time.Minute * 5,
		isDirty:           false,
	}
}

// SaveState saves the complete panel system state
func (cm *ContextManager) SaveState(pm *PanelManager, fm *FloatingManager, minimizer *PanelMinimizer) error {
	state := &ContextState{
		Version:           "1.0",
		Timestamp:         time.Now(),
		ActivePanel:       pm.activePanel,
		Panels:            make(map[PanelID]*PanelData),
		Layout:            pm.layout,
		NavigationHistory: make([]PanelID, len(pm.history)),
		Shortcuts:         make(map[string]PanelID),
		MinimizedPanels:   make(map[PanelID]*MinimizedState),
		FloatingPanels:    make(map[PanelID]*FloatingPanelData),
		ZOrderStack:       make([]PanelID, len(fm.zOrderStack)),
		WindowSize:        Size{Width: pm.width, Height: pm.height},
	}

	// Copy navigation history
	copy(state.NavigationHistory, pm.history)
	copy(state.ZOrderStack, fm.zOrderStack)

	// Copy shortcuts
	for key, panelID := range pm.shortcuts {
		state.Shortcuts[key] = panelID
	}

	// Serialize panels
	for id, panel := range pm.panels {
		panelData := &PanelData{
			ID:         panel.ID,
			Title:      panel.Title,
			Position:   panel.Position,
			Size:       panel.Size,
			Visible:    panel.Visible,
			Minimized:  panel.Minimized,
			ZOrder:     panel.ZOrder,
			Resizable:  panel.Resizable,
			Movable:    panel.Movable,
			CreatedAt:  panel.CreatedAt,
			LastActive: panel.LastActive,
		}

		// Serialize content if possible
		if contentSerializer, ok := panel.Content.(ContentSerializer); ok {
			panelData.ContentType = contentSerializer.GetType()
			if data, err := contentSerializer.Serialize(); err == nil {
				panelData.ContentData = data
			}
		}

		state.Panels[id] = panelData
	}

	// Serialize minimized panels
	for id, minState := range minimizer.minimizedPanels {
		state.MinimizedPanels[id] = minState
	}

	// Serialize floating panels
	for id, floatingPanel := range fm.floatingPanels {
		if panelData, exists := state.Panels[id]; exists {
			state.FloatingPanels[id] = &FloatingPanelData{
				PanelData: panelData,
				ZIndex:    floatingPanel.ZIndex,
				Shadow:    floatingPanel.Shadow,
				Modal:     floatingPanel.Modal,
			}
		}
	}

	// Calculate checksum
	state.Checksum = cm.calculateChecksum(state)

	// Save to file
	return cm.saveStateToFile(state)
}

// ContentSerializer interface for serializable content
type ContentSerializer interface {
	GetType() string
	Serialize() (interface{}, error)
	Deserialize(data interface{}) error
}

// calculateChecksum calculates MD5 checksum of the state
func (cm *ContextManager) calculateChecksum(state *ContextState) string {
	// Create a copy without checksum for calculation
	stateCopy := *state
	stateCopy.Checksum = ""

	data, err := json.Marshal(stateCopy)
	if err != nil {
		return ""
	}

	hash := md5.Sum(data)
	return fmt.Sprintf("%x", hash)
}

// saveStateToFile saves state to a JSON file
func (cm *ContextManager) saveStateToFile(state *ContextState) error {
	// Ensure base directory exists
	if err := os.MkdirAll(cm.baseDir, 0755); err != nil {
		return fmt.Errorf("failed to create base directory: %w", err)
	}

	// Calculate checksum if not already set
	if state.Checksum == "" {
		state.Checksum = cm.calculateChecksum(state)
	}

	// Generate filename with timestamp including milliseconds
	filename := fmt.Sprintf("context_%s.json", state.Timestamp.Format("20060102_150405.000"))
	filePathStr := filepath.Join(cm.baseDir, filename)

	// Create also a "latest" symlink/copy
	latestPath := filepath.Join(cm.baseDir, "latest.json")

	// Marshal to JSON
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal state: %w", err)
	}

	// Encrypt if enabled
	if cm.encryptionEnabled {
		data, err = cm.encrypt(data)
		if err != nil {
			return fmt.Errorf("failed to encrypt state: %w", err)
		}
	}

	// Compress if enabled
	if cm.compressionLevel > 0 {
		data, err = cm.compress(data)
		if err != nil {
			return fmt.Errorf("failed to compress state: %w", err)
		}
	}

	// Write to file
	if err := os.WriteFile(filePathStr, data, 0644); err != nil {
		return fmt.Errorf("failed to write state file: %w", err)
	}

	// Update latest
	if err := os.WriteFile(latestPath, data, 0644); err != nil {
		// Non-fatal error
		fmt.Printf("Warning: failed to update latest state: %v\n", err)
	}

	// Clean up old snapshots
	cm.cleanupOldSnapshots()

	cm.lastSaveTime = time.Now()
	cm.isDirty = false

	return nil
}

// LoadLatestState loads the most recent state
func (cm *ContextManager) LoadLatestState() (*ContextState, error) {
	latestPath := filepath.Join(cm.baseDir, "latest.json")
	return cm.loadStateFromFile(latestPath)
}

// LoadStateByTime loads state from a specific time
func (cm *ContextManager) LoadStateByTime(timestamp time.Time) (*ContextState, error) {
	filename := fmt.Sprintf("context_%s.json", timestamp.Format("20060102_150405.000"))
	filepath := filepath.Join(cm.baseDir, filename)
	return cm.loadStateFromFile(filepath)
}

// loadStateFromFile loads state from a JSON file
func (cm *ContextManager) loadStateFromFile(filepath string) (*ContextState, error) {
	// Check if file exists
	if _, err := os.Stat(filepath); os.IsNotExist(err) {
		return nil, ErrStateNotFound
	}

	// Read file
	data, err := os.ReadFile(filepath)
	if err != nil {
		return nil, fmt.Errorf("failed to read state file: %w", err)
	}

	// Decompress if needed
	if cm.compressionLevel > 0 {
		data, err = cm.decompress(data)
		if err != nil {
			return nil, fmt.Errorf("failed to decompress state: %w", err)
		}
	}

	// Decrypt if enabled
	if cm.encryptionEnabled {
		data, err = cm.decrypt(data)
		if err != nil {
			return nil, fmt.Errorf("failed to decrypt state: %w", err)
		}
	}

	// Unmarshal from JSON
	var state ContextState
	if err := json.Unmarshal(data, &state); err != nil {
		return nil, fmt.Errorf("failed to unmarshal state: %w", err)
	}

	// Verify checksum
	expectedChecksum := cm.calculateChecksum(&state)
	if state.Checksum != expectedChecksum {
		return nil, ErrCorruptedState
	}

	return &state, nil
}

// RestoreState restores the panel system from a saved state
func (cm *ContextManager) RestoreState(state *ContextState, pm *PanelManager, fm *FloatingManager, minimizer *PanelMinimizer) error {
	// Clear current state
	pm.panels = make(map[PanelID]*Panel)
	pm.panelOrder = make([]PanelID, 0)
	fm.floatingPanels = make(map[PanelID]*FloatingPanel)
	fm.zOrderStack = make([]PanelID, 0)
	minimizer.minimizedPanels = make(map[PanelID]*MinimizedState)

	// Restore basic manager state
	pm.activePanel = state.ActivePanel
	pm.layout = state.Layout
	pm.width = state.WindowSize.Width
	pm.height = state.WindowSize.Height

	// Restore navigation history
	pm.history = make([]PanelID, len(state.NavigationHistory))
	copy(pm.history, state.NavigationHistory)

	// Restore shortcuts
	pm.shortcuts = make(map[string]PanelID)
	for key, panelID := range state.Shortcuts {
		pm.shortcuts[key] = panelID
	}

	// Restore panels
	for id, panelData := range state.Panels {
		panel := &Panel{
			ID:         panelData.ID,
			Title:      panelData.Title,
			Position:   panelData.Position,
			Size:       panelData.Size,
			Visible:    panelData.Visible,
			Minimized:  panelData.Minimized,
			ZOrder:     panelData.ZOrder,
			Resizable:  panelData.Resizable,
			Movable:    panelData.Movable,
			CreatedAt:  panelData.CreatedAt,
			LastActive: panelData.LastActive,
		}

		// Restore content if possible
		if panelData.ContentType != "" && panelData.ContentData != nil {
			if content := cm.createContentFromType(panelData.ContentType); content != nil {
				if serializer, ok := content.(ContentSerializer); ok {
					if err := serializer.Deserialize(panelData.ContentData); err == nil {
						panel.Content = content
					}
				}
			}
		}

		pm.panels[id] = panel
		pm.panelOrder = append(pm.panelOrder, id)
	}

	// Restore minimized panels
	for id, minState := range state.MinimizedPanels {
		minimizer.minimizedPanels[id] = minState
	}

	// Restore floating panels
	copy(fm.zOrderStack, state.ZOrderStack)
	for id, floatingData := range state.FloatingPanels {
		if panel, exists := pm.panels[id]; exists {
			floatingPanel := &FloatingPanel{
				Panel:  panel,
				ZIndex: floatingData.ZIndex,
				Shadow: floatingData.Shadow,
				Modal:  floatingData.Modal,
			}
			fm.floatingPanels[id] = floatingPanel
		}
	}

	return nil
}

// createContentFromType creates content model from type string
func (cm *ContextManager) createContentFromType(contentType string) tea.Model {
	// This would be implemented based on available content types
	// For now, return nil
	return nil
}

// ListSavedStates returns a list of available saved states
func (cm *ContextManager) ListSavedStates() ([]time.Time, error) {
	files, err := os.ReadDir(cm.baseDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read context directory: %w", err)
	}

	var timestamps []time.Time
	for _, file := range files {
		if file.IsDir() || file.Name() == "latest.json" {
			continue
		}

		// Parse timestamp from filename
		if len(file.Name()) >= 24 && file.Name()[:8] == "context_" {
			timeStr := file.Name()[8 : len(file.Name())-5] // Remove "context_" and ".json"
			if timestamp, err := time.Parse("20060102_150405.000", timeStr); err == nil {
				timestamps = append(timestamps, timestamp)
			}
		}
	}

	return timestamps, nil
}

// cleanupOldSnapshots removes old snapshots beyond the maximum count
func (cm *ContextManager) cleanupOldSnapshots() {
	timestamps, err := cm.ListSavedStates()
	if err != nil || len(timestamps) <= cm.maxSnapshots {
		return
	}

	// Sort timestamps (oldest first)
	for i := 0; i < len(timestamps)-1; i++ {
		for j := i + 1; j < len(timestamps); j++ {
			if timestamps[i].After(timestamps[j]) {
				timestamps[i], timestamps[j] = timestamps[j], timestamps[i]
			}
		}
	}

	// Remove oldest files
	toRemove := len(timestamps) - cm.maxSnapshots
	for i := 0; i < toRemove; i++ {
		filename := fmt.Sprintf("context_%s.json", timestamps[i].Format("20060102_150405.000"))
		filepath := filepath.Join(cm.baseDir, filename)
		os.Remove(filepath) // Ignore errors
	}
}

// SetMaxSnapshots sets the maximum number of snapshots to keep
func (cm *ContextManager) SetMaxSnapshots(max int) {
	cm.maxSnapshots = max
}

// SetAutoSaveInterval sets the auto-save interval
func (cm *ContextManager) SetAutoSaveInterval(interval time.Duration) {
	cm.autoSaveInterval = interval
}

// MarkDirty marks the state as dirty (needs saving)
func (cm *ContextManager) MarkDirty() {
	cm.isDirty = true
}

// ShouldAutoSave returns true if auto-save should be triggered
func (cm *ContextManager) ShouldAutoSave() bool {
	return cm.isDirty && time.Since(cm.lastSaveTime) >= cm.autoSaveInterval
}

// DeleteState deletes a saved state
func (cm *ContextManager) DeleteState(timestamp time.Time) error {
	filename := fmt.Sprintf("context_%s.json", timestamp.Format("20060102_150405.000"))
	filepath := filepath.Join(cm.baseDir, filename)
	return os.Remove(filepath)
}

// GetStateInfo returns information about a saved state
func (cm *ContextManager) GetStateInfo(timestamp time.Time) (*ContextState, error) {
	state, err := cm.LoadStateByTime(timestamp)
	if err != nil {
		return nil, err
	}

	// Return only metadata (without full content)
	info := &ContextState{
		Version:     state.Version,
		Timestamp:   state.Timestamp,
		ActivePanel: state.ActivePanel,
		WindowSize:  state.WindowSize,
		Checksum:    state.Checksum,
	}

	// Count panels
	info.Panels = make(map[PanelID]*PanelData)
	for id := range state.Panels {
		info.Panels[id] = &PanelData{ID: id} // Only ID for counting
	}

	return info, nil
}

// SessionRestore provides session restoration functionality
type SessionRestore struct {
	contextManager   *ContextManager
	autoRecovery     bool
	recoveryAttempts int
	maxRecoveryTime  time.Duration
	recoveryChan     chan RecoveryResult
	lastRestoreTime  time.Time
	restoreCallback  func(*ContextState) error
}

// RecoveryResult represents the result of a recovery attempt
type RecoveryResult struct {
	Success   bool
	State     *ContextState
	Error     error
	Timestamp time.Time
	Attempts  int
}

// RecoveryOptions represents options for session recovery
type RecoveryOptions struct {
	AutoRecover      bool
	MaxAttempts      int
	RecoveryTimeout  time.Duration
	FallbackStrategy RecoveryStrategy
	ValidateState    bool
	RepairState      bool
}

// RecoveryStrategy represents different recovery strategies
type RecoveryStrategy int

const (
	RecoveryNone RecoveryStrategy = iota
	RecoveryLastKnownGood
	RecoveryPreviousSession
	RecoveryEmptyState
	RecoveryUserPrompt
)

// NewSessionRestore creates a new session restore manager
func NewSessionRestore(cm *ContextManager) *SessionRestore {
	return &SessionRestore{
		contextManager:   cm,
		autoRecovery:     true,
		recoveryAttempts: 3,
		maxRecoveryTime:  30 * time.Second,
		recoveryChan:     make(chan RecoveryResult, 10),
	}
}

// LoadLast attempts to load the most recent session state
func (sr *SessionRestore) LoadLast(options *RecoveryOptions) (*ContextState, error) {
	if options == nil {
		options = &RecoveryOptions{
			AutoRecover:      true,
			MaxAttempts:      3,
			RecoveryTimeout:  30 * time.Second,
			FallbackStrategy: RecoveryLastKnownGood,
			ValidateState:    true,
			RepairState:      true,
		}
	}

	// Get list of available states
	timestamps, err := sr.contextManager.ListSavedStates()
	if err != nil {
		return nil, fmt.Errorf("failed to list saved states: %w", err)
	}

	if len(timestamps) == 0 {
		return sr.createEmptyState(), nil
	}

	// Sort timestamps (newest first)
	sr.sortTimestampsDesc(timestamps)

	// Try to load states in order of recency
	for attempt := 0; attempt < options.MaxAttempts && attempt < len(timestamps); attempt++ {
		state, err := sr.attemptLoad(timestamps[attempt], options)
		if err == nil && state != nil {
			sr.lastRestoreTime = time.Now()

			// Execute restore callback if set
			if sr.restoreCallback != nil {
				if callbackErr := sr.restoreCallback(state); callbackErr != nil {
					continue // Try next state if callback fails
				}
			}

			return state, nil
		}

		// Log recovery attempt
		sr.recoveryChan <- RecoveryResult{
			Success:   false,
			Error:     err,
			Timestamp: timestamps[attempt],
			Attempts:  attempt + 1,
		}
	}

	// Apply fallback strategy
	return sr.applyFallbackStrategy(options.FallbackStrategy, timestamps)
}

// LoadLastAsync loads the last session asynchronously
func (sr *SessionRestore) LoadLastAsync(options *RecoveryOptions) <-chan RecoveryResult {
	result := make(chan RecoveryResult, 1)

	go func() {
		defer close(result)

		state, err := sr.LoadLast(options)
		result <- RecoveryResult{
			Success:   err == nil,
			State:     state,
			Error:     err,
			Timestamp: time.Now(),
			Attempts:  1,
		}
	}()

	return result
}

// AutoRecover continuously monitors and recovers from crashes
func (sr *SessionRestore) AutoRecover(pm *PanelManager, options *RecoveryOptions) {
	if !sr.autoRecovery {
		return
	}

	go func() {
		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				if sr.shouldAttemptRecovery(pm) {
					sr.performAutoRecovery(pm, options)
				}
			case result := <-sr.recoveryChan:
				sr.handleRecoveryResult(result)
			}
		}
	}()
}

// SetRestoreCallback sets a callback function to be called after successful restore
func (sr *SessionRestore) SetRestoreCallback(callback func(*ContextState) error) {
	sr.restoreCallback = callback
}

// GetRecoveryChannel returns the channel for recovery results
func (sr *SessionRestore) GetRecoveryChannel() <-chan RecoveryResult {
	return sr.recoveryChan
}

// EnableAutoRecovery enables or disables automatic recovery
func (sr *SessionRestore) EnableAutoRecovery(enabled bool) {
	sr.autoRecovery = enabled
}

// RestoreFromBackup restores from a specific backup timestamp
func (sr *SessionRestore) RestoreFromBackup(timestamp time.Time, options *RecoveryOptions) (*ContextState, error) {
	state, err := sr.contextManager.LoadStateByTime(timestamp)
	if err != nil {
		return nil, fmt.Errorf("failed to load backup: %w", err)
	}

	if options != nil && options.ValidateState {
		if err := sr.validateState(state); err != nil {
			if options.RepairState {
				state = sr.repairState(state)
			} else {
				return nil, fmt.Errorf("state validation failed: %w", err)
			}
		}
	}

	return state, nil
}

// attemptLoad attempts to load a specific state with validation and repair
func (sr *SessionRestore) attemptLoad(timestamp time.Time, options *RecoveryOptions) (*ContextState, error) {
	// Load state
	state, err := sr.contextManager.LoadStateByTime(timestamp)
	if err != nil {
		return nil, err
	}

	// Validate state if required
	if options.ValidateState {
		if err := sr.validateState(state); err != nil {
			if options.RepairState {
				state = sr.repairState(state)
				// Re-validate after repair
				if err := sr.validateState(state); err != nil {
					return nil, fmt.Errorf("state repair failed: %w", err)
				}
			} else {
				return nil, err
			}
		}
	}

	return state, nil
}

// validateState validates the integrity of a context state
func (sr *SessionRestore) validateState(state *ContextState) error {
	if state == nil {
		return fmt.Errorf("state is nil")
	}

	// Validate version
	if state.Version == "" {
		return fmt.Errorf("missing version")
	}

	// Validate timestamp
	if state.Timestamp.IsZero() {
		return fmt.Errorf("invalid timestamp")
	}

	// Validate panels
	if state.Panels == nil {
		return fmt.Errorf("panels map is nil")
	}

	// Validate active panel exists
	if state.ActivePanel != "" {
		if _, exists := state.Panels[state.ActivePanel]; !exists {
			return fmt.Errorf("active panel %s does not exist", state.ActivePanel)
		}
	}

	// Validate window size
	if state.WindowSize.Width <= 0 || state.WindowSize.Height <= 0 {
		return fmt.Errorf("invalid window size: %dx%d", state.WindowSize.Width, state.WindowSize.Height)
	}

	// Validate checksum if present
	if state.Checksum != "" {
		expectedChecksum := sr.contextManager.calculateChecksum(state)
		if state.Checksum != expectedChecksum {
			return fmt.Errorf("checksum mismatch: expected %s, got %s", expectedChecksum, state.Checksum)
		}
	}

	// Validate panel data
	for id, panelData := range state.Panels {
		if panelData == nil {
			return fmt.Errorf("panel data for %s is nil", id)
		}
		if panelData.ID != id {
			return fmt.Errorf("panel ID mismatch: expected %s, got %s", id, panelData.ID)
		}
		if panelData.Size.Width <= 0 || panelData.Size.Height <= 0 {
			return fmt.Errorf("invalid panel size for %s: %dx%d", id, panelData.Size.Width, panelData.Size.Height)
		}
	}

	return nil
}

// repairState attempts to repair a corrupted state
func (sr *SessionRestore) repairState(state *ContextState) *ContextState {
	if state == nil {
		return sr.createEmptyState()
	}

	// Repair version
	if state.Version == "" {
		state.Version = "1.0.0"
	}

	// Repair timestamp
	if state.Timestamp.IsZero() {
		state.Timestamp = time.Now()
	}

	// Repair panels map
	if state.Panels == nil {
		state.Panels = make(map[PanelID]*PanelData)
	}

	// Repair active panel
	if state.ActivePanel != "" {
		if _, exists := state.Panels[state.ActivePanel]; !exists {
			// Find first available panel
			for id := range state.Panels {
				state.ActivePanel = id
				break
			}
			// If no panels, clear active panel
			if len(state.Panels) == 0 {
				state.ActivePanel = ""
			}
		}
	}

	// Repair window size
	if state.WindowSize.Width <= 0 {
		state.WindowSize.Width = 80
	}
	if state.WindowSize.Height <= 0 {
		state.WindowSize.Height = 24
	}

	// Repair panel data
	toRemove := make([]PanelID, 0)
	for id, panelData := range state.Panels {
		if panelData == nil {
			toRemove = append(toRemove, id)
			continue
		}

		// Repair panel ID
		if panelData.ID != id {
			panelData.ID = id
		}

		// Repair panel size
		if panelData.Size.Width <= 0 {
			panelData.Size.Width = 20
		}
		if panelData.Size.Height <= 0 {
			panelData.Size.Height = 10
		}

		// Repair timestamps
		if panelData.CreatedAt.IsZero() {
			panelData.CreatedAt = time.Now()
		}
		if panelData.LastActive.IsZero() {
			panelData.LastActive = time.Now()
		}
	}

	// Remove invalid panels
	for _, id := range toRemove {
		delete(state.Panels, id)
	}

	// Recalculate checksum
	state.Checksum = sr.contextManager.calculateChecksum(state)

	return state
}

// applyFallbackStrategy applies the specified fallback strategy
func (sr *SessionRestore) applyFallbackStrategy(strategy RecoveryStrategy, timestamps []time.Time) (*ContextState, error) {
	switch strategy {
	case RecoveryLastKnownGood:
		return sr.findLastKnownGoodState(timestamps)
	case RecoveryPreviousSession:
		return sr.loadPreviousSession(timestamps)
	case RecoveryEmptyState:
		return sr.createEmptyState(), nil
	case RecoveryUserPrompt:
		return sr.promptUserForRecovery(timestamps)
	default:
		return nil, fmt.Errorf("unknown recovery strategy: %d", strategy)
	}
}

// findLastKnownGoodState finds the last state that passes validation
func (sr *SessionRestore) findLastKnownGoodState(timestamps []time.Time) (*ContextState, error) {
	for _, timestamp := range timestamps {
		state, err := sr.contextManager.LoadStateByTime(timestamp)
		if err != nil {
			continue
		}

		if err := sr.validateState(state); err == nil {
			return state, nil
		}
	}

	return sr.createEmptyState(), nil
}

// loadPreviousSession loads the session before the most recent one
func (sr *SessionRestore) loadPreviousSession(timestamps []time.Time) (*ContextState, error) {
	if len(timestamps) < 2 {
		return sr.createEmptyState(), nil
	}

	// Skip the most recent and try the second most recent
	for i := 1; i < len(timestamps); i++ {
		state, err := sr.contextManager.LoadStateByTime(timestamps[i])
		if err != nil {
			continue
		}

		if err := sr.validateState(state); err == nil {
			return state, nil
		}
	}

	return sr.createEmptyState(), nil
}

// promptUserForRecovery prompts the user to choose a recovery option
func (sr *SessionRestore) promptUserForRecovery(timestamps []time.Time) (*ContextState, error) {
	// This would integrate with the TUI to show recovery options
	// For now, return empty state
	return sr.createEmptyState(), nil
}

// createEmptyState creates a new empty context state
func (sr *SessionRestore) createEmptyState() *ContextState {
	return &ContextState{
		Version:           "1.0.0",
		Timestamp:         time.Now(),
		ActivePanel:       "",
		Panels:            make(map[PanelID]*PanelData),
		Layout:            LayoutConfig{Type: LayoutHorizontal},
		NavigationHistory: make([]PanelID, 0),
		Shortcuts:         make(map[string]PanelID),
		MinimizedPanels:   make(map[PanelID]*MinimizedState),
		FloatingPanels:    make(map[PanelID]*FloatingPanelData),
		ZOrderStack:       make([]PanelID, 0),
		WindowSize:        Size{Width: 80, Height: 24},
	}
}

// shouldAttemptRecovery determines if auto-recovery should be attempted
func (sr *SessionRestore) shouldAttemptRecovery(pm *PanelManager) bool {
	// Check if too soon since last restore
	if time.Since(sr.lastRestoreTime) < 10*time.Second {
		return false
	}

	// Check if panel manager seems corrupted or empty when it shouldn't be
	if pm == nil {
		return true
	}

	// Add more recovery triggers as needed
	return false
}

// performAutoRecovery performs automatic recovery
func (sr *SessionRestore) performAutoRecovery(pm *PanelManager, options *RecoveryOptions) {
	if sr.recoveryAttempts >= options.MaxAttempts {
		return
	}

	sr.recoveryAttempts++

	state, err := sr.LoadLast(options)
	if err != nil {
		sr.recoveryChan <- RecoveryResult{
			Success:   false,
			Error:     err,
			Timestamp: time.Now(),
			Attempts:  sr.recoveryAttempts,
		}
		return
	}

	sr.recoveryChan <- RecoveryResult{
		Success:   true,
		State:     state,
		Timestamp: time.Now(),
		Attempts:  sr.recoveryAttempts,
	}
}

// handleRecoveryResult handles the result of a recovery attempt
func (sr *SessionRestore) handleRecoveryResult(result RecoveryResult) {
	if result.Success {
		sr.recoveryAttempts = 0 // Reset on success
	}

	// Log recovery result (this could be enhanced with actual logging)
	if result.Error != nil {
		// Handle recovery error
	}
}

// sortTimestampsDesc sorts timestamps in descending order (newest first)
func (sr *SessionRestore) sortTimestampsDesc(timestamps []time.Time) {
	for i := 0; i < len(timestamps)-1; i++ {
		for j := i + 1; j < len(timestamps); j++ {
			if timestamps[i].Before(timestamps[j]) {
				timestamps[i], timestamps[j] = timestamps[j], timestamps[i]
			}
		}
	}
}

// GetLastRestoreTime returns the time of the last successful restore
func (sr *SessionRestore) GetLastRestoreTime() time.Time {
	return sr.lastRestoreTime
}

// GetRecoveryAttempts returns the current number of recovery attempts
func (sr *SessionRestore) GetRecoveryAttempts() int {
	return sr.recoveryAttempts
}

// ResetRecoveryAttempts resets the recovery attempt counter
func (sr *SessionRestore) ResetRecoveryAttempts() {
	sr.recoveryAttempts = 0
}

// Placeholder methods for encryption/compression (would be implemented)
func (cm *ContextManager) encrypt(data []byte) ([]byte, error) {
	// TODO: Implement encryption
	return data, nil
}

func (cm *ContextManager) decrypt(data []byte) ([]byte, error) {
	// TODO: Implement decryption
	return data, nil
}

func (cm *ContextManager) compress(data []byte) ([]byte, error) {
	// TODO: Implement compression
	return data, nil
}

func (cm *ContextManager) decompress(data []byte) ([]byte, error) {
	// TODO: Implement decompression
	return data, nil
}

// StateSerializer provides state serialization and export functionality
type StateSerializer struct {
	contextManager *ContextManager
	exportFormats  map[string]ExportHandler
	importFormats  map[string]ImportHandler
	encryption     EncryptionConfig
	compression    CompressionConfig
}

// ExportHandler represents a handler for exporting states
type ExportHandler func(*ContextState, string) error

// ImportHandler represents a handler for importing states
type ImportHandler func(string) (*ContextState, error)

// ExportFormat represents different export formats
type ExportFormat string

const (
	FormatJSON     ExportFormat = "json"
	FormatBinary   ExportFormat = "binary"
	FormatXML      ExportFormat = "xml"
	FormatYAML     ExportFormat = "yaml"
	FormatTOML     ExportFormat = "toml"
	FormatProtobuf ExportFormat = "protobuf"
)

// ExportOptions represents options for state export
type ExportOptions struct {
	Format      ExportFormat
	Compress    bool
	Encrypt     bool
	IncludeData bool
	PrettyPrint bool
	Timestamp   bool
	Metadata    map[string]interface{}
}

// ImportOptions represents options for state import
type ImportOptions struct {
	Format      ExportFormat
	Validate    bool
	Repair      bool
	MergeMode   MergeMode
	Overwrite   bool
	BackupFirst bool
}

// MergeMode represents different merge strategies
type MergeMode int

const (
	MergeReplace MergeMode = iota
	MergeAppend
	MergeSmart
	MergeUserChoice
)

// EncryptionConfig represents encryption configuration
type EncryptionConfig struct {
	Enabled   bool
	Algorithm string
	KeySize   int
	Key       []byte
}

// CompressionConfig represents compression configuration
type CompressionConfig struct {
	Enabled   bool
	Algorithm string
	Level     int
}

// ExportResult represents the result of an export operation
type ExportResult struct {
	Success    bool
	FilePath   string
	Format     ExportFormat
	Size       int64
	Checksum   string
	Error      error
	Timestamp  time.Time
	Compressed bool
	Encrypted  bool
}

// ImportResult represents the result of an import operation
type ImportResult struct {
	Success     bool
	State       *ContextState
	SourceFile  string
	Format      ExportFormat
	Error       error
	Timestamp   time.Time
	PanelsCount int
	Warnings    []string
}

// NewStateSerializer creates a new state serializer
func NewStateSerializer(cm *ContextManager) *StateSerializer {
	ss := &StateSerializer{
		contextManager: cm,
		exportFormats:  make(map[string]ExportHandler),
		importFormats:  make(map[string]ImportHandler),
		encryption: EncryptionConfig{
			Enabled:   false,
			Algorithm: "AES-256-GCM",
			KeySize:   32,
		},
		compression: CompressionConfig{
			Enabled:   false,
			Algorithm: "gzip",
			Level:     6,
		},
	}

	// Register default handlers
	ss.registerDefaultHandlers()

	return ss
}

// Export exports the current state to a file
func (ss *StateSerializer) Export(state *ContextState, filepath string, options *ExportOptions) (*ExportResult, error) {
	if options == nil {
		options = &ExportOptions{
			Format:      FormatJSON,
			Compress:    false,
			Encrypt:     false,
			IncludeData: true,
			PrettyPrint: true,
			Timestamp:   true,
		}
	}

	result := &ExportResult{
		Format:    options.Format,
		Timestamp: time.Now(),
	}

	// Add timestamp to filename if requested
	if options.Timestamp {
		ext := filepath[len(filepath)-len(".json"):]

		base := filepath[:len(filepath)-len(ext)]
		filepath = fmt.Sprintf("%s_%s%s", base, time.Now().Format("20060102_150405.000"), ext)
	}

	result.FilePath = filepath

	// Get export handler
	handler, exists := ss.exportFormats[string(options.Format)]
	if !exists {
		result.Error = fmt.Errorf("unsupported export format: %s", options.Format)
		return result, result.Error
	}

	// Prepare state for export
	exportState := ss.prepareStateForExport(state, options)

	// Add metadata if provided
	if options.Metadata != nil {
		// This would be added to the exported data structure
	}

	// Export using the handler
	if err := handler(exportState, filepath); err != nil {
		result.Error = err
		return result, err
	}

	// Get file info
	if fileInfo, err := os.Stat(filepath); err == nil {
		result.Size = fileInfo.Size()
	}

	// Calculate checksum
	if data, err := os.ReadFile(filepath); err == nil {
		result.Checksum = fmt.Sprintf("%x", md5.Sum(data))
	}

	result.Success = true
	result.Compressed = options.Compress
	result.Encrypted = options.Encrypt

	return result, nil
}

// ExportMultiple exports multiple states to separate files
func (ss *StateSerializer) ExportMultiple(states []*ContextState, baseDir string, options *ExportOptions) ([]*ExportResult, error) {
	results := make([]*ExportResult, 0, len(states))

	for i, state := range states {
		filename := fmt.Sprintf("state_%d_%s.%s", i+1, state.Timestamp.Format("20060102_150405.000"), options.Format)
		filepath := filepath.Join(baseDir, filename)

		result, err := ss.Export(state, filepath, options)
		results = append(results, result)

		if err != nil {
			// Continue with other exports even if one fails
			continue
		}
	}

	return results, nil
}

// ExportArchive exports multiple states to a single archive file
func (ss *StateSerializer) ExportArchive(states []*ContextState, archivePath string, options *ExportOptions) (*ExportResult, error) {
	result := &ExportResult{
		Format:    options.Format,
		Timestamp: time.Now(),
		FilePath:  archivePath,
	}

	// Create temporary directory for individual exports
	tempDir, err := os.MkdirTemp("", "state_export_*")
	if err != nil {
		result.Error = err
		return result, err
	}
	defer os.RemoveAll(tempDir)

	// Export each state to temp directory
	_, err = ss.ExportMultiple(states, tempDir, options)
	if err != nil {
		result.Error = err
		return result, err
	}

	// Create archive (this would use archive/zip or similar)
	if err := ss.createArchive(tempDir, archivePath); err != nil {
		result.Error = err
		return result, err
	}

	// Get file info
	if fileInfo, err := os.Stat(archivePath); err == nil {
		result.Size = fileInfo.Size()
	}

	result.Success = true
	return result, nil
}

// Import imports a state from a file
func (ss *StateSerializer) Import(filepath string, options *ImportOptions) (*ImportResult, error) {
	if options == nil {
		options = &ImportOptions{
			Format:      FormatJSON,
			Validate:    true,
			Repair:      true,
			MergeMode:   MergeReplace,
			Overwrite:   false,
			BackupFirst: true,
		}
	}

	result := &ImportResult{
		SourceFile: filepath,
		Format:     options.Format,
		Timestamp:  time.Now(),
		Warnings:   make([]string, 0),
	}

	// Backup current state if requested
	if options.BackupFirst {
		if currentState, err := ss.contextManager.LoadLatestState(); err == nil {
			backupPath := fmt.Sprintf("%s.backup_%s", filepath, time.Now().Format("20060102_150405.000"))
			if _, err := ss.Export(currentState, backupPath, &ExportOptions{Format: options.Format}); err != nil {
				result.Warnings = append(result.Warnings, fmt.Sprintf("Failed to create backup: %v", err))
			}
		}
	}

	// Get import handler
	handler, exists := ss.importFormats[string(options.Format)]
	if !exists {
		result.Error = fmt.Errorf("unsupported import format: %s", options.Format)
		return result, result.Error
	}

	// Import using the handler
	state, err := handler(filepath)
	if err != nil {
		result.Error = err
		return result, err
	}

	// Validate state if requested
	if options.Validate {
		if err := ss.validateImportedState(state); err != nil {
			if options.Repair {
				state = ss.repairImportedState(state)
				result.Warnings = append(result.Warnings, "State was repaired during import")
			} else {
				result.Error = fmt.Errorf("state validation failed: %w", err)
				return result, result.Error
			}
		}
	}

	result.State = state
	result.Success = true
	result.PanelsCount = len(state.Panels)

	return result, nil
}

// ImportArchive imports states from an archive file
func (ss *StateSerializer) ImportArchive(archivePath string, options *ImportOptions) ([]*ImportResult, error) {
	// Extract archive to temporary directory
	tempDir, err := os.MkdirTemp("", "state_import_*")
	if err != nil {
		return nil, err
	}
	defer os.RemoveAll(tempDir)

	if err := ss.extractArchive(archivePath, tempDir); err != nil {
		return nil, err
	}

	// Find all state files in the extracted directory
	stateFiles, err := ss.findStateFiles(tempDir, options.Format)
	if err != nil {
		return nil, err
	}

	// Import each state file
	results := make([]*ImportResult, 0, len(stateFiles))
	for _, stateFile := range stateFiles {
		result, err := ss.Import(stateFile, options)
		results = append(results, result)

		if err != nil {
			// Continue with other imports even if one fails
			continue
		}
	}

	return results, nil
}

// RegisterExportHandler registers a custom export handler
func (ss *StateSerializer) RegisterExportHandler(format string, handler ExportHandler) {
	ss.exportFormats[format] = handler
}

// RegisterImportHandler registers a custom import handler
func (ss *StateSerializer) RegisterImportHandler(format string, handler ImportHandler) {
	ss.importFormats[format] = handler
}

// SetEncryption configures encryption settings
func (ss *StateSerializer) SetEncryption(config EncryptionConfig) {
	ss.encryption = config
}

// SetCompression configures compression settings
func (ss *StateSerializer) SetCompression(config CompressionConfig) {
	ss.compression = config
}

// GetSupportedFormats returns the list of supported export/import formats
func (ss *StateSerializer) GetSupportedFormats() []ExportFormat {
	formats := make([]ExportFormat, 0, len(ss.exportFormats))
	for format := range ss.exportFormats {
		formats = append(formats, ExportFormat(format))
	}
	return formats
}

// registerDefaultHandlers registers the default export/import handlers
func (ss *StateSerializer) registerDefaultHandlers() {
	// JSON handler
	ss.exportFormats[string(FormatJSON)] = ss.exportJSON
	ss.importFormats[string(FormatJSON)] = ss.importJSON

	// Binary handler (placeholder)
	ss.exportFormats[string(FormatBinary)] = ss.exportBinary
	ss.importFormats[string(FormatBinary)] = ss.importBinary

	// Other format handlers would be added here
}

// exportJSON exports state to JSON format
func (ss *StateSerializer) exportJSON(state *ContextState, filepath string) error {
	var data []byte
	var err error

	data, err = json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}

	// Apply compression if enabled
	if ss.compression.Enabled {
		data, err = ss.contextManager.compress(data)
		if err != nil {
			return err
		}
	}

	// Apply encryption if enabled
	if ss.encryption.Enabled {
		data, err = ss.contextManager.encrypt(data)
		if err != nil {
			return err
		}
	}

	return os.WriteFile(filepath, data, 0644)
}

// importJSON imports state from JSON format
func (ss *StateSerializer) importJSON(filepath string) (*ContextState, error) {
	data, err := os.ReadFile(filepath)
	if err != nil {
		return nil, err
	}

	// Apply decryption if enabled
	if ss.encryption.Enabled {
		data, err = ss.contextManager.decrypt(data)
		if err != nil {
			return nil, err
		}
	}

	// Apply decompression if enabled
	if ss.compression.Enabled {
		data, err = ss.contextManager.decompress(data)
		if err != nil {
			return nil, err
		}
	}

	var state ContextState
	if err := json.Unmarshal(data, &state); err != nil {
		return nil, err
	}

	return &state, nil
}

// exportBinary exports state to binary format (placeholder)
func (ss *StateSerializer) exportBinary(state *ContextState, filepath string) error {
	// This would implement binary serialization
	// For now, use JSON as fallback
	return ss.exportJSON(state, filepath)
}

// importBinary imports state from binary format (placeholder)
func (ss *StateSerializer) importBinary(filepath string) (*ContextState, error) {
	// This would implement binary deserialization
	// For now, use JSON as fallback
	return ss.importJSON(filepath)
}

// prepareStateForExport prepares a state for export based on options
func (ss *StateSerializer) prepareStateForExport(state *ContextState, options *ExportOptions) *ContextState {
	// Create a copy to avoid modifying the original
	exportState := *state

	// Remove content data if not requested
	if !options.IncludeData {
		for id, panel := range exportState.Panels {
			panelCopy := *panel
			panelCopy.ContentData = nil
			exportState.Panels[id] = &panelCopy
		}
	}

	return &exportState
}

// validateImportedState validates an imported state
func (ss *StateSerializer) validateImportedState(state *ContextState) error {
	// Use the same validation as SessionRestore
	sr := NewSessionRestore(ss.contextManager)
	return sr.validateState(state)
}

// repairImportedState repairs an imported state
func (ss *StateSerializer) repairImportedState(state *ContextState) *ContextState {
	// Use the same repair logic as SessionRestore
	sr := NewSessionRestore(ss.contextManager)
	return sr.repairState(state)
}

// createArchive creates an archive from a directory (placeholder)
func (ss *StateSerializer) createArchive(sourceDir, archivePath string) error {
	// This would implement archive creation using archive/zip or similar
	// For now, return not implemented error
	return fmt.Errorf("archive creation not implemented")
}

// extractArchive extracts an archive to a directory (placeholder)
func (ss *StateSerializer) extractArchive(archivePath, destDir string) error {
	// This would implement archive extraction
	// For now, return not implemented error
	return fmt.Errorf("archive extraction not implemented")
}

// findStateFiles finds all state files in a directory
func (ss *StateSerializer) findStateFiles(dir string, format ExportFormat) ([]string, error) {
	var files []string
	pattern := fmt.Sprintf("*.%s", format)

	matches, err := filepath.Glob(filepath.Join(dir, pattern))
	if err != nil {
		return nil, err
	}

	files = append(files, matches...)
	return files, nil
}

// ContextValidator provides comprehensive state validation functionality
type ContextValidator struct {
	rules           []ValidationRule
	customRules     map[string]ValidationRule
	strictMode      bool
	repairMode      bool
	validationCache map[string]*ValidationResult
}

// ValidationRule represents a validation rule
type ValidationRule interface {
	Name() string
	Description() string
	Validate(*ContextState) *ValidationError
	Severity() ValidationSeverity
	AutoRepair() bool
}

// ValidationSeverity represents the severity of a validation error
type ValidationSeverity int

const (
	SeverityInfo ValidationSeverity = iota
	SeverityWarning
	SeverityError
	SeverityCritical
)

// ValidationError represents a validation error
type ValidationError struct {
	Rule        string                 `json:"rule"`
	Message     string                 `json:"message"`
	Severity    ValidationSeverity     `json:"severity"`
	Field       string                 `json:"field,omitempty"`
	Value       interface{}            `json:"value,omitempty"`
	Expected    interface{}            `json:"expected,omitempty"`
	Suggestions []string               `json:"suggestions,omitempty"`
	AutoRepair  bool                   `json:"autoRepair"`
	Context     map[string]interface{} `json:"context,omitempty"`
}

// ValidationResult represents the result of a validation operation
type ValidationResult struct {
	Valid       bool               `json:"valid"`
	Errors      []*ValidationError `json:"errors"`
	Warnings    []*ValidationError `json:"warnings"`
	Suggestions []*ValidationError `json:"suggestions"`
	Timestamp   time.Time          `json:"timestamp"`
	Duration    time.Duration      `json:"duration"`
	Checksum    string             `json:"checksum"`
	Repaired    bool               `json:"repaired"`
	RepairLog   []string           `json:"repairLog,omitempty"`
}

// ValidationOptions represents options for validation
type ValidationOptions struct {
	StrictMode   bool
	RepairMode   bool
	IncludeRules []string
	ExcludeRules []string
	StopOnFirst  bool
	CacheResults bool
	ParallelMode bool
	Timeout      time.Duration
}

// NewContextValidator creates a new context validator
func NewContextValidator() *ContextValidator {
	cv := &ContextValidator{
		rules:           make([]ValidationRule, 0),
		customRules:     make(map[string]ValidationRule),
		strictMode:      false,
		repairMode:      false,
		validationCache: make(map[string]*ValidationResult),
	}

	// Register default validation rules
	cv.registerDefaultRules()

	return cv
}

// Verify performs comprehensive validation of a context state
func (cv *ContextValidator) Verify(state *ContextState, options *ValidationOptions) (*ValidationResult, error) {
	if options == nil {
		options = &ValidationOptions{
			StrictMode:   cv.strictMode,
			RepairMode:   cv.repairMode,
			CacheResults: true,
			Timeout:      30 * time.Second,
		}
	}

	startTime := time.Now()

	// Check cache if enabled
	if options.CacheResults {
		checksum := cv.calculateStateChecksum(state)
		if cached, exists := cv.validationCache[checksum]; exists {
			return cached, nil
		}
	}

	result := &ValidationResult{
		Valid:       true,
		Errors:      make([]*ValidationError, 0),
		Warnings:    make([]*ValidationError, 0),
		Suggestions: make([]*ValidationError, 0),
		Timestamp:   startTime,
		RepairLog:   make([]string, 0),
	}

	// Apply rules
	rules := cv.selectRules(options)

	if options.ParallelMode {
		result = cv.validateParallel(state, rules, options, result)
	} else {
		result = cv.validateSequential(state, rules, options, result)
	}

	// Finalize result
	result.Duration = time.Since(startTime)
	result.Valid = len(result.Errors) == 0
	result.Checksum = cv.calculateStateChecksum(state)

	// Cache result if enabled
	if options.CacheResults {
		cv.validationCache[result.Checksum] = result
	}

	return result, nil
}

// VerifyQuick performs a quick validation with basic rules only
func (cv *ContextValidator) VerifyQuick(state *ContextState) (*ValidationResult, error) {
	options := &ValidationOptions{
		StrictMode:   false,
		RepairMode:   false,
		IncludeRules: []string{"basic", "structure", "integrity"},
		StopOnFirst:  true,
		CacheResults: false,
		Timeout:      5 * time.Second,
	}

	return cv.Verify(state, options)
}

// VerifyAndRepair performs validation and attempts to repair issues
func (cv *ContextValidator) VerifyAndRepair(state *ContextState) (*ValidationResult, *ContextState, error) {
	options := &ValidationOptions{
		StrictMode:   false,
		RepairMode:   true,
		CacheResults: false,
		Timeout:      60 * time.Second,
	}

	result, err := cv.Verify(state, options)
	if err != nil {
		return result, state, err
	}

	// Apply repairs if any were made
	repairedState := state
	if result.Repaired {
		repairedState = cv.applyRepairs(state, result)
	}

	return result, repairedState, nil
}

// AddRule adds a custom validation rule
func (cv *ContextValidator) AddRule(rule ValidationRule) {
	cv.rules = append(cv.rules, rule)
	cv.customRules[rule.Name()] = rule
}

// RemoveRule removes a validation rule by name
func (cv *ContextValidator) RemoveRule(name string) {
	delete(cv.customRules, name)

	// Remove from rules slice
	for i, rule := range cv.rules {
		if rule.Name() == name {
			cv.rules = append(cv.rules[:i], cv.rules[i+1:]...)
			break
		}
	}
}

// SetStrictMode enables or disables strict validation mode
func (cv *ContextValidator) SetStrictMode(enabled bool) {
	cv.strictMode = enabled
}

// SetRepairMode enables or disables automatic repair mode
func (cv *ContextValidator) SetRepairMode(enabled bool) {
	cv.repairMode = enabled
}

// GetRules returns the list of registered rules
func (cv *ContextValidator) GetRules() []ValidationRule {
	return cv.rules
}

// ClearCache clears the validation cache
func (cv *ContextValidator) ClearCache() {
	cv.validationCache = make(map[string]*ValidationResult)
}

// validateSequential performs sequential validation
func (cv *ContextValidator) validateSequential(state *ContextState, rules []ValidationRule, options *ValidationOptions, result *ValidationResult) *ValidationResult {
	for _, rule := range rules {
		if err := cv.applyRule(rule, state, options, result); err != nil {
			// Log rule application error
			continue
		}

		if options.StopOnFirst && len(result.Errors) > 0 {
			break
		}
	}

	return result
}

// validateParallel performs parallel validation (placeholder for future implementation)
func (cv *ContextValidator) validateParallel(state *ContextState, rules []ValidationRule, options *ValidationOptions, result *ValidationResult) *ValidationResult {
	// For now, fall back to sequential validation
	// In a full implementation, this would use goroutines with proper synchronization
	return cv.validateSequential(state, rules, options, result)
}

// applyRule applies a single validation rule
func (cv *ContextValidator) applyRule(rule ValidationRule, state *ContextState, options *ValidationOptions, result *ValidationResult) error {
	validationError := rule.Validate(state)
	if validationError == nil {
		return nil
	}

	// Categorize the error
	switch validationError.Severity {
	case SeverityInfo:
		result.Suggestions = append(result.Suggestions, validationError)
	case SeverityWarning:
		result.Warnings = append(result.Warnings, validationError)
	case SeverityError, SeverityCritical:
		result.Errors = append(result.Errors, validationError)
	}

	// Attempt auto-repair if enabled
	if options.RepairMode && validationError.AutoRepair {
		if repaired := cv.attemptRepair(rule, state, validationError); repaired {
			result.Repaired = true
			result.RepairLog = append(result.RepairLog,
				fmt.Sprintf("Auto-repaired: %s - %s", rule.Name(), validationError.Message))
		}
	}

	return nil
}

// selectRules selects which rules to apply based on options
func (cv *ContextValidator) selectRules(options *ValidationOptions) []ValidationRule {
	if len(options.IncludeRules) > 0 {
		return cv.filterRulesByInclude(options.IncludeRules)
	}

	if len(options.ExcludeRules) > 0 {
		return cv.filterRulesByExclude(options.ExcludeRules)
	}

	return cv.rules
}

// filterRulesByInclude filters rules to include only specified ones
func (cv *ContextValidator) filterRulesByInclude(includeRules []string) []ValidationRule {
	var filtered []ValidationRule
	for _, rule := range cv.rules {
		for _, include := range includeRules {
			if rule.Name() == include || cv.ruleMatchesCategory(rule, include) {
				filtered = append(filtered, rule)
				break
			}
		}
	}
	return filtered
}

// filterRulesByExclude filters rules to exclude specified ones
func (cv *ContextValidator) filterRulesByExclude(excludeRules []string) []ValidationRule {
	var filtered []ValidationRule
	for _, rule := range cv.rules {
		exclude := false
		for _, excludeName := range excludeRules {
			if rule.Name() == excludeName || cv.ruleMatchesCategory(rule, excludeName) {
				exclude = true
				break
			}
		}
		if !exclude {
			filtered = append(filtered, rule)
		}
	}
	return filtered
}

// ruleMatchesCategory checks if a rule matches a category
func (cv *ContextValidator) ruleMatchesCategory(rule ValidationRule, category string) bool {
	// This would implement category matching logic
	// For now, simple string contains check
	return strings.Contains(strings.ToLower(rule.Name()), strings.ToLower(category))
}

// calculateStateChecksum calculates a checksum for a state
func (cv *ContextValidator) calculateStateChecksum(state *ContextState) string {
	// Create a simplified representation for checksum calculation
	simplified := struct {
		Version     string
		Timestamp   time.Time
		ActivePanel PanelID
		PanelCount  int
		WindowSize  Size
	}{
		Version:     state.Version,
		Timestamp:   state.Timestamp,
		ActivePanel: state.ActivePanel,
		PanelCount:  len(state.Panels),
		WindowSize:  state.WindowSize,
	}

	data, _ := json.Marshal(simplified)
	return fmt.Sprintf("%x", md5.Sum(data))
}

// attemptRepair attempts to repair a validation error
func (cv *ContextValidator) attemptRepair(rule ValidationRule, state *ContextState, validationError *ValidationError) bool {
	// This would implement specific repair logic based on the rule and error
	// For now, return false (no repair attempted)
	return false
}

// applyRepairs applies repairs to a state based on validation result
func (cv *ContextValidator) applyRepairs(state *ContextState, result *ValidationResult) *ContextState {
	// This would implement the actual repair application
	// For now, return the original state
	return state
}

// registerDefaultRules registers the default validation rules
func (cv *ContextValidator) registerDefaultRules() {
	cv.AddRule(&BasicStructureRule{})
	cv.AddRule(&PanelIntegrityRule{})
	cv.AddRule(&LayoutValidationRule{})
	cv.AddRule(&TimestampValidationRule{})
	cv.AddRule(&SizeValidationRule{})
	cv.AddRule(&ChecksumValidationRule{})
	cv.AddRule(&ReferenceIntegrityRule{})
	cv.AddRule(&DataConsistencyRule{})
}

// Basic validation rules implementations

// BasicStructureRule validates basic structure
type BasicStructureRule struct{}

func (r *BasicStructureRule) Name() string                 { return "basic-structure" }
func (r *BasicStructureRule) Description() string          { return "Validates basic state structure" }
func (r *BasicStructureRule) Severity() ValidationSeverity { return SeverityCritical }
func (r *BasicStructureRule) AutoRepair() bool             { return true }

func (r *BasicStructureRule) Validate(state *ContextState) *ValidationError {
	if state == nil {
		return &ValidationError{
			Rule:       r.Name(),
			Message:    "State is nil",
			Severity:   r.Severity(),
			AutoRepair: r.AutoRepair(),
		}
	}

	if state.Panels == nil {
		return &ValidationError{
			Rule:       r.Name(),
			Message:    "Panels map is nil",
			Severity:   r.Severity(),
			Field:      "Panels",
			AutoRepair: r.AutoRepair(),
		}
	}

	return nil
}

// PanelIntegrityRule validates panel integrity
type PanelIntegrityRule struct{}

func (r *PanelIntegrityRule) Name() string                 { return "panel-integrity" }
func (r *PanelIntegrityRule) Description() string          { return "Validates panel data integrity" }
func (r *PanelIntegrityRule) Severity() ValidationSeverity { return SeverityError }
func (r *PanelIntegrityRule) AutoRepair() bool             { return true }

func (r *PanelIntegrityRule) Validate(state *ContextState) *ValidationError {
	for id, panel := range state.Panels {
		if panel == nil {
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Panel %s is nil", id),
				Severity:   r.Severity(),
				Field:      fmt.Sprintf("Panels[%s]", id),
				AutoRepair: r.AutoRepair(),
			}
		}

		if panel.ID != id {
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Panel ID mismatch: expected %s, got %s", id, panel.ID),
				Severity:   r.Severity(),
				Field:      fmt.Sprintf("Panels[%s].ID", id),
				Value:      panel.ID,
				Expected:   id,
				AutoRepair: r.AutoRepair(),
			}
		}
	}

	return nil
}

// LayoutValidationRule validates layout configuration
type LayoutValidationRule struct{}

func (r *LayoutValidationRule) Name() string                 { return "layout-validation" }
func (r *LayoutValidationRule) Description() string          { return "Validates layout configuration" }
func (r *LayoutValidationRule) Severity() ValidationSeverity { return SeverityWarning }
func (r *LayoutValidationRule) AutoRepair() bool             { return true }

func (r *LayoutValidationRule) Validate(state *ContextState) *ValidationError {
	if len(state.Layout.Ratio) > 0 {
		sum := 0.0
		for _, ratio := range state.Layout.Ratio {
			if ratio < 0 || ratio > 1 {
				return &ValidationError{
					Rule:       r.Name(),
					Message:    fmt.Sprintf("Invalid ratio value: %f (must be between 0 and 1)", ratio),
					Severity:   r.Severity(),
					Field:      "Layout.Ratio",
					Value:      ratio,
					Expected:   "0.0 - 1.0",
					AutoRepair: r.AutoRepair(),
				}
			}
			sum += ratio
		}

		if sum > 1.1 || sum < 0.9 { // Allow some tolerance
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Ratio sum is %f, should be close to 1.0", sum),
				Severity:   r.Severity(),
				Field:      "Layout.Ratio",
				Value:      sum,
				Expected:   "1.0",
				AutoRepair: r.AutoRepair(),
			}
		}
	}

	return nil
}

// TimestampValidationRule validates timestamps
type TimestampValidationRule struct{}

func (r *TimestampValidationRule) Name() string                 { return "timestamp-validation" }
func (r *TimestampValidationRule) Description() string          { return "Validates timestamp values" }
func (r *TimestampValidationRule) Severity() ValidationSeverity { return SeverityWarning }
func (r *TimestampValidationRule) AutoRepair() bool             { return true }

func (r *TimestampValidationRule) Validate(state *ContextState) *ValidationError {
	if state.Timestamp.IsZero() {
		return &ValidationError{
			Rule:       r.Name(),
			Message:    "State timestamp is zero",
			Severity:   r.Severity(),
			Field:      "Timestamp",
			AutoRepair: r.AutoRepair(),
		}
	}

	if state.Timestamp.After(time.Now().Add(time.Hour)) {
		return &ValidationError{
			Rule:       r.Name(),
			Message:    "State timestamp is in the future",
			Severity:   r.Severity(),
			Field:      "Timestamp",
			Value:      state.Timestamp,
			AutoRepair: r.AutoRepair(),
		}
	}

	return nil
}

// SizeValidationRule validates size values
type SizeValidationRule struct{}

func (r *SizeValidationRule) Name() string                 { return "size-validation" }
func (r *SizeValidationRule) Description() string          { return "Validates size values" }
func (r *SizeValidationRule) Severity() ValidationSeverity { return SeverityError }
func (r *SizeValidationRule) AutoRepair() bool             { return true }

func (r *SizeValidationRule) Validate(state *ContextState) *ValidationError {
	if state.WindowSize.Width <= 0 || state.WindowSize.Height <= 0 {
		return &ValidationError{
			Rule:       r.Name(),
			Message:    fmt.Sprintf("Invalid window size: %dx%d", state.WindowSize.Width, state.WindowSize.Height),
			Severity:   r.Severity(),
			Field:      "WindowSize",
			Value:      state.WindowSize,
			AutoRepair: r.AutoRepair(),
		}
	}

	for id, panel := range state.Panels {
		if panel.Size.Width <= 0 || panel.Size.Height <= 0 {
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Invalid panel size for %s: %dx%d", id, panel.Size.Width, panel.Size.Height),
				Severity:   r.Severity(),
				Field:      fmt.Sprintf("Panels[%s].Size", id),
				Value:      panel.Size,
				AutoRepair: r.AutoRepair(),
			}
		}
	}

	return nil
}

// ChecksumValidationRule validates checksums
type ChecksumValidationRule struct{}

func (r *ChecksumValidationRule) Name() string                 { return "checksum-validation" }
func (r *ChecksumValidationRule) Description() string          { return "Validates state checksum" }
func (r *ChecksumValidationRule) Severity() ValidationSeverity { return SeverityError }
func (r *ChecksumValidationRule) AutoRepair() bool             { return false }

func (r *ChecksumValidationRule) Validate(state *ContextState) *ValidationError {
	if state.Checksum == "" {
		return &ValidationError{
			Rule:       r.Name(),
			Message:    "Missing checksum",
			Severity:   SeverityWarning, // Downgrade severity for missing checksum
			Field:      "Checksum",
			AutoRepair: r.AutoRepair(),
		}
	}

	// Note: Actual checksum validation would require the original calculation logic
	// This is a placeholder for the validation

	return nil
}

// ReferenceIntegrityRule validates reference integrity
type ReferenceIntegrityRule struct{}

func (r *ReferenceIntegrityRule) Name() string                 { return "reference-integrity" }
func (r *ReferenceIntegrityRule) Description() string          { return "Validates reference integrity" }
func (r *ReferenceIntegrityRule) Severity() ValidationSeverity { return SeverityError }
func (r *ReferenceIntegrityRule) AutoRepair() bool             { return true }

func (r *ReferenceIntegrityRule) Validate(state *ContextState) *ValidationError {
	// Validate active panel exists
	if state.ActivePanel != "" {
		if _, exists := state.Panels[state.ActivePanel]; !exists {
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Active panel %s does not exist", state.ActivePanel),
				Severity:   r.Severity(),
				Field:      "ActivePanel",
				Value:      state.ActivePanel,
				AutoRepair: r.AutoRepair(),
			}
		}
	}

	// Validate navigation history references
	for _, panelID := range state.NavigationHistory {
		if _, exists := state.Panels[panelID]; !exists {
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Navigation history references non-existent panel %s", panelID),
				Severity:   r.Severity(),
				Field:      "NavigationHistory",
				Value:      panelID,
				AutoRepair: r.AutoRepair(),
			}
		}
	}

	// Validate shortcut references
	for shortcut, panelID := range state.Shortcuts {
		if _, exists := state.Panels[panelID]; !exists {
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Shortcut %s references non-existent panel %s", shortcut, panelID),
				Severity:   r.Severity(),
				Field:      "Shortcuts",
				Value:      fmt.Sprintf("%s -> %s", shortcut, panelID),
				AutoRepair: r.AutoRepair(),
			}
		}
	}

	return nil
}

// DataConsistencyRule validates data consistency
type DataConsistencyRule struct{}

func (r *DataConsistencyRule) Name() string                 { return "data-consistency" }
func (r *DataConsistencyRule) Description() string          { return "Validates data consistency" }
func (r *DataConsistencyRule) Severity() ValidationSeverity { return SeverityWarning }
func (r *DataConsistencyRule) AutoRepair() bool             { return true }

func (r *DataConsistencyRule) Validate(state *ContextState) *ValidationError {
	// Validate Z-order stack consistency
	for _, panelID := range state.ZOrderStack {
		if _, exists := state.Panels[panelID]; !exists {
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Z-order stack references non-existent panel %s", panelID),
				Severity:   r.Severity(),
				Field:      "ZOrderStack",
				Value:      panelID,
				AutoRepair: r.AutoRepair(),
			}
		}
	}

	// Validate minimized panels consistency
	for panelID := range state.MinimizedPanels {
		if _, exists := state.Panels[panelID]; !exists {
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Minimized panels references non-existent panel %s", panelID),
				Severity:   r.Severity(),
				Field:      "MinimizedPanels",
				Value:      panelID,
				AutoRepair: r.AutoRepair(),
			}
		}
	}

	// Validate floating panels consistency
	for panelID := range state.FloatingPanels {
		if _, exists := state.Panels[panelID]; !exists {
			return &ValidationError{
				Rule:       r.Name(),
				Message:    fmt.Sprintf("Floating panels references non-existent panel %s", panelID),
				Severity:   r.Severity(),
				Field:      "FloatingPanels",
				Value:      panelID,
				AutoRepair: r.AutoRepair(),
			}
		}
	}

	return nil
}

// StateCompression provides state compression and optimization functionality
type StateCompression struct {
	algorithm        CompressionAlgorithm
	level            int
	threshold        int64 // Minimum size to compress
	optimizations    []OptimizationStrategy
	statistics       *CompressionStats
	cache            map[string][]byte
	maxCacheSize     int64
	currentCacheSize int64
}

// CompressionAlgorithm represents different compression algorithms
type CompressionAlgorithm int

const (
	CompressionNone CompressionAlgorithm = iota
	CompressionGzip
	CompressionZlib
	CompressionLZ4
	CompressionZstd
	CompressionBrotli
)

// OptimizationStrategy represents different optimization strategies
type OptimizationStrategy int

const (
	OptimizeSize OptimizationStrategy = iota
	OptimizeSpeed
	OptimizeMemory
	OptimizeBalance
	OptimizeCustom
)

// CompressionStats tracks compression statistics
type CompressionStats struct {
	TotalOperations     int64
	TotalOriginalSize   int64
	TotalCompressedSize int64
	AverageRatio        float64
	BestRatio           float64
	WorstRatio          float64
	TotalTime           time.Duration
	AverageTime         time.Duration
	CompressionCount    map[CompressionAlgorithm]int64
	OptimizationCount   map[OptimizationStrategy]int64
}

// CompressionResult represents the result of a compression operation
type CompressionResult struct {
	OriginalSize   int64
	CompressedSize int64
	Ratio          float64
	Algorithm      CompressionAlgorithm
	Level          int
	Duration       time.Duration
	Error          error
	Optimized      bool
	Strategy       OptimizationStrategy
}

// OptimizationResult represents the result of an optimization operation
type OptimizationResult struct {
	OriginalState    *ContextState
	OptimizedState   *ContextState
	SizeReduction    int64
	CompressionRatio float64
	Optimizations    []string
	Duration         time.Duration
	MemoryUsage      int64
	Error            error
}

// NewStateCompression creates a new state compression manager
func NewStateCompression() *StateCompression {
	return &StateCompression{
		algorithm:     CompressionGzip,
		level:         6,    // Default compression level
		threshold:     1024, // 1KB threshold
		optimizations: []OptimizationStrategy{OptimizeBalance},
		statistics: &CompressionStats{
			CompressionCount:  make(map[CompressionAlgorithm]int64),
			OptimizationCount: make(map[OptimizationStrategy]int64),
		},
		cache:            make(map[string][]byte),
		maxCacheSize:     50 * 1024 * 1024, // 50MB cache
		currentCacheSize: 0,
	}
}

// Optimize optimizes a context state for storage efficiency
func (sc *StateCompression) Optimize(state *ContextState, strategy OptimizationStrategy) (*OptimizationResult, error) {
	startTime := time.Now()

	result := &OptimizationResult{
		OriginalState: state,
		Optimizations: make([]string, 0),
		Duration:      0,
	}

	// Create a copy for optimization
	optimizedState := sc.copyState(state)

	// Apply optimization strategies
	switch strategy {
	case OptimizeSize:
		optimizedState = sc.optimizeForSize(optimizedState, result)
	case OptimizeSpeed:
		optimizedState = sc.optimizeForSpeed(optimizedState, result)
	case OptimizeMemory:
		optimizedState = sc.optimizeForMemory(optimizedState, result)
	case OptimizeBalance:
		optimizedState = sc.optimizeForBalance(optimizedState, result)
	case OptimizeCustom:
		optimizedState = sc.optimizeCustom(optimizedState, result)
	}

	// Calculate results
	originalSize := sc.calculateStateSize(state)
	optimizedSize := sc.calculateStateSize(optimizedState)

	result.OptimizedState = optimizedState
	result.SizeReduction = originalSize - optimizedSize
	if originalSize > 0 {
		result.CompressionRatio = float64(optimizedSize) / float64(originalSize)
	}
	result.Duration = time.Since(startTime)

	// Update statistics
	sc.statistics.OptimizationCount[strategy]++

	return result, nil
}

// Compress compresses data using the configured algorithm
func (sc *StateCompression) Compress(data []byte) (*CompressionResult, error) {
	startTime := time.Now()

	result := &CompressionResult{
		OriginalSize: int64(len(data)),
		Algorithm:    sc.algorithm,
		Level:        sc.level,
	}

	// Check threshold
	if result.OriginalSize < sc.threshold {
		// Don't compress small data
		result.CompressedSize = result.OriginalSize
		result.Ratio = 1.0
		result.Duration = time.Since(startTime)
		return result, nil
	}

	// Check cache
	cacheKey := sc.generateCacheKey(data)
	if cached, exists := sc.cache[cacheKey]; exists {
		result.CompressedSize = int64(len(cached))
		result.Ratio = float64(result.CompressedSize) / float64(result.OriginalSize)
		result.Duration = time.Since(startTime)
		return result, nil
	}

	// Perform compression
	compressed, err := sc.compressWithAlgorithm(data, sc.algorithm, sc.level)
	if err != nil {
		result.Error = err
		return result, err
	}

	result.CompressedSize = int64(len(compressed))
	result.Ratio = float64(result.CompressedSize) / float64(result.OriginalSize)
	result.Duration = time.Since(startTime)

	// Cache result if it's worth it
	if result.Ratio < 0.8 { // Only cache if compression is effective
		sc.addToCache(cacheKey, compressed)
	}

	// Update statistics
	sc.updateCompressionStats(result)

	return result, nil
}

// Decompress decompresses data using the specified algorithm
func (sc *StateCompression) Decompress(data []byte, algorithm CompressionAlgorithm) ([]byte, error) {
	return sc.decompressWithAlgorithm(data, algorithm)
}

// CompressState compresses an entire context state
func (sc *StateCompression) CompressState(state *ContextState) (*CompressionResult, []byte, error) {
	// Serialize state to JSON
	data, err := json.Marshal(state)
	if err != nil {
		return nil, nil, err
	}

	// Compress the serialized data
	result, err := sc.Compress(data)
	if err != nil {
		return result, nil, err
	}

	// Get compressed data
	compressed, err := sc.compressWithAlgorithm(data, sc.algorithm, sc.level)
	if err != nil {
		return result, nil, err
	}

	return result, compressed, nil
}

// DecompressState decompresses and deserializes a context state
func (sc *StateCompression) DecompressState(data []byte, algorithm CompressionAlgorithm) (*ContextState, error) {
	// Decompress the data
	decompressed, err := sc.Decompress(data, algorithm)
	if err != nil {
		return nil, err
	}

	// Deserialize the state
	var state ContextState
	if err := json.Unmarshal(decompressed, &state); err != nil {
		return nil, err
	}

	return &state, nil
}

// SetAlgorithm sets the compression algorithm
func (sc *StateCompression) SetAlgorithm(algorithm CompressionAlgorithm) {
	sc.algorithm = algorithm
}

// SetLevel sets the compression level
func (sc *StateCompression) SetLevel(level int) {
	sc.level = level
}

// SetThreshold sets the compression threshold
func (sc *StateCompression) SetThreshold(threshold int64) {
	sc.threshold = threshold
}

// GetStatistics returns compression statistics
func (sc *StateCompression) GetStatistics() *CompressionStats {
	return sc.statistics
}

// ClearCache clears the compression cache
func (sc *StateCompression) ClearCache() {
	sc.cache = make(map[string][]byte)
	sc.currentCacheSize = 0
}

// GetBestAlgorithm returns the best compression algorithm for the given data
func (sc *StateCompression) GetBestAlgorithm(data []byte) (CompressionAlgorithm, int, error) {
	if len(data) < int(sc.threshold) {
		return CompressionNone, 0, nil
	}

	algorithms := []CompressionAlgorithm{
		CompressionGzip,
		CompressionZlib,
		CompressionLZ4,
	}

	bestAlgorithm := CompressionGzip
	bestRatio := float64(1.0)
	bestLevel := 6

	// Test different algorithms
	for _, algo := range algorithms {
		for level := 1; level <= 9; level++ {
			compressed, err := sc.compressWithAlgorithm(data, algo, level)
			if err != nil {
				continue
			}

			ratio := float64(len(compressed)) / float64(len(data))
			if ratio < bestRatio {
				bestRatio = ratio
				bestAlgorithm = algo
				bestLevel = level
			}
		}
	}

	return bestAlgorithm, bestLevel, nil
}

// optimizeForSize optimizes state for minimum size
func (sc *StateCompression) optimizeForSize(state *ContextState, result *OptimizationResult) *ContextState {
	// Remove unnecessary data
	state = sc.removeRedundantData(state, result)

	// Optimize panel data
	state = sc.optimizePanelData(state, result)

	// Optimize history and shortcuts
	state = sc.optimizeHistoryAndShortcuts(state, result)

	result.Optimizations = append(result.Optimizations, "optimized for size")
	return state
}

// optimizeForSpeed optimizes state for faster access
func (sc *StateCompression) optimizeForSpeed(state *ContextState, result *OptimizationResult) *ContextState {
	// Pre-calculate frequently accessed data
	state = sc.precalculateData(state, result)

	// Optimize data structures for faster access
	state = sc.optimizeDataStructures(state, result)

	result.Optimizations = append(result.Optimizations, "optimized for speed")
	return state
}

// optimizeForMemory optimizes state for minimal memory usage
func (sc *StateCompression) optimizeForMemory(state *ContextState, result *OptimizationResult) *ContextState {
	// Remove memory-heavy content data
	state = sc.removeContentData(state, result)

	// Compact data structures
	state = sc.compactDataStructures(state, result)

	result.Optimizations = append(result.Optimizations, "optimized for memory")
	return state
}

// optimizeForBalance optimizes state for balanced performance
func (sc *StateCompression) optimizeForBalance(state *ContextState, result *OptimizationResult) *ContextState {
	// Apply a mix of optimizations
	state = sc.removeRedundantData(state, result)
	state = sc.optimizePanelData(state, result)
	state = sc.optimizeDataStructures(state, result)

	result.Optimizations = append(result.Optimizations, "optimized for balance")
	return state
}

// optimizeCustom applies custom optimization logic
func (sc *StateCompression) optimizeCustom(state *ContextState, result *OptimizationResult) *ContextState {
	// Apply all available optimizations
	for _, strategy := range sc.optimizations {
		switch strategy {
		case OptimizeSize:
			state = sc.optimizeForSize(state, result)
		case OptimizeSpeed:
			state = sc.optimizeForSpeed(state, result)
		case OptimizeMemory:
			state = sc.optimizeForMemory(state, result)
		}
	}

	result.Optimizations = append(result.Optimizations, "custom optimization")
	return state
}

// Helper methods for optimization

func (sc *StateCompression) removeRedundantData(state *ContextState, result *OptimizationResult) *ContextState {
	// Remove duplicate entries from navigation history
	uniqueHistory := make([]PanelID, 0)
	seen := make(map[PanelID]bool)

	for _, panelID := range state.NavigationHistory {
		if !seen[panelID] {
			uniqueHistory = append(uniqueHistory, panelID)
			seen[panelID] = true
		}
	}

	if len(uniqueHistory) < len(state.NavigationHistory) {
		state.NavigationHistory = uniqueHistory
		result.Optimizations = append(result.Optimizations, "removed duplicate history entries")
	}

	return state
}

func (sc *StateCompression) optimizePanelData(state *ContextState, result *OptimizationResult) *ContextState {
	for id, panel := range state.Panels {
		// Remove content data if panel is not visible
		if !panel.Visible && panel.ContentData != nil {
			panel.ContentData = nil
			result.Optimizations = append(result.Optimizations, fmt.Sprintf("removed content data from hidden panel %s", id))
		}

		// Reset timestamps for very old panels (saves space in JSON)
		if time.Since(panel.LastActive) > 30*24*time.Hour { // 30 days
			panel.LastActive = time.Time{}
			result.Optimizations = append(result.Optimizations, fmt.Sprintf("reset old timestamp for panel %s", id))
		}
	}

	return state
}

func (sc *StateCompression) optimizeHistoryAndShortcuts(state *ContextState, result *OptimizationResult) *ContextState {
	// Limit navigation history size
	maxHistorySize := 20
	if len(state.NavigationHistory) > maxHistorySize {
		state.NavigationHistory = state.NavigationHistory[:maxHistorySize]
		result.Optimizations = append(result.Optimizations, "trimmed navigation history")
	}

	// Remove shortcuts to non-existent panels
	for shortcut, panelID := range state.Shortcuts {
		if _, exists := state.Panels[panelID]; !exists {
			delete(state.Shortcuts, shortcut)
			result.Optimizations = append(result.Optimizations, fmt.Sprintf("removed invalid shortcut %s", shortcut))
		}
	}

	return state
}

func (sc *StateCompression) precalculateData(state *ContextState, result *OptimizationResult) *ContextState {
	// This would pre-calculate frequently accessed data
	// For now, this is a placeholder
	result.Optimizations = append(result.Optimizations, "precalculated data")
	return state
}

func (sc *StateCompression) optimizeDataStructures(state *ContextState, result *OptimizationResult) *ContextState {
	// This would optimize data structures for faster access
	// For now, this is a placeholder
	result.Optimizations = append(result.Optimizations, "optimized data structures")
	return state
}

func (sc *StateCompression) removeContentData(state *ContextState, result *OptimizationResult) *ContextState {
	removedCount := 0
	for _, panel := range state.Panels {
		if panel.ContentData != nil {
			panel.ContentData = nil
			removedCount++
		}
	}

	if removedCount > 0 {
		result.Optimizations = append(result.Optimizations,
			fmt.Sprintf("removed content data from %d panels", removedCount))
	}

	return state
}

func (sc *StateCompression) compactDataStructures(state *ContextState, result *OptimizationResult) *ContextState {
	// Compact slices and maps
	if cap(state.NavigationHistory) > len(state.NavigationHistory)*2 {
		// Re-slice to reduce capacity
		newHistory := make([]PanelID, len(state.NavigationHistory))
		copy(newHistory, state.NavigationHistory)
		state.NavigationHistory = newHistory
		result.Optimizations = append(result.Optimizations, "compacted navigation history slice")
	}

	return state
}

// Compression algorithm implementations

func (sc *StateCompression) compressWithAlgorithm(data []byte, algorithm CompressionAlgorithm, level int) ([]byte, error) {
	switch algorithm {
	case CompressionNone:
		return data, nil
	case CompressionGzip:
		return sc.compressGzip(data, level)
	case CompressionZlib:
		return sc.compressZlib(data, level)
	case CompressionLZ4:
		return sc.compressLZ4(data)
	default:
		return nil, fmt.Errorf("unsupported compression algorithm: %d", algorithm)
	}
}

func (sc *StateCompression) decompressWithAlgorithm(data []byte, algorithm CompressionAlgorithm) ([]byte, error) {
	switch algorithm {
	case CompressionNone:
		return data, nil
	case CompressionGzip:
		return sc.decompressGzip(data)
	case CompressionZlib:
		return sc.decompressZlib(data)
	case CompressionLZ4:
		return sc.decompressLZ4(data)
	default:
		return nil, fmt.Errorf("unsupported compression algorithm: %d", algorithm)
	}
}

func (sc *StateCompression) compressGzip(data []byte, level int) ([]byte, error) {
	var buf bytes.Buffer
	writer, err := gzip.NewWriterLevel(&buf, level)
	if err != nil {
		return nil, err
	}

	if _, err := writer.Write(data); err != nil {
		return nil, err
	}

	if err := writer.Close(); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func (sc *StateCompression) decompressGzip(data []byte) ([]byte, error) {
	reader, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	defer reader.Close()

	return io.ReadAll(reader)
}

func (sc *StateCompression) compressZlib(data []byte, level int) ([]byte, error) {
	var buf bytes.Buffer
	writer, err := zlib.NewWriterLevel(&buf, level)
	if err != nil {
		return nil, err
	}

	if _, err := writer.Write(data); err != nil {
		return nil, err
	}

	if err := writer.Close(); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func (sc *StateCompression) decompressZlib(data []byte) ([]byte, error) {
	reader, err := zlib.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	defer reader.Close()

	return io.ReadAll(reader)
}

func (sc *StateCompression) compressLZ4(data []byte) ([]byte, error) {
	// Placeholder for LZ4 compression
	// Would require github.com/pierrec/lz4 or similar
	return data, fmt.Errorf("LZ4 compression not implemented")
}

func (sc *StateCompression) decompressLZ4(data []byte) ([]byte, error) {
	// Placeholder for LZ4 decompression
	return data, fmt.Errorf("LZ4 decompression not implemented")
}

// Utility methods

func (sc *StateCompression) copyState(state *ContextState) *ContextState {
	// Create a deep copy of the state
	data, err := json.Marshal(state)
	if err != nil {
		return state // Return original if copy fails
	}

	var copy ContextState
	if err := json.Unmarshal(data, &copy); err != nil {
		return state // Return original if copy fails
	}

	return &copy
}

func (sc *StateCompression) calculateStateSize(state *ContextState) int64 {
	data, err := json.Marshal(state)
	if err != nil {
		return 0
	}
	return int64(len(data))
}

func (sc *StateCompression) generateCacheKey(data []byte) string {
	hash := md5.Sum(data)
	return fmt.Sprintf("%x", hash)
}

func (sc *StateCompression) addToCache(key string, data []byte) {
	dataSize := int64(len(data))

	// Check if adding this would exceed cache size
	if sc.currentCacheSize+dataSize > sc.maxCacheSize {
		sc.evictCache(dataSize)
	}

	sc.cache[key] = data
	sc.currentCacheSize += dataSize
}

func (sc *StateCompression) evictCache(neededSize int64) {
	// Simple LRU-like eviction - remove random entries until we have space
	for key, data := range sc.cache {
		delete(sc.cache, key)
		sc.currentCacheSize -= int64(len(data))

		if sc.currentCacheSize+neededSize <= sc.maxCacheSize {
			break
		}
	}
}

func (sc *StateCompression) updateCompressionStats(result *CompressionResult) {
	stats := sc.statistics
	stats.TotalOperations++
	stats.TotalOriginalSize += result.OriginalSize
	stats.TotalCompressedSize += result.CompressedSize
	stats.TotalTime += result.Duration
	stats.CompressionCount[result.Algorithm]++

	// Update averages
	if stats.TotalOperations > 0 {
		stats.AverageRatio = float64(stats.TotalCompressedSize) / float64(stats.TotalOriginalSize)
		stats.AverageTime = stats.TotalTime / time.Duration(stats.TotalOperations)
	}

	// Update best/worst ratios
	if stats.TotalOperations == 1 || result.Ratio < stats.BestRatio {
		stats.BestRatio = result.Ratio
	}
	if stats.TotalOperations == 1 || result.Ratio > stats.WorstRatio {
		stats.WorstRatio = result.Ratio
	}
}
