package navigation

import (
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/lipgloss"
	tea "github.com/charmbracelet/bubbletea"
)

// ViewRenderer handles rendering for different navigation modes and views
type ViewRenderer struct {
	currentMode    NavigationMode
	currentView    ViewMode
	styles         *RenderStyles
	animations     *AnimationManager
	layout         *LayoutManager
	accessibility  *AccessibilityRenderer
}

// RenderStyles contains styling for different modes and views
type RenderStyles struct {
	Normal        ModeStyles `json:"normal"`
	Vim           ModeStyles `json:"vim"`
	Accessibility ModeStyles `json:"accessibility"`
	Custom        ModeStyles `json:"custom"`
}

// ModeStyles contains styles for a specific navigation mode
type ModeStyles struct {
	Background      lipgloss.Style `json:"background"`
	Foreground      lipgloss.Style `json:"foreground"`
	Border          lipgloss.Style `json:"border"`
	Selected        lipgloss.Style `json:"selected"`
	Focused         lipgloss.Style `json:"focused"`
	Disabled        lipgloss.Style `json:"disabled"`
	StatusBar       lipgloss.Style `json:"status_bar"`
	Toolbar         lipgloss.Style `json:"toolbar"`
	Sidebar         lipgloss.Style `json:"sidebar"`
	Modal           lipgloss.Style `json:"modal"`
	Error           lipgloss.Style `json:"error"`
	Warning         lipgloss.Style `json:"warning"`
	Success         lipgloss.Style `json:"success"`
	Info            lipgloss.Style `json:"info"`
	HighContrast    bool           `json:"high_contrast"`
	ReducedMotion   bool           `json:"reduced_motion"`
	LargeText       bool           `json:"large_text"`
}

// AnimationManager handles animations and transitions
type AnimationManager struct {
	currentAnimation *Animation
	animationQueue   []Animation
	preferences      AnimationPreferences
}

// Animation represents an active animation
type Animation struct {
	ID           string        `json:"id"`
	Type         string        `json:"type"`
	StartTime    time.Time     `json:"start_time"`
	Duration     time.Duration `json:"duration"`
	Progress     float64       `json:"progress"`
	Easing       string        `json:"easing"`
	FromState    interface{}   `json:"from_state"`
	ToState      interface{}   `json:"to_state"`
	CurrentState interface{}   `json:"current_state"`
	Completed    bool          `json:"completed"`
}

// AnimationPreferences contains animation preferences
type AnimationPreferences struct {
	Enabled          bool          `json:"enabled"`
	ReducedMotion    bool          `json:"reduced_motion"`
	DefaultDuration  time.Duration `json:"default_duration"`
	DefaultEasing    string        `json:"default_easing"`
	FadeEnabled      bool          `json:"fade_enabled"`
	SlideEnabled     bool          `json:"slide_enabled"`
	ScaleEnabled     bool          `json:"scale_enabled"`
	RotateEnabled    bool          `json:"rotate_enabled"`
}

// LayoutManager handles layout adaptation for different modes
type LayoutManager struct {
	currentLayout  LayoutConfig
	layouts        map[string]LayoutConfig
	adaptiveMode   bool
	screenSize     Position
	panelStates    map[string]PanelState
}

// PanelState represents the state of a UI panel
type PanelState struct {
	ID          string    `json:"id"`
	Visible     bool      `json:"visible"`
	Size        Position  `json:"size"`
	Position    Position  `json:"position"`
	ZIndex      int       `json:"z_index"`
	Resizable   bool      `json:"resizable"`
	Movable     bool      `json:"movable"`
	Minimized   bool      `json:"minimized"`
	Maximized   bool      `json:"maximized"`
	LastUpdated time.Time `json:"last_updated"`
}

// AccessibilityRenderer handles accessibility-specific rendering
type AccessibilityRenderer struct {
	screenReader    bool
	highContrast    bool
	largeText       bool
	keyboardOnly    bool
	reducedMotion   bool
	audioFeedback   bool
	focusIndicator  lipgloss.Style
	landmarks       []string
	headingLevels   map[string]int
}

