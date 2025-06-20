// SPDX-License-Identifier: MIT
// Package docmanager : path tracker intelligent (v65B)
package docmanager

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"
)

// PathTracker structure pour suivi chemins de fichiers uniquement (SRP)
// MICRO-TASK 3.1.1.2.1 - Responsabilité suivi chemins exclusive
type PathTracker struct {
	// Champs uniquement liés au tracking de paths
	trackedPaths  map[string]string   // oldPath -> newPath
	references    map[string][]string // path -> list of referencing files
	ContentHashes map[string]string   // path -> content hash pour détection changements

	// TASK ATOMIQUE 3.5.1.2 - Tracking par hash de contenu
	hashToPath    map[string]string       // content hash -> original path
	pathToHash    map[string]string       // path -> current content hash
	hashHistory   map[string][]HashRecord // path -> historical hash records
	moveDetection map[string]time.Time    // hash -> last seen timestamp

	mu sync.RWMutex
}

// HashRecord enregistrement historique des hashs
type HashRecord struct {
	Hash      string    `json:"hash"`
	Timestamp time.Time `json:"timestamp"`
	Path      string    `json:"path"`
	Size      int64     `json:"size"`
	Operation string    `json:"operation"` // "created", "modified", "moved", "deleted"
}

// ContentHashInfo information détaillée sur un hash de contenu
type ContentHashInfo struct {
	Hash         string    `json:"hash"`
	OriginalPath string    `json:"original_path"`
	CurrentPath  string    `json:"current_path"`
	FirstSeen    time.Time `json:"first_seen"`
	LastSeen     time.Time `json:"last_seen"`
	Size         int64     `json:"size"`
	MoveHistory  []string  `json:"move_history"`
	References   []string  `json:"references"`
}

// MoveDetectionResult résultat de détection de déplacement
type MoveDetectionResult struct {
	Hash       string    `json:"hash"`
	OldPath    string    `json:"old_path"`
	NewPath    string    `json:"new_path"`
	Confidence float64   `json:"confidence"`
	Timestamp  time.Time `json:"timestamp"`
	References []string  `json:"references"`
}

// NewPathTracker constructeur respectant SRP
func NewPathTracker() *PathTracker {
	return &PathTracker{
		trackedPaths:  make(map[string]string),
		references:    make(map[string][]string),
		ContentHashes: make(map[string]string),
		hashToPath:    make(map[string]string),
		pathToHash:    make(map[string]string),
		hashHistory:   make(map[string][]HashRecord),
		moveDetection: make(map[string]time.Time),
	}
}

// PathHealthReport rapport de santé des chemins
type PathHealthReport struct {
	TotalPaths   int
	BrokenLinks  int
	MissingFiles int
	UpdatedPaths int
	Issues       []string
}

// Structures précédentes inchangées...

// --- LOT 16-31 : MICRO-TÂCHES ATOMIQUES NUMÉROTÉES --- //

// 16. Implémentation du squelette de updateAllReferences
// 17. Ajout des sous-fonctions updateMarkdownLinks, updateCodeReferences, updateConfigPaths, updateImportStatements
// 18. Ajout d’un WaitGroup pour exécution parallèle des mises à jour
// 19. Collecte des erreurs de chaque goroutine
// 20. Retour d’erreur consolidée si au moins une mise à jour échoue
func (pt *PathTracker) UpdateAllReferences(oldPath, newPath string) error {
	// 16. Validation et court-circuit
	if oldPath == newPath {
		return nil
	}
	var errs []error
	var wg sync.WaitGroup
	errCh := make(chan error, 4)

	// 18. Ajout WaitGroup et lancement goroutines
	wg.Add(4)
	go func() {
		defer wg.Done()
		// 17. updateMarkdownLinks
		if err := pt.updateMarkdownLinks(oldPath, newPath); err != nil {
			errCh <- fmt.Errorf("updateMarkdownLinks: %w", err)
		}
	}()
	go func() {
		defer wg.Done()
		// 17. updateCodeReferences
		if err := pt.updateCodeReferences(oldPath, newPath); err != nil {
			errCh <- fmt.Errorf("updateCodeReferences: %w", err)
		}
	}()
	go func() {
		defer wg.Done()
		// 17. updateConfigPaths
		if err := pt.updateConfigPaths(oldPath, newPath); err != nil {
			errCh <- fmt.Errorf("updateConfigPaths: %w", err)
		}
	}()
	go func() {
		defer wg.Done()
		// 17. updateImportStatements
		if err := pt.updateImportStatements(oldPath, newPath); err != nil {
			errCh <- fmt.Errorf("updateImportStatements: %w", err)
		}
	}()
	wg.Wait()
	close(errCh)
	// 19. Collecte des erreurs
	for err := range errCh {
		errs = append(errs, err)
	}
	// 20. Retour d’erreur consolidée
	if len(errs) > 0 {
		return fmt.Errorf("multiple update errors: %v", errs)
	}
	return nil
}

