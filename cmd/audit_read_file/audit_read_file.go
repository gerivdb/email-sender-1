package audit_read_file

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

type Usage struct {
	FilePath	string
	LineNum		int
	Context		string
	Snippet		string
}

func main() {
	var usages []Usage
	auditDir := "."	// Current directory

	err := filepath.Walk(auditDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}

		// Only scan .go and .ts files for now, as they are likely to contain code
		if !(strings.HasSuffix(path, ".go") || strings.HasSuffix(path, ".ts")) {
			return nil
		}

		content, err := ioutil.ReadFile(path)
		if err != nil {
			return err
		}

		lines := strings.Split(string(content), "\n")
		for i, line := range lines {
			if strings.Contains(line, "read_file") {	// Simple string match for "read_file"
				// Capture context: 2 lines before, the line itself, and 2 lines after
				contextLines := []string{}
				start := i - 2
				if start < 0 {
					start = 0
				}
				end := i + 2
				if end >= len(lines) {
					end = len(lines) - 1
				}
				for j := start; j <= end; j++ {
					contextLines = append(contextLines, lines[j])
				}

				usages = append(usages, Usage{
					FilePath:	path,
					LineNum:	i + 1,	// Line numbers are 1-based
					Context:	strings.Join(contextLines, "\n"),
					Snippet:	line,
				})
			}
		}
		return nil
	})
	if err != nil {
		fmt.Printf("Error during audit: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("# Audit usages read_file\n")
	fmt.Println("Ce rapport liste tous les appels détectés à la fonction `read_file` dans le dépôt.\n")
	fmt.Println("## Résumé")
	fmt.Printf("- Nombre total d'appels détectés: %d\n", len(usages))
	fmt.Println("\n## Détails des Usages\n")

	if len(usages) == 0 {
		fmt.Println("Aucun usage de `read_file` n'a été trouvé.")
		return
	}

	fmt.Println("| Fichier | Ligne | Extrait |")
	fmt.Println("|---|---|---|")
	for _, usage := range usages {
		fmt.Printf("| %s | %d | `%s` |\n", usage.FilePath, usage.LineNum, strings.TrimSpace(usage.Snippet))
	}

	fmt.Println("\n## Contexte des Usages\n")
	for i, usage := range usages {
		fmt.Printf("### Usage %d: %s:%d\n", i+1, usage.FilePath, usage.LineNum)
		fmt.Println("```")
		fmt.Println(usage.Context)
		fmt.Println("```\n")
	}
}
