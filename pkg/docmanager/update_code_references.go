package docmanager

import (
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

// updateCodeReferences parcourt les fichiers Go et met à jour les références de fichiers dans les imports et string literals.
func updateCodeReferences(root, oldPath, newPath string) error {
	var goFiles []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(path, ".go") {
			goFiles = append(goFiles, path)
		}
		return nil
	})
	if err != nil {
		return err
	}
	for _, file := range goFiles {
		orig, err := ioutil.ReadFile(file)
		if err != nil {
			return err
		}
		fset := token.NewFileSet()
		f, err := parser.ParseFile(fset, file, orig, parser.ParseComments)
		if err != nil {
			continue // skip invalid Go files
		}
		changed := false
		ast.Inspect(f, func(n ast.Node) bool {
			switch x := n.(type) {
			case *ast.BasicLit:
				if x.Kind == token.STRING && strings.Contains(x.Value, oldPath) {
					x.Value = strings.ReplaceAll(x.Value, oldPath, newPath)
					changed = true
				}
			case *ast.ImportSpec:
				if x.Path != nil && strings.Contains(x.Path.Value, oldPath) {
					x.Path.Value = strings.ReplaceAll(x.Path.Value, oldPath, newPath)
					changed = true
				}
			}
			return true
		})
		if changed {
			var buf strings.Builder
			if err := format.Node(&buf, fset, f); err != nil {
				return err
			}
			tempFile := file + ".tmp"
			if err := ioutil.WriteFile(tempFile, []byte(buf.String()), 0o644); err != nil {
				return err
			}
			if err := os.Rename(tempFile, file); err != nil {
				return err
			}
		}
	}
	return nil
}
