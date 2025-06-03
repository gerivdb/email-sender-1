package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"golang.org/x/mod/modfile"
)

// Dependency représente une dépendance avec ses métadonnées.
type Dependency struct {
	Name     string `json:"name"`
	Version  string `json:"version"`
	Indirect bool   `json:"indirect,omitempty"`
}

// Config représente la configuration du gestionnaire.
type Config struct {
	Name     string `json:"name"`
	Version  string `json:"version"`
	Settings struct {
		LogPath            string `json:"logPath"`
		LogLevel           string `json:"logLevel"`
		GoModPath          string `json:"goModPath"`
		AutoTidy           bool   `json:"autoTidy"`
		VulnerabilityCheck bool   `json:"vulnerabilityCheck"`
		BackupOnChange     bool   `json:"backupOnChange"`
	} `json:"settings"`
}

// DepManager gère les opérations sur les dépendances (interface SOLID).
type DepManager interface {
	List() ([]Dependency, error)
	Add(module, version string) error
	Remove(module string) error
	Update(module string) error
	Audit() error
	Cleanup() error
}

// GoModManager implémente DepManager pour go.mod.
type GoModManager struct {
	modFilePath string
	config      *Config
}

// NewGoModManager crée une instance de GoModManager.
func NewGoModManager(modFilePath string, config *Config) *GoModManager {
	return &GoModManager{
		modFilePath: modFilePath,
		config:      config,
	}
}

// Log écrit un message dans le log.
func (m *GoModManager) Log(level, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logMessage := fmt.Sprintf("[%s] [%s] %s", timestamp, level, message)

	if m.config != nil && m.config.Settings.LogPath != "" {
		// Écrire dans le fichier de log si configuré
		logFile, err := os.OpenFile(m.config.Settings.LogPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err == nil {
			defer logFile.Close()
			logFile.WriteString(logMessage + "\n")
		}
	}

	// Toujours afficher sur la console
	fmt.Println(logMessage)
}

// backupGoMod crée une sauvegarde du fichier go.mod.
func (m *GoModManager) backupGoMod() error {
	if m.config == nil || !m.config.Settings.BackupOnChange {
		return nil
	}

	timestamp := time.Now().Format("20060102-150405")
	backupPath := fmt.Sprintf("%s.backup.%s", m.modFilePath, timestamp)

	input, err := os.ReadFile(m.modFilePath)
	if err != nil {
		return err
	}

	return os.WriteFile(backupPath, input, 0644)
}

// List retourne la liste des dépendances du fichier go.mod.
func (m *GoModManager) List() ([]Dependency, error) {
	m.Log("INFO", "Listing dependencies")

	data, err := os.ReadFile(m.modFilePath)
	if err != nil {
		return nil, fmt.Errorf("erreur lecture go.mod: %v", err)
	}

	modFile, err := modfile.Parse(m.modFilePath, data, nil)
	if err != nil {
		return nil, fmt.Errorf("erreur parsing go.mod: %v", err)
	}

	var deps []Dependency
	for _, req := range modFile.Require {
		deps = append(deps, Dependency{
			Name:     req.Mod.Path,
			Version:  req.Mod.Version,
			Indirect: req.Indirect,
		})
	}

	m.Log("INFO", fmt.Sprintf("Found %d dependencies", len(deps)))
	return deps, nil
}

// Add ajoute une dépendance au projet.
func (m *GoModManager) Add(module, version string) error {
	m.Log("INFO", fmt.Sprintf("Adding dependency: %s@%s", module, version))

	if err := m.backupGoMod(); err != nil {
		m.Log("WARNING", fmt.Sprintf("Failed to backup go.mod: %v", err))
	}

	cmd := exec.Command("go", "get", fmt.Sprintf("%s@%s", module, version))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("erreur ajout dépendance %s: %v", module, err)
	}

	if m.config != nil && m.config.Settings.AutoTidy {
		if err := m.runGoModTidy(); err != nil {
			m.Log("WARNING", fmt.Sprintf("Failed to run go mod tidy: %v", err))
		}
	}

	m.Log("SUCCESS", fmt.Sprintf("Successfully added %s@%s", module, version))
	return nil
}

