// cmd/roadmap-cli/main.go
package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

type Roadmap struct {
	ID         string   `json:"id"`
	Title      string   `json:"title"`
	Objectives string   `json:"objectives"`
	Sections   []string `json:"sections"`
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: roadmap-cli [list|show <id>]")
		return
	}
	cmd := os.Args[1]
	data, err := ioutil.ReadFile("projet/roadmaps/plans/consolidated/roadmaps.json")
	if err != nil {
		fmt.Println("Erreur lecture roadmaps.json:", err)
		return
	}
	var roadmaps []Roadmap
	if err := json.Unmarshal(data, &roadmaps); err != nil {
		fmt.Println("Erreur parsing JSON:", err)
		return
	}
	switch cmd {
	case "list":
		for _, r := range roadmaps {
			fmt.Printf("- %s: %s\n", r.ID, r.Title)
		}
	case "show":
		if len(os.Args) < 3 {
			fmt.Println("Usage: roadmap-cli show <id>")
			return
		}
		id := os.Args[2]
		for _, r := range roadmaps {
			if r.ID == id {
				fmt.Printf("Titre: %s\nObjectifs: %s\nSections: %v\n", r.Title, r.Objectives, r.Sections)
				return
			}
		}
		fmt.Println("Roadmap non trouvée:", id)
	default:
		fmt.Println("Commande inconnue.")
	}
}
