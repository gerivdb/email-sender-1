// Package presentation provides web presentation functionality for reports
package presentation

import (
	"embed"
	"fmt"
	"html/template"
	"net/http"
	"strconv"
	"strings"

	"github.com/gerivdb/email-sender-1/internal/report"
)

//go:embed templates/*
var templateFS embed.FS

// Server represents a web presentation server
type Server struct {
	reports    []*report.Report
	templates  *template.Template
	generator  *report.ReportGenerator
	listenAddr string
}

// NewServer creates a new web presentation server
func NewServer(generator *report.ReportGenerator, listenAddr string) (*Server, error) {
	templates, err := template.ParseFS(templateFS, "templates/*.html")
	if err != nil {
		return nil, fmt.Errorf("failed to parse templates: %w", err)
	}

	return &Server{
		reports:    make([]*report.Report, 0),
		templates:  templates,
		generator:  generator,
		listenAddr: listenAddr,
	}, nil
}

// AddReport adds a report to the server
func (s *Server) AddReport(r *report.Report) {
	s.reports = append(s.reports, r)
}

// Start starts the web server
func (s *Server) Start() error {
	http.HandleFunc("/", s.handleHome)
	http.HandleFunc("/view/", s.handleView)
	return http.ListenAndServe(s.listenAddr, nil)
}

// handleHome handles the home page request
func (s *Server) handleHome(w http.ResponseWriter, r *http.Request) {
	data := struct {
		Reports []*report.Report
	}{
		Reports: s.reports,
	}

	if err := s.templates.ExecuteTemplate(w, "home.html", data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

// handleView handles individual report view requests
func (s *Server) handleView(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(r.URL.Path, "/")
	if len(parts) < 3 {
		http.Error(w, "Invalid report ID", http.StatusBadRequest)
		return
	}

	id, err := strconv.Atoi(parts[2])
	if err != nil {
		http.Error(w, "Invalid report ID", http.StatusBadRequest)
		return
	}

	if id < 0 || id >= len(s.reports) {
		http.Error(w, "Report not found", http.StatusNotFound)
		return
	}

	format := report.FormatHTML
	if formatParam := r.URL.Query().Get("format"); formatParam != "" {
		format = report.Format(formatParam)
	}

	rpt := s.reports[id]
	if format == report.FormatHTML {
		data := struct {
			Report *report.Report
			ID     int
		}{
			Report: rpt,
			ID:     id,
		}
		if err := s.templates.ExecuteTemplate(w, "view.html", data); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	} else {
		if err := s.generator.Generate(rpt, format, w); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}
}
