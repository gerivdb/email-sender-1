package tui

import (
	"fmt"
	"sort"
	"strings"
	"time"

	"email_sender/cmd/roadmap-cli/types"

	"github.com/charmbracelet/bubbles/help"
	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// HierarchyModel represents the TUI model for hierarchical navigation
type HierarchyModel struct {
	roadmap            *types.AdvancedRoadmap
	currentLevel       int
	currentPath        []string
	selectedIndex      int
	viewportContent    string
	viewport           viewport.Model
	help               help.Model
	keyMap             HierarchyKeyMap
	showDetails        bool
	showTechnicalSpecs bool
	filterComplexity   string
	width              int
	height             int
}

// HierarchyKeyMap defines keyboard shortcuts for hierarchy navigation
type HierarchyKeyMap struct {
	Up               key.Binding
	Down             key.Binding
	Enter            key.Binding
	Back             key.Binding
	Home             key.Binding
	Details          key.Binding
	TechnicalSpecs   key.Binding
	FilterComplexity key.Binding
	Search           key.Binding
	Export           key.Binding
	Help             key.Binding
	Quit             key.Binding
}

// DefaultHierarchyKeyMap returns the default key mappings
func DefaultHierarchyKeyMap() HierarchyKeyMap {
	return HierarchyKeyMap{
		Up: key.NewBinding(
			key.WithKeys("up", "k"),
			key.WithHelp("↑/k", "move up"),
		),
		Down: key.NewBinding(
			key.WithKeys("down", "j"),
			key.WithHelp("↓/j", "move down"),
		),
		Enter: key.NewBinding(
			key.WithKeys("enter", "right", "l"),
			key.WithHelp("enter/→/l", "drill down"),
		),
		Back: key.NewBinding(
			key.WithKeys("left", "h", "backspace"),
			key.WithHelp("←/h/backspace", "go back"),
		),
		Home: key.NewBinding(
			key.WithKeys("home", "g"),
			key.WithHelp("home/g", "go to root"),
		),
		Details: key.NewBinding(
			key.WithKeys("d"),
			key.WithHelp("d", "toggle details"),
		),
		TechnicalSpecs: key.NewBinding(
			key.WithKeys("t"),
			key.WithHelp("t", "toggle tech specs"),
		),
		FilterComplexity: key.NewBinding(
			key.WithKeys("f"),
			key.WithHelp("f", "filter by complexity"),
		),
		Search: key.NewBinding(
			key.WithKeys("/"),
			key.WithHelp("/", "search"),
		),
		Export: key.NewBinding(
			key.WithKeys("e"),
			key.WithHelp("e", "export current view"),
		),
		Help: key.NewBinding(
			key.WithKeys("?"),
			key.WithHelp("?", "toggle help"),
		),
		Quit: key.NewBinding(
			key.WithKeys("q", "ctrl+c"),
			key.WithHelp("q", "quit"),
		),
	}
}

// ShortHelp implements help.KeyMap
func (k HierarchyKeyMap) ShortHelp() []key.Binding {
	return []key.Binding{k.Up, k.Down, k.Enter, k.Back, k.Details, k.Help, k.Quit}
}

// FullHelp implements help.KeyMap
func (k HierarchyKeyMap) FullHelp() [][]key.Binding {
	return [][]key.Binding{
		{k.Up, k.Down, k.Enter, k.Back, k.Home},
		{k.Details, k.TechnicalSpecs, k.FilterComplexity, k.Search},
		{k.Export, k.Help, k.Quit},
	}
}

// NewHierarchyModel creates a new hierarchy navigation model
func NewHierarchyModel(roadmap *types.AdvancedRoadmap) HierarchyModel {
	vp := viewport.New(80, 20)

	model := HierarchyModel{
		roadmap:            roadmap,
		currentLevel:       1,
		currentPath:        []string{},
		selectedIndex:      0,
		viewport:           vp,
		help:               help.New(),
		keyMap:             DefaultHierarchyKeyMap(),
		showDetails:        false,
		showTechnicalSpecs: false,
		filterComplexity:   "",
	}

	model.updateViewportContent()
	return model
}

// Init implements tea.Model
func (m HierarchyModel) Init() tea.Cmd {
	return nil
}

// Update implements tea.Model
func (m HierarchyModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var (
		cmd  tea.Cmd
		cmds []tea.Cmd
	)

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.viewport.Width = msg.Width - 4
		m.viewport.Height = msg.Height - 8
		m.updateViewportContent()

	case tea.KeyMsg:
		switch {
		case key.Matches(msg, m.keyMap.Quit):
			return m, tea.Quit

		case key.Matches(msg, m.keyMap.Up):
			if m.selectedIndex > 0 {
				m.selectedIndex--
				m.updateViewportContent()
			}

		case key.Matches(msg, m.keyMap.Down):
			items := m.getCurrentLevelItems()
			if m.selectedIndex < len(items)-1 {
				m.selectedIndex++
				m.updateViewportContent()
			}

		case key.Matches(msg, m.keyMap.Enter):
			m.drillDown()

		case key.Matches(msg, m.keyMap.Back):
			m.goBack()

		case key.Matches(msg, m.keyMap.Home):
			m.goHome()

		case key.Matches(msg, m.keyMap.Details):
			m.showDetails = !m.showDetails
			m.updateViewportContent()

		case key.Matches(msg, m.keyMap.TechnicalSpecs):
			m.showTechnicalSpecs = !m.showTechnicalSpecs
			m.updateViewportContent()

		case key.Matches(msg, m.keyMap.FilterComplexity):
			m.cycleComplexityFilter()

		case key.Matches(msg, m.keyMap.Help):
			m.help.ShowAll = !m.help.ShowAll
		}
	}

	// Update the viewport
	m.viewport, cmd = m.viewport.Update(msg)
	cmds = append(cmds, cmd)

	return m, tea.Batch(cmds...)
}