// Remove supprime une dépendance du projet.
func (m *GoModManager) Remove(module string) error {
	m.Log("INFO", fmt.Sprintf("Removing dependency: %s", module))

	if err := m.backupGoMod(); err != nil {
		m.Log("WARNING", fmt.Sprintf("Failed to backup go.mod: %v", err))
	}

	data, err := os.ReadFile(m.modFilePath)
	if err != nil {
		return fmt.Errorf("erreur lecture go.mod: %v", err)
	}

	modFile, err := modfile.Parse(m.modFilePath, data, nil)
	if err != nil {
		return fmt.Errorf("erreur parsing go.mod: %v", err)
	}

	if err := modFile.DropRequire(module); err != nil {
		return fmt.Errorf("erreur suppression dépendance %s: %v", module, err)
	}

	newData, err := modFile.Format()
	if err != nil {
		return fmt.Errorf("erreur formatage go.mod: %v", err)
	}

	if err := os.WriteFile(m.modFilePath, newData, 0644); err != nil {
		return fmt.Errorf("erreur écriture go.mod: %v", err)
	}

	if err := m.runGoModTidy(); err != nil {
		return fmt.Errorf("erreur tidy go.mod: %v", err)
	}

	m.Log("SUCCESS", fmt.Sprintf("Successfully removed %s", module))
	return nil
}

// Update met à jour une dépendance vers la dernière version.
func (m *GoModManager) Update(module string) error {
	m.Log("INFO", fmt.Sprintf("Updating dependency: %s", module))

	if err := m.backupGoMod(); err != nil {
		m.Log("WARNING", fmt.Sprintf("Failed to backup go.mod: %v", err))
	}

	cmd := exec.Command("go", "get", fmt.Sprintf("%s@latest", module))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("erreur mise à jour %s: %v", module, err)
	}

	m.Log("SUCCESS", fmt.Sprintf("Successfully updated %s", module))
	return nil
}

// Audit vérifie les vulnérabilités des dépendances.
func (m *GoModManager) Audit() error {
	m.Log("INFO", "Running security audit")

	cmd := exec.Command("go", "list", "-json", "-m", "all")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("erreur audit dépendances: %v", err)
	}

	// Ici on pourrait intégrer avec des outils d'audit comme govulncheck
	// Pour l'instant, on affiche juste les modules
	m.Log("INFO", "Audit completed - consider running 'govulncheck' for detailed security analysis")
	fmt.Println(string(output))

	return nil
}

// Cleanup nettoie les dépendances inutilisées.
func (m *GoModManager) Cleanup() error {
	m.Log("INFO", "Cleaning up unused dependencies")

	if err := m.backupGoMod(); err != nil {
		m.Log("WARNING", fmt.Sprintf("Failed to backup go.mod: %v", err))
	}

	return m.runGoModTidy()
}

// runGoModTidy exécute go mod tidy.
func (m *GoModManager) runGoModTidy() error {
	cmd := exec.Command("go", "mod", "tidy")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("erreur tidy go.mod: %v", err)
	}
	return nil
}

