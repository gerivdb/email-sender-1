package main

import (
	"fmt"
	"html/template"
	"os"
)

type ResourceUsageData struct {
	CPU    float64
	Memory float64
	Disk   float64
}

type DashboardData struct {
	EventsPublishedByType   map[string]int
	EventsConsumedByService map[string]int
	AverageProcessingTime   map[string]float64
	ErrorsByService         map[string]int
	ResourceUsage           map[string]ResourceUsageData
}

func main() {
	fmt.Println("Génération du dashboard Event Bus")

	data := DashboardData{
		EventsPublishedByType: map[string]int{
			"manager.created": 10,
			"script.executed": 5,
		},
		EventsConsumedByService: map[string]int{
			"service1": 8,
			"service2": 3,
		},
		AverageProcessingTime: map[string]float64{
			"service1": 0.5,
			"service2": 1.2,
		},
		ErrorsByService: map[string]int{
			"service1": 1,
			"service2": 0,
		},
		ResourceUsage: map[string]ResourceUsageData{
			"service1": {
				CPU:    0.2,
				Memory: 0.1,
				Disk:   0.05,
			},
			"service2": {
				CPU:    0.1,
				Memory: 0.05,
				Disk:   0.02,
			},
		},
	}

	// Generate dashboard_eventbus.html
	t, err := template.New("dashboard").Parse(`
		<h1>Dashboard Event Bus</h1>
		<h2>Events Published By Type</h2>
		<ul>
			{{range $key, $value := .EventsPublishedByType}}
				<li>{{$key}}: {{$value}}</li>
			{{end}}
		</ul>
		<h2>Events Consumed By Service</h2>
		<ul>
			{{range $key, $value := .EventsConsumedByService}}
				<li>{{$key}}: {{$value}}</li>
			{{end}}
		</ul>
		<h2>Average Processing Time</h2>
		<ul>
			{{range $key, $value := .AverageProcessingTime}}
				<li>{{$key}}: {{$value}}</li>
			{{end}}
		</ul>
		<h2>Errors By Service</h2>
		<ul>
			{{range $key, $value := .ErrorsByService}}
				<li>{{$key}}: {{$value}}</li>
			{{end}}
		</ul>
		<h2>Resource Usage</h2>
		<ul>
			{{range $key, $value := .ResourceUsage}}
				<li>{{$key}}: CPU: {{$value.CPU}}, Memory: {{$value.Memory}}, Disk: {{$value.Disk}}</li>
			{{end}}
		</ul>
	`)
	if err != nil {
		fmt.Println("Erreur lors de la création du template:", err)
		return
	}
	f, err := os.Create("dashboard_eventbus.html")
	if err != nil {
		fmt.Println("Erreur lors de la création du fichier:", err)
		return
	}
	defer f.Close()
	err = t.Execute(f, data)
	if err != nil {
		fmt.Println("Erreur lors de l'exécution du template:", err)
		return
	}

	// Générer dashboard_eventbus.md
	mdContent := fmt.Sprintf(`
# Dashboard Event Bus

## Events Published By Type
%v

## Events Consumed By Service
%v

## Average Processing Time
%v

## Errors By Service
%v

## Resource Usage
%v
`, data.EventsPublishedByType, data.EventsConsumedByService, data.AverageProcessingTime, data.ErrorsByService, data.ResourceUsage)

	err = os.WriteFile("dashboard_eventbus.md", []byte(mdContent), 0o644)
	if err != nil {
		fmt.Println("Erreur lors de la création du fichier:", err)
		return
	}

	fmt.Println("Les dashboards ont été générés avec succès !")
}