// View implements tea.Model
func (m HierarchyModel) View() string {
	var sections []string

	// Header
	header := m.renderHeader()
	sections = append(sections, header)

	// Navigation breadcrumb
	breadcrumb := m.renderBreadcrumb()
	sections = append(sections, breadcrumb)

	// Main content viewport
	sections = append(sections, m.viewport.View())

	// Footer with help
	footer := m.renderFooter()
	sections = append(sections, footer)

	return lipgloss.JoinVertical(lipgloss.Left, sections...)
}

// Helper methods

func (m *HierarchyModel) getCurrentLevelItems() []types.AdvancedRoadmapItem {
	var items []types.AdvancedRoadmapItem

	for _, item := range m.roadmap.Items {
		// Check if item matches current path and level
		if m.isItemInCurrentContext(item) {
			// Apply complexity filter if set
			if m.filterComplexity != "" &&
				item.ComplexityMetrics.Overall.Level != m.filterComplexity {
				continue
			}
			items = append(items, item)
		}
	}

	// Sort by hierarchy position or creation order
	sort.Slice(items, func(i, j int) bool {
		return items[i].Hierarchy.Position < items[j].Hierarchy.Position
	})

	return items
}

func (m *HierarchyModel) isItemInCurrentContext(item types.AdvancedRoadmapItem) bool {
	// Check if item is at the current level and matches the current path
	if item.Hierarchy.Level != m.currentLevel {
		return false
	}

	// If we're at root level, show all level 1 items
	if m.currentLevel == 1 {
		return true
	}

	// Check if the item's path matches our current path
	if len(item.HierarchyPath) < len(m.currentPath) {
		return false
	}

	for i, pathPart := range m.currentPath {
		if i >= len(item.HierarchyPath) || item.HierarchyPath[i] != pathPart {
			return false
		}
	}

	return true
}

func (m *HierarchyModel) drillDown() {
	items := m.getCurrentLevelItems()
	if m.selectedIndex >= len(items) {
		return
	}

	selectedItem := items[m.selectedIndex]

	// Check if there are child items
	hasChildren := m.hasChildItems(selectedItem)

	if hasChildren && m.currentLevel < m.roadmap.MaxDepth {
		// Drill down to next level
		m.currentPath = append(m.currentPath, selectedItem.Title)
		m.currentLevel++
		m.selectedIndex = 0
		m.updateViewportContent()
	}
}

