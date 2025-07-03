package visualizer

import (
	"fmt"
	"strings"
)

// Dependency represents a relationship between two components.
type Dependency struct {
	Source string
	Target string
	Type   string // e.g., "calls", "uses", "depends on"
}

// GenerateMermaidGraph generates a Mermaid graph definition from a list of dependencies.
func GenerateMermaidGraph(dependencies []Dependency, graphType string) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("%s TD\n", graphType)) // Default to Graph TD

	for _, dep := range dependencies {
		// Example: A -->|uses| B
		sb.WriteString(fmt.Sprintf("    %s -- %s --> %s\n", dep.Source, dep.Type, dep.Target))
	}

	return sb.String()
}
