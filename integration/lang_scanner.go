package integration

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

// ProjectType représente les types de projets détectés.
type ProjectType string

const (
	GoProject         ProjectType = "Go"
	PythonProject     ProjectType = "Python"
	NodeJSProject     ProjectType = "Node.js"
	PowerShellProject ProjectType = "PowerShell"
	UnknownProject    ProjectType = "Unknown"
)

// Project représente un projet détecté avec son chemin et son type.
type Project struct {
	Path string
	Type ProjectType
}

// LangScanner est une interface pour scanner les projets multilingues.
type LangScanner interface {
	Scan(rootPath string) ([]Project, error)
}

// fileSystemScanner implémente LangScanner en parcourant le système de fichiers.
type fileSystemScanner struct{}

// NewLangScanner crée une nouvelle instance de LangScanner.
func NewLangScanner() LangScanner {
	return &fileSystemScanner{}
}

// Scan parcourt le répertoire racine et identifie les types de projets.
func (s *fileSystemScanner) Scan(rootPath string) ([]Project, error) {
	var projects []Project

	files, err := ioutil.ReadDir(rootPath)
	if err != nil {
		return nil, fmt.Errorf("erreur de lecture du répertoire %s: %w", rootPath, err)
	}

	for _, file := range files {
		fullPath := filepath.Join(rootPath, file.Name())

		if file.IsDir() {
			// Ignorer les répertoires Git et autres répertoires de build/dépendances
			if file.Name() == ".git" || file.Name() == "node_modules" || file.Name() == "vendor" || file.Name() == "bin" {
				continue
			}
			// Recherche récursive dans les sous-répertoires
			subProjects, err := s.Scan(fullPath)
			if err != nil {
				return nil, err // Propager l'erreur
			}
			projects = append(projects, subProjects...)
		} else {
			projectType := s.detectProjectType(file.Name(), fullPath)
			if projectType != UnknownProject {
				projects = append(projects, Project{Path: fullPath, Type: projectType})
			}
		}
	}
	return projects, nil
}

// detectProjectType détermine le type de projet basé sur le nom du fichier.
func (s *fileSystemScanner) detectProjectType(fileName, filePath string) ProjectType {
	switch {
	case strings.HasSuffix(fileName, ".go"):
		return GoProject
	case strings.HasSuffix(fileName, ".py"):
		return PythonProject
	case strings.HasSuffix(fileName, ".js") && !strings.Contains(filePath, "node_modules"): // Exclure node_modules
		// Pour Node.js, on peut aussi chercher package.json dans le répertoire parent
		if s.hasPackageJson(filepath.Dir(filePath)) {
			return NodeJSProject
		}
		return UnknownProject // ou un type plus générique comme JavaScript
	case strings.HasSuffix(fileName, ".ps1"):
		return PowerShellProject
	case strings.HasSuffix(fileName, ".csproj"), strings.HasSuffix(fileName, ".sln"): // Exemple pour C#/.NET
		return ProjectType("C#/.NET")
	case strings.HasSuffix(fileName, ".java"), strings.HasSuffix(fileName, ".jar"): // Exemple pour Java
		return ProjectType("Java")
	case strings.HasSuffix(fileName, ".ts"):
		return ProjectType("TypeScript")
	case strings.HasSuffix(fileName, ".html"), strings.HasSuffix(fileName, ".css"):
		return ProjectType("Web Frontend")
	}
	return UnknownProject
}

// hasPackageJson vérifie si un répertoire contient un fichier package.json.
func (s *fileSystemScanner) hasPackageJson(dirPath string) bool {
	packageJsonPath := filepath.Join(dirPath, "package.json")
	_, err := os.Stat(packageJsonPath)
	return err == nil
}
