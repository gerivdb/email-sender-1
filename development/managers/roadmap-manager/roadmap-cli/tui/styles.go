package tui

import "github.com/charmbracelet/lipgloss"

// Shared styles for TUI components
var (
	SelectedStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("12")).
			Bold(true)

	NormalStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("15"))

	MetaStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("8"))

	HeaderStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("14")).
			Border(lipgloss.DoubleBorder()).
			Padding(0, 1)

	HelpStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("8")).
			Italic(true)
)
