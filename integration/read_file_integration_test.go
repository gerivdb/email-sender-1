package integration

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"email_sender/pkg/common" // Assurez-vous que le chemin est correct pour votre module Go
)

// TestCLIIntegration tests the read_file_navigator CLI tool.
func TestCLIIntegration(t *testing.T) {
	// Create a test file
	testFilePath := "test_cli_integration.txt"
	err := common.CreateLargeTestFile(testFilePath, 200) // 200 lines for testing
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	defer os.Remove(testFilePath)

	// Build the CLI tool
	cliPath := "cmd/read_file_navigator/read_file_navigator.go"

	tests := []struct {
		name        string
		args        []string
		expectedOut string
		expectErr   bool
	}{
		{
			"first_block",
			[]string{"--file", testFilePath, "--action", "first", "--block-size", "10"},
			"--- Affichage du Bloc 1/20 (Lignes 1-10) ---",
			false,
		},
		{
			"goto_block_5",
			[]string{"--file", testFilePath, "--action", "goto", "--block", "5", "--block-size", "10"},
			"--- Affichage du Bloc 5/20 (Lignes 41-50) ---",
			false,
		},
		{
			"invalid_file",
			[]string{"--file", "non_existent_file.txt", "--action", "first"},
			"Erreur lors de la lecture du fichier",
			true,
		},
		{
			"missing_file_arg",
			[]string{"--action", "first"},
			"Erreur: Le chemin du fichier est obligatoire",
			true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cmd := exec.Command("go", append([]string{"run", cliPath}, tt.args...)...)
			var stdout, stderr bytes.Buffer
			cmd.Stdout = &stdout
			cmd.Stderr = &stderr

			err := cmd.Run()

			if (err != nil) != tt.expectErr {
				t.Errorf("Command exited with error: %v, stderr: %s", err, stderr.String())
			}

			output := stdout.String() + stderr.String() // Combine stdout and stderr for checking
			if !strings.Contains(output, tt.expectedOut) {
				t.Errorf("Expected output not found.\nExpected to contain: %s\nActual output: %s", tt.expectedOut, output)
			}
		})
	}
}

// TestVSCodeExtensionIntegration (Placeholder)
// This would typically involve mocking VSCode APIs or running an actual VSCode instance for E2E tests.
// For a real project, consider using tools like Spectron or VSCode's Test API.
func TestVSCodeExtensionIntegration(t *testing.T) {
	t.Skip("Skipping VSCode extension integration test as it requires a VSCode environment.")
	// Example of how you might structure a test if you had a test framework for VSCode extensions:
	//
	// // Simulate opening a file and making a selection
	// mockEditor.OpenFile("test_vscode_file.txt", "Lorem ipsum dolor sit amet...")
	// mockEditor.SelectRange(0, 0, 1, 10) // Select first line
	//
	// // Execute the command provided by the extension
	// err := vscode.commands.executeCommand('extension.analyzeSelection')
	// if err != nil {
	//    t.Fatalf("Failed to execute VSCode command: %v", err)
	// }
	//
	// // Check if the output channel received the expected content
	// expectedOutput := "--- Affichage du Bloc 1/1 (Lignes 1-1) ---" // Assuming single line selection
	// if !mockOutputChannel.Contains(expectedOutput) {
	//    t.Errorf("VSCode output channel did not contain expected output.")
	// }
}

// TestBinaryFileHandlingIntegration tests binary file detection and hex preview.
func TestBinaryFileHandlingIntegration(t *testing.T) {
	tempDir := t.TempDir()
	binaryFilePath := filepath.Join(tempDir, "test_binary_file.bin")
	err := common.CreateBinaryTestFile(binaryFilePath, 100) // 100 bytes binary file
	if err != nil {
		t.Fatalf("Failed to create binary test file: %v", err)
	}
	defer os.Remove(binaryFilePath)

	// Test IsBinaryFile
	isBinary, err := common.IsBinaryFile(binaryFilePath)
	if err != nil {
		t.Errorf("IsBinaryFile returned an error: %v", err)
	}
	if !isBinary {
		t.Errorf("File %s was not detected as binary", binaryFilePath)
	}

	// Test PreviewHex
	expectedHexPrefix := "00ff1a00"                           // Corresponds to the first few bytes of the simulated binary data
	hexOutput, err := common.PreviewHex(binaryFilePath, 0, 4) // Read first 4 bytes
	if err != nil {
		t.Errorf("PreviewHex returned an error: %v", err)
	}
	if strings.ToLower(string(hexOutput)) != expectedHexPrefix {
		t.Errorf("PreviewHex got %s, want %s", hexOutput, expectedHexPrefix)
	}

	// Test CLI with binary file (expect error or specific output)
	cmd := exec.Command("go", "run", "cmd/read_file_navigator/read_file_navigator.go", "--file", binaryFilePath, "--action", "first")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err = cmd.Run()
	if err == nil {
		t.Errorf("Expected CLI to return an error or specific output for binary file, got none. Output: %s", stdout.String())
	}
	// Depending on how the CLI handles binary files, you might check stderr for specific error messages
	if !strings.Contains(stderr.String(), "Erreur lors de la lecture du fichier") && !strings.Contains(stdout.String(), "binary") {
		// This check might need adjustment based on final CLI binary handling logic
		t.Errorf("CLI did not indicate binary file issue. Stderr: %s, Stdout: %s", stderr.String(), stdout.String())
	}
}

// TestLargeFileHandlingIntegration (Placeholder for performance tests)
func TestLargeFileHandlingIntegration(t *testing.T) {
	t.Skip("Skipping large file handling integration test as it might be time-consuming.")
	// Example:
	// testFilePath := "large_performance_test.txt"
	// err := common.CreateLargeTestFile(testFilePath, 1000000) // 1 million lines
	// if err != nil {
	// 	t.Fatalf("Failed to create large test file: %v", err)
	// }
	// defer os.Remove(testFilePath)

	// startTime := time.Now()
	// // Perform a read operation on a large file
	// _, err = common.ReadFileRange(testFilePath, 1, 100) // Read first 100 lines
	// if err != nil {
	// 	t.Errorf("Failed to read from large file: %v", err)
	// }
	// duration := time.Since(startTime)
	//
	// if duration > 500*time.Millisecond { // Example performance threshold
	// 	t.Errorf("Reading from large file took too long: %v", duration)
	// }
}
