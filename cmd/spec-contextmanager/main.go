package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

// ContextManagerSpec représente la spécification du ContextManager étendu
type ContextManagerSpec struct {
	Name        string              `json:"name"`
	Description string              `json:"description"`
	API         []APIFunction       `json:"api"`
	DataSchema  map[string]Property `json:"data_schema"`
	Hooks       []Hook              `json:"hooks"`
}

// APIFunction représente une fonction de l'API du ContextManager
type APIFunction struct {
	Name        string            `json:"name"`
	Description string            `json:"description"`
	Parameters  map[string]string `json:"parameters"`
	Returns     string            `json:"returns"`
}

// Property représente une propriété dans le schéma de données
type Property struct {
	Type        string `json:"type"`
	Description string `json:"description"`
}

// Hook représente un point d'extension pour le ContextManager
type Hook struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	When        string `json:"when"` // "before", "after"
}

func main() {
	var err error // Déclarer err une seule fois
	spec := ContextManagerSpec{
		Name:        "ContextManager étendu pour Jan",
		Description: "Spécification de l'API et du schéma de données pour le ContextManager, adapté à l'orchestration séquentielle multi-personas avec Jan.",
		API: []APIFunction{
			{
				Name:        "StoreDialogueHistory",
				Description: "Stocke un message dans l'historique de dialogue d'un persona spécifique.",
				Parameters: map[string]string{
					"persona": "string (identifiant unique du persona)",
					"message": "string (le message à stocker)",
				},
				Returns: "void",
			},
			{
				Name:        "GetDialogueContext",
				Description: "Récupère les 'n' derniers messages de l'historique de dialogue d'un persona.",
				Parameters: map[string]string{
					"persona": "string (identifiant unique du persona)",
					"n":       "int (nombre de messages à récupérer)",
				},
				Returns: "[]string (slice de messages)",
			},
			{
				Name:        "GetGlobalContext",
				Description: "Récupère le contexte global partagé entre tous les personas.",
				Parameters:  map[string]string{},
				Returns:     "map[string]interface{} (contexte global)",
			},
			{
				Name:        "UpdateGlobalContext",
				Description: "Met à jour le contexte global partagé avec de nouvelles données.",
				Parameters: map[string]string{
					"key":   "string (clé de la donnée)",
					"value": "interface{} (valeur de la donnée)",
				},
				Returns: "void",
			},
			{
				Name:        "ClearDialogueHistory",
				Description: "Efface l'historique de dialogue d'un persona ou de tous les personas.",
				Parameters: map[string]string{
					"persona": "string (optionnel, si vide efface tout)",
				},
				Returns: "void",
			},
		},
		DataSchema: map[string]Property{
			"history": {
				Type:        "map[string][]string",
				Description: "Historique des dialogues, clé: persona, valeur: liste de messages.",
			},
			"globalContext": {
				Type:        "map[string]interface{}",
				Description: "Contexte global partagé entre tous les personas.",
			},
		},
		Hooks: []Hook{
			{
				Name:        "OnBeforeStore",
				Description: "Exécuté avant le stockage d'un message.",
				When:        "before",
			},
			{
				Name:        "OnAfterStore",
				Description: "Exécuté après le stockage d'un message.",
				When:        "after",
			},
			{
				Name:        "OnContextRetrieval",
				Description: "Exécuté lors de la récupération du contexte.",
				When:        "after",
			},
		},
	}

	// Générer le fichier Markdown
	mdContent := "# Spécification du ContextManager étendu pour Jan\n\n"
	mdContent += spec.Description + "\n\n"

	mdContent += "## API\n\n"
	for _, f := range spec.API {
		mdContent += fmt.Sprintf("### `%s`\n", f.Name)
		mdContent += fmt.Sprintf("- **Description**: %s\n", f.Description)
		mdContent += "- **Paramètres**:\n"
		if len(f.Parameters) == 0 {
			mdContent += "  - Aucun\n"
		} else {
			for p, t := range f.Parameters {
				mdContent += fmt.Sprintf("  - `%s`: `%s`\n", p, t)
			}
		}
		mdContent += fmt.Sprintf("- **Retourne**: `%s`\n\n", f.Returns)
	}

	mdContent += "## Schéma des Données Internes\n\n"
	mdContent += "| Propriété | Type | Description |\n"
	mdContent += "|---|---|---|\n"
	for p, s := range spec.DataSchema {
		mdContent += fmt.Sprintf("| `%s` | `%s` | %s |\n", p, s.Type, s.Description)
	}
	mdContent += "\n"

	mdContent += "## Hooks (Points d'extension)\n\n"
	mdContent += "| Hook | Description | Quand |\n"
	mdContent += "|---|---|---|\n"
	for _, h := range spec.Hooks {
		mdContent += fmt.Sprintf("| `%s` | %s | %s |\n", h.Name, h.Description, h.When)
	}
	mdContent += "\n"

	mdContent += "## Critères de Validation\n"
	mdContent += "- La spécification est complète et cohérente.\n"
	mdContent += "- Le format JSON est valide.\n"
	mdContent += "- Le fichier `spec_contextmanager_jan.md` est généré.\n"
	mdContent += "- Le schéma des données, l'API et les hooks sont clairement définis.\n"
	mdContent += "- La spécification est validée par des tests de structure (via ce script) et une revue humaine.\n"

	err = ioutil.WriteFile("spec_contextmanager_jan.md", []byte(mdContent), 0o644)
	if err != nil {
		fmt.Printf("Erreur lors de l'écriture de spec_contextmanager_jan.md: %v\n", err)
		os.Exit(1)
	}

	// Générer le fichier JSON (pour le schéma)
	var jsonContent []byte
	jsonContent, err = json.MarshalIndent(spec, "", "  ")
	if err != nil {
		fmt.Printf("Erreur lors de la sérialisation JSON: %v\n", err)
		os.Exit(1)
	}

	err = ioutil.WriteFile("spec_contextmanager_jan.json", jsonContent, 0o644)
	if err != nil {
		fmt.Printf("Erreur lors de l'écriture de spec_contextmanager_jan.json: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Spécification du ContextManager terminée. Voir spec_contextmanager_jan.md et spec_contextmanager_jan.json")
}
