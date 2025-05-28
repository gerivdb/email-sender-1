// Package diff provides unified diff generation for reports
package diff

import (
	"fmt"
	"strings"
)

// UnifiedDiff represents a unified diff format generator
type UnifiedDiff struct {
	ContextLines int
}

// DiffLine represents a single line in a diff with its content and type
type DiffLine struct {
	Content string
	Type    LineType
}

// LineType represents the type of a diff line
type LineType int

const (
	// LineUnchanged represents unchanged lines
	LineUnchanged LineType = iota
	// LineAdded represents added lines
	LineAdded
	// LineRemoved represents removed lines
	LineRemoved
)

// NewUnifiedDiff creates a new UnifiedDiff instance
func NewUnifiedDiff(contextLines int) *UnifiedDiff {
	return &UnifiedDiff{
		ContextLines: contextLines,
	}
}

// Generate generates a unified diff between two texts
func (ud *UnifiedDiff) Generate(oldText, newText string) (string, error) {
	oldLines := strings.Split(oldText, "\n")
	newLines := strings.Split(newText, "\n")
	
	diffLines := ud.computeDiff(oldLines, newLines)
	return ud.formatDiff(diffLines), nil
}

// computeDiff computes the differences between two sets of lines
func (ud *UnifiedDiff) computeDiff(oldLines, newLines []string) []DiffLine {
	// Use Longest Common Subsequence (LCS) algorithm
	lcs := ud.lcs(oldLines, newLines)
	diffLines := make([]DiffLine, 0)

	oldIndex, newIndex := 0, 0
	
	for _, line := range lcs {
		// Add removed lines
		for oldIndex < len(oldLines) && oldLines[oldIndex] != line {
			diffLines = append(diffLines, DiffLine{Content: oldLines[oldIndex], Type: LineRemoved})
			oldIndex++
		}
		
		// Add added lines
		for newIndex < len(newLines) && newLines[newIndex] != line {
			diffLines = append(diffLines, DiffLine{Content: newLines[newIndex], Type: LineAdded})
			newIndex++
		}
		
		// Add unchanged line
		if oldIndex < len(oldLines) && newIndex < len(newLines) {
			diffLines = append(diffLines, DiffLine{Content: line, Type: LineUnchanged})
			oldIndex++
			newIndex++
		}
	}

	// Add remaining lines
	for oldIndex < len(oldLines) {
		diffLines = append(diffLines, DiffLine{Content: oldLines[oldIndex], Type: LineRemoved})
		oldIndex++
	}
	for newIndex < len(newLines) {
		diffLines = append(diffLines, DiffLine{Content: newLines[newIndex], Type: LineAdded})
		newIndex++
	}

	return ud.addContext(diffLines)
}

// lcs computes the Longest Common Subsequence between two sets of lines
func (ud *UnifiedDiff) lcs(oldLines, newLines []string) []string {
	m, n := len(oldLines), len(newLines)
	dp := make([][]int, m+1)
	for i := range dp {
		dp[i] = make([]int, n+1)
	}

	// Fill the dp table
	for i := 1; i <= m; i++ {
		for j := 1; j <= n; j++ {
			if oldLines[i-1] == newLines[j-1] {
				dp[i][j] = dp[i-1][j-1] + 1
			} else {
				dp[i][j] = max(dp[i-1][j], dp[i][j-1])
			}
		}
	}

	// Reconstruct the LCS
	lcs := make([]string, 0)
	i, j := m, n
	for i > 0 && j > 0 {
		if oldLines[i-1] == newLines[j-1] {
			lcs = append([]string{oldLines[i-1]}, lcs...)
			i--
			j--
		} else if dp[i-1][j] > dp[i][j-1] {
			i--
		} else {
			j--
		}
	}

	return lcs
}

// addContext adds context lines around changes
func (ud *UnifiedDiff) addContext(diffLines []DiffLine) []DiffLine {
	if ud.ContextLines <= 0 {
		return diffLines
	}

	result := make([]DiffLine, 0)
	inChange := false
	changeStart := 0

	for i, line := range diffLines {
		if line.Type != LineUnchanged && !inChange {
			// Start of a change block
			inChange = true
			changeStart = max(0, i-ud.ContextLines)
			// Add context before
			result = append(result, diffLines[changeStart:i]...)
		} else if line.Type == LineUnchanged && inChange {
			// End of a change block
			inChange = false
			// Add context after
			end := min(i+ud.ContextLines, len(diffLines))
			result = append(result, diffLines[i:end]...)
			i = end - 1 // Skip added context
			continue
		}

		if inChange || line.Type != LineUnchanged {
			result = append(result, line)
		}
	}

	return result
}

// formatDiff formats the diff lines into a string
func (ud *UnifiedDiff) formatDiff(diffLines []DiffLine) string {
	var sb strings.Builder

	for _, line := range diffLines {
		var prefix string
		switch line.Type {
		case LineUnchanged:
			prefix = " "
		case LineAdded:
			prefix = "+"
		case LineRemoved:
			prefix = "-"
		}
		sb.WriteString(fmt.Sprintf("%s%s\n", prefix, line.Content))
	}

	return sb.String()
}

// max returns the maximum of two integers
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// min returns the minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}