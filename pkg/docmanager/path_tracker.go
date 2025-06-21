// SPDX-License-Identifier: MIT
// Package docmanager : path tracker intelligent (v65B)
package docmanager

import (
	"crypto/sha256"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
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

	// Nouveaux champs pour fonctionnalités avancées
	movementHistory []MovementEvent   // historique des mouvements
	recoveryHistory []RecoveryEvent   // historique des récupérations
	watcher         *fsnotify.Watcher // surveillance du système de fichiers
	watcherActive   bool              // état du watcher
	watchedPaths    map[string]bool   // chemins surveillés
	fileWatcher     *fsnotify.Watcher // watcher pour les fichiers (TASK 4.1.1.1.4)
	moveHistory     []FileMoveEvent   // historique des déplacements (TASK 4.1.1.1.5)

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

// MovementEvent enregistrement d'événement de mouvement
type MovementEvent struct {
	EventID    string    `json:"event_id"`
	EventType  string    `json:"event_type"` // "move", "rename", "delete", "create"
	OldPath    string    `json:"old_path"`
	NewPath    string    `json:"new_path"`
	Hash       string    `json:"hash"`
	Timestamp  time.Time `json:"timestamp"`
	Confidence float64   `json:"confidence"`
	References []string  `json:"references"`
	Automated  bool      `json:"automated"`
}

// MovementResult résultat de détection de mouvement
type MovementResult struct {
	OldPath    string    `json:"old_path"`
	NewPath    string    `json:"new_path"`
	Confidence float64   `json:"confidence"`
	Timestamp  time.Time `json:"timestamp"`
}

// BrokenLink lien cassé détecté
type BrokenLink struct {
	FilePath   string  `json:"file_path"`
	LinkText   string  `json:"link_text"`
	TargetPath string  `json:"target_path"`
	LineNumber int     `json:"line_number"`
	Confidence float64 `json:"confidence"`
}

// RepairResult résultat de réparation de lien
type RepairResult struct {
	Success    bool      `json:"success"`
	OldTarget  string    `json:"old_target"`
	NewTarget  string    `json:"new_target"`
	Confidence float64   `json:"confidence"`
	Timestamp  time.Time `json:"timestamp"`
	Error      string    `json:"error,omitempty"`
}

// BatchRepairResult résultat de réparation en lot
type BatchRepairResult struct {
	TotalLinks    int            `json:"total_links"`
	RepairedLinks int            `json:"repaired_links"`
	FailedLinks   int            `json:"failed_links"`
	Results       []RepairResult `json:"results"`
	Duration      time.Duration  `json:"duration"`
}

// RecoveryEvent événement de récupération
type RecoveryEvent struct {
	EventID   string    `json:"event_id"`
	Type      string    `json:"type"`
	FilePath  string    `json:"file_path"`
	Action    string    `json:"action"`
	Success   bool      `json:"success"`
	Timestamp time.Time `json:"timestamp"`
	Details   string    `json:"details"`
}

// IntegrityResult résultat de validation d'intégrité
type IntegrityResult struct {
	Valid          bool          `json:"valid"`
	Hash           string        `json:"hash"`
	ReferenceCount int           `json:"reference_count"`
	BrokenRefs     []string      `json:"broken_refs"`
	ValidationTime time.Duration `json:"validation_time"`
}

// GlobalIntegrityResult résultat de validation globale
type GlobalIntegrityResult struct {
	TotalFiles     int                        `json:"total_files"`
	ValidFiles     int                        `json:"valid_files"`
	InvalidFiles   int                        `json:"invalid_files"`
	BrokenLinks    []BrokenLink               `json:"broken_links"`
	IntegrityMap   map[string]IntegrityResult `json:"integrity_map"`
	ValidationTime time.Duration              `json:"validation_time"`
}

// InconsistencyError erreur d'incohérence
type InconsistencyError struct {
	Type        string    `json:"type"`
	FilePath    string    `json:"file_path"`
	Expected    string    `json:"expected"`
	Actual      string    `json:"actual"`
	Description string    `json:"description"`
	Timestamp   time.Time `json:"timestamp"`
}

// IntegrityReport rapport d'intégrité
type IntegrityReport struct {
	GeneratedAt     time.Time            `json:"generated_at"`
	TotalFiles      int                  `json:"total_files"`
	ValidFiles      int                  `json:"valid_files"`
	Issues          []InconsistencyError `json:"issues"`
	Recommendations []string             `json:"recommendations"`
	Summary         string               `json:"summary"`
}

// NewPathTracker constructeur respectant SRP
func NewPathTracker() *PathTracker {
	return &PathTracker{
		trackedPaths:    make(map[string]string),
		references:      make(map[string][]string),
		ContentHashes:   make(map[string]string),
		hashToPath:      make(map[string]string),
		pathToHash:      make(map[string]string),
		hashHistory:     make(map[string][]HashRecord),
		moveDetection:   make(map[string]time.Time),
		movementHistory: make([]MovementEvent, 0),
		recoveryHistory: make([]RecoveryEvent, 0),
		watchedPaths:    make(map[string]bool),
		watcherActive:   false,
	}
}

// PathHealthReport is defined in path_health_report.go
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
		TotalFiles:      len(pt.ContentHashes),
		ValidPaths:      0,
		BrokenPaths:     []string{},
		OrphanedHashes:  []string{}, // Not fully implemented by original logic here
		Recommendations: []string{},
		Timestamp:       time.Now(),
	}

	var issuesForRecommendations []string

	for path, storedHash := range pt.ContentHashes {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			issueMsg := fmt.Sprintf("Fichier manquant: %s (hash attendu: %s)", path, storedHash)
			report.BrokenPaths = append(report.BrokenPaths, issueMsg)
			issuesForRecommendations = append(issuesForRecommendations, issueMsg)
			continue
		}
		actualHash, err := pt.CalculateContentHash(path)
		if err != nil {
			issueMsg := fmt.Sprintf("Erreur de calcul de hash pour %s: %v", path, err)
			report.BrokenPaths = append(report.BrokenPaths, issueMsg)
			issuesForRecommendations = append(issuesForRecommendations, issueMsg)
			continue
		}
		if actualHash != storedHash {
			issueMsg := fmt.Sprintf("Contenu modifié (hash mismatch) pour %s: attendu %s, obtenu %s", path, storedHash, actualHash)
			report.BrokenPaths = append(report.BrokenPaths, issueMsg)
			issuesForRecommendations = append(issuesForRecommendations, issueMsg)
		} else {
			report.ValidPaths++
		}
	}

	if len(issuesForRecommendations) > 0 {
		report.Recommendations = append(report.Recommendations, "Veuillez vérifier les problèmes signalés: "+strings.Join(issuesForRecommendations, "; "))
	}
	if report.ValidPaths < report.TotalFiles {
		report.Recommendations = append(report.Recommendations, fmt.Sprintf("%d fichiers sur %d présentent des problèmes d'intégrité.", report.TotalFiles-report.ValidPaths, report.TotalFiles))
	}
	if len(report.Recommendations) == 0 && report.TotalFiles > 0 {
		report.Recommendations = append(report.Recommendations, "Aucun problème d'intégrité majeur détecté pour les chemins suivis.")
	} else if report.TotalFiles == 0 {
		report.Recommendations = append(report.Recommendations, "Aucun chemin n'est actuellement suivi.")
	}

	return report, nil
}

