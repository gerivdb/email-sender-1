package common

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
)

// TestReadFileRange tests the ReadFileRange function.
func TestReadFileRange(t *testing.T) {
	testFilePath := "test_file_range.txt"
	content := "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\n"
	err := ioutil.WriteFile(testFilePath, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	defer os.Remove(testFilePath)

	tests := []struct {
		name      string
		startLine int
		endLine   int
		expected  []string
		expectErr bool
	}{
		{"full_range", 1, 5, []string{"Line 1", "Line 2", "Line 3", "Line 4", "Line 5"}, false},
		{"partial_range", 2, 4, []string{"Line 2", "Line 3", "Line 4"}, false},
		{"single_line", 3, 3, []string{"Line 3"}, false},
		{"out_of_bounds_end", 4, 10, []string{"Line 4", "Line 5"}, false},
		{"out_of_bounds_start", 10, 12, []string{}, false},
		{"invalid_range_start_gt_end", 5, 1, nil, true},
		{"invalid_range_zero_start", 0, 3, nil, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			lines, err := ReadFileRange(testFilePath, tt.startLine, tt.endLine)
			if (err != nil) != tt.expectErr {
				t.Errorf("ReadFileRange() error = %v, expectErr %v", err, tt.expectErr)
				return
			}
			if !tt.expectErr && !compareStringSlices(lines, tt.expected) {
				t.Errorf("ReadFileRange() got = %v, want %v", lines, tt.expected)
			}
		})
	}
}

// TestIsBinaryFile tests the IsBinaryFile function.
func TestIsBinaryFile(t *testing.T) {
	tempDir := t.TempDir()

	// Test case 1: Text file
	textFile := filepath.Join(tempDir, "text_file.txt")
	err := ioutil.WriteFile(textFile, []byte("This is a plain text file."), 0o644)
	if err != nil {
		t.Fatalf("Failed to create text file: %v", err)
	}
	isBinary, err := IsBinaryFile(textFile)
	if err != nil {
		t.Errorf("IsBinaryFile for text file returned an error: %v", err)
	}
	if isBinary {
		t.Errorf("IsBinaryFile identified text file as binary")
	}

	// Test case 2: Binary file (simulated with null bytes)
	binaryFile := filepath.Join(tempDir, "binary_file.bin")
	err = ioutil.WriteFile(binaryFile, []byte{0x00, 0x01, 0x02, 0xFF, 0x03, 0x04}, 0o644)
	if err != nil {
		t.Fatalf("Failed to create binary file: %v", err)
	}
	isBinary, err = IsBinaryFile(binaryFile)
	if err != nil {
		t.Errorf("IsBinaryFile for binary file returned an error: %v", err)
	}
	if !isBinary {
		t.Errorf("IsBinaryFile failed to identify binary file")
	}

	// Test case 3: Empty file
	emptyFile := filepath.Join(tempDir, "empty_file.txt")
	err = ioutil.WriteFile(emptyFile, []byte{}, 0o644)
	if err != nil {
		t.Fatalf("Failed to create empty file: %v", err)
	}
	isBinary, err = IsBinaryFile(emptyFile)
	if err != nil {
		t.Errorf("IsBinaryFile for empty file returned an error: %v", err)
	}
	if isBinary {
		t.Errorf("IsBinaryFile identified empty file as binary")
	}
}

// TestPreviewHex tests the PreviewHex function.
func TestPreviewHex(t *testing.T) {
	testFilePath := "test_hex_file.bin"
	content := "Hello World!" // ASCII string, but will be read as bytes
	err := ioutil.WriteFile(testFilePath, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	defer os.Remove(testFilePath)

	tests := []struct {
		name        string
		offset      int
		length      int
		expectedHex string
		expectErr   bool
	}{
		{"full_content", 0, len(content), "48656c6c6f20576f726c6421", false},
		{"partial_content", 6, 5, "576f726c64", false},                                  // "World"
		{"offset_out_of_bounds", 20, 5, "", false},                                      // Should read 0 bytes
		{"length_exceeds_file", 0, len(content) + 5, "48656c6c6f20576f726c6421", false}, // Should read up to EOF
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			hexBytes, err := PreviewHex(testFilePath, tt.offset, tt.length)
			if (err != nil) != tt.expectErr {
				t.Errorf("PreviewHex() error = %v, expectErr %v", err, tt.expectErr)
				return
			}
			if !tt.expectErr && string(hexBytes) != tt.expectedHex {
				t.Errorf("PreviewHex() got hex = %s, want %s", hexBytes, tt.expectedHex)
			}
		})
	}
}

// Helper function to compare two string slices.
func compareStringSlices(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i, v := range a {
		if v != b[i] {
			return false
		}
	}
	return true
}

// TestCreateLargeTestFile and TestCreateBinaryTestFile for coverage
func TestCreateLargeTestFile(t *testing.T) {
	testFilePath := "large_test_file.txt"
	defer os.Remove(testFilePath)

	err := CreateLargeTestFile(testFilePath, 100)
	if err != nil {
		t.Fatalf("Failed to create large test file: %v", err)
	}

	// Verify file exists and has content
	info, err := os.Stat(testFilePath)
	if err != nil {
		t.Fatalf("Failed to stat large test file: %v", err)
	}
	if info.Size() == 0 {
		t.Errorf("Large test file is empty")
	}
}

func TestCreateBinaryTestFile(t *testing.T) {
	testFilePath := "binary_test_file.bin"
	defer os.Remove(testFilePath)

	err := CreateBinaryTestFile(testFilePath, 100)
	if err != nil {
		t.Fatalf("Failed to create binary test file: %v", err)
	}

	// Verify file exists and has content
	info, err := os.Stat(testFilePath)
	if err != nil {
		t.Fatalf("Failed to stat binary test file: %v", err)
	}
	if info.Size() == 0 {
		t.Errorf("Binary test file is empty")
	}
}
