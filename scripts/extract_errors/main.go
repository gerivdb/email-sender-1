// scripts/extract_errors/main.go
// Extraction enrichie des erreurs Go pour diagnostic automatisé (tous patterns du log)

package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"regexp"
)

type BuildError struct {
	File    string `json:"file,omitempty"`
	Message string `json:"message"`
}

func extractFile(line string) string {
	re := regexp.MustCompile(`^([^\s:]+)`)
	matches := re.FindStringSubmatch(line)
	if len(matches) > 1 {
		return matches[1]
	}
	return ""
}

func main() {
	f, err := os.Open("build-errors.log")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur ouverture build-errors.log: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()

	// Patterns enrichis pour couvrir tous les cas du log fourni
	patterns := []*regexp.Regexp{
		regexp.MustCompile(`(?i)found packages`),
		regexp.MustCompile(`(?i)expected 'package'`),
		regexp.MustCompile(`(?i)missing import path`),
		regexp.MustCompile(`(?i)is not in std`),
		regexp.MustCompile(`(?i)no required module provides package`),
		regexp.MustCompile(`(?i)import cycle not allowed`),
		regexp.MustCompile(`(?i)local import`),
		regexp.MustCompile(`(?i)relative import paths are not supported`),
		regexp.MustCompile(`(?i)to add missing requirements, run: go get`),
		regexp.MustCompile(`(?i)error|panic|cycle|EOF`),
	}

	var errors []BuildError

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		for _, re := range patterns {
			if re.MatchString(line) {
				errors = append(errors, BuildError{
					File:    extractFile(line),
					Message: line,
				})
				break
			}
		}
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lecture log: %v\n", err)
		os.Exit(1)
	}

	out, err := os.Create("errors-extracted.json")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création errors-extracted.json: %v\n", err)
		os.Exit(1)
	}
	defer out.Close()
	enc := json.NewEncoder(out)
	enc.SetIndent("", "  ")
	if err := enc.Encode(errors); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur écriture JSON: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Extraction enrichie terminée. %d erreurs extraites.\n", len(errors))
}
