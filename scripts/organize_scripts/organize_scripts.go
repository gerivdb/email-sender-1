package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	scriptsDir := "."
	files, err := ioutil.ReadDir(scriptsDir)
	if err != nil {
		fmt.Printf("Error reading directory: %v\n", err)
		os.Exit(1)
	}

	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), ".go") && !strings.HasSuffix(file.Name(), "_test.go") {
			scriptName := strings.TrimSuffix(file.Name(), ".go")
			newDir := filepath.Join(scriptsDir, scriptName)
			if err := os.MkdirAll(newDir, 0755); err != nil {
				fmt.Printf("Error creating directory %s: %v\n", newDir, err)
				continue
			}

			// Move the script file
			oldPath := filepath.Join(scriptsDir, file.Name())
			newPath := filepath.Join(newDir, file.Name())
			if err := os.Rename(oldPath, newPath); err != nil {
				fmt.Printf("Error moving file %s to %s: %v\n", oldPath, newPath, err)
			}

			// Move the corresponding test file
			testFileName := scriptName + "_test.go"
			oldTestPath := filepath.Join(scriptsDir, testFileName)
			newTestPath := filepath.Join(newDir, testFileName)
			if _, err := os.Stat(oldTestPath); err == nil {
				if err := os.Rename(oldTestPath, newTestPath); err != nil {
					fmt.Printf("Error moving test file %s to %s: %v\n", oldTestPath, newTestPath, err)
				}
			}
		}
	}

	fmt.Println("Go scripts organized successfully.")
}
