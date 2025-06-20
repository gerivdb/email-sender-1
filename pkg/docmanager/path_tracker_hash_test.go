// SPDX-License-Identifier: MIT
// Package docmanager : tests pour le tracking par hash de contenu
// TASK ATOMIQUE 3.5.1.2 - Tracking par hash de contenu tests

package docmanager

import (
	"os"
	"path/filepath"
	"testing"
)

// TestPathTracker_CalculateContentHash teste le calcul de hash SHA256
func TestPathTracker_CalculateContentHash(t *testing.T) {
	tracker := NewPathTracker()

	// Créer un fichier temporaire
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")
	content := "Hello, World! This is test content."

	err := os.WriteFile(testFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("failed to create test file: %v", err)
	}

	// Calculer le hash
	hash1, err := tracker.CalculateContentHash(testFile)
	if err != nil {
		t.Errorf("failed to calculate hash: %v", err)
	}

	// Vérifier que le hash n'est pas vide
	if hash1 == "" {
		t.Error("hash should not be empty")
	}

	// Vérifier que le hash est cohérent
	hash2, err := tracker.CalculateContentHash(testFile)
	if err != nil {
		t.Errorf("failed to calculate hash second time: %v", err)
	}

	if hash1 != hash2 {
		t.Errorf("hash should be consistent, got %s and %s", hash1, hash2)
	}

	// Vérifier que le hash change avec un contenu différent
	newContent := "Different content"
	err = os.WriteFile(testFile, []byte(newContent), 0o644)
	if err != nil {
		t.Fatalf("failed to update test file: %v", err)
	}

	hash3, err := tracker.CalculateContentHash(testFile)
	if err != nil {
		t.Errorf("failed to calculate hash for updated file: %v", err)
	}

	if hash1 == hash3 {
		t.Error("hash should change when content changes")
	}
}

// TestPathTracker_TrackFileByContent teste l'enregistrement de fichier par contenu
func TestPathTracker_TrackFileByContent(t *testing.T) {
	tracker := NewPathTracker()

	// Créer un fichier temporaire
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "track_test.txt")
	content := "Content to track"

	err := os.WriteFile(testFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("failed to create test file: %v", err)
	}

	// Enregistrer le fichier
	err = tracker.TrackFileByContent(testFile)
	if err != nil {
		t.Errorf("failed to track file: %v", err)
	}

	// Vérifier que le fichier est enregistré
	if _, exists := tracker.ContentHashes[testFile]; !exists {
		t.Error("file should be tracked in ContentHashes")
	}

	if _, exists := tracker.pathToHash[testFile]; !exists {
		t.Error("file should be tracked in pathToHash")
	}

	// Vérifier l'historique
	history := tracker.GetHashHistory(testFile)
	if len(history) == 0 {
		t.Error("file should have history records")
	}

	if history[0].Operation != "tracked" {
		t.Errorf("expected operation 'tracked', got '%s'", history[0].Operation)
	}
}

// TestPathTracker_DetectMovedFile teste la détection de déplacement de fichier
func TestPathTracker_DetectMovedFile(t *testing.T) {
	tracker := NewPathTracker()

	// Créer un fichier temporaire
	tmpDir := t.TempDir()
	originalFile := filepath.Join(tmpDir, "original.txt")
	movedFile := filepath.Join(tmpDir, "moved.txt")
	content := "Content that will be moved"

	err := os.WriteFile(originalFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("failed to create original file: %v", err)
	}

	// Enregistrer le fichier original
	err = tracker.TrackFileByContent(originalFile)
	if err != nil {
		t.Errorf("failed to track original file: %v", err)
	}

	// Simuler un déplacement en créant le même contenu dans un nouveau fichier
	err = os.WriteFile(movedFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("failed to create moved file: %v", err)
	}

	// Détecter le déplacement
	result, err := tracker.DetectMovedFile(movedFile)
	if err != nil {
		t.Errorf("failed to detect moved file: %v", err)
	}

	if result == nil {
		t.Error("should detect file movement")
	} else {
		if result.OldPath != originalFile {
			t.Errorf("expected old path %s, got %s", originalFile, result.OldPath)
		}
		if result.NewPath != movedFile {
			t.Errorf("expected new path %s, got %s", movedFile, result.NewPath)
		}
		if result.Confidence <= 0 {
			t.Error("confidence should be positive")
		}
	}
}