// loadConfig charge la configuration depuis le fichier JSON.
func loadConfig(configPath string) (*Config, error) {
	if configPath == "" {
		return nil, nil // Configuration optionnelle
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	var config Config
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

// CLI gère les commandes utilisateur.
func runCLI(manager DepManager) {
	listCmd := flag.NewFlagSet("list", flag.ExitOnError)
	addCmd := flag.NewFlagSet("add", flag.ExitOnError)
	removeCmd := flag.NewFlagSet("remove", flag.ExitOnError)
	updateCmd := flag.NewFlagSet("update", flag.ExitOnError)
	auditCmd := flag.NewFlagSet("audit", flag.ExitOnError)
	cleanupCmd := flag.NewFlagSet("cleanup", flag.ExitOnError)

	// Flags pour add
	addModule := addCmd.String("module", "", "Module à ajouter (ex: github.com/pkg)")
	addVersion := addCmd.String("version", "latest", "Version du module")

	// Flags pour remove
	removeModule := removeCmd.String("module", "", "Module à supprimer")

	// Flags pour update
	updateModule := updateCmd.String("module", "", "Module à mettre à jour")

	// Flag pour list (format JSON)
	listJSON := listCmd.Bool("json", false, "Sortie au format JSON")

	if len(os.Args) < 2 {
		fmt.Println("Commandes: list, add, remove, update, audit, cleanup")
		fmt.Println("Utilisez 'help' pour plus d'informations")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "list":
		listCmd.Parse(os.Args[2:])
		deps, err := manager.List()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
			os.Exit(1)
		}

		if *listJSON {
			jsonData, _ := json.MarshalIndent(deps, "", "  ")
			fmt.Println(string(jsonData))
		} else {
			fmt.Printf("Dependencies (%d):\n", len(deps))
			for _, dep := range deps {
				indirect := ""
				if dep.Indirect {
					indirect = " (indirect)"
				}
				fmt.Printf("  %s@%s%s\n", dep.Name, dep.Version, indirect)
			}
		}

	case "add":
		addCmd.Parse(os.Args[2:])
		if *addModule == "" {
			fmt.Fprintln(os.Stderr, "Erreur: --module requis")
			os.Exit(1)
		}
		if err := manager.Add(*addModule, *addVersion); err != nil {
			fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Ajouté %s@%s\n", *addModule, *addVersion)

	case "remove":
		removeCmd.Parse(os.Args[2:])
		if *removeModule == "" {
			fmt.Fprintln(os.Stderr, "Erreur: --module requis")
			os.Exit(1)
		}
		if err := manager.Remove(*removeModule); err != nil {
			fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Supprimé %s\n", *removeModule)

	case "update":
		updateCmd.Parse(os.Args[2:])
		if *updateModule == "" {
			fmt.Fprintln(os.Stderr, "Erreur: --module requis")
			os.Exit(1)
		}
		if err := manager.Update(*updateModule); err != nil {
			fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Mis à jour %s\n", *updateModule)

	case "audit":
		auditCmd.Parse(os.Args[2:])
		if err := manager.Audit(); err != nil {
			fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
			os.Exit(1)
		}

	case "cleanup":
		cleanupCmd.Parse(os.Args[2:])
		if err := manager.Cleanup(); err != nil {
			fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Nettoyage terminé")

	case "help":
		fmt.Println("Gestionnaire de dépendances Go")
		fmt.Println("===============================")
		fmt.Println("")
		fmt.Println("Commandes:")
		fmt.Println("  list [--json]              - Liste toutes les dépendances")
		fmt.Println("  add --module <mod> [--version <ver>] - Ajoute une dépendance")
		fmt.Println("  remove --module <mod>      - Supprime une dépendance")
		fmt.Println("  update --module <mod>      - Met à jour une dépendance")
		fmt.Println("  audit                      - Vérifie les vulnérabilités")
		fmt.Println("  cleanup                    - Nettoie les dépendances inutilisées")
		fmt.Println("  help                       - Affiche cette aide")
		fmt.Println("")
		fmt.Println("Exemples:")
		fmt.Println("  go run dependency_manager.go list")
		fmt.Println("  go run dependency_manager.go add --module github.com/pkg/errors --version v0.9.1")
		fmt.Println("  go run dependency_manager.go remove --module github.com/pkg/errors")
		fmt.Println("  go run dependency_manager.go update --module github.com/gorilla/mux")

	default:
		fmt.Printf("Commande inconnue: %s\n", os.Args[1])
		fmt.Println("Utilisez 'help' pour voir les commandes disponibles")
		os.Exit(1)
	}
}

func main() {
	// Déterminer le chemin du go.mod selon la localisation du script
	var modFilePath, configPath string

	// Obtenir le répertoire de travail actuel
	wd, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur: impossible d'obtenir le répertoire de travail: %v\n", err)
		os.Exit(1)
	}

	// Chercher go.mod dans le répertoire courant ou dans les répertoires parents
	modFilePath = findGoMod(wd)
	if modFilePath == "" {
		fmt.Fprintln(os.Stderr, "Erreur: go.mod introuvable")
		os.Exit(1)
	}

	// Déterminer le chemin de configuration relatif à go.mod
	projectRoot := filepath.Dir(modFilePath)
	configPath = filepath.Join(projectRoot, "projet", "config", "managers", "dependency-manager", "dependency-manager.config.json")

	config, err := loadConfig(configPath)
	if err != nil {
		fmt.Printf("Attention: Impossible de charger la configuration: %v\n", err)
	}

	manager := NewGoModManager(modFilePath, config)
	runCLI(manager)
}

// findGoMod recherche le fichier go.mod dans le répertoire actuel ou ses parents.
func findGoMod(startDir string) string {
	dir := startDir
	for {
		modPath := filepath.Join(dir, "go.mod")
		if _, err := os.Stat(modPath); err == nil {
			return modPath
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			// Nous avons atteint la racine
			break
		}
		dir = parent
	}
	return ""
}