// RenderConfig represents rendering configuration
type RenderConfig struct {
	Width           int                    `json:"width"`
	Height          int                    `json:"height"`
	Mode            NavigationMode         `json:"mode"`
	View            ViewMode               `json:"view"`
	ShowAnimations  bool                   `json:"show_animations"`
	HighContrast    bool                   `json:"high_contrast"`
	LargeText       bool                   `json:"large_text"`
	CustomSettings  map[string]interface{} `json:"custom_settings"`
}

// RenderResult represents the result of a render operation
type RenderResult struct {
	Content         string                 `json:"content"`
	Styles          []lipgloss.Style       `json:"styles"`
	Animations      []Animation            `json:"animations"`
	Accessibility   AccessibilityInfo      `json:"accessibility"`
	Performance     RenderPerformance      `json:"performance"`
	Metadata        map[string]interface{} `json:"metadata"`
}

// AccessibilityInfo contains accessibility information
type AccessibilityInfo struct {
	AriaLabels      map[string]string `json:"aria_labels"`
	TabOrder        []string          `json:"tab_order"`
	Landmarks       []string          `json:"landmarks"`
	HeadingStructure []HeadingInfo    `json:"heading_structure"`
	FocusPath       []string          `json:"focus_path"`
	ScreenReaderText string           `json:"screen_reader_text"`
}

// HeadingInfo represents heading information for accessibility
type HeadingInfo struct {
	Level   int    `json:"level"`
	Text    string `json:"text"`
	ID      string `json:"id"`
	Section string `json:"section"`
}

// RenderPerformance contains performance metrics
type RenderPerformance struct {
	RenderTime      time.Duration `json:"render_time"`
	LayoutTime      time.Duration `json:"layout_time"`
	StyleTime       time.Duration `json:"style_time"`
	AnimationTime   time.Duration `json:"animation_time"`
	MemoryUsage     int64         `json:"memory_usage"`
	CacheHitRate    float64       `json:"cache_hit_rate"`
}

// NewViewRenderer creates a new view renderer
func NewViewRenderer() *ViewRenderer {
	return &ViewRenderer{
		currentMode:   NavigationModeNormal,
		currentView:   ViewModeList,
		styles:        NewDefaultRenderStyles(),
		animations:    NewAnimationManager(),
		layout:        NewLayoutManager(),
		accessibility: NewAccessibilityRenderer(),
	}
}

// AdaptLayout adapts the layout for the current mode and view
func (vr *ViewRenderer) AdaptLayout(config RenderConfig) (*RenderResult, error) {
	startTime := time.Now()

	// Select appropriate styles based on mode
	modeStyles := vr.getModeStyles(config.Mode)
	
	// Apply accessibility adaptations
	if config.HighContrast {
		modeStyles = vr.applyHighContrastStyles(modeStyles)
	}
	
	if config.LargeText {
		modeStyles = vr.applyLargeTextStyles(modeStyles)
	}

	// Generate layout based on view mode
	layout := vr.generateViewLayout(config.View, config.Width, config.Height)
	
	// Apply mode-specific layout modifications
	layout = vr.applyModeLayoutModifications(layout, config.Mode)

	// Generate content
	content := vr.renderContent(layout, modeStyles, config)
	
	// Handle animations
	animations := make([]Animation, 0)
	if config.ShowAnimations && vr.animations.preferences.Enabled {
		animations = vr.getActiveAnimations()
	}

	// Generate accessibility information
	accessibilityInfo := vr.generateAccessibilityInfo(layout, config.Mode)

	// Calculate performance metrics
	performance := RenderPerformance{
		RenderTime:    time.Since(startTime),
		LayoutTime:    50 * time.Millisecond, // Placeholder
		StyleTime:     20 * time.Millisecond, // Placeholder
		AnimationTime: 10 * time.Millisecond, // Placeholder
		MemoryUsage:   1024,                   // Placeholder
		CacheHitRate:  0.85,                   // Placeholder
	}

	return &RenderResult{
		Content:       content,
		Styles:        []lipgloss.Style{modeStyles.Background},
		Animations:    animations,
		Accessibility: accessibilityInfo,
		Performance:   performance,
		Metadata: map[string]interface{}{
			"mode":   config.Mode.String(),
			"view":   config.View.String(),
			"width":  config.Width,
			"height": config.Height,
		},
	}, nil
}

