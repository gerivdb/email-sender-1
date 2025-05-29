package diff

import (
	"testing"
)

func TestUnifiedDiff(t *testing.T) {
	tests := []struct {
		name         string
		oldText      string
		newText      string
		contextLines int
		expectError  bool
	}{
		{
			name:         "No changes",
			oldText:      "test\nline",
			newText:      "test\nline",
			contextLines: 3,
			expectError:  false,
		},
		{
			name:         "Add line",
			oldText:      "first\nsecond",
			newText:      "first\nmiddle\nsecond",
			contextLines: 3,
			expectError:  false,
		},
		{
			name:         "Remove line",
			oldText:      "first\nmiddle\nsecond",
			newText:      "first\nsecond",
			contextLines: 3,
			expectError:  false,
		},
		{
			name:         "Complex changes",
			oldText:      "one\ntwo\nthree\nfour\nfive",
			newText:      "one\n2\nthree\n4\nfive",
			contextLines: 1,
			expectError:  false,
		},
		{
			name:         "Empty old text",
			oldText:      "",
			newText:      "new content",
			contextLines: 3,
			expectError:  false,
		},
		{
			name:         "Empty new text",
			oldText:      "old content",
			newText:      "",
			contextLines: 3,
			expectError:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ud := NewUnifiedDiff(tt.contextLines)
			result, err := ud.Generate(tt.oldText, tt.newText)

			if tt.expectError && err == nil {
				t.Errorf("Expected error but got none")
				return
			}
			if !tt.expectError && err != nil {
				t.Errorf("Generate() error = %v", err)
				return
			}

			// Basic validation - result should be a string
			if !tt.expectError && result == "" && tt.oldText != tt.newText {
				t.Errorf("Expected non-empty diff for different texts")
			}
		})
	}
}

func TestNewUnifiedDiff(t *testing.T) {
	tests := []struct {
		name         string
		contextLines int
		expected     int
	}{
		{
			name:         "Default context",
			contextLines: 3,
			expected:     3,
		},
		{
			name:         "Zero context",
			contextLines: 0,
			expected:     0,
		},
		{
			name:         "Large context",
			contextLines: 10,
			expected:     10,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ud := NewUnifiedDiff(tt.contextLines)
			if ud.ContextLines != tt.expected {
				t.Errorf("NewUnifiedDiff().ContextLines = %v, expected %v", ud.ContextLines, tt.expected)
			}
		})
	}
}

func TestDiffLineTypes(t *testing.T) {
	// Test that the LineType constants are properly defined
	tests := []struct {
		name     string
		lineType LineType
		expected int
	}{
		{
			name:     "LineUnchanged",
			lineType: LineUnchanged,
			expected: 0,
		},
		{
			name:     "LineAdded",
			lineType: LineAdded,
			expected: 1,
		},
		{
			name:     "LineRemoved",
			lineType: LineRemoved,
			expected: 2,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if int(tt.lineType) != tt.expected {
				t.Errorf("LineType %v = %v, expected %v", tt.name, int(tt.lineType), tt.expected)
			}
		})
	}
}

func TestDiffLineStruct(t *testing.T) {
	// Test DiffLine struct creation and field access
	line := DiffLine{
		Content: "test content",
		Type:    LineAdded,
	}

	if line.Content != "test content" {
		t.Errorf("DiffLine.Content = %v, expected 'test content'", line.Content)
	}

	if line.Type != LineAdded {
		t.Errorf("DiffLine.Type = %v, expected LineAdded", line.Type)
	}
}
