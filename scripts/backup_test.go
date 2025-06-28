package main

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
)

func TestCopyFile(t *testing.T) {
	tempDir := t.TempDir()
	srcFile := filepath.Join(tempDir, "source.txt")
	dstFile := filepath.Join(tempDir, "dest", "destination.txt")
	content := "Hello, world!"

	err := ioutil.WriteFile(srcFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create source file: %v", err)
	}

	err = copyFile(srcFile, dstFile)
	if err != nil {
		t.Errorf("copyFile() error = %v, wantErr %v", err, false)
	}

	// Verify destination file exists and content matches
	readContent, err := ioutil.ReadFile(dstFile)
	if err != nil {
		t.Fatalf("Failed to read destination file: %v", err)
	}
	if string(readContent) != content {
		t.Errorf("Copied content mismatch: got %s, want %s", string(readContent), content)
	}
}

func TestCopyDir(t *testing.T) {
	tempDir := t.TempDir()
	srcDir := filepath.Join(tempDir, "source_dir")
	dstDir := filepath.Join(tempDir, "dest_dir")

	// Create source directory and files
	os.MkdirAll(filepath.Join(srcDir, "subdir"), 0o755)
	ioutil.WriteFile(filepath.Join(srcDir, "file1.txt"), []byte("content1"), 0o644)
	ioutil.WriteFile(filepath.Join(srcDir, "subdir", "file2.txt"), []byte("content2"), 0o644)

	err := copyDir(srcDir, dstDir)
	if err != nil {
		t.Errorf("copyDir() error = %v, wantErr %v", err, false)
	}

	// Verify destination directory and files exist
	if _, err := os.Stat(filepath.Join(dstDir, "file1.txt")); os.IsNotExist(err) {
		t.Errorf("file1.txt not copied")
	}
	if _, err := os.Stat(filepath.Join(dstDir, "subdir", "file2.txt")); os.IsNotExist(err) {
		t.Errorf("file2.txt not copied")
	}
}

func TestBackupMain(t *testing.T) {
	// This test is more of an end-to-end check for the main backup function.
	// It's harder to fully mock or isolate without significant refactoring.
	// For simplicity, we'll run the main function and check if a backup directory is created.

	// Save original main function (if it were in a different package) or just run it.
	// For this direct execution, we rely on the side effect of creating a directory.

	// Ensure test files exist for backup script to find
	tempDir := t.TempDir()
	os.Chdir(tempDir) // Change working directory for the test

	// Create dummy critical files/dirs that the backup script expects
	os.MkdirAll("cmd/audit_read_file", 0o755)
	os.MkdirAll("cmd/gap_analysis", 0o755)
	ioutil.WriteFile("config.yaml", []byte("test_config: value"), 0o644)
	ioutil.WriteFile("pkg/common/read_file.go", []byte("package common"), 0o644)

	// Run the main backup function
	main()

	// Check if a backup directory was created
	backupDirs, err := filepath.Glob("backup/20*-*")
	if err != nil || len(backupDirs) == 0 {
		t.Errorf("Backup directory not found: %v", err)
	}

	// Clean up - change back to original directory and remove temp dir
	os.Chdir("..") // Assuming test runner changes to tempDir, change back
	os.RemoveAll(tempDir)
}