// RenderModeIndicator renders a mode indicator
func (vr *ViewRenderer) RenderModeIndicator(mode NavigationMode) string {
	styles := vr.getModeStyles(mode)
	
	modeText := strings.ToUpper(mode.String())
	switch mode {
	case NavigationModeNormal:
		return styles.StatusBar.Render(fmt.Sprintf(" %s ", modeText))
	case NavigationModeVim:
		return styles.StatusBar.Background(lipgloss.Color("#ff6b6b")).Render(fmt.Sprintf(" %s ", modeText))
	case NavigationModeAccessibility:
		return styles.StatusBar.Background(lipgloss.Color("#4ecdc4")).Render(fmt.Sprintf(" ♿ %s ", modeText))
	case NavigationModeCustom:
		return styles.StatusBar.Background(lipgloss.Color("#ffe66d")).Render(fmt.Sprintf(" ⚙ %s ", modeText))
	default:
		return styles.StatusBar.Render(fmt.Sprintf(" %s ", modeText))
	}
}

// RenderViewHeader renders a view header
func (vr *ViewRenderer) RenderViewHeader(view ViewMode, title string) string {
	styles := vr.getModeStyles(vr.currentMode)
	
	viewIcon := vr.getViewIcon(view)
	headerText := fmt.Sprintf("%s %s", viewIcon, title)
	
	return styles.Toolbar.
		Width(50).
		Padding(0, 1).
		Render(headerText)
}

// RenderTransition renders a view transition
func (vr *ViewRenderer) RenderTransition(transition ModeTransition) tea.Cmd {
	if !vr.animations.preferences.Enabled {
		return nil
	}

	animation := Animation{
		ID:        fmt.Sprintf("transition_%d", time.Now().Unix()),
		Type:      transition.AnimationType,
		StartTime: time.Now(),
		Duration:  transition.Duration,
		Progress:  0.0,
		Easing:    "ease-in-out",
		Completed: false,
	}

	vr.animations.animationQueue = append(vr.animations.animationQueue, animation)

	return tea.Tick(time.Millisecond*16, func(t time.Time) tea.Msg {
		return AnimationTickMsg{
			AnimationID: animation.ID,
			Timestamp:   t,
		}
	})
}

// UpdateAnimation updates an active animation
func (vr *ViewRenderer) UpdateAnimation(animationID string) {
	for i, animation := range vr.animations.animationQueue {
		if animation.ID == animationID {
			elapsed := time.Since(animation.StartTime)
			progress := float64(elapsed) / float64(animation.Duration)
			
			if progress >= 1.0 {
				progress = 1.0
				animation.Completed = true
			}
			
			animation.Progress = vr.applyEasing(progress, animation.Easing)
			vr.animations.animationQueue[i] = animation
			
			if animation.Completed {
				vr.removeCompletedAnimation(animationID)
			}
			break
		}
	}
}

// SetMode sets the current rendering mode
func (vr *ViewRenderer) SetMode(mode NavigationMode) {
	vr.currentMode = mode
	vr.accessibility.updateForMode(mode)
}

// SetView sets the current view
func (vr *ViewRenderer) SetView(view ViewMode) {
	vr.currentView = view
	vr.layout.adaptForView(view)
}

// GetAccessibilityInfo returns accessibility information
func (vr *ViewRenderer) GetAccessibilityInfo() AccessibilityInfo {
	return vr.generateAccessibilityInfo(vr.layout.currentLayout, vr.currentMode)
}

// Private helper methods

func (vr *ViewRenderer) getModeStyles(mode NavigationMode) ModeStyles {
	switch mode {
	case NavigationModeNormal:
		return vr.styles.Normal
	case NavigationModeVim:
		return vr.styles.Vim
	case NavigationModeAccessibility:
		return vr.styles.Accessibility
	case NavigationModeCustom:
		return vr.styles.Custom
	default:
		return vr.styles.Normal
	}
}

