// types.go - Types partagés pour commit-interceptor
package commitinterceptor

import (
	"time"
)

// CommitData représente les données extraites d'un commit
type CommitData struct {
	Hash       string    `json:"hash"`
	Message    string    `json:"message"`
	Author     string    `json:"author"`
	Timestamp  time.Time `json:"timestamp"`
	Files      []string  `json:"files"`
	Branch     string    `json:"branch"`
	Repository string    `json:"repository"`
}

// CommitAnalysis - Résultat d’analyse enrichi pour le routage
type CommitAnalysis struct {
	ChangeType      string     // ex: "feature", "fix", etc.
	Impact          string     // "low", "medium", "high"
	Priority        string     // "normal", "critical", etc.
	SuggestedBranch string     // nom de branche suggéré
	Confidence      float64    // score de confiance
	CommitData      CommitData // données du commit associé
}
