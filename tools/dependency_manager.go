package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"golang.org/x/mod/modfile"
)

// Dependency représente une dépendance avec ses métadonnées.
type Dependency struct {
	Name    string
	Version string
}

// DepManager gère les opérations sur les dépendances (interface SOLID).
type DepManager interface {
	List() ([]Dependency, error)
	Add(module, version string) error
	Remove(module string) error
	Update(module string) error
}

// GoModManager implémente DepManager pour go.mod.
type GoModManager struct {
	modFilePath string
}

// NewGoModManager crée une instance de GoModManager.
func NewGoModManager(modFilePath string) *GoModManager {
	return &GoModManager{modFilePath: modFilePath}
}

// List retourne la liste des dépendances du fichier go.mod.
func (m *GoModManager) List() ([]Dependency, error) {
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
			Name:    req.Mod.Path,
			Version: req.Mod.Version,
		})
	}
	return deps, nil
}

// Add ajoute une dépendance au projet.
func (m *GoModManager) Add(module, version string) error {
	cmd := exec.Command("go", "get", fmt.Sprintf("%s@%s", module, version))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("erreur ajout dépendance %s: %v", module, err)
	}
	return nil
}

// Remove supprime une dépendance du projet.
func (m *GoModManager) Remove(module string) error {
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

	cmd := exec.Command("go", "mod", "tidy")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("erreur tidy go.mod: %v", err)
	}
	return nil
}

// Update met à jour une dépendance vers la dernière version.
func (m *GoModManager) Update(module string) error {
	cmd := exec.Command("go", "get", fmt.Sprintf("%s@latest", module))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("erreur mise à jour %s: %v", module, err)
	}
	return nil
}

// CLI gère les commandes utilisateur.
func runCLI(manager DepManager) {
	listCmd := flag.NewFlagSet("list", flag.ExitOnError)
	addCmd := flag.NewFlagSet("add", flag.ExitOnError)
	removeCmd := flag.NewFlagSet("remove", flag.ExitOnError)
	updateCmd := flag.NewFlagSet("update", flag.ExitOnError)

	addModule := addCmd.String("module", "", "Module à ajouter (ex: github.com/pkg)")
	addVersion := addCmd.String("version", "latest", "Version du module")
	removeModule := removeCmd.String("module", "", "Module à supprimer")
	updateModule := updateCmd.String("module", "", "Module à mettre à jour")

	if len(os.Args) < 2 {
		fmt.Println("Commandes: list, add, remove, update")
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
		for _, dep := range deps {
			fmt.Printf("%s@%s\n", dep.Name, dep.Version)
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
	default:
		fmt.Println("Commandes: list, add, remove, update")
		os.Exit(1)
	}
}

func main() {
	modFilePath := filepath.Join("..", "go.mod")
	if _, err := os.Stat(modFilePath); os.IsNotExist(err) {
		fmt.Fprintln(os.Stderr, "Erreur: go.mod introuvable")
		os.Exit(1)
	}

	manager := NewGoModManager(modFilePath)
	runCLI(manager)
}