// TASK ATOMIQUE 3.5.1.2 - Enhanced content hash calculation
// CalculateContentHash calcule le hash SHA256 du contenu d'un fichier
func (pt *PathTracker) CalculateContentHash(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("cannot open file %s: %w", filePath, err)
	}
	defer file.Close()
	stat, err := file.Stat()
	if err != nil {
		return "", err
	}
	_ = stat // utilisé pour tests/validation
	hasher := sha256.New()
	buffer := make([]byte, 32*1024)
	for {
		n, err := file.Read(buffer)
		if n > 0 {
			hasher.Write(buffer[:n])
		}
		if err == io.EOF {
			break
		}
		if err != nil {
			return "", err
		}
	}
	hashBytes := hasher.Sum(nil)
	return fmt.Sprintf("%x", hashBytes), nil
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

// DetectMovedFile détecte automatiquement les déplacements via hash
func (pt *PathTracker) DetectMovedFile(newPath string) (*MovementResult, error) {
	pt.mu.RLock()
	defer pt.mu.RUnlock()

	hash, err := pt.CalculateContentHash(newPath)
	if err != nil {
		return nil, fmt.Errorf("hash calculation failed: %w", err)
	}

	for trackedPath, trackedHash := range pt.ContentHashes {
		if trackedHash == hash && trackedPath != newPath {
			confidence := pt.calculateMoveConfidence(trackedPath, newPath)
			return &MovementResult{
				OldPath:    trackedPath,
				NewPath:    newPath,
				Confidence: confidence,
				Timestamp:  time.Now(),
			}, nil
		}
	}
	return nil, nil
}

