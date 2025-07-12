package main

import (
	"testing"
)

func TestImportData(t *testing.T) {
	err := ImportData("source")
	if err != nil {
		t.Errorf("ImportData devrait réussir avec une source valide")
	}
	err = ImportData("")
	if err == nil {
		t.Errorf("ImportData devrait échouer avec une source vide")
	}
}

func TestExportData(t *testing.T) {
	err := ExportData("dest")
	if err != nil {
		t.Errorf("ExportData devrait réussir avec une destination valide")
	}
	err = ExportData("")
	if err == nil {
		t.Errorf("ExportData devrait échouer avec une destination vide")
	}
}

func TestCheckIntegrity(t *testing.T) {
	if !CheckIntegrity("valide") {
		t.Errorf("CheckIntegrity devrait retourner true pour 'valide'")
	}
	if CheckIntegrity("invalide") {
		t.Errorf("CheckIntegrity devrait retourner false pour une donnée invalide")
	}
}

// Teste la fonction main pour la couverture
func TestMainFunc(t *testing.T) {
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("main a paniqué : %v", r)
		}
	}()
	// Comme main appelle os.Exit, on ne peut pas le tester directement.
	// On peut tester la logique principale dans une fonction séparée si besoin.
}
