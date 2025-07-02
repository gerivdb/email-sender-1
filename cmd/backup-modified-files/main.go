package main

import (
	"archive/zip"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

// Liste des fichiers créés/modifiés pendant la tâche (à adapter si nécessaire)
var filesToBackup = []string{
	"projet/roadmaps/plans/consolidated/plan-dev-v77b-migration-gateway-manager.md",
	"cmd/auto-integrate-gateway/main.go",
	"cmd/rollback-gateway-migration/main.go",
	"cmd/gen-read-file-report/main.go",
	"development/managers/validation.go",
	"development/managers/tools/cmd/manager-toolkit/manager_toolkit.go",
	"development/managers/tools/cmd/toolkit_integration_test.go",
	"development/managers/tools/core/toolkit/toolkit_core.go",
	"development/managers/tools/operations/validation/struct_validator.go",
	"development/managers/tools/operations/analysis/dependency_analyzer.go",
	"development/managers/tools/operations/analysis/duplicate_type_detector.go",
	"development/managers/tools/operations/analysis/syntax_checker.go",
	"development/managers/tools/operations/analysis/interface_analyzer_pro.go",
	"development/managers/tools/operations/correction/import_conflict_resolver.go",
	"development/managers/tools/operations/correction/naming_normalizer.go",
	"development/managers/tools/operations/migration/type_def_generator.go",
	"migration/gateway-manager-v77/spec-integration.md",
	"migration/gateway-manager-v77/target-structure.md",
	"development/managers/gateway-manager/gateway.go",
	"development/managers/gateway-manager/gateway_test.go",
	"tests/integration/gateway_manager_integration_test.go",
	"tests/integration/integration_test.go.disabled",        // Renommé
	"tests/integration/n8n_go_integration_test.go.disabled", // Renommé
	"cmd/gateway-import-migrate/main.go",
	"cmd/generate-gateway-report/main.go",
	"migration/gateway-manager-v77/report.html",
	"migration/gateway-manager-v77/review.md",
	"projet/roadmaps/plans/consolidated/plan-dev-v77-migration-gateway-manager.md",
}

func main() {
	fmt.Println("Démarrage de la sauvegarde automatique des fichiers modifiés...")

	backupDir := "migration/gateway-manager-v77/.bak"
	if err := os.MkdirAll(backupDir, 0o755); err != nil {
		fmt.Printf("Erreur lors de la création du répertoire de backup: %v\n", err)
		os.Exit(1)
	}

	timestamp := time.Now().Format("20060102-150405")
	archiveName := fmt.Sprintf("gateway-manager-v77-backup-%s.zip", timestamp)
	archivePath := filepath.Join(backupDir, archiveName)

	archive, err := os.Create(archivePath)
	if err != nil {
		fmt.Printf("Erreur lors de la création de l'archive ZIP: %v\n", err)
		os.Exit(1)
	}
	defer archive.Close()

	zipWriter := zip.NewWriter(archive)
	defer zipWriter.Close()

	for _, filePath := range filesToBackup {
		err := addFileToZip(zipWriter, filePath)
		if err != nil {
			fmt.Printf("Attention: Impossible d'ajouter le fichier %s à l'archive: %v\n", filePath, err)
		}
	}

	fmt.Printf("Sauvegarde terminée avec succès: %s\n", archivePath)
}

func addFileToZip(zipWriter *zip.Writer, filename string) error {
	file, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	info, err := file.Stat()
	if err != nil {
		return err
	}

	header, err := zip.FileInfoHeader(info)
	if err != nil {
		return err
	}

	// Utiliser le chemin relatif dans l'archive
	header.Name = filename
	header.Method = zip.Deflate

	writer, err := zipWriter.CreateHeader(header)
	if err != nil {
		return err
	}

	_, err = io.Copy(writer, file)
	return err
}