// TestPathTracker_UpdateFileHash teste la mise à jour de hash après modification
func TestPathTracker_UpdateFileHash(t *testing.T) {
	tracker := NewPathTracker()

	// Créer un fichier temporaire
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "update_test.txt")
	originalContent := "Original content"

	err := os.WriteFile(testFile, []byte(originalContent), 0o644)
	if err != nil {
		t.Fatalf("failed to create test file: %v", err)
	}

	// Enregistrer le fichier
	err = tracker.TrackFileByContent(testFile)
	if err != nil {
		t.Errorf("failed to track file: %v", err)
	}

	originalHash := tracker.ContentHashes[testFile]

	// Modifier le contenu
	newContent := "Modified content"
	err = os.WriteFile(testFile, []byte(newContent), 0o644)
	if err != nil {
		t.Fatalf("failed to modify test file: %v", err)
	}

	// Mettre à jour le hash
	err = tracker.UpdateFileHash(testFile)
	if err != nil {
		t.Errorf("failed to update file hash: %v", err)
	}

	newHash := tracker.ContentHashes[testFile]

	// Vérifier que le hash a changé
	if originalHash == newHash {
		t.Error("hash should change after content modification")
	}

	// Vérifier l'historique
	history := tracker.GetHashHistory(testFile)
	if len(history) < 2 {
		t.Error("should have at least 2 history records")
	}

	// Vérifier que le dernier enregistrement est une modification
	lastRecord := history[len(history)-1]
	if lastRecord.Operation != "modified" {
		t.Errorf("expected last operation 'modified', got '%s'", lastRecord.Operation)
	}
}

// TestPathTracker_GetContentHashInfo teste la récupération d'informations de hash
func TestPathTracker_GetContentHashInfo(t *testing.T) {
	tracker := NewPathTracker()

	// Créer un fichier temporaire
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "info_test.txt")
	content := "Content for info test"

	err := os.WriteFile(testFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("failed to create test file: %v", err)
	}

	// Enregistrer le fichier
	err = tracker.TrackFileByContent(testFile)
	if err != nil {
		t.Errorf("failed to track file: %v", err)
	}

	hash := tracker.ContentHashes[testFile]

	// Récupérer les informations
	info, err := tracker.GetContentHashInfo(hash)
	if err != nil {
		t.Errorf("failed to get hash info: %v", err)
	}

	if info.Hash != hash {
		t.Errorf("expected hash %s, got %s", hash, info.Hash)
	}

	if info.OriginalPath != testFile {
		t.Errorf("expected original path %s, got %s", testFile, info.OriginalPath)
	}

	if info.CurrentPath != testFile {
		t.Errorf("expected current path %s, got %s", testFile, info.CurrentPath)
	}

	if info.Size <= 0 {
		t.Error("size should be positive")
	}
}

// TestPathTracker_FindDuplicatesByHash teste la détection de doublons
func TestPathTracker_FindDuplicatesByHash(t *testing.T) {
	tracker := NewPathTracker()

	// Créer des fichiers temporaires avec le même contenu
	tmpDir := t.TempDir()
	file1 := filepath.Join(tmpDir, "duplicate1.txt")
	file2 := filepath.Join(tmpDir, "duplicate2.txt")
	file3 := filepath.Join(tmpDir, "unique.txt")

	sameContent := "Duplicate content"
	uniqueContent := "Unique content"

	err := os.WriteFile(file1, []byte(sameContent), 0o644)
	if err != nil {
		t.Fatalf("failed to create file1: %v", err)
	}

	err = os.WriteFile(file2, []byte(sameContent), 0o644)
	if err != nil {
		t.Fatalf("failed to create file2: %v", err)
	}

	err = os.WriteFile(file3, []byte(uniqueContent), 0o644)
	if err != nil {
		t.Fatalf("failed to create file3: %v", err)
	}

	// Enregistrer tous les fichiers
	err = tracker.TrackFileByContent(file1)
	if err != nil {
		t.Errorf("failed to track file1: %v", err)
	}

	err = tracker.TrackFileByContent(file2)
	if err != nil {
		t.Errorf("failed to track file2: %v", err)
	}

	err = tracker.TrackFileByContent(file3)
	if err != nil {
		t.Errorf("failed to track file3: %v", err)
	}

	// Trouver les doublons
	duplicates := tracker.FindDuplicatesByHash()

	// Devrait avoir exactement un groupe de doublons
	if len(duplicates) != 1 {
		t.Errorf("expected 1 duplicate group, got %d", len(duplicates))
	}

	// Vérifier que le groupe contient les deux fichiers dupliqués
	for _, paths := range duplicates {
		if len(paths) != 2 {
			t.Errorf("expected 2 duplicate files, got %d", len(paths))
		}

		// Vérifier que les deux fichiers sont présents
		containsFile1 := false
		containsFile2 := false
		for _, path := range paths {
			if path == file1 {
				containsFile1 = true
			}
			if path == file2 {
				containsFile2 = true
			}
		}

		if !containsFile1 || !containsFile2 {
			t.Error("duplicate group should contain both file1 and file2")
		}
	}
}

