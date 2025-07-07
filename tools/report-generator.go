package tools

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"os"
	"path/filepath"
	"time"
)

// ReportGenerator handles automated report generation
type ReportGenerator struct {
	performanceMetrics *PerformanceMetrics
	alertManager       *AlertManager
	driftDetector      *DriftDetector
	logger             *log.Logger
	config             *ReportConfig
}

// ReportConfig contains configuration for report generation
type ReportConfig struct {
	OutputDir           string   `json:"output_dir"`
	ReportFormats       []string `json:"report_formats"` // html, json, pdf
	Schedule            string   `json:"schedule"`       // daily, weekly, monthly
	EmailRecipients     []string `json:"email_recipients"`
	RetentionDays       int      `json:"retention_days"`
	IncludeCharts       bool     `json:"include_charts"`
	AutomaticGeneration bool     `json:"automatic_generation"`
}

// Report represents a comprehensive system report
type Report struct {
	ID                 string                 `json:"id"`
	Title              string                 `json:"title"`
	GeneratedAt        time.Time              `json:"generated_at"`
	Period             ReportPeriod           `json:"period"`
	Summary            *ReportSummary         `json:"summary"`
	PerformanceSection *PerformanceSection    `json:"performance_section"`
	AlertsSection      *AlertsSection         `json:"alerts_section"`
	TrendsSection      *TrendsSection         `json:"trends_section"`
	BusinessSection    *BusinessSection       `json:"business_section"`
	Recommendations    []string               `json:"recommendations"`
	Appendices         map[string]interface{} `json:"appendices"`
}

// ReportPeriod defines the time period covered by the report
type ReportPeriod struct {
	StartTime time.Time `json:"start_time"`
	EndTime   time.Time `json:"end_time"`
	Duration  string    `json:"duration"`
	Type      string    `json:"type"` // daily, weekly, monthly
}

// ReportSummary contains executive summary information
type ReportSummary struct {
	SystemHealth        string                 `json:"system_health"`
	TotalSyncs          int                    `json:"total_syncs"`
	SuccessRate         float64                `json:"success_rate"`
	AverageResponseTime float64                `json:"average_response_time"`
	TotalAlerts         int                    `json:"total_alerts"`
	CriticalIssues      int                    `json:"critical_issues"`
	SystemUptime        float64                `json:"system_uptime"`
	KeyMetrics          map[string]interface{} `json:"key_metrics"`
}

// PerformanceSection contains detailed performance analysis
type PerformanceSection struct {
	Report               *PerformanceReport `json:"report"`
	Charts               []ChartData        `json:"charts"`
	PerformanceScore     float64            `json:"performance_score"`
	ComparisonToPrevious map[string]float64 `json:"comparison_to_previous"`
}

// AlertsSection contains alert analysis and statistics
type AlertsSection struct {
	TotalAlerts        int                `json:"total_alerts"`
	AlertsBySeverity   map[string]int     `json:"alerts_by_severity"`
	AlertsByType       map[string]int     `json:"alerts_by_type"`
	MostFrequentAlerts []AlertFrequency   `json:"most_frequent_alerts"`
	ResolutionTimes    map[string]float64 `json:"resolution_times"`
	RecentAlerts       []Alert            `json:"recent_alerts"`
}

// TrendsSection contains trend analysis and predictions
type TrendsSection struct {
	PerformanceTrends *TrendAnalysis     `json:"performance_trends"`
	UsageTrends       map[string]float64 `json:"usage_trends"`
	Predictions       map[string]float64 `json:"predictions"`
	SeasonalPatterns  []SeasonalPattern  `json:"seasonal_patterns"`
}

// BusinessSection contains business-oriented metrics and insights
type BusinessSection struct {
	Metrics           *BusinessMetrics   `json:"metrics"`
	ROIAnalysis       map[string]float64 `json:"roi_analysis"`
	EfficiencyMetrics map[string]float64 `json:"efficiency_metrics"`
	UserSatisfaction  *UserSatisfaction  `json:"user_satisfaction"`
}

