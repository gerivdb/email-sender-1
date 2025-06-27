// Package monitoring implements the Real-Time Monitoring Dashboard component
package monitoring

import (
	"time"
)

// TimeSeries représente une série temporelle de données
type TimeSeries struct {
	DataPoints []TimeSeriesPoint `json:"data_points"`
	StartTime  time.Time         `json:"start_time"`
	EndTime    time.Time         `json:"end_time"`
	MetricName string            `json:"metric_name"`
}

// TimeSeriesPoint représente un point de données dans une série temporelle
type TimeSeriesPoint struct {
	Timestamp time.Time `json:"timestamp"`
	Value     float64   `json:"value"`
}
