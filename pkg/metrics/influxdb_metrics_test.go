// SPDX-License-Identifier: MIT
package metrics

import (
	"context"
	"testing"
	"time"
)

func TestNewInfluxDBDocumentationMetrics(t *testing.T) {
	m := NewInfluxDBDocumentationMetrics("http://localhost:8086", "token", "org", "bucket")
	if m == nil {
		t.Fatal("Expected non-nil InfluxDBDocumentationMetrics")
	}
	m.Close()
}

func TestRecordDocumentationActivity(t *testing.T) {
	m := NewInfluxDBDocumentationMetrics("http://localhost:8086", "token", "org", "bucket")
	defer m.Close()
	err := m.RecordDocumentationActivity(context.Background(), "user1", "edit", "doc123")
	if err != nil {
		t.Logf("Expected error if InfluxDB not running: %v", err)
	}
}

func TestRecordPerformanceMetrics(t *testing.T) {
	m := NewInfluxDBDocumentationMetrics("http://localhost:8086", "token", "org", "bucket")
	defer m.Close()
	err := m.RecordPerformanceMetrics(context.Background(), "doc123", 1500*time.Millisecond, 2048, true)
	if err != nil {
		t.Logf("Expected error if InfluxDB not running: %v", err)
	}
}

func TestGetDocumentationTrends(t *testing.T) {
	m := NewInfluxDBDocumentationMetrics("http://localhost:8086", "token", "org", "bucket")
	defer m.Close()
	trends, err := m.GetDocumentationTrends(context.Background(), time.Now().Add(-24*time.Hour), time.Now())
	if err != nil {
		t.Error(err)
	}
	if trends != nil && len(trends) > 0 {
		t.Logf("Trends: %+v", trends)
	}
}