// calculateMoveConfidence calcule la confiance de déplacement
func (pt *PathTracker) calculateMoveConfidence(oldPath, newPath string) float64 {
	// Calcul basé sur similarité de nom, structure de dossier, etc.
	oldName := filepath.Base(oldPath)
	newName := filepath.Base(newPath)

	if oldName == newName {
		return 0.9 // Même nom = haute confiance
	}

	// Analyser la similarité des chemins
	oldDir := filepath.Dir(oldPath)
	newDir := filepath.Dir(newPath)

	if oldDir == newDir {
		return 0.7 // Même dossier = confiance moyenne
	}

	return 0.5 // Confiance de base
}

// UpdateAutomaticReferences met à jour automatiquement les références
func (pt *PathTracker) UpdateAutomaticReferences(oldPath, newPath string) error {
	pt.mu.Lock()
	defer pt.mu.Unlock()

	// Enregistrer l'événement de mouvement
	event := MovementEvent{
		EventID:   fmt.Sprintf("move_%d", time.Now().Unix()),
		EventType: "move",
		OldPath:   oldPath,
		NewPath:   newPath,
		Timestamp: time.Now(),
		Automated: true,
	}

	// Calculer le hash pour validation
	if hash, err := pt.CalculateContentHash(newPath); err == nil {
		event.Hash = hash
	}

	// Mettre à jour les références
	if refs, exists := pt.references[oldPath]; exists {
		event.References = refs
		for _, refFile := range refs {
			if err := pt.updateFileReferences(refFile, oldPath, newPath); err != nil {
				return fmt.Errorf("failed to update references in %s: %w", refFile, err)
			}
		}

		// Déplacer les références vers le nouveau chemin
		pt.references[newPath] = refs
		delete(pt.references, oldPath)
	}

	// Mettre à jour les hashes
	if hash, exists := pt.ContentHashes[oldPath]; exists {
		pt.ContentHashes[newPath] = hash
		delete(pt.ContentHashes, oldPath)
	}

	// Ajouter à l'historique
	pt.movementHistory = append(pt.movementHistory, event)

	return nil
}

// StartFileSystemWatcher démarre la surveillance du système de fichiers
func (pt *PathTracker) StartFileSystemWatcher() error {
	pt.mu.Lock()
	defer pt.mu.Unlock()

	if pt.watcherActive {
		return fmt.Errorf("file system watcher already active")
	}

	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return fmt.Errorf("failed to create watcher: %w", err)
	}

	pt.watcher = watcher
	pt.watcherActive = true
	pt.watchedPaths = make(map[string]bool)

	// Démarrer la goroutine de surveillance
	go pt.watchFileSystemEvents()

	return nil
}

// StopFileSystemWatcher arrête la surveillance du système de fichiers
func (pt *PathTracker) StopFileSystemWatcher() error {
	pt.mu.Lock()
	defer pt.mu.Unlock()

	if !pt.watcherActive || pt.watcher == nil {
		return fmt.Errorf("file system watcher not active")
	}

	pt.watcherActive = false

	if err := pt.watcher.Close(); err != nil {
		return fmt.Errorf("failed to close watcher: %w", err)
	}

	pt.watcher = nil
	pt.watchedPaths = nil

	return nil
}

