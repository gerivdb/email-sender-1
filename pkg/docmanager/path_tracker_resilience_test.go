// SPDX-License-Identifier: MIT
// Tests pour les nouvelles fonctionnalités de résilience aux déplacements
package docmanager

import (
	"os"
	"path/filepath"
	"testing"
)

// TestPathTracker_DetectMovedFile teste la détection de fichiers déplacés
func TestPathTracker_DetectMovedFile(t *testing.T) {
	tracker := NewPathTracker()
	tmpDir := t.TempDir()

	// Créer un fichier test
	originalFile := filepath.Join(tmpDir, "original.txt")
	content := "Content for movement detection test"

	err := os.WriteFile(originalFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Enregistrer le fichier original
	err = tracker.TrackFileByContent(originalFile)
	if err != nil {
		t.Fatalf("Failed to track original file: %v", err)
	}

	// Créer le fichier "déplacé" avec le même contenu
	movedFile := filepath.Join(tmpDir, "moved.txt")
	err = os.WriteFile(movedFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create moved file: %v", err)
	}

	// Détecter le mouvement
	result, err := tracker.DetectMovedFile(movedFile)
	if err != nil {
		t.Fatalf("DetectMovedFile failed: %v", err)
	}

	if result == nil {
		t.Fatal("Expected movement detection result, got nil")
	}

	if result.OldPath != originalFile {
		t.Errorf("Expected old path %s, got %s", originalFile, result.OldPath)
	}

	if result.NewPath != movedFile {
		t.Errorf("Expected new path %s, got %s", movedFile, result.NewPath)
	}

	if result.Confidence <= 0 {
		t.Error("Expected positive confidence score")
	}
}

// TestPathTracker_UpdateAutomaticReferences teste la mise à jour automatique des références
func TestPathTracker_UpdateAutomaticReferences(t *testing.T) {
	tracker := NewPathTracker()
	tmpDir := t.TempDir()

	oldPath := filepath.Join(tmpDir, "old.txt")
	newPath := filepath.Join(tmpDir, "new.txt")

	// Créer des fichiers de test
	err := os.WriteFile(oldPath, []byte("test content"), 0o644)
	if err != nil {
		t.Fatalf("Failed to create old file: %v", err)
	}

	err = os.WriteFile(newPath, []byte("test content"), 0o644)
	if err != nil {
		t.Fatalf("Failed to create new file: %v", err)
	}

	// Ajouter des références
	tracker.references = map[string][]string{
		oldPath: {"ref1.txt", "ref2.txt"},
	}

	// Mettre à jour les références
	err = tracker.UpdateAutomaticReferences(oldPath, newPath)
	if err != nil {
		t.Fatalf("UpdateAutomaticReferences failed: %v", err)
	}

	// Vérifier que les références ont été déplacées
	if refs, exists := tracker.references[newPath]; !exists {
		t.Error("References should be moved to new path")
	} else if len(refs) != 2 {
		t.Errorf("Expected 2 references, got %d", len(refs))
	}

	// Vérifier que l'ancien chemin n'a plus de références
	if _, exists := tracker.references[oldPath]; exists {
		t.Error("Old path should not have references anymore")
	}

	// Vérifier l'historique des mouvements
	history := tracker.GetMovementHistory()
	if len(history) == 0 {
		t.Error("Movement should be recorded in history")
	}
}

// TestPathTracker_FileSystemWatcher teste le système de surveillance
func TestPathTracker_FileSystemWatcher(t *testing.T) {
	tracker := NewPathTracker()

	// Démarrer le watcher
	err := tracker.StartFileSystemWatcher()
	if err != nil {
		t.Fatalf("Failed to start file system watcher: %v", err)
	}

	// Vérifier que le watcher est actif
	if !tracker.watcherActive {
		t.Error("Watcher should be active")
	}

	// Arrêter le watcher
	err = tracker.StopFileSystemWatcher()
	if err != nil {
		t.Fatalf("Failed to stop file system watcher: %v", err)
	}

	// Vérifier que le watcher est inactif
	if tracker.watcherActive {
		t.Error("Watcher should be inactive")
	}
}

// TestPathTracker_ScanBrokenLinks teste la détection de liens cassés
func TestPathTracker_ScanBrokenLinks(t *testing.T) {
	tracker := NewPathTracker()
	tmpDir := t.TempDir()

	// Créer un fichier markdown avec des liens
	mdFile := filepath.Join(tmpDir, "test.md")
	content := `# Test Document
	
[Valid Link](existing.txt)
[Broken Link](nonexistent.txt)
[Another Valid](valid.md)
`

	err := os.WriteFile(mdFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create markdown file: %v", err)
	}

	// Créer seulement certains fichiers cibles
	err = os.WriteFile(filepath.Join(tmpDir, "existing.txt"), []byte("exists"), 0o644)
	if err != nil {
		t.Fatalf("Failed to create target file: %v", err)
	}

	// Scanner les liens cassés
	brokenLinks, err := tracker.ScanBrokenLinks(tmpDir)
	if err != nil {
		t.Fatalf("ScanBrokenLinks failed: %v", err)
	}

	// Vérifier qu'on a trouvé des liens cassés
	if len(brokenLinks) == 0 {
		t.Error("Expected to find broken links")
	}

	// Vérifier les détails du lien cassé
	found := false
	for _, link := range brokenLinks {
		if link.TargetPath == "nonexistent.txt" {
			found = true
			if link.FilePath != mdFile {
				t.Errorf("Expected file path %s, got %s", mdFile, link.FilePath)
			}
			if link.LinkText != "Broken Link" {
				t.Errorf("Expected link text 'Broken Link', got '%s'", link.LinkText)
			}
		}
	}

	if !found {
		t.Error("Expected to find the specific broken link")
	}
}

// TestPathTracker_RepairBrokenLink teste la réparation de liens cassés
func TestPathTracker_RepairBrokenLink(t *testing.T) {
	tracker := NewPathTracker()
	tmpDir := t.TempDir()

	// Créer un fichier avec un lien cassé
	mdFile := filepath.Join(tmpDir, "test.md")
	content := `[Broken Link](old_name.txt)`

	err := os.WriteFile(mdFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create markdown file: %v", err)
	}

	// Créer le fichier cible avec le nouveau nom
	newFile := filepath.Join(tmpDir, "new_name.txt")
	err = os.WriteFile(newFile, []byte("content"), 0o644)
	if err != nil {
		t.Fatalf("Failed to create target file: %v", err)
	}

	// Enregistrer le fichier dans le tracker
	tracker.ContentHashes[newFile] = "dummy_hash"

	// Créer un lien cassé à réparer
	brokenLink := BrokenLink{
		FilePath:   mdFile,
		LinkText:   "Broken Link",
		TargetPath: "old_name.txt",
		LineNumber: 1,
		Confidence: 0.8,
	}

	// Réparer le lien
	result, err := tracker.RepairBrokenLink(brokenLink)
	if err != nil {
		t.Fatalf("RepairBrokenLink failed: %v", err)
	}

	if !result.Success {
		t.Errorf("Expected successful repair, got error: %s", result.Error)
	}

	// Vérifier l'historique de récupération
	history := tracker.GetRecoveryHistory()
	if len(history) == 0 {
		t.Error("Recovery should be recorded in history")
	}
}

// TestPathTracker_ValidatePostMove teste la validation après déplacement
func TestPathTracker_ValidatePostMove(t *testing.T) {
	tracker := NewPathTracker()
	tmpDir := t.TempDir()

	oldPath := filepath.Join(tmpDir, "old.txt")
	newPath := filepath.Join(tmpDir, "new.txt")
	content := "validation test content"

	// Créer et enregistrer le fichier original
	err := os.WriteFile(oldPath, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create old file: %v", err)
	}

	hash, err := tracker.CalculateContentHash(oldPath)
	if err != nil {
		t.Fatalf("Failed to calculate hash: %v", err)
	}

	tracker.ContentHashes[oldPath] = hash

	// Créer le nouveau fichier avec le même contenu
	err = os.WriteFile(newPath, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create new file: %v", err)
	}

	// Valider le déplacement
	result, err := tracker.ValidatePostMove(oldPath, newPath)
	if err != nil {
		t.Fatalf("ValidatePostMove failed: %v", err)
	}

	if !result.Valid {
		t.Error("Expected valid move validation")
	}

	if result.Hash != hash {
		t.Errorf("Expected hash %s, got %s", hash, result.Hash)
	}

	if result.ValidationTime <= 0 {
		t.Error("Expected positive validation time")
	}
}

// TestPathTracker_IntegrityCheck teste la vérification d'intégrité complète
func TestPathTracker_IntegrityCheck(t *testing.T) {
	tracker := NewPathTracker()
	tmpDir := t.TempDir()

	// Créer quelques fichiers de test
	file1 := filepath.Join(tmpDir, "file1.txt")
	file2 := filepath.Join(tmpDir, "file2.txt")

	err := os.WriteFile(file1, []byte("content1"), 0o644)
	if err != nil {
		t.Fatalf("Failed to create file1: %v", err)
	}

	err = os.WriteFile(file2, []byte("content2"), 0o644)
	if err != nil {
		t.Fatalf("Failed to create file2: %v", err)
	}

	// Enregistrer dans le tracker
	hash1, _ := tracker.CalculateContentHash(file1)
	hash2, _ := tracker.CalculateContentHash(file2)
	tracker.ContentHashes[file1] = hash1
	tracker.ContentHashes[file2] = hash2

	// Effectuer la vérification d'intégrité
	result, err := tracker.PerformFullIntegrityCheck(tmpDir)
	if err != nil {
		t.Fatalf("PerformFullIntegrityCheck failed: %v", err)
	}

	if result.TotalFiles < 2 {
		t.Errorf("Expected at least 2 files, got %d", result.TotalFiles)
	}

	if result.ValidFiles != 2 {
		t.Errorf("Expected 2 valid files, got %d", result.ValidFiles)
	}

	if result.ValidationTime <= 0 {
		t.Error("Expected positive validation time")
	}
}

// TestPathTracker_GenerateIntegrityReport teste la génération de rapport d'intégrité
func TestPathTracker_GenerateIntegrityReport(t *testing.T) {
	tracker := NewPathTracker()

	// Ajouter quelques fichiers au tracker
	tracker.ContentHashes = map[string]string{
		"/test/file1.txt": "hash1",
		"/test/file2.txt": "hash2",
	}

	// Générer le rapport
	report, err := tracker.GenerateIntegrityReport()
	if err != nil {
		t.Fatalf("GenerateIntegrityReport failed: %v", err)
	}

	if report.TotalFiles != 2 {
		t.Errorf("Expected 2 total files, got %d", report.TotalFiles)
	}

	if report.Summary == "" {
		t.Error("Expected non-empty summary")
	}

	if report.GeneratedAt.IsZero() {
		t.Error("Expected valid generation timestamp")
	}
}
