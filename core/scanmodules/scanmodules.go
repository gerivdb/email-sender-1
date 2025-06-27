/*
Package scanmodules fournit des fonctions pour scanner les modules du projet.

Fonctions principales :
- ScanDir : parcourt récursivement un dossier et retourne la liste des modules détectés.
- DetectLang : détermine le langage d’un fichier selon son extension.
- ExportModules : exporte la liste des modules au format JSON.

Utilisation typique :
modules, err := scanmodules.ScanDir("chemin/du/projet")
err := scanmodules.ExportModules(modules, "modules.json")
*/
package scanmodules

import (
	"encoding/json"
	"os"
	"path/filepath"
)

type ModuleInfo struct {
	Name    string   `json:"name"`
	Path    string   `json:"path"`
	Type    string   `json:"type"`
	Lang    string   `json:"lang"`
	Role    string   `json:"role"`
	Deps    []string `json:"deps"`
	Outputs []string `json:"outputs"`
}

/*
ScanDir parcourt récursivement le dossier root et retourne la liste des modules détectés.

Paramètres :
- root : chemin du dossier à scanner

Retourne :
- []ModuleInfo : liste des modules détectés
- error : erreur éventuelle
*/
func ScanDir(root string) ([]ModuleInfo, error) {
	var modules []ModuleInfo
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		lang := DetectLang(info.Name())
		modules = append(modules, ModuleInfo{
			Name:    info.Name(),
			Path:    path,
			Type:    "file",
			Lang:    lang,
			Role:    "",
			Deps:    []string{},
			Outputs: []string{},
		})
		return nil
	})
	return modules, nil
}

/*
DetectLang détermine le langage d’un fichier selon son extension.

Paramètre :
- filename : nom du fichier

Retourne :
- string : langage détecté ("Go", "Node.js", "Python", "unknown")
*/
func DetectLang(filename string) string {
	switch filepath.Ext(filename) {
	case ".go":
		return "Go"
	case ".js":
		return "Node.js"
	case ".py":
		return "Python"
	default:
		return "unknown"
	}
}

/*
ExportModules exporte la liste des modules au format JSON.

Paramètres :
- modules : liste des modules à exporter
- outPath : chemin du fichier de sortie

Retourne :
- error : erreur éventuelle
*/
func ExportModules(modules []ModuleInfo, outPath string) error {
	data, err := json.MarshalIndent(modules, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(outPath, data, 0644)
}