// watchFileSystemEvents surveille les événements du système de fichiers
func (pt *PathTracker) watchFileSystemEvents() {
	for pt.watcherActive {
		select {
		case event, ok := <-pt.watcher.Events:
			if !ok {
				return
			}

			pt.handleFileSystemEvent(event)

		case err, ok := <-pt.watcher.Errors:
			if !ok {
				return
			}
			// Log l'erreur (ici on pourrait utiliser un logger)
			fmt.Printf("Watcher error: %v\n", err)
		}
	}
}

// handleFileSystemEvent gère un événement du système de fichiers
func (pt *PathTracker) handleFileSystemEvent(event fsnotify.Event) {
	pt.mu.Lock()
	defer pt.mu.Unlock()

	switch {
	case event.Has(fsnotify.Create):
		pt.handleFileCreate(event.Name)
	case event.Has(fsnotify.Remove):
		pt.handleFileRemove(event.Name)
	case event.Has(fsnotify.Write):
		pt.handleFileModify(event.Name)
	case event.Has(fsnotify.Rename):
		pt.handleFileRename(event.Name)
	}
}

// handleFileCreate gère la création d'un fichier
func (pt *PathTracker) handleFileCreate(path string) {
	// Vérifier si c'est un fichier déplacé
	if result, err := pt.DetectMovedFile(path); err == nil && result != nil {
		pt.UpdateAutomaticReferences(result.OldPath, result.NewPath)
	}
}

// handleFileRemove gère la suppression d'un fichier
func (pt *PathTracker) handleFileRemove(path string) {
	// Marquer le fichier comme supprimé dans l'historique
	if hash, exists := pt.ContentHashes[path]; exists {
		record := HashRecord{
			Hash:      hash,
			Timestamp: time.Now(),
			Path:      path,
			Operation: "deleted",
		}
		pt.hashHistory[path] = append(pt.hashHistory[path], record)
	}
}

// handleFileModify gère la modification d'un fichier
func (pt *PathTracker) handleFileModify(path string) {
	// Recalculer et mettre à jour le hash
	if hash, err := pt.CalculateContentHash(path); err == nil {
		pt.ContentHashes[path] = hash

		record := HashRecord{
			Hash:      hash,
			Timestamp: time.Now(),
			Path:      path,
			Operation: "modified",
		}
		pt.hashHistory[path] = append(pt.hashHistory[path], record)
	}
}

// handleFileRename gère le renommage d'un fichier
func (pt *PathTracker) handleFileRename(path string) {
	// Logique de gestion des renommages
	// Déjà gérée par la combinaison Create/Remove
}

// GetMovementHistory retourne l'historique des mouvements
func (pt *PathTracker) GetMovementHistory() []MovementEvent {
	pt.mu.RLock()
	defer pt.mu.RUnlock()

	// Retourner une copie pour éviter les modifications concurrentes
	history := make([]MovementEvent, len(pt.movementHistory))
	copy(history, pt.movementHistory)
	return history
}

// ScanBrokenLinks scanne récursivement les liens cassés
func (pt *PathTracker) ScanBrokenLinks(rootPath string) ([]BrokenLink, error) {
	var brokenLinks []BrokenLink

	err := filepath.Walk(rootPath, func(path string, info os.FileInfo, err error) error {
		if err != nil || !strings.HasSuffix(path, ".md") {
			return err
		}

		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}

		links := pt.extractMarkdownLinks(string(content))
		for lineNum, link := range links {
			if !pt.pathExists(link.TargetPath) {
				brokenLinks = append(brokenLinks, BrokenLink{
					FilePath:   path,
					LinkText:   link.Text,
					TargetPath: link.TargetPath,
					LineNumber: lineNum,
					Confidence: pt.calculateRepairConfidence(link.TargetPath),
				})
			}
		}
		return nil
	})

	return brokenLinks, err
}

// MarkdownLink représente un lien markdown
type MarkdownLink struct {
	Text       string
	TargetPath string
}

// extractMarkdownLinks extrait les liens markdown d'un contenu
func (pt *PathTracker) extractMarkdownLinks(content string) map[int]MarkdownLink {
	links := make(map[int]MarkdownLink)

	// Regex pour détecter les liens markdown [text](path)
	linkRegex := regexp.MustCompile(`\[([^\]]+)\]\(([^)]+)\)`)

	lines := strings.Split(content, "\n")
	for lineNum, line := range lines {
		matches := linkRegex.FindAllStringSubmatch(line, -1)
		for _, match := range matches {
			if len(match) >= 3 {
				links[lineNum+1] = MarkdownLink{
					Text:       match[1],
					TargetPath: match[2],
				}
			}
		}
	}

	return links
}

