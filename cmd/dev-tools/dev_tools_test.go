// cmd/dev-tools/dev_tools_test.go
package main

import (
	"os"
	"testing"
)

func TestDevToolsOutput(t *testing.T) {
	f := "dev_tools.log"
	_ = os.Remove(f) // Nettoyage avant test
	main()
	if _, err := os.Stat(f); os.IsNotExist(err) {
		t.Errorf("%s n'a pas été généré", f)
	}
}