func (vr *ViewRenderer) applyHighContrastStyles(styles ModeStyles) ModeStyles {
	styles.Background = styles.Background.Background(lipgloss.Color("#000000"))
	styles.Foreground = styles.Foreground.Foreground(lipgloss.Color("#ffffff"))
	styles.Selected = styles.Selected.Background(lipgloss.Color("#ffffff")).Foreground(lipgloss.Color("#000000"))
	styles.Focused = styles.Focused.Border(lipgloss.ThickBorder()).BorderForeground(lipgloss.Color("#ffffff"))
	return styles
}

func (vr *ViewRenderer) applyLargeTextStyles(styles ModeStyles) ModeStyles {
	// Apply larger text sizes (implementation would depend on the lipgloss version)
	// This is a placeholder for demonstration
	styles.Foreground = styles.Foreground.Bold(true)
	styles.Selected = styles.Selected.Bold(true)
	styles.Focused = styles.Focused.Bold(true)
	return styles
}

func (vr *ViewRenderer) generateViewLayout(view ViewMode, width, height int) LayoutConfig {
	switch view {
	case ViewModeList:
		return LayoutConfig{
			PanelLayout:   "vertical",
			ShowSidebar:   true,
			ShowStatusBar: true,
			ShowToolbar:   true,
			GridColumns:   1,
			GridRows:      1,
		}
	case ViewModeKanban:
		return LayoutConfig{
			PanelLayout:   "horizontal",
			ShowSidebar:   false,
			ShowStatusBar: true,
			ShowToolbar:   true,
			GridColumns:   3,
			GridRows:      1,
		}
	case ViewModeCalendar:
		return LayoutConfig{
			PanelLayout:   "grid",
			ShowSidebar:   true,
			ShowStatusBar: true,
			ShowToolbar:   true,
			GridColumns:   7,
			GridRows:      6,
		}
	case ViewModeMatrix:
		return LayoutConfig{
			PanelLayout:   "matrix",
			ShowSidebar:   false,
			ShowStatusBar: true,
			ShowToolbar:   false,
			GridColumns:   2,
			GridRows:      2,
		}
	default:
		return LayoutConfig{
			PanelLayout:   "standard",
			ShowSidebar:   true,
			ShowStatusBar: true,
			ShowToolbar:   true,
		}
	}
}

func (vr *ViewRenderer) applyModeLayoutModifications(layout LayoutConfig, mode NavigationMode) LayoutConfig {
	switch mode {
	case NavigationModeVim:
		layout.ShowToolbar = false
		layout.ShowSidebar = false
	case NavigationModeAccessibility:
		layout.ShowToolbar = true
		layout.ShowSidebar = true
		layout.ShowStatusBar = true
	case NavigationModeCustom:
		// Apply custom modifications
	}
	return layout
}

func (vr *ViewRenderer) renderContent(layout LayoutConfig, styles ModeStyles, config RenderConfig) string {
	var content strings.Builder
	
	// Render based on layout type
	switch layout.PanelLayout {
	case "vertical":
		content.WriteString(vr.renderVerticalLayout(layout, styles, config))
	case "horizontal":
		content.WriteString(vr.renderHorizontalLayout(layout, styles, config))
	case "grid":
		content.WriteString(vr.renderGridLayout(layout, styles, config))
	case "matrix":
		content.WriteString(vr.renderMatrixLayout(layout, styles, config))
	default:
		content.WriteString(vr.renderStandardLayout(layout, styles, config))
	}
	
	return content.String()
}

func (vr *ViewRenderer) renderVerticalLayout(layout LayoutConfig, styles ModeStyles, config RenderConfig) string {
	return styles.Background.
		Width(config.Width).
		Height(config.Height).
		Render("Vertical Layout\n[Content would be rendered here]")
}

func (vr *ViewRenderer) renderHorizontalLayout(layout LayoutConfig, styles ModeStyles, config RenderConfig) string {
	return styles.Background.
		Width(config.Width).
		Height(config.Height).
		Render("Horizontal Layout\n[Content would be rendered here]")
}

func (vr *ViewRenderer) renderGridLayout(layout LayoutConfig, styles ModeStyles, config RenderConfig) string {
	return styles.Background.
		Width(config.Width).
		Height(config.Height).
		Render("Grid Layout\n[Content would be rendered here]")
}

