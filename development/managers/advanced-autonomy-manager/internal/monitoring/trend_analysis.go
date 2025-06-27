// Package monitoring implements the Real-Time Monitoring Dashboard component
package monitoring

// TrendAnalysis représente une analyse de tendance
type TrendAnalysis struct {
	Type        string
	Direction   string
	Strength    float64
	Confidence  float64
	Description string
}

// IsSignificant vérifie si la tendance est significative
func (ta *TrendAnalysis) IsSignificant() bool {
	return ta.Confidence > 0.8 && ta.Strength > 0.5
}
