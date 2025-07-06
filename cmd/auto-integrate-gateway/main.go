package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
)

// copyDir copies a directory from src to dst.
func copyDir(src, dst string) error {
	return filepath.Walk(src, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}

		targetPath := filepath.Join(dst, relPath)

		if info.IsDir() {
			return os.MkdirAll(targetPath, info.Mode())
		}

		// It's a file, copy it
		srcFile, err := os.Open(path)
		if err != nil {
			return err
		}
		defer srcFile.Close()

		dstFile, err := os.Create(targetPath)
		if err != nil {
			return err
		}
		defer dstFile.Close()

		_, err = io.Copy(dstFile, srcFile)
		return err
	})
}

func main() {
	fmt.Println("Exécution du script auto-integrate-gateway.go")

	// Placeholder for actual integration logic
	// As per the plan, this would involve copying, removing git artifacts, etc.
	// For now, it's just a placeholder.

	// Example from the plan:
	// cp -r /tmp/mcp-gateway/* development/managers/gateway-manager/
	// rm -rf development/managers/gateway-manager/.git*

	// Assuming /tmp/mcp-gateway is a source directory that would exist in a real scenario
	// For testing purposes, we might need a dummy directory
	srcGatewayPath := "/tmp/mcp-gateway" // This path might need to be adapted for Windows or a dummy local path
	dstGatewayManagerPath := "development/managers/gateway-manager"

	// Create a dummy source directory for testing if it doesn't exist
	if _, err := os.Stat(srcGatewayPath); os.IsNotExist(err) {
		log.Printf("Le répertoire source factice '%s' n'existe pas. Création pour le test.", srcGatewayPath)
		err := os.MkdirAll(srcGatewayPath, 0o755)
		if err != nil {
			log.Fatalf("Erreur lors de la création du répertoire source factice: %v", err)
		}
		// Create a dummy file inside for copyDir to have something to copy
		dummyFilePath := filepath.Join(srcGatewayPath, "dummy_file.txt")
		err = os.WriteFile(dummyFilePath, []byte("Ceci est un fichier factice."), 0o644)
		if err != nil {
			log.Fatalf("Erreur lors de la création du fichier factice: %v", err)
		}
	}

	// Create destination directory if it doesn't exist
	if _, err := os.Stat(dstGatewayManagerPath); os.IsNotExist(err) {
		log.Printf("Le répertoire de destination '%s' n'existe pas. Création.", dstGatewayManagerPath)
		err := os.MkdirAll(dstGatewayManagerPath, 0o755)
		if err != nil {
			log.Fatalf("Erreur lors de la création du répertoire de destination: %v", err)
		}
	}

	// Simulate copy operation
	log.Printf("Simulation de la copie de '%s' vers '%s'", srcGatewayPath, dstGatewayManagerPath)
	err := copyDir(srcGatewayPath, dstGatewayManagerPath)
	if err != nil {
		log.Printf("Erreur lors de la simulation de la copie: %v", err)
	} else {
		log.Println("Simulation de la copie terminée avec succès.")
	}

	// Simulate removal of .git* artifacts (as per example in plan)
	log.Printf("Simulation de la suppression des artefacts .git* dans '%s'", dstGatewayManagerPath)
	err = filepath.Walk(dstGatewayManagerPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if strings.HasPrefix(filepath.Base(path), ".git") {
			log.Printf("Suppression de: %s", path)
			return os.RemoveAll(path)
		}
		return nil
	})
	if err != nil {
		log.Printf("Erreur lors de la simulation de la suppression des artefacts .git*: %v", err)
	} else {
		log.Println("Simulation de la suppression des artefacts .git* terminée avec succès.")
	}

	fmt.Println("Intégration de la passerelle terminée (simulation).")
}
