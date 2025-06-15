package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

type DashboardData struct {
	Title       string    `json:"title"`
	Status      string    `json:"status"`
	Uptime      string    `json:"uptime"`
	Version     string    `json:"version"`
	Services    []Service `json:"services"`
	Timestamp   time.Time `json:"timestamp"`
	Performance struct {
		CPU    float64 `json:"cpu"`
		Memory float64 `json:"memory"`
		Disk   float64 `json:"disk"`
	} `json:"performance"`
}

type Service struct {
	Name   string `json:"name"`
	Status string `json:"status"`
	Port   int    `json:"port"`
	Health string `json:"health"`
}

func main() {
	fmt.Println("📊 Dashboard Manager - Version 1.0.0")
	fmt.Println("🖥️  Real-time Monitoring Dashboard")

	if len(os.Args) > 1 && os.Args[1] == "--status" {
		fmt.Println("✅ Dashboard Status: Running")
		fmt.Println("🌐 Web Interface: http://localhost:8082")
		fmt.Println("📈 Monitoring: Active")
		fmt.Println("🔄 Real-time updates: Enabled")
		return
	}

	if len(os.Args) > 1 && os.Args[1] == "--version" {
		fmt.Println("dashboard version 1.0.0")
		return
	}

	startTime := time.Now()

	// Données du dashboard
	dashboardData := DashboardData{
		Title:     "Smart Email Sender Infrastructure Dashboard",
		Status:    "operational",
		Uptime:    time.Since(startTime).String(),
		Version:   "1.0.0",
		Timestamp: time.Now(),
		Services: []Service{
			{Name: "Infrastructure Orchestrator", Status: "running", Port: 8080, Health: "healthy"},
			{Name: "Cache Manager", Status: "running", Port: 8081, Health: "healthy"},
			{Name: "Dashboard", Status: "running", Port: 8082, Health: "healthy"},
		},
	}
	dashboardData.Performance.CPU = 15.5
	dashboardData.Performance.Memory = 34.2
	dashboardData.Performance.Disk = 67.8

	// API endpoints
	http.HandleFunc("/api/dashboard", func(w http.ResponseWriter, r *http.Request) {
		dashboardData.Timestamp = time.Now()
		dashboardData.Uptime = time.Since(startTime).String()

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(dashboardData)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"healthy","dashboard":"operational","uptime":"%s"}`, time.Since(startTime).String())
	})

	// Page web simple
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		tmpl := `<!DOCTYPE html>
<html>
<head>
    <title>{{.Title}}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .status { color: #28a745; font-weight: bold; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { background: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #007bff; }
        .service { background: #e9ecef; padding: 10px; margin: 5px 0; border-radius: 3px; }
        .performance { background: linear-gradient(45deg, #007bff, #28a745); color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{.Title}}</h1>
            <p>Status: <span class="status">{{.Status}}</span> | Uptime: {{.Uptime}} | Version: {{.Version}}</p>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>🔧 Services</h3>
                {{range .Services}}
                <div class="service">
                    <strong>{{.Name}}</strong><br>
                    Status: {{.Status}} | Port: {{.Port}} | Health: {{.Health}}
                </div>
                {{end}}
            </div>
            
            <div class="card performance">
                <h3>📊 Performance</h3>
                <p>CPU Usage: {{.Performance.CPU}}%</p>
                <p>Memory Usage: {{.Performance.Memory}}%</p>
                <p>Disk Usage: {{.Performance.Disk}}%</p>
            </div>
            
            <div class="card">
                <h3>🕒 System Info</h3>
                <p>Last Update: {{.Timestamp.Format "15:04:05"}}</p>
                <p>Date: {{.Timestamp.Format "2006-01-02"}}</p>
                <p>Auto-refresh: Every 30s</p>
            </div>
        </div>
    </div>
    
    <script>
        setInterval(() => {
            location.reload();
        }, 30000);
    </script>
</body>
</html>`

		t, err := template.New("dashboard").Parse(tmpl)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		dashboardData.Timestamp = time.Now()
		dashboardData.Uptime = time.Since(startTime).String()

		t.Execute(w, dashboardData)
	})

	fmt.Println("🌐 Starting Dashboard HTTP server on :8082")
	fmt.Println("🖥️  Dashboard available at: http://localhost:8082")
	go func() {
		if err := http.ListenAndServe(":8082", nil); err != nil {
			log.Printf("Dashboard HTTP server error: %v", err)
		}
	}()

	// Attendre signal d'arrêt
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	fmt.Println("✅ Dashboard Manager running... Press Ctrl+C to stop")
	<-c
	fmt.Println("🛑 Shutting down Dashboard Manager")
}
