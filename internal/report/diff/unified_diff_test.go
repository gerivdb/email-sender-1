package diff

import (
	"testing"
)

func TestUnifiedDiff(t *testing.T) {
	tests := []struct {
		name        string
		oldText     string
		newText     string
		expected    string
		ContextLines int
	}{
		{
			name:        "No changes",
			oldText:     "test\nline",
			newText:     "test\nline",
			expected:    " test\n line\n",
			contextLines: 3,
		},
		{
			name:        "Add line",
			oldText:     "first\nsecond",
			newText:     "first\nmiddle\nsecond",
			expected:    " first\n+middle\n second\n",
			contextLines: 3,
		},
		{
			name:        "Remove line",
			oldText:     "first\nmiddle\nsecond",
			newText:     "first\nsecond",
			expected:    " first\n-middle\n second\n",
			contextLines: 3,
		},
		{
			name:        "Complex changes",
			oldText:     "one\ntwo\nthree\nfour\nfive",
			newText:     "one\n2\nthree\n4\nfive",
			expected:    " one\n-two\n+2\n three\n-four\n+4\n five\n",
			contextLines: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ud := NewUnifiedDiff(tt.contextLines)
			result, err := ud.Generate(tt.oldText, tt.newText)
			if err != nil {
				t.Errorf("Generate() error = %v", err)
				return
			}
			if result != tt.expected {
				t.Errorf("Generate()\ngot:\n%v\nwant:\n%v", result, tt.expected)
			}
		})
	}
}