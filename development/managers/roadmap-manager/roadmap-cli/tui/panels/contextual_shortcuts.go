// Package panels - Context-aware shortcuts and dynamic key binding system
package panels

import (
	"fmt"
	"time"

	"github.com/charmbracelet/bubbles/key"
	tea "github.com/charmbracelet/bubbletea"
)

// ContextualShortcut represents a context-aware shortcut
type ContextualShortcut struct {
	Key         string
	Description string
	Action      string
	Context     []string // Contexts where this shortcut is available
	Condition   func(*PanelManager, PanelID) bool
	Handler     func(*PanelManager, PanelID) tea.Cmd
	Priority    int // Higher priority shortcuts override lower ones
}

// ShortcutContext represents the current context for shortcuts
type ShortcutContext struct {
	ActivePanel   PanelID
	PanelType     string
	ViewMode      string
	SelectedItems []string
	EditMode      bool
	FilterActive  bool
}

// ContextualShortcutManager manages dynamic shortcuts based on context
type ContextualShortcutManager struct {
	shortcuts        map[string]*ContextualShortcut
	contextShortcuts map[string][]*ContextualShortcut // shortcuts by context
	currentContext   ShortcutContext
	panelManager     *PanelManager
	lastUpdate       time.Time
	dynamicKeys      map[string]key.Binding
}

// NewContextualShortcutManager creates a new contextual shortcut manager
func NewContextualShortcutManager(pm *PanelManager) *ContextualShortcutManager {
	csm := &ContextualShortcutManager{
		shortcuts:        make(map[string]*ContextualShortcut),
		contextShortcuts: make(map[string][]*ContextualShortcut),
		panelManager:     pm,
		dynamicKeys:      make(map[string]key.Binding),
	}

	// Register default contextual shortcuts
	csm.registerDefaultShortcuts()
	return csm
}