func (vr *ViewRenderer) renderMatrixLayout(layout LayoutConfig, styles ModeStyles, config RenderConfig) string {
	return styles.Background.
		Width(config.Width).
		Height(config.Height).
		Render("Matrix Layout\n[Content would be rendered here]")
}

func (vr *ViewRenderer) renderStandardLayout(layout LayoutConfig, styles ModeStyles, config RenderConfig) string {
	return styles.Background.
		Width(config.Width).
		Height(config.Height).
		Render("Standard Layout\n[Content would be rendered here]")
}

func (vr *ViewRenderer) getActiveAnimations() []Animation {
	active := make([]Animation, 0)
	for _, animation := range vr.animations.animationQueue {
		if !animation.Completed {
			active = append(active, animation)
		}
	}
	return active
}

func (vr *ViewRenderer) generateAccessibilityInfo(layout LayoutConfig, mode NavigationMode) AccessibilityInfo {
	return AccessibilityInfo{
		AriaLabels: map[string]string{
			"main":    "Main content area",
			"sidebar": "Navigation sidebar",
			"toolbar": "Application toolbar",
		},
		TabOrder:        []string{"toolbar", "sidebar", "main", "statusbar"},
		Landmarks:       []string{"banner", "navigation", "main", "contentinfo"},
		HeadingStructure: []HeadingInfo{
			{Level: 1, Text: "TaskMaster", ID: "main-title", Section: "header"},
		},
		FocusPath:       []string{"main"},
		ScreenReaderText: fmt.Sprintf("Navigation mode: %s, View mode: %s", mode.String(), vr.currentView.String()),
	}
}

func (vr *ViewRenderer) getViewIcon(view ViewMode) string {
	switch view {
	case ViewModeList:
		return "📋"
	case ViewModeKanban:
		return "📊"
	case ViewModeCalendar:
		return "📅"
	case ViewModeMatrix:
		return "⚡"
	case ViewModeGantt:
		return "📈"
	case ViewModeTimeline:
		return "⏱️"
	default:
		return "📄"
	}
}

func (vr *ViewRenderer) applyEasing(progress float64, easing string) float64 {
	switch easing {
	case "ease-in":
		return progress * progress
	case "ease-out":
		return 1 - ((1 - progress) * (1 - progress))
	case "ease-in-out":
		if progress < 0.5 {
			return 2 * progress * progress
		}
		return 1 - 2*((1-progress)*(1-progress))
	default:
		return progress // Linear
	}
}

func (vr *ViewRenderer) removeCompletedAnimation(animationID string) {
	for i, animation := range vr.animations.animationQueue {
		if animation.ID == animationID {
			vr.animations.animationQueue = append(
				vr.animations.animationQueue[:i],
				vr.animations.animationQueue[i+1:]...,
			)
			break
		}
	}
}

// Bubble Tea Messages for rendering
type AnimationTickMsg struct {
	AnimationID string
	Timestamp   time.Time
}

type RenderCompleteMsg struct {
	Result *RenderResult
}

type LayoutChangedMsg struct {
	Layout LayoutConfig
}

// Factory functions