// pathExists vérifie si un chemin existe
func (pt *PathTracker) pathExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// calculateRepairConfidence calcule la confiance de réparation d'un lien
func (pt *PathTracker) calculateRepairConfidence(targetPath string) float64 {
	// Rechercher des fichiers similaires
	dir := filepath.Dir(targetPath)
	filename := filepath.Base(targetPath)

	// Vérifier les fichiers du même dossier
	if entries, err := os.ReadDir(dir); err == nil {
		for _, entry := range entries {
			if strings.Contains(entry.Name(), strings.TrimSuffix(filename, filepath.Ext(filename))) {
				return 0.8 // Fichier similaire trouvé
			}
		}
	}

	return 0.3 // Confiance faible
}

// RepairBrokenLink répare un lien cassé
func (pt *PathTracker) RepairBrokenLink(link BrokenLink) (*RepairResult, error) {
	result := &RepairResult{
		Success:   false,
		OldTarget: link.TargetPath,
		Timestamp: time.Now(),
	}

	// Rechercher une cible alternative
	newTarget := pt.findAlternativeTarget(link.TargetPath)
	if newTarget == "" {
		result.Error = "no alternative target found"
		return result, nil
	}

	// Mettre à jour le fichier
	if err := pt.updateLinkInFile(link.FilePath, link.TargetPath, newTarget, link.LineNumber); err != nil {
		result.Error = err.Error()
		return result, err
	}

	result.Success = true
	result.NewTarget = newTarget
	result.Confidence = pt.calculateRepairConfidence(newTarget)

	// Enregistrer l'événement de récupération
	event := RecoveryEvent{
		EventID:   fmt.Sprintf("repair_%d", time.Now().Unix()),
		Type:      "link_repair",
		FilePath:  link.FilePath,
		Action:    fmt.Sprintf("Updated link from %s to %s", link.TargetPath, newTarget),
		Success:   true,
		Timestamp: time.Now(),
	}

	pt.mu.Lock()
	pt.recoveryHistory = append(pt.recoveryHistory, event)
	pt.mu.Unlock()

	return result, nil
}

// findAlternativeTarget trouve une cible alternative pour un lien cassé
func (pt *PathTracker) findAlternativeTarget(brokenPath string) string {
	// Rechercher dans les hashes de contenu
	filename := filepath.Base(brokenPath)

	pt.mu.RLock()
	defer pt.mu.RUnlock()

	for path := range pt.ContentHashes {
		if filepath.Base(path) == filename {
			return path
		}
	}

	return ""
}

// updateLinkInFile met à jour un lien dans un fichier
func (pt *PathTracker) updateLinkInFile(filePath, oldTarget, newTarget string, lineNumber int) error {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	lines := strings.Split(string(content), "\n")
	if lineNumber > 0 && lineNumber <= len(lines) {
		lines[lineNumber-1] = strings.ReplaceAll(lines[lineNumber-1], oldTarget, newTarget)
	}

	newContent := strings.Join(lines, "\n")
	return os.WriteFile(filePath, []byte(newContent), 0o644)
}

// RepairAllBrokenLinks répare tous les liens cassés
func (pt *PathTracker) RepairAllBrokenLinks(links []BrokenLink) (*BatchRepairResult, error) {
	startTime := time.Now()

	result := &BatchRepairResult{
		TotalLinks: len(links),
		Results:    make([]RepairResult, 0, len(links)),
	}

	for _, link := range links {
		repairResult, err := pt.RepairBrokenLink(link)
		if err == nil && repairResult.Success {
			result.RepairedLinks++
		} else {
			result.FailedLinks++
		}

		if repairResult != nil {
			result.Results = append(result.Results, *repairResult)
		}
	}

	result.Duration = time.Since(startTime)
	return result, nil
}