// registerDefaultShortcuts registers the default context-aware shortcuts
func (csm *ContextualShortcutManager) registerDefaultShortcuts() {
	shortcuts := []*ContextualShortcut{
		// Panel navigation shortcuts (Ctrl+1-8)
		{
			Key:         "ctrl+1",
			Description: "Switch to panel 1",
			Action:      "switch_panel",
			Context:     []string{"any"},
			Priority:    100,
			Handler:     csm.switchToPanelHandler(1),
		},
		{
			Key:         "ctrl+2",
			Description: "Switch to panel 2",
			Action:      "switch_panel",
			Context:     []string{"any"},
			Priority:    100,
			Handler:     csm.switchToPanelHandler(2),
		},
		{
			Key:         "ctrl+3",
			Description: "Switch to panel 3",
			Action:      "switch_panel",
			Context:     []string{"any"},
			Priority:    100,
			Handler:     csm.switchToPanelHandler(3),
		},
		{
			Key:         "ctrl+4",
			Description: "Switch to panel 4",
			Action:      "switch_panel",
			Context:     []string{"any"},
			Priority:    100,
			Handler:     csm.switchToPanelHandler(4),
		},
		{
			Key:         "ctrl+5",
			Description: "Switch to panel 5",
			Action:      "switch_panel",
			Context:     []string{"any"},
			Priority:    100,
			Handler:     csm.switchToPanelHandler(5),
		},
		{
			Key:         "ctrl+6",
			Description: "Switch to panel 6",
			Action:      "switch_panel",
			Context:     []string{"any"},
			Priority:    100,
			Handler:     csm.switchToPanelHandler(6),
		},
		{
			Key:         "ctrl+7",
			Description: "Switch to panel 7",
			Action:      "switch_panel",
			Context:     []string{"any"},
			Priority:    100,
			Handler:     csm.switchToPanelHandler(7),
		},
		{
			Key:         "ctrl+8",
			Description: "Switch to panel 8",
			Action:      "switch_panel",
			Context:     []string{"any"},
			Priority:    100,
			Handler:     csm.switchToPanelHandler(8),
		},

		// Context-aware shortcuts for Kanban mode
		{
			Key:         "n",
			Description: "New card",
			Action:      "new_card",
			Context:     []string{"kanban", "board"},
			Priority:    80,
			Condition:   csm.isKanbanModeCondition,
			Handler:     csm.newCardHandler,
		},
		{
			Key:         "e",
			Description: "Edit card",
			Action:      "edit_card",
			Context:     []string{"kanban", "card_selected"},
			Priority:    80,
			Condition:   csm.hasSelectedCardCondition,
			Handler:     csm.editCardHandler,
		},
		{
			Key:         "m",
			Description: "Move card",
			Action:      "move_card",
			Context:     []string{"kanban", "card_selected"},
			Priority:    80,
			Condition:   csm.hasSelectedCardCondition,
			Handler:     csm.moveCardHandler,
		},

		// Context-aware shortcuts for List mode
		{
			Key:         "space",
			Description: "Toggle completion",
			Action:      "toggle_complete",
			Context:     []string{"list", "item_selected"},
			Priority:    80,
			Condition:   csm.hasSelectedItemCondition,
			Handler:     csm.toggleCompleteHandler,
		},
		{
			Key:         "p",
			Description: "Set priority",
			Action:      "set_priority",
			Context:     []string{"list", "item_selected"},
			Priority:    80,
			Condition:   csm.hasSelectedItemCondition,
			Handler:     csm.setPriorityHandler,
		},

		// Panel management shortcuts
		{
			Key:         "ctrl+w",
			Description: "Close panel",
			Action:      "close_panel",
			Context:     []string{"any"},
			Priority:    90,
			Handler:     csm.closePanelHandler,
		},
		{
			Key:         "ctrl+shift+w",
			Description: "Close all panels",
			Action:      "close_all_panels",
			Context:     []string{"any"},
			Priority:    90,
			Handler:     csm.closeAllPanelsHandler,
		},
		{
			Key:         "ctrl+t",
			Description: "New panel",
		 Action:      "new_panel",
			Context:     []string{"any"},
			Priority:    90,
			Handler:     csm.newPanelHandler,
		},
		{
			Key:         "tab",
			Description: "Next panel",
			Action:      "next_panel",
			Context:     []string{"any"},
			Priority:    90,
			Handler:     csm.nextPanelHandler,
		},
		{
			Key:         "shift+tab",
			Description: "Previous panel",
			Action:      "prev_panel",
			Context:     []string{"any"},
			Priority:    90,
			Handler:     csm.prevPanelHandler,
		},

		// Resize and layout shortcuts
		{
			Key:         "ctrl+plus",
			Description: "Increase panel size",
			Action:      "resize_increase",
			Context:     []string{"any"},
			Priority:    70,
			Handler:     csm.resizeIncreaseHandler,
		},
		{
			Key:         "ctrl+minus",
			Description: "Decrease panel size",
			Action:      "resize_decrease",
			Context:     []string{"any"},
			Priority:    70,
			Handler:     csm.resizeDecreaseHandler,
		},
		{
			Key:         "ctrl+shift+h",
			Description: "Split horizontal",
			Action:      "split_horizontal",
			Context:     []string{"any"},
			Priority:    70,
			Handler:     csm.splitHorizontalHandler,
		},
		{
			Key:         "ctrl+shift+v",
			Description: "Split vertical",
			Action:      "split_vertical",
			Context:     []string{"any"},
			Priority:    70,
			Handler:     csm.splitVerticalHandler,
		},
	}

	for _, shortcut := range shortcuts {
		csm.RegisterShortcut(shortcut)
	}
}

// RegisterShortcut registers a new contextual shortcut
func (csm *ContextualShortcutManager) RegisterShortcut(shortcut *ContextualShortcut) {
	csm.shortcuts[shortcut.Key] = shortcut

	// Index by context
	for _, context := range shortcut.Context {
		if csm.contextShortcuts[context] == nil {
			csm.contextShortcuts[context] = make([]*ContextualShortcut, 0)
		}
		csm.contextShortcuts[context] = append(csm.contextShortcuts[context], shortcut)
	}

	csm.lastUpdate = time.Now()
}

// UpdateContext updates the current context for dynamic shortcuts
func (csm *ContextualShortcutManager) UpdateContext(context ShortcutContext) {
	csm.currentContext = context
	csm.rebuildDynamicKeyBindings()
}

