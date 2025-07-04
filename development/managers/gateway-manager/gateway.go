package gatewaymanager

import (
	"context"
	"fmt"

	"github.com/gerivdb/email-sender-1/internal/core" // Importer les interfaces définies
)

// GatewayManager représente le gestionnaire de passerelle, avec des dépendances sur d'autres managers.
type GatewayManager struct {
	Name         string
	CacheManager core.CacheManagerInterface
	LWM          core.LWMInterface
	RAG          core.RAGInterface
	MemoryBank   core.MemoryBankAPIClient
}

// NewGatewayManager crée une nouvelle instance de GatewayManager.
// Il prend maintenant des interfaces pour les dépendances.
func NewGatewayManager(
	name string,
	cacheMgr core.CacheManagerInterface,
	lwm core.LWMInterface,
	rag core.RAGInterface,
	memoryBank core.MemoryBankAPIClient,
) *GatewayManager {
	return &GatewayManager{
		Name:         name,
		CacheManager: cacheMgr,
		LWM:          lwm,
		RAG:          rag,
		MemoryBank:   memoryBank,
	}
}

// Start démarre le gestionnaire de passerelle.
func (gm *GatewayManager) Start() {
	fmt.Printf("GatewayManager %s démarré.\n", gm.Name)
}

// ProcessRequest simule le traitement d'une requête, utilisant les managers dépendants.
func (gm *GatewayManager) ProcessRequest(ctx context.Context, requestID string, data map[string]interface{}) (string, error) {
	fmt.Printf("GatewayManager %s - Traitement de la requête %s...\n", gm.Name, requestID)

	// Exemple d'interaction avec CacheManager
	err := gm.CacheManager.Invalidate(ctx, requestID)
	if err != nil {
		fmt.Printf("Erreur CacheManager Invalidate: %v\n", err)
		// Continuer ou retourner l'erreur selon la logique métier
	} else {
		fmt.Println("CacheManager Invalidate appelé.")
	}

	// Exemple d'interaction avec MemoryBank (stockage)
	_, err = gm.MemoryBank.Store(ctx, requestID, data, "24h")
	if err != nil {
		fmt.Printf("Erreur MemoryBank Store: %v\n", err)
	} else {
		fmt.Println("MemoryBank Store appelé.")
	}

	// Exemple d'interaction avec LWM
	workflowID := "sample-workflow"
	taskID, err := gm.LWM.TriggerWorkflow(ctx, workflowID, data)
	if err != nil {
		fmt.Printf("Erreur LWM TriggerWorkflow: %v\n", err)
	} else {
		fmt.Printf("LWM TriggerWorkflow appelé, TaskID: %s\n", taskID)
	}

	// Exemple d'interaction avec RAG
	generatedContent, err := gm.RAG.GenerateContent(ctx, "Générer un résumé", []string{"contexte"})
	if err != nil {
		fmt.Printf("Erreur RAG GenerateContent: %v\n", err)
	} else {
		fmt.Printf("RAG GenerateContent appelé, Contenu généré: %s\n", generatedContent)
	}

	fmt.Printf("GatewayManager %s - Requête %s traitée.\n", gm.Name, requestID)
	return fmt.Sprintf("Réponse pour la requête %s", requestID), nil
}
