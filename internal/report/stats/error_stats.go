// Package stats provides error statistics aggregation for reports
package stats

import (
	"sort"
	"time"
)

// ErrorStats tracks and aggregates error statistics
type ErrorStats struct {
	errors  map[string]*ErrorEntry
	topN    int
	window  time.Duration
}

// ErrorEntry represents statistics for a single error type
type ErrorEntry struct {
	Count     int
	FirstSeen time.Time
	LastSeen  time.Time
	Samples   []string
}

// ErrorSummary summarizes error statistics
type ErrorSummary struct {
	Type      string
	Count     int
	FirstSeen time.Time
	LastSeen  time.Time
	Samples   []string
}

// NewErrorStats creates a new ErrorStats instance
func NewErrorStats(window time.Duration, topN int) *ErrorStats {
	return &ErrorStats{
		errors: make(map[string]*ErrorEntry),
		topN:   topN,
		window: window,
	}
}

// RecordError records an error occurrence
func (es *ErrorStats) RecordError(errType string, sample string) {
	now := time.Now()
	entry, exists := es.errors[errType]
	
	if !exists {
		entry = &ErrorEntry{
			FirstSeen: now,
			Samples:   make([]string, 0),
		}
		es.errors[errType] = entry
	}

	entry.Count++
	entry.LastSeen = now
	if len(entry.Samples) < es.topN {
		entry.Samples = append(entry.Samples, sample)
	}
}

// GetTopErrors returns the top N most frequent errors
func (es *ErrorStats) GetTopErrors() []ErrorSummary {
	// Filter old errors
	cutoff := time.Now().Add(-es.window)
	for errType, entry := range es.errors {
		if entry.LastSeen.Before(cutoff) {
			delete(es.errors, errType)
		}
	}

	// Convert to slice for sorting
	summaries := make([]ErrorSummary, 0, len(es.errors))
	for errType, entry := range es.errors {
		summaries = append(summaries, ErrorSummary{
			Type:      errType,
			Count:     entry.Count,
			FirstSeen: entry.FirstSeen,
			LastSeen:  entry.LastSeen,
			Samples:   entry.Samples,
		})
	}

	// Sort by count descending
	sort.Slice(summaries, func(i, j int) bool {
		return summaries[i].Count > summaries[j].Count
	})

	// Return top N
	if len(summaries) > es.topN {
		summaries = summaries[:es.topN]
	}

	return summaries
}

// GetTotalErrors returns the total number of errors
func (es *ErrorStats) GetTotalErrors() int {
	total := 0
	for _, entry := range es.errors {
		total += entry.Count
	}
	return total
}

// Reset clears all error statistics
func (es *ErrorStats) Reset() {
	es.errors = make(map[string]*ErrorEntry)
}

// GetErrorRate returns the error rate over a given duration
func (es *ErrorStats) GetErrorRate(duration time.Duration) float64 {
	cutoff := time.Now().Add(-duration)
	count := 0
	for _, entry := range es.errors {
		if !entry.LastSeen.Before(cutoff) {
			count += entry.Count
		}
	}
	return float64(count) / duration.Seconds()
}