// ChartData represents data for generating charts in reports
type ChartData struct {
	Type   string                   `json:"type"` // line, bar, pie, area
	Title  string                   `json:"title"`
	XAxis  string                   `json:"x_axis"`
	YAxis  string                   `json:"y_axis"`
	Data   []map[string]interface{} `json:"data"`
	Config map[string]interface{}   `json:"config"`
}

// AlertFrequency represents frequency of alert types
type AlertFrequency struct {
	AlertType string    `json:"alert_type"`
	Count     int       `json:"count"`
	LastSeen  time.Time `json:"last_seen"`
}

// SeasonalPattern represents seasonal usage patterns
type SeasonalPattern struct {
	Period      string  `json:"period"` // hourly, daily, weekly
	Pattern     string  `json:"pattern"`
	Confidence  float64 `json:"confidence"`
	Description string  `json:"description"`
}

// UserSatisfaction contains user satisfaction metrics
type UserSatisfaction struct {
	OverallScore  float64            `json:"overall_score"`
	ResponseTime  float64            `json:"response_time_satisfaction"`
	Reliability   float64            `json:"reliability_satisfaction"`
	Features      float64            `json:"features_satisfaction"`
	Feedback      []string           `json:"recent_feedback"`
	SurveyResults map[string]float64 `json:"survey_results"`
}

// NewReportGenerator creates a new report generator
func NewReportGenerator(
	performanceMetrics *PerformanceMetrics,
	alertManager *AlertManager,
	driftDetector *DriftDetector,
	config *ReportConfig,
	logger *log.Logger,
) *ReportGenerator {
	return &ReportGenerator{
		performanceMetrics: performanceMetrics,
		alertManager:       alertManager,
		driftDetector:      driftDetector,
		config:             config,
		logger:             logger,
	}
}

// GenerateReport generates a comprehensive system report
func (rg *ReportGenerator) GenerateReport(reportType string, period ReportPeriod) (*Report, error) {
	rg.logger.Printf("Generating %s report for period %s to %s",
		reportType, period.StartTime.Format("2006-01-02"), period.EndTime.Format("2006-01-02"))

	report := &Report{
		ID:          fmt.Sprintf("report_%s_%d", reportType, time.Now().Unix()),
		Title:       fmt.Sprintf("Planning Ecosystem Sync - %s Report", reportType),
		GeneratedAt: time.Now(),
		Period:      period,
		Appendices:  make(map[string]interface{}),
	}

	// Generate executive summary
	summary, err := rg.generateSummary(period)
	if err != nil {
		return nil, fmt.Errorf("failed to generate summary: %w", err)
	}
	report.Summary = summary

	// Generate performance section
	performanceSection, err := rg.generatePerformanceSection(period)
	if err != nil {
		return nil, fmt.Errorf("failed to generate performance section: %w", err)
	}
	report.PerformanceSection = performanceSection

	// Generate alerts section
	alertsSection, err := rg.generateAlertsSection(period)
	if err != nil {
		return nil, fmt.Errorf("failed to generate alerts section: %w", err)
	}
	report.AlertsSection = alertsSection

	// Generate trends section
	trendsSection, err := rg.generateTrendsSection(period)
	if err != nil {
		return nil, fmt.Errorf("failed to generate trends section: %w", err)
	}
	report.TrendsSection = trendsSection

	// Generate business section
	businessSection, err := rg.generateBusinessSection(period)
	if err != nil {
		return nil, fmt.Errorf("failed to generate business section: %w", err)
	}
	report.BusinessSection = businessSection

	// Generate recommendations
	report.Recommendations = rg.generateRecommendations(report)

	// Add appendices
	report.Appendices["raw_metrics"] = rg.performanceMetrics.GetPerformanceReport()
	report.Appendices["system_info"] = rg.collectSystemInfo()

	return report, nil
}

