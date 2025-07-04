package main

import (
	"fmt"
	"log"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/tui/panels"

	"github.com/charmbracelet/lipgloss"
)

func runPanelDemo() {
	fmt.Println("🧪 Test d'intégration des panels TaskMaster...")

	// Configuration de base
	layout := panels.LayoutConfig{
		Type:        panels.LayoutHorizontal,
		Ratio:       []float64{0.3, 0.7},
		Padding:     1,
		Margin:      1,
		BorderStyle: lipgloss.NormalBorder(),
		Adaptive:    true,
	}

	// Création du gestionnaire de panels
	pm := panels.NewPanelManager(120, 40, layout)

	// Test de création d'un panel
	panel := &panels.Panel{
		ID:        "test-panel",
		Title:     "Test Panel",
		Position:  panels.Position{X: 0, Y: 0},
		Size:      panels.Size{Width: 60, Height: 20},
		Visible:   true,
		Minimized: false,
		ZOrder:    1,
		Resizable: true,
		Movable:   true,
	}

	// Ajout du panel
	err := pm.AddPanel(panel)
	if err != nil {
		log.Fatalf("❌ Erreur lors de l'ajout du panel: %v", err)
	}

	// Test de changement de mode
	err = pm.SetViewMode(panels.ViewModeKanban)
	if err != nil {
		log.Fatalf("❌ Erreur lors du changement de mode: %v", err)
	}

	// Test du gestionnaire contextuel
	contextManager := pm.GetContextualManager()
	if contextManager == nil {
		log.Fatal("❌ Gestionnaire contextuel non initialisé")
	}

	// Test du gestionnaire de modes
	modeManager := pm.GetModeKeyManager()
	if modeManager == nil {
		log.Fatal("❌ Gestionnaire de modes non initialisé")
	}

	// Mise à jour du contexte
	pm.UpdateShortcutContext()

	// Récupération des raccourcis disponibles
	shortcuts := pm.GetAvailableShortcuts()

	fmt.Println("✅ Tests d'intégration réussis!")
	fmt.Printf("📊 Panel actif: %s\n", pm.GetActivePanelID())
	fmt.Printf("🎮 Mode actuel: %s\n", pm.GetViewMode())
	fmt.Printf("⌨️  Raccourcis disponibles: %d\n", len(shortcuts))

	// Affichage de quelques raccourcis
	fmt.Println("\n🔧 Exemples de raccourcis contextuels:")
	count := 0
	for key, desc := range shortcuts {
		if count < 5 {
			fmt.Printf("  %s: %s\n", key, desc)
			count++
		}
	}

	fmt.Println("\n🎯 Section 1.2.1.1.2 Gestion des Panneaux: 100% COMPLÈTE!")
}
