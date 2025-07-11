// cmd/notion-like/main.go
// Prototype minimal Notion-like Go : expose la table harmonisée des plans en JSON

package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strings"
)

type Plan struct {
	ID     string `json:"id_plan"`
	Titre  string `json:"titre"`
	Resume string `json:"resume"`
	Statut string `json:"statut_migration"`
}

func loadPlans() ([]Plan, error) {
	content, err := ioutil.ReadFile("./projet/roadmaps/plans/consolidated/plans_harmonized.md")
	if err != nil {
		return nil, err
	}
	lines := strings.Split(string(content), "\n")
	var plans []Plan
	for _, l := range lines {
		if strings.HasPrefix(l, "|") && !strings.Contains(l, "id_plan") {
			cols := strings.Split(l, "|")
			if len(cols) > 4 {
				plans = append(plans, Plan{
					ID:     strings.TrimSpace(cols[1]),
					Titre:  strings.TrimSpace(cols[2]),
					Resume: strings.TrimSpace(cols[3]),
					Statut: strings.TrimSpace(cols[4]),
				})
			}
		}
	}
	return plans, nil
}

func plansHandler(w http.ResponseWriter, r *http.Request) {
	plans, err := loadPlans()
	if err != nil {
		http.Error(w, "Erreur chargement plans", 500)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(plans)
}

func main() {
	http.HandleFunc("/plans", plansHandler)
	fmt.Println("Serveur Notion-like Go sur http://localhost:8080/plans")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