func NewDefaultRenderStyles() *RenderStyles {
	// Base colors
	primaryBg := lipgloss.Color("#1a1a1a")
	primaryFg := lipgloss.Color("#ffffff")
	accentColor := lipgloss.Color("#7c3aed")
	
	baseStyle := lipgloss.NewStyle().
		Foreground(primaryFg).
		Background(primaryBg)
	
	selectedStyle := baseStyle.Copy().
		Background(accentColor).
		Bold(true)
	
	focusedStyle := baseStyle.Copy().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(accentColor)

	return &RenderStyles{
		Normal: ModeStyles{
			Background: baseStyle,
			Foreground: baseStyle,
			Selected:   selectedStyle,
			Focused:    focusedStyle,
			StatusBar:  baseStyle.Copy().Background(lipgloss.Color("#2d2d2d")),
			Toolbar:    baseStyle.Copy().Background(lipgloss.Color("#2d2d2d")),
			Sidebar:    baseStyle.Copy().Background(lipgloss.Color("#1a1a1a")),
			Error:      baseStyle.Copy().Foreground(lipgloss.Color("#ff6b6b")),
			Warning:    baseStyle.Copy().Foreground(lipgloss.Color("#ffd93d")),
			Success:    baseStyle.Copy().Foreground(lipgloss.Color("#6bcf7f")),
			Info:       baseStyle.Copy().Foreground(lipgloss.Color("#4dabf7")),
		},
		Vim: ModeStyles{
			Background: baseStyle.Copy().Background(lipgloss.Color("#0f0f0f")),
			Foreground: baseStyle.Copy().Foreground(lipgloss.Color("#00ff00")),
			Selected:   selectedStyle.Copy().Background(lipgloss.Color("#005500")),
			Focused:    focusedStyle.Copy().BorderForeground(lipgloss.Color("#00ff00")),
			StatusBar:  baseStyle.Copy().Background(lipgloss.Color("#003300")),
		},
		Accessibility: ModeStyles{
			Background:    baseStyle.Copy().Background(lipgloss.Color("#000000")),
			Foreground:    baseStyle.Copy().Foreground(lipgloss.Color("#ffffff")),
			Selected:      selectedStyle.Copy().Background(lipgloss.Color("#ffffff")).Foreground(lipgloss.Color("#000000")),
			Focused:       focusedStyle.Copy().Border(lipgloss.ThickBorder()),
			HighContrast:  true,
			ReducedMotion: true,
			LargeText:     true,
		},
		Custom: ModeStyles{
			Background: baseStyle,
			Foreground: baseStyle,
			Selected:   selectedStyle,
			Focused:    focusedStyle,
		},
	}
}

func NewAnimationManager() *AnimationManager {
	return &AnimationManager{
		animationQueue: make([]Animation, 0),
		preferences: AnimationPreferences{
			Enabled:         true,
			ReducedMotion:   false,
			DefaultDuration: 300 * time.Millisecond,
			DefaultEasing:   "ease-in-out",
			FadeEnabled:     true,
			SlideEnabled:    true,
			ScaleEnabled:    true,
			RotateEnabled:   false,
		},
	}
}

func NewLayoutManager() *LayoutManager {
	return &LayoutManager{
		layouts:     make(map[string]LayoutConfig),
		adaptiveMode: true,
		panelStates: make(map[string]PanelState),
	}
}

func NewAccessibilityRenderer() *AccessibilityRenderer {
	return &AccessibilityRenderer{
		screenReader:   false,
		highContrast:   false,
		largeText:      false,
		keyboardOnly:   false,
		reducedMotion:  false,
		audioFeedback:  false,
		landmarks:      make([]string, 0),
		headingLevels:  make(map[string]int),
		focusIndicator: lipgloss.NewStyle().Border(lipgloss.ThickBorder()).BorderForeground(lipgloss.Color("#ffffff")),
	}
}

func (ar *AccessibilityRenderer) updateForMode(mode NavigationMode) {
	switch mode {
	case NavigationModeAccessibility:
		ar.screenReader = true
		ar.highContrast = true
		ar.largeText = true
		ar.keyboardOnly = true
		ar.reducedMotion = true
		ar.audioFeedback = true
	default:
		ar.screenReader = false
		ar.highContrast = false
		ar.largeText = false
		ar.keyboardOnly = false
		ar.reducedMotion = false
		ar.audioFeedback = false
	}
}

func (lm *LayoutManager) adaptForView(view ViewMode) {
	// Adapt layout based on view mode
	switch view {
	case ViewModeKanban:
		lm.currentLayout.PanelLayout = "horizontal"
		lm.currentLayout.GridColumns = 3
	case ViewModeCalendar:
		lm.currentLayout.PanelLayout = "grid"
		lm.currentLayout.GridColumns = 7
		lm.currentLayout.GridRows = 6
	case ViewModeMatrix:
		lm.currentLayout.PanelLayout = "matrix"
		lm.currentLayout.GridColumns = 2
		lm.currentLayout.GridRows = 2
	default:
		lm.currentLayout.PanelLayout = "vertical"
		lm.currentLayout.GridColumns = 1
	}
}
