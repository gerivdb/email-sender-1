package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

type PersonaNeeds struct {
	Persona string   `json:"persona"`
	Needs   []string `json:"needs"`
}

func main() {
	// Lire le fichier d'analyse d'écart pour identifier les points clés
	ecartFile, err := ioutil.ReadFile("ecart_jan_vs_multiagent.md")
	if err != nil {
		fmt.Printf("Erreur lors de la lecture de ecart_jan_vs_multiagent.md: %v\n", err)
		os.Exit(1)
	}
	ecartContent := string(ecartFile)

	// Extraire les besoins des personas à partir du contenu du fichier d'écart
	var personaNeedsList []PersonaNeeds

	if strings.Contains(ecartContent, "Prospection automatisée") {
		personaNeedsList = append(personaNeedsList, PersonaNeeds{
			Persona: "Commercial",
			Needs:   []string{"Générer des emails de prospection"},
		})
	}
	if strings.Contains(ecartContent, "Support client") {
		personaNeedsList = append(personaNeedsList, PersonaNeeds{
			Persona: "Agent de support",
			Needs:   []string{"Gérer un dialogue avec un utilisateur", "Compréhension de requête", "Génération de réponse"},
		})
	}
	if strings.Contains(ecartContent, "Création de contenu") {
		personaNeedsList = append(personaNeedsList, PersonaNeeds{
			Persona: "Créateur de contenu",
			Needs:   []string{"Recherche", "Rédaction", "Révision"},
		})
	}

	// Convertir la liste des besoins des personas en JSON
	personaNeedsJSON, err := json.MarshalIndent(personaNeedsList, "", "  ")
	if err != nil {
		fmt.Printf("Erreur lors de la conversion en JSON: %v\n", err)
		os.Exit(1)
	}

	// Écrire le JSON dans le fichier besoins-personas.json
	err = ioutil.WriteFile("besoins-personas.json", personaNeedsJSON, 0644)
	if err != nil {
		fmt.Printf("Erreur lors de l'écriture du fichier besoins-personas.json: %v\n", err)
		os.Exit(1)
	}

	// Créer le fichier de synthèse des besoins
	syntheseFile, err := os.Create("synthese-besoins.md")
	if err != nil {
		fmt.Printf("Erreur lors de la création de synthese-besoins.md: %v\n", err)
		os.Exit(1)
	}
	defer syntheseFile.Close()

	syntheseFile.WriteString("# Synthèse des besoins par persona\n\n")

	for _, personaNeeds := range personaNeedsList {
		syntheseFile.WriteString(fmt.Sprintf("## %s\n", personaNeeds.Persona))
		syntheseFile.WriteString("\n")
		syntheseFile.WriteString("### Besoins\n")
		for _, need := range personaNeeds.Needs {
			syntheseFile.WriteString(fmt.Sprintf("- %s\n", need))
		}
		syntheseFile.WriteString("\n")
	}

	// Générer le contenu du fichier synthese-besoins.md
	syntheseContent := "# Rapport de synthèse des besoins\n\n"
	for _, personaNeeds := range personaNeedsList {
		syntheseContent += fmt.Sprintf("## Persona: %s\n", personaNeeds.Persona)
		syntheseContent += "\n"
		syntheseContent += "### Besoins:\n"
		for _, need := range personaNeeds.Needs {
			syntheseContent += fmt.Sprintf("- %s\n", need)
		}
		syntheseContent += "\n"
	}

	// Écrire le contenu dans le fichier synthese-besoins.md
	err = ioutil.WriteFile("synthese-besoins.md", []byte(syntheseContent), 0644)
	if err != nil {
		fmt.Printf("Erreur lors de l'écriture du fichier synthese-besoins.md: %v\n", err)
		os.Exit(1)
	}

	// Ouvrir le fichier de sortie pour les besoins Jan
	outputFile, err := os.Create("besoins_jan.md")
	if err != nil {
		fmt.Printf("Erreur lors de la création de besoins_jan.md: %v\n", err)
		os.Exit(1)
	}
	defer outputFile.Close()

	outputFile.WriteString("# Recueil des besoins spécifiques à Jan\n\n")
	outputFile.WriteString("Ce document liste les exigences, limites et scénarios cibles pour l'intégration de Jan en tant que moteur d'orchestration séquentielle multi-personas.\n\n")

	outputFile.WriteString("## Exigences Fonctionnelles\n")
	outputFile.WriteString("- **Orchestration séquentielle**: Jan doit pouvoir exécuter une série de tâches IA en séquence, simulant différents personas.\n")
	outputFile.WriteString("- **Gestion du contexte**: Le ContextManager doit centraliser l'historique des dialogues et le contexte de chaque persona, et le rendre accessible à Jan.\n")
	outputFile.WriteString("- **Flexibilité des prompts**: Possibilité d'injecter des prompts système et contextuels dynamiques pour chaque étape de l'orchestration.\n")
	outputFile.WriteString("- **Performance**: L'intégration doit minimiser la latence et l'utilisation des ressources, en cohérence avec les limites matérielles.\n")
	outputFile.WriteString("- **Traçabilité**: Chaque interaction avec Jan et chaque changement de contexte doit être logué pour le débogage et l'audit.\n")
	outputFile.WriteString("\n")

	outputFile.WriteString("## Exigences Non-Fonctionnelles\n")
	outputFile.WriteString("- **Robustesse**: Le système doit être résilient aux erreurs de communication avec Jan ou aux réponses inattendues.\n")
	outputFile.WriteString("- **Sécurité**: Assurer la confidentialité des données échangées avec Jan.\n")
	outputFile.WriteString("- **Maintenabilité**: Le code d'intégration doit être clair, modulaire et facile à maintenir.\n")
	outputFile.WriteString("- **Évolutivité**: La solution doit pouvoir s'adapter à de nouveaux personas ou à des scénarios d'orchestration plus complexes.\n")
	outputFile.WriteString("\n")

	outputFile.WriteString("## Limites Identifiées (basées sur l'analyse d'écart)\n")
	// Ajouter ici une analyse des lignes du fichier ecart_jan_vs_multiagent.md pour les limites
	// Pour l'instant, c'est un exemple statique
	if strings.Contains(ecartContent, "Multi-agent, AgentZero, CrewAI") {
		outputFile.WriteString("- **Mono-agent**: Jan opère comme un mono-agent. L'orchestration multi-agent doit être simulée séquentiellement.\n")
	}
	if strings.Contains(ecartContent, "Multiples modèles LLM") {
		outputFile.WriteString("- **Modèle unique**: Jan utilise un modèle LLM unique. La diversité des modèles doit être gérée par la configuration des prompts et du contexte.\n")
	}
	if strings.Contains(ecartContent, "Historique par agent/LLM") {
		outputFile.WriteString("- **Gestion centralisée de l'historique**: L'historique des dialogues doit être géré et injecté par le ContextManager, et non par Jan directement.\n")
	}
	outputFile.WriteString("\n")

	outputFile.WriteString("## Scénarios Cibles\n")
	outputFile.WriteString("- **Prospection automatisée**: Jan simule un commercial, un analyste, puis un rédacteur pour générer des emails de prospection.\n")
	outputFile.WriteString("- **Support client**: Jan gère un dialogue avec un utilisateur en alternant entre un persona de compréhension de requête et un persona de génération de réponse.\n")
	outputFile.WriteString("- **Création de contenu**: Jan orchestre la création d'articles en passant par des personas de recherche, de rédaction et de révision.\n")
	outputFile.WriteString("\n")

	outputFile.WriteString("## Critères de Validation\n")
	outputFile.WriteString("- Le fichier `besoins_jan.md` est généré.\n")
	outputFile.WriteString("- Les exigences fonctionnelles et non-fonctionnelles sont clairement définies.\n")
	outputFile.WriteString("- Les limites identifiées sont prises en compte.\n")
	outputFile.WriteString("- Les scénarios cibles sont décrits.\n")
	outputFile.WriteString("- Le document est validé par revue croisée (simulée ici par la génération).\n")

	fmt.Println("Recueil des besoins Jan terminé. Voir besoins_jan.md")
}
