package main

import (
	"fmt"
	"go/doc"
	"go/parser"
	"go/token"
	"os"
	"strings"
)

func main() {
	root := "../pkg/docmanager"
	fs := token.NewFileSet()
	pkgs, err := parser.ParseDir(fs, root, nil, parser.ParseComments)
	if err != nil {
		panic(err)
	}

	f, _ := os.Create("../AGENTS.md")
	defer f.Close()
	fmt.Fprintln(f, "# AGENTS.md\n\n## Documentation générée automatiquement\n")

	for pkgName, pkgAst := range pkgs {
		pkg := doc.New(pkgAst, root, 0)
		fmt.Fprintf(f, "## Package %s\n\n", pkgName)
		for _, t := range pkg.Types {
			fmt.Fprintf(f, "### %s\n\n", t.Name)
			if t.Doc != "" {
				fmt.Fprintf(f, "%s\n\n", t.Doc)
			}
			if len(t.Methods) > 0 {
				fmt.Fprintln(f, "**Méthodes :**")
				for _, m := range t.Methods {
					fmt.Fprintf(f, "- `%s` — %s\n", m.Name, strings.TrimSpace(m.Doc))
				}
				fmt.Fprintln(f)
			}
		}
	}
	fmt.Fprintln(f, "\n---\nCe fichier est généré automatiquement. Ne pas éditer à la main.")
}