// GetRecoveryHistory retourne l'historique des récupérations
func (pt *PathTracker) GetRecoveryHistory() []RecoveryEvent {
	pt.mu.RLock()
	defer pt.mu.RUnlock()

	history := make([]RecoveryEvent, len(pt.recoveryHistory))
	copy(history, pt.recoveryHistory)
	return history
}

// ValidatePostMove valide l'intégrité après un déplacement
func (pt *PathTracker) ValidatePostMove(oldPath, newPath string) (*IntegrityResult, error) {
	startTime := time.Now()

	// Vérification hash du nouveau fichier
	newHash, err := pt.CalculateContentHash(newPath)
	if err != nil {
		return nil, fmt.Errorf("hash validation failed: %w", err)
	}

	// Vérification que l'ancien hash correspond
	oldHash, exists := pt.ContentHashes[oldPath]
	if !exists || oldHash != newHash {
		return &IntegrityResult{
			Valid:          false,
			Hash:           newHash,
			ValidationTime: time.Since(startTime),
		}, nil
	}

	// Validation des références mises à jour
	brokenRefs := pt.scanForBrokenReferences(newPath)
	refCount := pt.countReferencesToFile(newPath)

	return &IntegrityResult{
		Valid:          len(brokenRefs) == 0,
		Hash:           newHash,
		ReferenceCount: refCount,
		BrokenRefs:     brokenRefs,
		ValidationTime: time.Since(startTime),
	}, nil
}

// scanForBrokenReferences scanne les références cassées vers un fichier
func (pt *PathTracker) scanForBrokenReferences(filePath string) []string {
	var brokenRefs []string

	pt.mu.RLock()
	defer pt.mu.RUnlock()

	if refs, exists := pt.references[filePath]; exists {
		for _, refFile := range refs {
			if !pt.pathExists(refFile) {
				brokenRefs = append(brokenRefs, refFile)
			}
		}
	}

	return brokenRefs
}

// countReferencesToFile compte les références vers un fichier
func (pt *PathTracker) countReferencesToFile(filePath string) int {
	pt.mu.RLock()
	defer pt.mu.RUnlock()

	if refs, exists := pt.references[filePath]; exists {
		return len(refs)
	}

	return 0
}

