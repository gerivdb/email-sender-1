package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"strings"
)

func main() {
	var count int
	processGoFile("development/managers/dependencymanager", "dependencymanager", &count)
}

func processGoFile(path string, targetPkg string, count *int) error {
	input, err := ioutil.ReadFile(path)
	if err != nil {
		return fmt.Errorf("lecture du fichier %s échouée : %w", path, err)
	}

	scanner := bufio.NewScanner(bytes.NewReader(input))
	var output bytes.Buffer
	changed := false
	lineNum := 0

	for scanner.Scan() {
		line := scanner.Text()
		if lineNum == 0 && strings.HasPrefix(line, "package ") && !strings.HasPrefix(line, "package "+targetPkg) {
			output.WriteString("package " + targetPkg + "\n")
			changed = true
		} else {
			output.WriteString(line + "\n")
		}
		lineNum++
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("erreur lors du scan du fichier %s : %w", path, err)
	}

	if changed {
		// Permissions 0600 : lecture/écriture pour le propriétaire
		err = ioutil.WriteFile(path, output.Bytes(), 0o600)
		if err != nil {
			return fmt.Errorf("écriture du fichier %s échouée : %w", path, err)
		}

		*count++
		log.Printf("Fichier corrigé : %s", path)
	}

	return nil
}