// rebuildDynamicKeyBindings rebuilds the dynamic key bindings based on current context
func (csm *ContextualShortcutManager) rebuildDynamicKeyBindings() {
	csm.dynamicKeys = make(map[string]key.Binding)

	// Get available shortcuts for current context
	availableShortcuts := csm.getAvailableShortcuts()

	for _, shortcut := range availableShortcuts {
		binding := key.NewBinding(
			key.WithKeys(shortcut.Key),
			key.WithHelp(shortcut.Key, shortcut.Description),
		)
		csm.dynamicKeys[shortcut.Key] = binding
	}
}

// getAvailableShortcuts returns shortcuts available in the current context
func (csm *ContextualShortcutManager) getAvailableShortcuts() []*ContextualShortcut {
	var available []*ContextualShortcut

	// Check each registered shortcut
	for _, shortcut := range csm.shortcuts {
		if csm.isShortcutAvailable(shortcut) {
			available = append(available, shortcut)
		}
	}

	return available
}

// isShortcutAvailable checks if a shortcut is available in current context
func (csm *ContextualShortcutManager) isShortcutAvailable(shortcut *ContextualShortcut) bool {
	// Check context match
	contextMatch := false
	for _, context := range shortcut.Context {
		if context == "any" || csm.matchesCurrentContext(context) {
			contextMatch = true
			break
		}
	}

	if !contextMatch {
		return false
	}

	// Check condition if present
	if shortcut.Condition != nil {
		return shortcut.Condition(csm.panelManager, csm.currentContext.ActivePanel)
	}

	return true
}

// matchesCurrentContext checks if a context string matches the current context
func (csm *ContextualShortcutManager) matchesCurrentContext(context string) bool {
	switch context {
	case "kanban":
		return csm.currentContext.ViewMode == "kanban"
	case "list":
		return csm.currentContext.ViewMode == "list"
	case "card_selected":
		return len(csm.currentContext.SelectedItems) > 0 && csm.currentContext.ViewMode == "kanban"
	case "item_selected":
		return len(csm.currentContext.SelectedItems) > 0
	case "edit_mode":
		return csm.currentContext.EditMode
	case "filter_active":
		return csm.currentContext.FilterActive
	default:
		return false
	}
}

// HandleKeyPress handles a key press and executes the appropriate action
func (csm *ContextualShortcutManager) HandleKeyPress(key string) tea.Cmd {
	if shortcut, exists := csm.shortcuts[key]; exists {
		if csm.isShortcutAvailable(shortcut) {
			return shortcut.Handler(csm.panelManager, csm.currentContext.ActivePanel)
		}
	}
	return nil
}

// HandleKey processes a key input through the contextual system
func (csm *ContextualShortcutManager) HandleKey(keypress string, panelID PanelID) tea.Cmd {
	// Get the shortcut for this key in the current context
	if shortcut, exists := csm.shortcuts[keypress]; exists {
		// Check if this shortcut is available in current context
		if shortcut.Condition != nil && csm.panelManager != nil {
			if !shortcut.Condition(csm.panelManager, panelID) {
				return nil
			}
		}

		// Execute the handler
		if shortcut.Handler != nil && csm.panelManager != nil {
			return shortcut.Handler(csm.panelManager, panelID)
		}
	}

	return nil
}

// GetDynamicKeyBindings returns the current dynamic key bindings
func (csm *ContextualShortcutManager) GetDynamicKeyBindings() map[string]key.Binding {
	return csm.dynamicKeys
}

// GetHelpText returns help text for available shortcuts
func (csm *ContextualShortcutManager) GetHelpText() []string {
	available := csm.getAvailableShortcuts()
	help := make([]string, 0, len(available))

	for _, shortcut := range available {
		help = append(help, fmt.Sprintf("%s: %s", shortcut.Key, shortcut.Description))
	}

	return help
}

// GetAvailableShortcuts returns all available shortcuts for the current context as a map
func (csm *ContextualShortcutManager) GetAvailableShortcuts(panelID PanelID) map[string]string {
	result := make(map[string]string)

	// Get available shortcuts from internal method
	available := csm.getAvailableShortcuts()

	for _, shortcut := range available {
		// Check if shortcut is available for this panel
		if shortcut.Condition != nil && csm.panelManager != nil {
			if !shortcut.Condition(csm.panelManager, panelID) {
				continue
			}
		}

		result[shortcut.Key] = shortcut.Description
	}

	return result
}