func (m *HierarchyModel) hasChildItems(item types.AdvancedRoadmapItem) bool {
	childLevel := item.Hierarchy.Level + 1

	for _, otherItem := range m.roadmap.Items {
		if otherItem.Hierarchy.Level == childLevel && otherItem.ParentItemID == item.ID {
			return true
		}
	}

	return false
}

func (m *HierarchyModel) goBack() {
	if m.currentLevel > 1 {
		m.currentLevel--
		if len(m.currentPath) > 0 {
			m.currentPath = m.currentPath[:len(m.currentPath)-1]
		}
		m.selectedIndex = 0
		m.updateViewportContent()
	}
}

func (m *HierarchyModel) goHome() {
	m.currentLevel = 1
	m.currentPath = []string{}
	m.selectedIndex = 0
	m.updateViewportContent()
}

func (m *HierarchyModel) cycleComplexityFilter() {
	filters := []string{"", "trivial", "simple", "moderate", "complex", "expert"}

	currentIndex := 0
	for i, filter := range filters {
		if filter == m.filterComplexity {
			currentIndex = i
			break
		}
	}

	nextIndex := (currentIndex + 1) % len(filters)
	m.filterComplexity = filters[nextIndex]
	m.selectedIndex = 0
	m.updateViewportContent()
}

func (m *HierarchyModel) updateViewportContent() {
	var content strings.Builder

	items := m.getCurrentLevelItems()

	if len(items) == 0 {
		content.WriteString("No items found at this level")
		if m.filterComplexity != "" {
			content.WriteString(fmt.Sprintf(" (filtered by complexity: %s)", m.filterComplexity))
		}
		content.WriteString("\n\nPress 'h' or 'backspace' to go back")
	} else {
		for i, item := range items {
			m.renderItem(&content, item, i == m.selectedIndex)
		}
	}

	m.viewportContent = content.String()
	m.viewport.SetContent(m.viewportContent)
}

func (m *HierarchyModel) renderItem(content *strings.Builder, item types.AdvancedRoadmapItem, isSelected bool) {
	// Style for selected item
	var style lipgloss.Style
	if isSelected {
		style = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("205")).
			Background(lipgloss.Color("236"))
	} else {
		style = lipgloss.NewStyle()
	}

	// Item indicator
	indicator := "  "
	if isSelected {
		indicator = "▶ "
	}

	// Check if item has children
	hasChildren := m.hasChildItems(item)
	childIndicator := ""
	if hasChildren {
		childIndicator = " +"
	}

	// Main title line
	titleLine := fmt.Sprintf("%s%s%s", indicator, item.Title, childIndicator)
	content.WriteString(style.Render(titleLine))
	content.WriteString("\n")

	if m.showDetails || isSelected {
		m.renderItemDetails(content, item, isSelected)
	}

	content.WriteString("\n")
}

func (m *HierarchyModel) renderItemDetails(content *strings.Builder, item types.AdvancedRoadmapItem, _ bool) {
	indent := "    "

	// Status and priority
	if item.Status != "pending" || item.Priority != "medium" {
		content.WriteString(fmt.Sprintf("%sStatus: %s | Priority: %s\n",
			indent, item.Status, item.Priority))
	}

	// Complexity metrics
	if item.ComplexityMetrics.Overall.Score > 0 {
		content.WriteString(fmt.Sprintf("%sComplexity: %s (%d/10)",
			indent,
			item.ComplexityMetrics.Overall.Level,
			item.ComplexityMetrics.Overall.Score))

		if item.ComplexityMetrics.RiskLevel != "" {
			content.WriteString(fmt.Sprintf(" | Risk: %s", item.ComplexityMetrics.RiskLevel))
		}
		content.WriteString("\n")
	}

	// Effort estimation
	if item.EstimatedEffort > 0 {
		content.WriteString(fmt.Sprintf("%sEstimated Effort: %s\n",
			indent, formatDuration(item.EstimatedEffort)))
	}

	// Dependencies
	if len(item.TechnicalDependencies) > 0 {
		content.WriteString(fmt.Sprintf("%sDependencies: %d\n",
			indent, len(item.TechnicalDependencies)))
	}

	// Implementation steps
	if len(item.ImplementationSteps) > 0 {
		content.WriteString(fmt.Sprintf("%sImplementation Steps: %d\n",
			indent, len(item.ImplementationSteps)))
	}

	// Description (truncated)
	if item.Description != "" {
		desc := item.Description
		if len(desc) > 150 {
			desc = desc[:147] + "..."
		}
		// Replace newlines with spaces for compact display
		desc = strings.ReplaceAll(desc, "\n", " ")
		content.WriteString(fmt.Sprintf("%s%s\n", indent, desc))
	}

	// Technical specifications (if enabled)
	if m.showTechnicalSpecs && hasNonEmptyTechnicalSpecs(&item.TechnicalSpec) {
		m.renderTechnicalSpecs(content, item, indent)
	}
}

