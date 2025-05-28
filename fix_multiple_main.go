// fix_multiple_main.go - Script to fix multiple main functions error
package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	fmt.Println("🔧 EMAIL_SENDER_1 - Multiple Main Package Fix")
	fmt.Println("===========================================")

	// Define paths
	projectRoot := "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
	testDir := filepath.Join(projectRoot, ".github", "docs", "algorithms", "test")

	// Move FINAL_VALIDATION_COMPLETE.go to test directory if it's not there already
	finalValidationSrc := filepath.Join(projectRoot, ".github", "docs", "algorithms", "FINAL_VALIDATION_COMPLETE.go")
	finalValidationDst := filepath.Join(testDir, "FINAL_VALIDATION_COMPLETE.go")

	if _, err := os.Stat(finalValidationSrc); err == nil {
		// Update the package name first
		updatePackageName(finalValidationSrc, "test")

		// Then move the file
		if err := moveFile(finalValidationSrc, finalValidationDst); err != nil {
			fmt.Printf("❌ Error moving %s: %v\n", finalValidationSrc, err)
		} else {
			fmt.Printf("✅ Moved %s to test directory\n", "FINAL_VALIDATION_COMPLETE.go")
		}
	} else {
		fmt.Printf("ℹ️ File %s not found, assuming already moved\n", "FINAL_VALIDATION_COMPLETE.go")
	}

	// Now check all Go files in the test directory and ensure they use "package test"
	files, err := ioutil.ReadDir(testDir)
	if err != nil {
		fmt.Printf("❌ Error reading test directory: %v\n", err)
		return
	}

	for _, file := range files {
		if strings.HasSuffix(file.Name(), ".go") {
			filePath := filepath.Join(testDir, file.Name())
			updatePackageName(filePath, "test")
			fmt.Printf("✅ Updated %s to use 'package test'\n", file.Name())
		}
	}

	fmt.Println("✅ Package conflict resolution complete!")
}

func moveFile(src, dst string) error {
	// Read the source file
	content, err := ioutil.ReadFile(src)
	if err != nil {
		return err
	}

	// Write to the destination file
	err = ioutil.WriteFile(dst, content, 0644)
	if err != nil {
		return err
	}

	// Remove the source file
	return os.Remove(src)
}

func updatePackageName(filePath, newPackage string) error {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return err
	}

	lines := strings.Split(string(content), "\n")
	for i, line := range lines {
		if strings.HasPrefix(line, "package ") {
			lines[i] = "package " + newPackage
			break
		}
	}

	newContent := strings.Join(lines, "\n")
	return ioutil.WriteFile(filePath, []byte(newContent), 0644)
}
