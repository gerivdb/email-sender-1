// main_test.go — Test unitaire du point d’entrée reporting Roo
package main

import (
	"testing"
)

func TestReportingMain(t *testing.T) {
	// Test minimal : vérifie que la fonction main s’exécute sans panic
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("main panique: %v", r)
		}
	}()
	main()
}