// Condition functions
func (csm *ContextualShortcutManager) isKanbanModeCondition(pm *PanelManager, panelID PanelID) bool {
	return csm.currentContext.ViewMode == "kanban"
}

func (csm *ContextualShortcutManager) hasSelectedCardCondition(pm *PanelManager, panelID PanelID) bool {
	return len(csm.currentContext.SelectedItems) > 0 && csm.currentContext.ViewMode == "kanban"
}

func (csm *ContextualShortcutManager) hasSelectedItemCondition(pm *PanelManager, panelID PanelID) bool {
	return len(csm.currentContext.SelectedItems) > 0
}

// Handler functions
func (csm *ContextualShortcutManager) switchToPanelHandler(panelNum int) func(*PanelManager, PanelID) tea.Cmd {
	return func(pm *PanelManager, currentPanel PanelID) tea.Cmd {
		if panelNum <= len(pm.panelOrder) {
			targetPanel := pm.panelOrder[panelNum-1]
			return func() tea.Msg {
				return SwitchPanelMsg{PanelID: targetPanel}
			}
		}
		return nil
	}
}

func (csm *ContextualShortcutManager) newCardHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return NewCardMsg{PanelID: panelID}
	}
}

func (csm *ContextualShortcutManager) editCardHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return EditCardMsg{PanelID: panelID, ItemID: csm.currentContext.SelectedItems[0]}
	}
}

func (csm *ContextualShortcutManager) moveCardHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return MoveCardMsg{PanelID: panelID, ItemID: csm.currentContext.SelectedItems[0]}
	}
}

func (csm *ContextualShortcutManager) toggleCompleteHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return ToggleCompleteMsg{PanelID: panelID, ItemID: csm.currentContext.SelectedItems[0]}
	}
}

func (csm *ContextualShortcutManager) setPriorityHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return SetPriorityMsg{PanelID: panelID, ItemID: csm.currentContext.SelectedItems[0]}
	}
}

func (csm *ContextualShortcutManager) closePanelHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return ClosePanelMsg{PanelID: panelID}
	}
}

func (csm *ContextualShortcutManager) closeAllPanelsHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return CloseAllPanelsMsg{}
	}
}

func (csm *ContextualShortcutManager) newPanelHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return NewPanelMsg{}
	}
}

func (csm *ContextualShortcutManager) nextPanelHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return NextPanelMsg{}
	}
}

func (csm *ContextualShortcutManager) prevPanelHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return PrevPanelMsg{}
	}
}

func (csm *ContextualShortcutManager) resizeIncreaseHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return ResizePanelMsg{PanelID: panelID, Direction: "increase"}
	}
}

func (csm *ContextualShortcutManager) resizeDecreaseHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return ResizePanelMsg{PanelID: panelID, Direction: "decrease"}
	}
}

func (csm *ContextualShortcutManager) splitHorizontalHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return SplitPanelMsg{PanelID: panelID, Direction: "horizontal"}
	}
}

func (csm *ContextualShortcutManager) splitVerticalHandler(pm *PanelManager, panelID PanelID) tea.Cmd {
	return func() tea.Msg {
		return SplitPanelMsg{PanelID: panelID, Direction: "vertical"}
	}
}

// Message types for panel actions
type SwitchPanelMsg struct {
	PanelID PanelID
}

type NewCardMsg struct {
	PanelID PanelID
}

type EditCardMsg struct {
	PanelID PanelID
	ItemID  string
}

type MoveCardMsg struct {
	PanelID PanelID
	ItemID  string
}

type ToggleCompleteMsg struct {
	PanelID PanelID
	ItemID  string
}

type SetPriorityMsg struct {
	PanelID PanelID
	ItemID  string
}

type ClosePanelMsg struct {
	PanelID PanelID
}

type CloseAllPanelsMsg struct{}

type NewPanelMsg struct{}

type NextPanelMsg struct{}

type PrevPanelMsg struct{}

type ResizePanelMsg struct {
	PanelID   PanelID
	Direction string
}

type SplitPanelMsg struct {
	PanelID   PanelID
	Direction string
}