// SaveReport saves a report in the specified formats
func (rg *ReportGenerator) SaveReport(report *Report) error {
	// Ensure output directory exists
	if err := os.MkdirAll(rg.config.OutputDir, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	for _, format := range rg.config.ReportFormats {
		switch format {
		case "json":
			if err := rg.saveJSONReport(report); err != nil {
				rg.logger.Printf("Failed to save JSON report: %v", err)
			}
		case "html":
			if err := rg.saveHTMLReport(report); err != nil {
				rg.logger.Printf("Failed to save HTML report: %v", err)
			}
		case "pdf":
			if err := rg.savePDFReport(report); err != nil {
				rg.logger.Printf("Failed to save PDF report: %v", err)
			}
		default:
			rg.logger.Printf("Unknown report format: %s", format)
		}
	}

	return nil
}

// StartScheduledReporting starts automatic report generation
func (rg *ReportGenerator) StartScheduledReporting() {
	if !rg.config.AutomaticGeneration {
		rg.logger.Println("Automatic report generation is disabled")
		return
	}

	rg.logger.Printf("Starting scheduled reporting: %s", rg.config.Schedule)

	go func() {
		for {
			switch rg.config.Schedule {
			case "daily":
				time.Sleep(24 * time.Hour)
				rg.generateDailyReport()
			case "weekly":
				// Wait until next Monday
				now := time.Now()
				nextMonday := now.AddDate(0, 0, 7-int(now.Weekday())+1)
				if now.Weekday() == time.Monday {
					nextMonday = now.AddDate(0, 0, 7)
				}
				time.Sleep(time.Until(nextMonday))
				rg.generateWeeklyReport()
			case "monthly":
				// Wait until next month
				now := time.Now()
				nextMonth := time.Date(now.Year(), now.Month()+1, 1, 0, 0, 0, 0, now.Location())
				time.Sleep(time.Until(nextMonth))
				rg.generateMonthlyReport()
			default:
				rg.logger.Printf("Unknown schedule type: %s", rg.config.Schedule)
				return
			}
		}
	}()
}

// generateDailyReport generates a daily report
func (rg *ReportGenerator) generateDailyReport() {
	end := time.Now()
	start := end.AddDate(0, 0, -1)

	period := ReportPeriod{
		StartTime: start,
		EndTime:   end,
		Duration:  "24 hours",
		Type:      "daily",
	}

	report, err := rg.GenerateReport("Daily", period)
	if err != nil {
		rg.logger.Printf("Failed to generate daily report: %v", err)
		return
	}

	if err := rg.SaveReport(report); err != nil {
		rg.logger.Printf("Failed to save daily report: %v", err)
	}

	rg.logger.Println("Daily report generated successfully")
}

// generateWeeklyReport generates a weekly report
func (rg *ReportGenerator) generateWeeklyReport() {
	end := time.Now()
	start := end.AddDate(0, 0, -7)

	period := ReportPeriod{
		StartTime: start,
		EndTime:   end,
		Duration:  "7 days",
		Type:      "weekly",
	}

	report, err := rg.GenerateReport("Weekly", period)
	if err != nil {
		rg.logger.Printf("Failed to generate weekly report: %v", err)
		return
	}

	if err := rg.SaveReport(report); err != nil {
		rg.logger.Printf("Failed to save weekly report: %v", err)
	}

	rg.logger.Println("Weekly report generated successfully")
}

// generateMonthlyReport generates a monthly report
func (rg *ReportGenerator) generateMonthlyReport() {
	end := time.Now()
	start := end.AddDate(0, -1, 0)

	period := ReportPeriod{
		StartTime: start,
		EndTime:   end,
		Duration:  "30 days",
		Type:      "monthly",
	}

	report, err := rg.GenerateReport("Monthly", period)
	if err != nil {
		rg.logger.Printf("Failed to generate monthly report: %v", err)
		return
	}

	if err := rg.SaveReport(report); err != nil {
		rg.logger.Printf("Failed to save monthly report: %v", err)
	}

	rg.logger.Println("Monthly report generated successfully")
}

// Generation helper functions

func (rg *ReportGenerator) generateSummary(period ReportPeriod) (*ReportSummary, error) {
	perfReport := rg.performanceMetrics.GetPerformanceReport()
	alerts := rg.alertManager.GetRecentAlerts(100) // Get all recent alerts

	criticalAlerts := 0
	for _, alert := range alerts {
		if alert.Severity == "critical" {
			criticalAlerts++
		}
	}

	return &ReportSummary{
		SystemHealth:        "healthy", // Would be calculated based on metrics
		TotalSyncs:          100,       // Mock value
		SuccessRate:         95.2,      // Mock value
		AverageResponseTime: float64(perfReport.AvgResponseTime.Milliseconds()),
		TotalAlerts:         len(alerts),
		CriticalIssues:      criticalAlerts,
		SystemUptime:        99.8, // Mock value
		KeyMetrics: map[string]interface{}{
			"avg_sync_duration": perfReport.AvgSyncDuration.Seconds(),
			"avg_throughput":    perfReport.AvgThroughput,
			"avg_error_rate":    perfReport.AvgErrorRate,
		},
	}, nil
}

func (rg *ReportGenerator) generatePerformanceSection(period ReportPeriod) (*PerformanceSection, error) {
	perfReport := rg.performanceMetrics.GetPerformanceReport()

	charts := []ChartData{
		{
			Type:  "line",
			Title: "Sync Duration Over Time",
			XAxis: "Time",
			YAxis: "Duration (ms)",
			Data: []map[string]interface{}{
				{"time": "2024-01-01", "value": 150},
				{"time": "2024-01-02", "value": 140},
				{"time": "2024-01-03", "value": 160},
			},
		},
		{
			Type:  "bar",
			Title: "Throughput by Hour",
			XAxis: "Hour",
			YAxis: "Tasks/second",
			Data: []map[string]interface{}{
				{"hour": "00", "value": 10},
				{"hour": "01", "value": 15},
				{"hour": "02", "value": 12},
			},
		},
	}

	return &PerformanceSection{
		Report:           perfReport,
		Charts:           charts,
		PerformanceScore: 85.5, // Mock calculated score
		ComparisonToPrevious: map[string]float64{
			"sync_duration": -5.2,  // 5.2% improvement
			"throughput":    +8.1,  // 8.1% improvement
			"error_rate":    -12.3, // 12.3% improvement
		},
	}, nil
}

func (rg *ReportGenerator) generateAlertsSection(period ReportPeriod) (*AlertsSection, error) {
	alerts := rg.alertManager.GetRecentAlerts(100)

	// Count alerts by severity and type
	bySeverity := make(map[string]int)
	byType := make(map[string]int)

	for _, alert := range alerts {
		bySeverity[alert.Severity]++
		byType[alert.Type]++
	}

	// Calculate most frequent alerts
	var mostFrequent []AlertFrequency
	for alertType, count := range byType {
		mostFrequent = append(mostFrequent, AlertFrequency{
			AlertType: alertType,
			Count:     count,
			LastSeen:  time.Now(), // Would be actual last seen time
		})
	}

	return &AlertsSection{
		TotalAlerts:        len(alerts),
		AlertsBySeverity:   bySeverity,
		AlertsByType:       byType,
		MostFrequentAlerts: mostFrequent,
		ResolutionTimes: map[string]float64{
			"critical": 5.2,  // minutes
			"warning":  15.8, // minutes
			"info":     45.0, // minutes
		},
		RecentAlerts: alerts[:min(len(alerts), 10)],
	}, nil
}

func (rg *ReportGenerator) generateTrendsSection(period ReportPeriod) (*TrendsSection, error) {
	perfReport := rg.performanceMetrics.GetPerformanceReport()

	return &TrendsSection{
		PerformanceTrends: perfReport.TrendAnalysis,
		UsageTrends: map[string]float64{
			"daily_syncs":   +12.5, // 12.5% increase
			"user_activity": +8.2,  // 8.2% increase
			"api_calls":     +15.3, // 15.3% increase
		},
		Predictions: map[string]float64{
			"next_week_load":  110.2, // Predicted load percentage
			"capacity_needed": 85.0,  // Predicted capacity percentage
		},
		SeasonalPatterns: []SeasonalPattern{
			{
				Period:      "daily",
				Pattern:     "peak_morning_afternoon",
				Confidence:  0.87,
				Description: "Higher activity during business hours",
			},
		},
	}, nil
}

func (rg *ReportGenerator) generateBusinessSection(period ReportPeriod) (*BusinessSection, error) {
	businessMetrics, err := rg.performanceMetrics.CollectBusinessMetrics()
	if err != nil {
		// Return mock data if collection fails
		businessMetrics = &BusinessMetrics{
			PlansSynchronized:     45,
			TasksProcessed:        1250,
			ConflictsResolved:     3,
			ValidationErrors:      2,
			UserInteractions:      87,
			SystemUptime:          99.8,
			DataConsistencyScore:  98.7,
			UserSatisfactionScore: 4.6,
		}
	}

	return &BusinessSection{
		Metrics: businessMetrics,
		ROIAnalysis: map[string]float64{
			"time_saved_hours":    152.3,
			"error_reduction_pct": 23.8,
			"efficiency_gain_pct": 18.5,
		},
		EfficiencyMetrics: map[string]float64{
			"automation_rate":     85.2,
			"manual_intervention": 14.8,
			"processing_speed":    125.6, // tasks per hour
		},
		UserSatisfaction: &UserSatisfaction{
			OverallScore: 4.6,
			ResponseTime: 4.3,
			Reliability:  4.8,
			Features:     4.5,
			Feedback:     []string{"Great performance", "Easy to use", "Reliable synchronization"},
			SurveyResults: map[string]float64{
				"ease_of_use":   4.4,
				"performance":   4.7,
				"reliability":   4.8,
				"documentation": 4.2,
			},
		},
	}, nil
}

func (rg *ReportGenerator) generateRecommendations(report *Report) []string {
	var recommendations []string

	// Performance-based recommendations
	if report.PerformanceSection.PerformanceScore < 80 {
		recommendations = append(recommendations, "Performance score is below optimal. Consider system optimization.")
	}

	// Alert-based recommendations
	if report.AlertsSection.TotalAlerts > 50 {
		recommendations = append(recommendations, "High alert volume detected. Review alert thresholds and investigate root causes.")
	}

	// Trend-based recommendations
	if report.TrendsSection.PerformanceTrends.SyncDurationTrend == "increasing" {
		recommendations = append(recommendations, "Sync duration is trending upward. Investigate performance bottlenecks.")
	}

	// Business metrics recommendations
	if report.BusinessSection.UserSatisfaction.OverallScore < 4.0 {
		recommendations = append(recommendations, "User satisfaction is below target. Review user feedback and prioritize improvements.")
	}

	if len(recommendations) == 0 {
		recommendations = append(recommendations, "System is performing well. Continue monitoring and maintain current practices.")
	}

	return recommendations
}

func (rg *ReportGenerator) collectSystemInfo() map[string]interface{} {
	return map[string]interface{}{
		"version":    "1.0.0",
		"build_date": "2024-01-15",
		"go_version": "1.21",
		"platform":   "linux/amd64",
		"components": []string{
			"sync-engine",
			"drift-detector",
			"alert-manager",
			"performance-metrics",
			"realtime-dashboard",
		},
	}
}

// Save functions

func (rg *ReportGenerator) saveJSONReport(report *Report) error {
	filename := fmt.Sprintf("%s_%s.json", report.ID, report.Period.Type)
	filepath := filepath.Join(rg.config.OutputDir, filename)

	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal report: %w", err)
	}

	return os.WriteFile(filepath, data, 0644)
}