// PerformFullIntegrityCheck effectue une vérification complète d'intégrité
func (pt *PathTracker) PerformFullIntegrityCheck(rootPath string) (*GlobalIntegrityResult, error) {
	startTime := time.Now()

	result := &GlobalIntegrityResult{
		IntegrityMap: make(map[string]IntegrityResult),
		BrokenLinks:  make([]BrokenLink, 0),
	}

	// Scanner tous les fichiers
	err := filepath.Walk(rootPath, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return err
		}

		result.TotalFiles++

		// Vérifier l'intégrité du fichier
		integrityResult, err := pt.validateFileIntegrity(path)
		if err != nil {
			return err
		}

		result.IntegrityMap[path] = *integrityResult

		if integrityResult.Valid {
			result.ValidFiles++
		} else {
			result.InvalidFiles++
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	// Scanner les liens cassés
	brokenLinks, err := pt.ScanBrokenLinks(rootPath)
	if err != nil {
		return nil, err
	}

	result.BrokenLinks = brokenLinks
	result.ValidationTime = time.Since(startTime)

	return result, nil
}

// validateFileIntegrity valide l'intégrité d'un fichier individuel
func (pt *PathTracker) validateFileIntegrity(filePath string) (*IntegrityResult, error) {
	startTime := time.Now()

	// Calculer le hash actuel
	currentHash, err := pt.CalculateContentHash(filePath)
	if err != nil {
		return nil, err
	}

	// Comparer avec le hash stocké
	pt.mu.RLock()
	storedHash, exists := pt.ContentHashes[filePath]
	pt.mu.RUnlock()

	valid := exists && storedHash == currentHash
	refCount := pt.countReferencesToFile(filePath)
	brokenRefs := pt.scanForBrokenReferences(filePath)

	return &IntegrityResult{
		Valid:          valid,
		Hash:           currentHash,
		ReferenceCount: refCount,
		BrokenRefs:     brokenRefs,
		ValidationTime: time.Since(startTime),
	}, nil
}

// ValidateReferenceConsistency valide la cohérence des références
func (pt *PathTracker) ValidateReferenceConsistency() ([]InconsistencyError, error) {
	var errors []InconsistencyError

	pt.mu.RLock()
	defer pt.mu.RUnlock()

	// Vérifier que tous les fichiers référencés existent
	for filePath, refs := range pt.references {
		for _, refFile := range refs {
			if !pt.pathExists(refFile) {
				errors = append(errors, InconsistencyError{
					Type:        "missing_reference",
					FilePath:    filePath,
					Expected:    "file should exist",
					Actual:      "file not found",
					Description: fmt.Sprintf("Referenced file %s does not exist", refFile),
					Timestamp:   time.Now(),
				})
			}
		}
	}

	// Vérifier la cohérence des hashes
	for filePath, hash := range pt.ContentHashes {
		if currentHash, err := pt.CalculateContentHash(filePath); err == nil {
			if hash != currentHash {
				errors = append(errors, InconsistencyError{
					Type:        "hash_mismatch",
					FilePath:    filePath,
					Expected:    hash,
					Actual:      currentHash,
					Description: "File content has changed without proper tracking",
					Timestamp:   time.Now(),
				})
			}
		}
	}

	return errors, nil
}

// GenerateIntegrityReport génère un rapport d'intégrité
func (pt *PathTracker) GenerateIntegrityReport() (*IntegrityReport, error) {
	inconsistencies, err := pt.ValidateReferenceConsistency()
	if err != nil {
		return nil, err
	}

	pt.mu.RLock()
	totalFiles := len(pt.ContentHashes)
	pt.mu.RUnlock()

	validFiles := totalFiles - len(inconsistencies)

	recommendations := make([]string, 0)
	if len(inconsistencies) > 0 {
		recommendations = append(recommendations, "Run automatic link repair")
		recommendations = append(recommendations, "Update content hashes for modified files")
		recommendations = append(recommendations, "Review and fix broken references")
	}

	summary := fmt.Sprintf("Integrity check completed. %d/%d files valid, %d issues found.",
		validFiles, totalFiles, len(inconsistencies))

	return &IntegrityReport{
		GeneratedAt:     time.Now(),
		TotalFiles:      totalFiles,
		ValidFiles:      validFiles,
		Issues:          inconsistencies,
		Recommendations: recommendations,
		Summary:         summary,
	}, nil
}

// updateFileReferences met à jour les références dans un fichier
func (pt *PathTracker) updateFileReferences(filePath, oldPath, newPath string) error {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	// Remplacer toutes les occurrences de l'ancien chemin
	newContent := strings.ReplaceAll(string(content), oldPath, newPath)

	if newContent != string(content) {
		return os.WriteFile(filePath, []byte(newContent), 0o644)
	}

	return nil
}

// FileMoveEvent représente un événement de déplacement de fichier
type FileMoveEvent struct {
	OldPath   string
	NewPath   string
	Timestamp time.Time
	Hash      string
}

// TrackFileMove gère le déplacement d'un fichier et met à jour l'historique et les références
func (pt *PathTracker) TrackFileMove(oldPath, newPath string) error {
	if oldPath == "" || newPath == "" {
		return fmt.Errorf("invalid paths")
	}
	if !filepath.IsAbs(oldPath) || !filepath.IsAbs(newPath) {
		return fmt.Errorf("paths must be absolute")
	}
	if _, err := os.Stat(oldPath); os.IsNotExist(err) {
		return fmt.Errorf("source file does not exist: %s", oldPath)
	}
	hash, err := pt.CalculateContentHash(oldPath)
	if err != nil {
		return err
	}
	pt.mu.Lock()
	defer pt.mu.Unlock()
	pt.ContentHashes[newPath] = hash
	delete(pt.ContentHashes, oldPath)
	moveEvent := FileMoveEvent{OldPath: oldPath, NewPath: newPath, Timestamp: time.Now(), Hash: hash}
	pt.moveHistory = append(pt.moveHistory, moveEvent)
	if len(pt.moveHistory) > 1000 {
		pt.moveHistory = pt.moveHistory[1:]
	}
	return pt.UpdateAllReferences(oldPath, newPath)
}