// TestPathTracker_CleanupOrphanedHashes teste le nettoyage des hashs orphelins
func TestPathTracker_CleanupOrphanedHashes(t *testing.T) {
	tracker := NewPathTracker()

	// Créer un fichier temporaire
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "cleanup_test.txt")
	content := "Content to be deleted"

	err := os.WriteFile(testFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("failed to create test file: %v", err)
	}

	// Enregistrer le fichier
	err = tracker.TrackFileByContent(testFile)
	if err != nil {
		t.Errorf("failed to track file: %v", err)
	}

	// Vérifier que le fichier est enregistré
	if _, exists := tracker.pathToHash[testFile]; !exists {
		t.Error("file should be tracked before deletion")
	}

	// Supprimer le fichier
	err = os.Remove(testFile)
	if err != nil {
		t.Fatalf("failed to delete test file: %v", err)
	}

	// Nettoyer les hashs orphelins
	err = tracker.CleanupOrphanedHashes()
	if err != nil {
		t.Errorf("failed to cleanup orphaned hashes: %v", err)
	}

	// Vérifier que le fichier n'est plus enregistré
	if _, exists := tracker.pathToHash[testFile]; exists {
		t.Error("file should not be tracked after cleanup")
	}

	// Vérifier que l'historique contient un enregistrement de suppression
	history := tracker.GetHashHistory(testFile)
	if len(history) == 0 {
		t.Error("should have history even after cleanup")
	}

	lastRecord := history[len(history)-1]
	if lastRecord.Operation != "deleted" {
		t.Errorf("expected last operation 'deleted', got '%s'", lastRecord.Operation)
	}
}

// TestPathTracker_CalculateMoveConfidence teste le calcul de confiance de déplacement
func TestPathTracker_CalculateMoveConfidence(t *testing.T) {
	tracker := NewPathTracker()

	tests := []struct {
		name            string
		oldPath         string
		newPath         string
		expectedMinConf float64
		expectedMaxConf float64
	}{
		{
			name:            "same filename same directory",
			oldPath:         "/path/to/file.txt",
			newPath:         "/path/to/file.txt",
			expectedMinConf: 0.9,
			expectedMaxConf: 1.0,
		},
		{
			name:            "same filename different directory",
			oldPath:         "/old/path/file.txt",
			newPath:         "/new/path/file.txt",
			expectedMinConf: 0.5,
			expectedMaxConf: 0.8,
		},
		{
			name:            "different filename same directory",
			oldPath:         "/path/to/old.txt",
			newPath:         "/path/to/new.txt",
			expectedMinConf: 0.5,
			expectedMaxConf: 0.8,
		},
		{
			name:            "completely different",
			oldPath:         "/old/path/old.txt",
			newPath:         "/completely/different/new.md",
			expectedMinConf: 0.0,
			expectedMaxConf: 0.3,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			confidence := tracker.calculateMoveConfidence(tt.oldPath, tt.newPath)

			if confidence < tt.expectedMinConf || confidence > tt.expectedMaxConf {
				t.Errorf("expected confidence between %f and %f, got %f",
					tt.expectedMinConf, tt.expectedMaxConf, confidence)
			}
		})
	}
}

// TestPathTracker_GetHashHistory teste la récupération de l'historique
func TestPathTracker_GetHashHistory(t *testing.T) {
	tracker := NewPathTracker()

	// Créer un fichier temporaire
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "history_test.txt")
	content := "Original content"

	err := os.WriteFile(testFile, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("failed to create test file: %v", err)
	}

	// Enregistrer le fichier
	err = tracker.TrackFileByContent(testFile)
	if err != nil {
		t.Errorf("failed to track file: %v", err)
	}

	// Modifier le fichier
	newContent := "Modified content"
	err = os.WriteFile(testFile, []byte(newContent), 0o644)
	if err != nil {
		t.Fatalf("failed to modify test file: %v", err)
	}

	err = tracker.UpdateFileHash(testFile)
	if err != nil {
		t.Errorf("failed to update file hash: %v", err)
	}

	// Récupérer l'historique
	history := tracker.GetHashHistory(testFile)

	if len(history) < 2 {
		t.Errorf("expected at least 2 history records, got %d", len(history))
	}

	// Vérifier l'ordre chronologique
	for i := 1; i < len(history); i++ {
		if history[i].Timestamp.Before(history[i-1].Timestamp) {
			t.Error("history should be in chronological order")
		}
	}

	// Vérifier les opérations
	if history[0].Operation != "tracked" {
		t.Errorf("expected first operation 'tracked', got '%s'", history[0].Operation)
	}

	if history[len(history)-1].Operation != "modified" {
		t.Errorf("expected last operation 'modified', got '%s'", history[len(history)-1].Operation)
	}
}