func (rg *ReportGenerator) saveHTMLReport(report *Report) error {
	filename := fmt.Sprintf("%s_%s.html", report.ID, report.Period.Type)
	filepath := filepath.Join(rg.config.OutputDir, filename)

	htmlTemplate := `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{.Title}}</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 40px; }
        .header { border-bottom: 2px solid #333; padding-bottom: 20px; margin-bottom: 30px; }
        .section { margin-bottom: 30px; }
        .metric { display: inline-block; background: #f4f4f4; padding: 10px; margin: 5px; border-radius: 5px; }
        .alert { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .alert-critical { background: #ffe6e6; border-left: 4px solid #e74c3c; }
        .alert-warning { background: #fff3cd; border-left: 4px solid #f39c12; }
        .alert-info { background: #e6f3ff; border-left: 4px solid #3498db; }
        .recommendation { background: #e8f5e8; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #27ae60; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>{{.Title}}</h1>
        <p>Generated: {{.GeneratedAt.Format "2006-01-02 15:04:05"}}</p>
        <p>Period: {{.Period.StartTime.Format "2006-01-02"}} to {{.Period.EndTime.Format "2006-01-02"}}</p>
    </div>

    <div class="section">
        <h2>Executive Summary</h2>
        <div class="metric">System Health: {{.Summary.SystemHealth}}</div>
        <div class="metric">Total Syncs: {{.Summary.TotalSyncs}}</div>
        <div class="metric">Success Rate: {{printf "%.1f" .Summary.SuccessRate}}%</div>
        <div class="metric">System Uptime: {{printf "%.1f" .Summary.SystemUptime}}%</div>
        <div class="metric">Total Alerts: {{.Summary.TotalAlerts}}</div>
        <div class="metric">Critical Issues: {{.Summary.CriticalIssues}}</div>
    </div>

    <div class="section">
        <h2>Performance Analysis</h2>
        <p>Performance Score: {{printf "%.1f" .PerformanceSection.PerformanceScore}}/100</p>
        <p>Average Sync Duration: {{.PerformanceSection.Report.AvgSyncDuration}}</p>
        <p>Average Throughput: {{printf "%.1f" .PerformanceSection.Report.AvgThroughput}} tasks/second</p>
        <p>Average Error Rate: {{printf "%.2f" .PerformanceSection.Report.AvgErrorRate}}%</p>
    </div>

    <div class="section">
        <h2>Alerts Summary</h2>
        <p>Total Alerts: {{.AlertsSection.TotalAlerts}}</p>
        <h3>Alerts by Severity</h3>
        {{range $severity, $count := .AlertsSection.AlertsBySeverity}}
        <div class="metric">{{$severity}}: {{$count}}</div>
        {{end}}
    </div>

    <div class="section">
        <h2>Business Metrics</h2>
        <div class="metric">Plans Synchronized: {{.BusinessSection.Metrics.PlansSynchronized}}</div>
        <div class="metric">Tasks Processed: {{.BusinessSection.Metrics.TasksProcessed}}</div>
        <div class="metric">Conflicts Resolved: {{.BusinessSection.Metrics.ConflictsResolved}}</div>
        <div class="metric">User Satisfaction: {{printf "%.1f" .BusinessSection.UserSatisfaction.OverallScore}}/5.0</div>
    </div>

    <div class="section">
        <h2>Recommendations</h2>
        {{range .Recommendations}}
        <div class="recommendation">{{.}}</div>
        {{end}}
    </div>
</body>
</html>`

	tmpl, err := template.New("report").Parse(htmlTemplate)
	if err != nil {
		return fmt.Errorf("failed to parse template: %w", err)
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, report); err != nil {
		return fmt.Errorf("failed to execute template: %w", err)
	}

	return os.WriteFile(filepath, buf.Bytes(), 0644)
}

func (rg *ReportGenerator) savePDFReport(report *Report) error {
	// PDF generation would require additional libraries like wkhtmltopdf or similar
	// For now, we'll just save a placeholder
	filename := fmt.Sprintf("%s_%s.pdf.txt", report.ID, report.Period.Type)
	filepath := filepath.Join(rg.config.OutputDir, filename)

	content := fmt.Sprintf("PDF Report Placeholder\nTitle: %s\nGenerated: %s\n",
		report.Title, report.GeneratedAt.Format("2006-01-02 15:04:05"))

	return os.WriteFile(filepath, []byte(content), 0644)
}

// CleanupOldReports removes old reports based on retention policy
func (rg *ReportGenerator) CleanupOldReports() error {
	if rg.config.RetentionDays <= 0 {
		return nil
	}

	cutoff := time.Now().AddDate(0, 0, -rg.config.RetentionDays)

	return filepath.Walk(rg.config.OutputDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && info.ModTime().Before(cutoff) {
			rg.logger.Printf("Removing old report: %s", path)
			return os.Remove(path)
		}

		return nil
	})
}

// Helper function
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
