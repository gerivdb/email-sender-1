package docmanager

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
)

// updateMarkdownLinks parcourt tous les fichiers Markdown du projet et met à jour les liens selon les patterns définis.
func updateMarkdownLinks(root string) error {
	pattern := "**/*.md"
	files, err := filepath.Glob(filepath.Join(root, "**", "*.md"))
	if err != nil {
		return err
	}
	for _, file := range files {
		if !isInProjectDir(file, root) {
			continue
		}
		content, err := ioutil.ReadFile(file)
		if err != nil {
			return err
		}
		linkPattern := regexp.MustCompile(`\[([^\]]*)\]\(([^)]*)\)`)
		relativePattern := regexp.MustCompile(`]\(\.?/[^)]*\)`)
		newContent := linkPattern.ReplaceAllFunc(content, func(match []byte) []byte {
			// Ici, on pourrait appliquer des corrections spécifiques sur les liens
			return match // Placeholder: à adapter selon la logique métier
		})
		tempFile := file + ".tmp"
		err = ioutil.WriteFile(tempFile, newContent, 0o644)
		if err != nil {
			return err
		}
		err = os.Rename(tempFile, file)
		if err != nil {
			return err
		}
	}
	return nil
}

// isInProjectDir vérifie si le fichier appartient bien au répertoire projet.
func isInProjectDir(file, root string) bool {
	absFile, err := filepath.Abs(file)
	if err != nil {
		return false
	}
	absRoot, err := filepath.Abs(root)
	if err != nil {
		return false
	}
	return filepath.HasPrefix(absFile, absRoot)
}