func (m *HierarchyModel) renderTechnicalSpecs(content *strings.Builder, item types.AdvancedRoadmapItem, indent string) {
	subIndent := indent + "  "

	if len(item.TechnicalSpec.DatabaseSchemas) > 0 {
		content.WriteString(fmt.Sprintf("%sDatabase Schemas:\n", indent))
		for _, schema := range item.TechnicalSpec.DatabaseSchemas {
			content.WriteString(fmt.Sprintf("%s- %s (%d fields)\n",
				subIndent, schema.TableName, len(schema.Fields)))
		}
	}

	if len(item.TechnicalSpec.APIEndpoints) > 0 {
		content.WriteString(fmt.Sprintf("%sAPI Endpoints:\n", indent))
		for _, endpoint := range item.TechnicalSpec.APIEndpoints {
			content.WriteString(fmt.Sprintf("%s- %s %s\n",
				subIndent, endpoint.Method, endpoint.Path))
		}
	}

	if len(item.TechnicalSpec.CodeReferences) > 0 {
		content.WriteString(fmt.Sprintf("%sCode References:\n", indent))
		for _, codeRef := range item.TechnicalSpec.CodeReferences {
			content.WriteString(fmt.Sprintf("%s- %s (%s)\n",
				subIndent, codeRef.FilePath, codeRef.Language))
		}
	}
}

func (m *HierarchyModel) renderHeader() string {
	title := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("205")).
		Render(fmt.Sprintf("TaskMaster Hierarchy Navigator - %s", m.roadmap.Name))

	stats := fmt.Sprintf("Items: %d | Progress: %.1f%% | Max Depth: %d",
		m.roadmap.TotalItems, m.roadmap.OverallProgress, m.roadmap.MaxDepth)

	return lipgloss.JoinHorizontal(lipgloss.Left, title, "  ", stats)
}

func (m *HierarchyModel) renderBreadcrumb() string {
	var breadcrumb strings.Builder

	breadcrumb.WriteString("📍 ")

	if len(m.currentPath) == 0 {
		breadcrumb.WriteString("Root")
	} else {
		breadcrumb.WriteString("Root")
		for _, pathPart := range m.currentPath {
			breadcrumb.WriteString(" > ")
			breadcrumb.WriteString(pathPart)
		}
	}

	breadcrumb.WriteString(fmt.Sprintf(" (Level %d)", m.currentLevel))

	if m.filterComplexity != "" {
		breadcrumb.WriteString(fmt.Sprintf(" [Filter: %s]", m.filterComplexity))
	}

	if m.showDetails {
		breadcrumb.WriteString(" [Details]")
	}

	if m.showTechnicalSpecs {
		breadcrumb.WriteString(" [Tech Specs]")
	}

	return breadcrumb.String()
}

func (m *HierarchyModel) renderFooter() string {
	return m.help.View(m.keyMap)
}

// Utility functions

func formatDuration(d time.Duration) string {
	hours := d.Hours()
	if hours < 24 {
		return fmt.Sprintf("%.1f hours", hours)
	}
	days := hours / 24
	if days < 7 {
		return fmt.Sprintf("%.1f days", days)
	}
	weeks := days / 7
	return fmt.Sprintf("%.1f weeks", weeks)
}

func hasNonEmptyTechnicalSpecs(spec *types.TechnicalSpec) bool {
	return len(spec.DatabaseSchemas) > 0 ||
		len(spec.APIEndpoints) > 0 ||
		len(spec.CodeReferences) > 0 ||
		len(spec.SystemRequirements) > 0 ||
		len(spec.PerformanceTargets) > 0
}
