package docmanager

import "time"

// PathHealthReport structure rapport santé pour HealthCheck
// 4.1.3.1.1
// Utilisé pour diagnostic complet de l'intégrité des chemins et liens
// (voir plan v65B)
type PathHealthReport struct {
	TotalFiles      int
	ValidPaths      int
	BrokenPaths     []string
	OrphanedHashes  []string
	Recommendations []string
	Timestamp       time.Time
}