// 21. updateMarkdownLinks : recherche fichiers .md, regex remplacement liens
func (pt *PathTracker) updateMarkdownLinks(oldPath, newPath string) error {
	mdFiles, err := filepath.Glob("**/*.md")
	if err != nil {
		return err
	}
	linkPattern := regexp.MustCompile(`\[[^\]]*\]\(([^)]*)\)`)
	for _, file := range mdFiles {
		input, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		changed := false
		lines := strings.Split(string(input), "\n")
		for i, line := range lines {
			if strings.Contains(line, oldPath) {
				newLine := linkPattern.ReplaceAllStringFunc(line, func(m string) string {
					return strings.ReplaceAll(m, oldPath, newPath)
				})
				if newLine != line {
					lines[i] = newLine
					changed = true
				}
			}
		}
		if changed {
			tmpFile := file + ".tmp"
			err := os.WriteFile(tmpFile, []byte(strings.Join(lines, "\n")), 0o644)
			if err != nil {
				return err
			}
			err = os.Rename(tmpFile, file)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

// 22. updateCodeReferences : recherche fichiers .go, AST parsing, remplacement string literals
func (pt *PathTracker) updateCodeReferences(oldPath, newPath string) error {
	goFiles, err := filepath.Glob("**/*.go")
	if err != nil {
		return err
	}
	for _, file := range goFiles {
		fset := token.NewFileSet()
		node, err := parser.ParseFile(fset, file, nil, parser.ParseComments)
		if err != nil {
			continue
		}
		changed := false
		var output strings.Builder
		src, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		lines := strings.Split(string(src), "\n")
		ast.Inspect(node, func(n ast.Node) bool {
			lit, ok := n.(*ast.BasicLit)
			if ok && lit.Kind == token.STRING && strings.Contains(lit.Value, oldPath) {
				lit.Value = strings.ReplaceAll(lit.Value, oldPath, newPath)
				changed = true
			}
			return true
		})
		if changed {
			for _, line := range lines {
				output.WriteString(strings.ReplaceAll(line, oldPath, newPath) + "\n")
			}
			tmpFile := file + ".tmp"
			err := os.WriteFile(tmpFile, []byte(output.String()), 0o644)
			if err != nil {
				return err
			}
			err = os.Rename(tmpFile, file)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

// 23. updateConfigPaths : recherche fichiers .json/.yaml, remplacement chemins
func (pt *PathTracker) updateConfigPaths(oldPath, newPath string) error {
	configFiles, err := filepath.Glob("**/*.{json,yaml,yml}")
	if err != nil {
		return err
	}
	for _, file := range configFiles {
		input, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		if !strings.Contains(string(input), oldPath) {
			continue
		}
		newContent := strings.ReplaceAll(string(input), oldPath, newPath)
		tmpFile := file + ".tmp"
		err = os.WriteFile(tmpFile, []byte(newContent), 0o644)
		if err != nil {
			return err
		}
		err = os.Rename(tmpFile, file)
		if err != nil {
			return err
		}
	}
	return nil
}

// 24. updateImportStatements : recherche imports Go, remplacement si besoin
func (pt *PathTracker) updateImportStatements(oldPath, newPath string) error {
	goFiles, err := filepath.Glob("**/*.go")
	if err != nil {
		return err
	}
	for _, file := range goFiles {
		input, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		changed := false
		lines := strings.Split(string(input), "\n")
		for i, line := range lines {
			if strings.HasPrefix(strings.TrimSpace(line), "import") && strings.Contains(line, oldPath) {
				lines[i] = strings.ReplaceAll(line, oldPath, newPath)
				changed = true
			}
		}
		if changed {
			tmpFile := file + ".tmp"
			err := os.WriteFile(tmpFile, []byte(strings.Join(lines, "\n")), 0o644)
			if err != nil {
				return err
			}
			err = os.Rename(tmpFile, file)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

// 25. Ajout de PathHealthReport détaillé (structure déjà présente)
// 26. Squelette HealthCheck : scan ContentHashes, vérification existence fichiers
// 27. Pour chaque hash, recalcul et comparaison avec stocké
// 28. Ajout des fichiers manquants à BrokenPaths
// 29. Ajout des hashes orphelins à OrphanedHashes
// 30. Génération de recommandations simples (stub)
// 31. Retour du rapport santé complet
func (pt *PathTracker) HealthCheck() (*PathHealthReport, error) {
	pt.mu.RLock()
	defer pt.mu.RUnlock()
	report := &PathHealthReport{
		TotalPaths:   len(pt.ContentHashes),
		BrokenLinks:  0,
		MissingFiles: 0,
		UpdatedPaths: 0,
		Issues:       []string{},
	}
	for path, hash := range pt.ContentHashes {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			// 28. Ajout fichier manquant
			report.MissingFiles++
			report.Issues = append(report.Issues, fmt.Sprintf("Fichier manquant: %s", path))
			continue
		}
		actualHash, err := pt.CalculateContentHash(path)
		if err != nil {
			report.BrokenLinks++
			report.Issues = append(report.Issues, fmt.Sprintf("Erreur de calcul de hash: %s", path))
			continue
		}
		if actualHash != hash {
			// 29. Ajout hash orphelin
			report.BrokenLinks++
			report.Issues = append(report.Issues, fmt.Sprintf("Hash orphelin détecté: %s", path))
		} else {
			report.UpdatedPaths++
		}
	}
	// 30. Génération recommandations
	if len(report.Issues) > 0 {
		report.Issues = append(report.Issues, "Veuillez vérifier les problèmes signalés.")
	}
	// 31. Retour rapport santé
	return report, nil
}

// TASK ATOMIQUE 3.5.1.2 - Enhanced content hash calculation
// CalculateContentHash calcule le hash SHA256 du contenu d'un fichier
func (pt *PathTracker) CalculateContentHash(path string) (string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("failed to read file %s: %w", path, err)
	}

	// Utilisation de SHA256 pour un hash robuste
	hasher := sha256.New()
	hasher.Write(content)
	hash := hex.EncodeToString(hasher.Sum(nil))

	return hash, nil
}

// TrackFileByContent enregistre un fichier par son contenu
func (pt *PathTracker) TrackFileByContent(path string) error {
	pt.mu.Lock()
	defer pt.mu.Unlock()

	// Calculer le hash du contenu
	hash, err := pt.CalculateContentHash(path)
	if err != nil {
		return fmt.Errorf("failed to calculate hash for %s: %w", path, err)
	}

	// Obtenir les informations du fichier
	info, err := os.Stat(path)
	if err != nil {
		return fmt.Errorf("failed to stat file %s: %w", path, err)
	}

	// Enregistrer le hash et le chemin
	pt.ContentHashes[path] = hash
	pt.pathToHash[path] = hash

	// Enregistrer l'historique
	record := HashRecord{
		Hash:      hash,
		Timestamp: time.Now(),
		Path:      path,
		Size:      info.Size(),
		Operation: "tracked",
	}

	pt.hashHistory[path] = append(pt.hashHistory[path], record)

	// Mettre à jour le mapping hash -> path
	if existingPath, exists := pt.hashToPath[hash]; exists {
		// Possible déplacement détecté
		if existingPath != path {
			pt.moveDetection[hash] = time.Now()
			// Créer un enregistrement de déplacement
			moveRecord := HashRecord{
				Hash:      hash,
				Timestamp: time.Now(),
				Path:      path,
				Size:      info.Size(),
				Operation: "moved",
			}
			pt.hashHistory[path] = append(pt.hashHistory[path], moveRecord)
		}
	} else {
		pt.hashToPath[hash] = path
	}

	return nil
}

// DetectMovedFile détecte si un fichier a été déplacé en comparant les hashs
func (pt *PathTracker) DetectMovedFile(newPath string) (*MoveDetectionResult, error) {
	pt.mu.RLock()
	defer pt.mu.RUnlock()

	// Calculer le hash du nouveau fichier
	hash, err := pt.CalculateContentHash(newPath)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate hash for %s: %w", newPath, err)
	}

	// Vérifier si ce hash existe déjà avec un autre chemin
	if originalPath, exists := pt.hashToPath[hash]; exists && originalPath != newPath {
		// Calculer la confiance basée sur la similarité des chemins
		confidence := pt.calculateMoveConfidence(originalPath, newPath)

		// Récupérer les références de l'ancien chemin
		references := pt.references[originalPath]

		result := &MoveDetectionResult{
			Hash:       hash,
			OldPath:    originalPath,
			NewPath:    newPath,
			Confidence: confidence,
			Timestamp:  time.Now(),
			References: references,
		}

		return result, nil
	}

	return nil, nil // Aucun déplacement détecté
}

// calculateMoveConfidence calcule la confiance qu'un fichier ait été déplacé
func (pt *PathTracker) calculateMoveConfidence(oldPath, newPath string) float64 {
	// Facteurs de confiance
	confidence := 0.0

	// 1. Même nom de fichier
	oldBase := filepath.Base(oldPath)
	newBase := filepath.Base(newPath)
	if oldBase == newBase {
		confidence += 0.4
	}

	// 2. Extension similaire
	oldExt := filepath.Ext(oldPath)
	newExt := filepath.Ext(newPath)
	if oldExt == newExt {
		confidence += 0.2
	}

	// 3. Proximité des répertoires
	oldDir := filepath.Dir(oldPath)
	newDir := filepath.Dir(newPath)

	// Compter les composants communs du chemin
	oldParts := strings.Split(oldDir, string(filepath.Separator))
	newParts := strings.Split(newDir, string(filepath.Separator))

	commonParts := 0
	maxParts := len(oldParts)
	if len(newParts) < maxParts {
		maxParts = len(newParts)
	}

	for i := 0; i < maxParts; i++ {
		if oldParts[i] == newParts[i] {
			commonParts++
		} else {
			break
		}
	}

	if maxParts > 0 {
		pathSimilarity := float64(commonParts) / float64(maxParts)
		confidence += pathSimilarity * 0.3
	}

	// 4. Timing - fichiers détectés récemment ont plus de chance d'être des déplacements
	if lastSeen, exists := pt.moveDetection[pt.pathToHash[oldPath]]; exists {
		timeDiff := time.Since(lastSeen)
		if timeDiff < 5*time.Minute {
			confidence += 0.1
		}
	}

	// Limiter la confiance à 1.0
	if confidence > 1.0 {
		confidence = 1.0
	}

	return confidence
}

// UpdateFileHash met à jour le hash d'un fichier après modification
func (pt *PathTracker) UpdateFileHash(path string) error {
	pt.mu.Lock()
	defer pt.mu.Unlock()

	// Calculer le nouveau hash
	newHash, err := pt.CalculateContentHash(path)
	if err != nil {
		return fmt.Errorf("failed to calculate new hash for %s: %w", path, err)
	}

	// Obtenir l'ancien hash
	oldHash, exists := pt.pathToHash[path]
	if !exists {
		// Nouveau fichier
		return pt.TrackFileByContent(path)
	}

	// Si le hash a changé
	if oldHash != newHash {
		// Obtenir les informations du fichier
		info, err := os.Stat(path)
		if err != nil {
			return fmt.Errorf("failed to stat file %s: %w", path, err)
		}

		// Mettre à jour les mappings
		pt.ContentHashes[path] = newHash
		pt.pathToHash[path] = newHash
		pt.hashToPath[newHash] = path

		// Nettoyer l'ancien mapping si aucun autre fichier ne l'utilise
		if currentPath, exists := pt.hashToPath[oldHash]; exists && currentPath == path {
			delete(pt.hashToPath, oldHash)
		}

		// Enregistrer l'historique
		record := HashRecord{
			Hash:      newHash,
			Timestamp: time.Now(),
			Path:      path,
			Size:      info.Size(),
			Operation: "modified",
		}

		pt.hashHistory[path] = append(pt.hashHistory[path], record)
	}

	return nil
}

// GetContentHashInfo retourne les informations détaillées sur un hash
func (pt *PathTracker) GetContentHashInfo(hash string) (*ContentHashInfo, error) {
	pt.mu.RLock()
	defer pt.mu.RUnlock()

	currentPath, exists := pt.hashToPath[hash]
	if !exists {
		return nil, fmt.Errorf("hash not found: %s", hash)
	}

	// Trouver le chemin original et l'historique
	var originalPath string
	var firstSeen, lastSeen time.Time
	var moveHistory []string

	// Parcourir l'historique pour trouver les informations
	for path, records := range pt.hashHistory {
		for _, record := range records {
			if record.Hash == hash {
				if originalPath == "" || record.Timestamp.Before(firstSeen) {
					originalPath = path
					firstSeen = record.Timestamp
				}
				if record.Timestamp.After(lastSeen) {
					lastSeen = record.Timestamp
				}
				if record.Operation == "moved" {
					moveHistory = append(moveHistory, record.Path)
				}
			}
		}
	}

	// Obtenir la taille actuelle
	var size int64
	if info, err := os.Stat(currentPath); err == nil {
		size = info.Size()
	}

	info := &ContentHashInfo{
		Hash:         hash,
		OriginalPath: originalPath,
		CurrentPath:  currentPath,
		FirstSeen:    firstSeen,
		LastSeen:     lastSeen,
		Size:         size,
		MoveHistory:  moveHistory,
		References:   pt.references[currentPath],
	}

	return info, nil
}

// FindDuplicatesByHash trouve les fichiers dupliqués basés sur le hash de contenu
func (pt *PathTracker) FindDuplicatesByHash() map[string][]string {
	pt.mu.RLock()
	defer pt.mu.RUnlock()

	hashCounts := make(map[string][]string)

	// Grouper les chemins par hash
	for path, hash := range pt.pathToHash {
		hashCounts[hash] = append(hashCounts[hash], path)
	}

	// Retourner seulement les hashs avec plusieurs fichiers
	duplicates := make(map[string][]string)
	for hash, paths := range hashCounts {
		if len(paths) > 1 {
			duplicates[hash] = paths
		}
	}

	return duplicates
}

// CleanupOrphanedHashes nettoie les hashs orphelins
func (pt *PathTracker) CleanupOrphanedHashes() error {
	pt.mu.Lock()
	defer pt.mu.Unlock()

	// Vérifier quels fichiers existent encore
	var toRemove []string

	for path := range pt.pathToHash {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			toRemove = append(toRemove, path)
		}
	}

	// Supprimer les entrées orphelines
	for _, path := range toRemove {
		hash := pt.pathToHash[path]

		// Supprimer de tous les mappings
		delete(pt.pathToHash, path)
		delete(pt.ContentHashes, path)

		// Supprimer du mapping hash->path seulement si c'est le seul fichier avec ce hash
		if currentPath, exists := pt.hashToPath[hash]; exists && currentPath == path {
			delete(pt.hashToPath, hash)
		}

		// Marquer comme supprimé dans l'historique
		record := HashRecord{
			Hash:      hash,
			Timestamp: time.Now(),
			Path:      path,
			Size:      0,
			Operation: "deleted",
		}
		pt.hashHistory[path] = append(pt.hashHistory[path], record)
	}

	return nil
}

// GetHashHistory retourne l'historique complet des hashs pour un chemin
func (pt *PathTracker) GetHashHistory(path string) []HashRecord {
	pt.mu.RLock()
	defer pt.mu.RUnlock()

	history, exists := pt.hashHistory[path]
	if !exists {
		return []HashRecord{}
	}

	// Retourner une copie pour éviter les modifications concurrentes
	result := make([]HashRecord, len(history))
	copy(result, history)
	return result
}

// Helper function
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
