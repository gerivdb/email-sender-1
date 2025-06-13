#!/usr/bin/env pwsh
# Script d'application automatique des 7 méthodes time-saving au projet EMAIL_SENDER_1
# Utilisation: ./tools/apply-time-saving-methods.ps1 -Phase "3" -Method "all"

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("3", "4", "5", "6", "all")]
    [string]$Phase,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("fail-fast", "mock-first", "contract-first", "inverted-tdd", "code-gen", "metrics-driven", "pipeline-as-code", "all")]
    [string]$Method = "all",
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Configuration des chemins
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ToolsDir = "$ProjectRoot/tools"
$MetricsDir = "$ProjectRoot/metrics"
$DevOpsDir = "$ProjectRoot/devops"

Write-Host "🚀 Application des méthodes Time-Saving au projet EMAIL_SENDER_1" -ForegroundColor Green
Write-Host "Phase: $Phase | Méthode: $Method | Mode: $(if($DryRun) {'Dry Run'} else {'Execution'})" -ForegroundColor Yellow

# Ensure directories exist
if (-not $DryRun) {
    @($MetricsDir, $DevOpsDir, "$ProjectRoot/internal", "$ProjectRoot/pkg", "$ProjectRoot/mocks") | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Force -Path $_ | Out-Null
        }
    }
}

function Set-FailFastValidation {
    param([string]$Phase)
    
    Write-Host "🔧 Application de Fail-Fast Validation pour Phase $Phase" -ForegroundColor Cyan
    
    switch ($Phase) {
        "3" {
            # Phase 3: API & Search - Validation des requêtes
            $validationCode = @'
// Fail-Fast Validation pour Phase 3 - API & Search
package validation

import (
    "errors"
    "strings"
)

var (
    ErrEmptyQuery = errors.New("query cannot be empty")
    ErrInvalidLimit = errors.New("limit must be between 1 and 1000")
    ErrInvalidProvider = errors.New("invalid embedding provider")
)

func ValidateSearchRequest(query string, limit int, provider string) error {
    if strings.TrimSpace(query) == "" {
        return ErrEmptyQuery
    }
    
    if limit < 1 || limit > 1000 {
        return ErrInvalidLimit
    }
    
    validProviders := []string{"openai", "huggingface", "sentence-transformers"}
    for _, valid := range validProviders {
        if provider == valid {
            return nil
        }
    }
    
    return ErrInvalidProvider
}
'@
            
            if (-not $DryRun) {
                New-Item -ItemType Directory -Force -Path "$ProjectRoot/internal/validation" | Out-Null
                Set-Content -Path "$ProjectRoot/internal/validation/search.go" -Value $validationCode
                Write-Host "✅ Validation search créée: internal/validation/search.go" -ForegroundColor Green
            }
        }
        
        "4" {
            # Phase 4: Email Integration - Validation des emails
            $emailValidationCode = @'
// Fail-Fast Validation pour Phase 4 - Email Integration
package validation

import (
    "errors"
    "net/mail"
    "strings"
)

var (
    ErrInvalidEmail = errors.New("invalid email address")
    ErrEmptySubject = errors.New("subject cannot be empty")
    ErrEmptyBody = errors.New("email body cannot be empty")
)

func ValidateEmailRequest(to, subject, body string) error {
    if _, err := mail.ParseAddress(to); err != nil {
        return ErrInvalidEmail
    }
    
    if strings.TrimSpace(subject) == "" {
        return ErrEmptySubject
    }
    
    if strings.TrimSpace(body) == "" {
        return ErrEmptyBody
    }
    
    return nil
}
'@
            
            if (-not $DryRun) {
                New-Item -ItemType Directory -Force -Path "$ProjectRoot/internal/validation" | Out-Null
                Set-Content -Path "$ProjectRoot/internal/validation/email.go" -Value $emailValidationCode
                Write-Host "✅ Validation email créée: internal/validation/email.go" -ForegroundColor Green
            }
        }
    }
}

function Set-MockFirstStrategy {
    param([string]$Phase)
    
    Write-Host "🎭 Application de Mock-First Strategy pour Phase $Phase" -ForegroundColor Cyan
    
    switch ($Phase) {
        "3" {
            # Mock pour le service de recherche
            $mockSearchCode = @'
// Mock Search Service pour développement parallèle
package mocks

import (
    "time"
)

type MockSearchService struct {
    latency time.Duration
}

func NewMockSearchService() *MockSearchService {
    return &MockSearchService{
        latency: 50 * time.Millisecond,
    }
}

func (m *MockSearchService) Search(query string, limit int) ([]SearchResult, error) {
    time.Sleep(m.latency) // Simulation latence
    
    // Simulation de résultats
    results := []SearchResult{
        {
            ID:    "1",
            Title: "Mock Result 1 for: " + query,
            Score: 0.95,
        },
        {
            ID:    "2", 
            Title: "Mock Result 2 for: " + query,
            Score: 0.87,
        },
    }
    
    if limit < len(results) {
        results = results[:limit]
    }
    
    return results, nil
}

type SearchResult struct {
    ID    string
    Title string
    Score float64
}
'@
            
            if (-not $DryRun) {
                New-Item -ItemType Directory -Force -Path "$ProjectRoot/mocks" | Out-Null
                Set-Content -Path "$ProjectRoot/mocks/search_service.go" -Value $mockSearchCode
                Write-Host "✅ Mock search service créé: mocks/search_service.go" -ForegroundColor Green
            }
        }
        
        "4" {
            # Mock pour le service email
            $mockEmailCode = @'
// Mock Email Service pour développement parallèle
package mocks

import (
    "fmt"
    "time"
)

type MockEmailService struct {
    sentEmails []EmailMessage
    latency    time.Duration
}

func NewMockEmailService() *MockEmailService {
    return &MockEmailService{
        sentEmails: make([]EmailMessage, 0),
        latency:    100 * time.Millisecond,
    }
}

func (m *MockEmailService) SendEmail(to, subject, body string) error {
    time.Sleep(m.latency) // Simulation latence
    
    email := EmailMessage{
        To:      to,
        Subject: subject,
        Body:    body,
        SentAt:  time.Now(),
    }
    
    m.sentEmails = append(m.sentEmails, email)
    fmt.Printf("Mock: Email sent to %s with subject '%s'\n", to, subject)
    
    return nil
}

func (m *MockEmailService) GetSentEmails() []EmailMessage {
    return m.sentEmails
}

type EmailMessage struct {
    To      string
    Subject string
    Body    string
    SentAt  time.Time
}
'@
            
            if (-not $DryRun) {
                New-Item -ItemType Directory -Force -Path "$ProjectRoot/mocks" | Out-Null
                Set-Content -Path "$ProjectRoot/mocks/email_service.go" -Value $mockEmailCode
                Write-Host "✅ Mock email service créé: mocks/email_service.go" -ForegroundColor Green
            }
        }
    }
}

function Set-ContractFirstAPI {
    param([string]$Phase)
    
    Write-Host "📋 Application de Contract-First API pour Phase $Phase" -ForegroundColor Cyan
    
    $openApiSpec = @'
openapi: 3.0.3
info:
  title: EMAIL_SENDER_1 API
  description: API pour le système de recherche et d'envoi d'emails
  version: 1.0.0

paths:
  /search:
    post:
      summary: Recherche de contenu
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - query
              properties:
                query:
                  type: string
                  minLength: 1
                limit:
                  type: integer
                  minimum: 1
                  maximum: 1000
                  default: 10
                provider:
                  type: string
                  enum: [openai, huggingface, sentence-transformers]
                  default: openai
      responses:
        '200':
          description: Résultats de recherche
          content:
            application/json:
              schema:
                type: object
                properties:
                  results:
                    type: array
                    items:
                      type: object
                      properties:
                        id:
                          type: string
                        title:
                          type: string
                        score:
                          type: number
                          format: float
        '400':
          description: Requête invalide
          content:
            application/json:
              schema:
                type: object
                properties:
                  error:
                    type: string

  /email/send:
    post:
      summary: Envoyer un email
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - to
                - subject
                - body
              properties:
                to:
                  type: string
                  format: email
                subject:
                  type: string
                  minLength: 1
                body:
                  type: string
                  minLength: 1
      responses:
        '200':
          description: Email envoyé avec succès
          content:
            application/json:
              schema:
                type: object
                properties:
                  message:
                    type: string
                    example: "Email sent successfully"
        '400':
          description: Requête invalide
          content:
            application/json:
              schema:
                type: object
                properties:
                  error:
                    type: string
'@
    
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path "$ProjectRoot/api" | Out-Null
        Set-Content -Path "$ProjectRoot/api/openapi.yaml" -Value $openApiSpec
        Write-Host "✅ Spécification OpenAPI créée: api/openapi.yaml" -ForegroundColor Green
    }
}

function Set-MetricsDrivenDevelopment {
    param([string]$Phase)
    
    Write-Host "📊 Application de Metrics-Driven Development pour Phase $Phase" -ForegroundColor Cyan
    
    $metricsCode = @'
// Metrics collection pour EMAIL_SENDER_1
package metrics

import (
    "time"
    "sync"
)

type Metrics struct {
    mu            sync.RWMutex
    searchQueries int64
    emailsSent    int64
    searchTime    time.Duration
    emailTime     time.Duration
}

var instance *Metrics
var once sync.Once

func GetMetrics() *Metrics {
    once.Do(func() {
        instance = &Metrics{}
    })
    return instance
}

func (m *Metrics) IncrementSearchQueries() {
    m.mu.Lock()
    defer m.mu.Unlock()
    m.searchQueries++
}

func (m *Metrics) IncrementEmailsSent() {
    m.mu.Lock()
    defer m.mu.Unlock()
    m.emailsSent++
}

func (m *Metrics) AddSearchTime(duration time.Duration) {
    m.mu.Lock()
    defer m.mu.Unlock()
    m.searchTime += duration
}

func (m *Metrics) AddEmailTime(duration time.Duration) {
    m.mu.Lock()
    defer m.mu.Unlock()
    m.emailTime += duration
}

func (m *Metrics) GetStats() map[string]interface{} {
    m.mu.RLock()
    defer m.mu.RUnlock()
    
    return map[string]interface{}{
        "search_queries":     m.searchQueries,
        "emails_sent":        m.emailsSent,
        "avg_search_time_ms": m.searchTime.Milliseconds() / max(1, m.searchQueries),
        "avg_email_time_ms":  m.emailTime.Milliseconds() / max(1, m.emailsSent),
    }
}
'@
    
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path "$ProjectRoot/pkg/metrics" | Out-Null
        Set-Content -Path "$ProjectRoot/pkg/metrics/metrics.go" -Value $metricsCode
        Write-Host "✅ Système de métriques créé: pkg/metrics/metrics.go" -ForegroundColor Green
    }
}

function Set-PipelineAsCode {
    param([string]$Phase)
    
    Write-Host "🔄 Application de Pipeline-as-Code pour Phase $Phase" -ForegroundColor Cyan
    
    $githubWorkflow = @'
name: EMAIL_SENDER_1 CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v3
      with:
        go-version: 1.21
    
    - name: Cache Go modules
      uses: actions/cache@v3
      with:
        path: ~/go/pkg/mod
        key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
        restore-keys: |
          ${{ runner.os }}-go-
    
    - name: Install dependencies
      run: go mod download
    
    - name: Run tests
      run: go test -v ./...
    
    - name: Run linter
      uses: golangci/golangci-lint-action@v3
      with:
        version: latest
    
    - name: Build
      run: go build -v ./...

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v3
      with:
        go-version: 1.21
    
    - name: Build binaries
      run: |
        CGO_ENABLED=0 GOOS=linux go build -o bin/email-sender-linux ./cmd/server
        CGO_ENABLED=0 GOOS=windows go build -o bin/email-sender-windows.exe ./cmd/server
        CGO_ENABLED=0 GOOS=darwin go build -o bin/email-sender-darwin ./cmd/server
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: binaries
        path: bin/
'@
    
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path "$ProjectRoot/.github/workflows" | Out-Null
        Set-Content -Path "$ProjectRoot/.github/workflows/ci-cd.yml" -Value $githubWorkflow
        Write-Host "✅ Pipeline CI/CD créé: .github/workflows/ci-cd.yml" -ForegroundColor Green
    }
}

# Main execution logic
switch ($Method) {
    "fail-fast" { Set-FailFastValidation -Phase $Phase }
    "mock-first" { Set-MockFirstStrategy -Phase $Phase }
    "contract-first" { Set-ContractFirstAPI -Phase $Phase }
    "metrics-driven" { Set-MetricsDrivenDevelopment -Phase $Phase }
    "pipeline-as-code" { Set-PipelineAsCode -Phase $Phase }
    "all" {
        Set-FailFastValidation -Phase $Phase
        Set-MockFirstStrategy -Phase $Phase
        Set-ContractFirstAPI -Phase $Phase
        Set-MetricsDrivenDevelopment -Phase $Phase
        Set-PipelineAsCode -Phase $Phase
    }
    default {
        Write-Host "❌ Méthode non reconnue: $Method" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Application des méthodes Time-Saving terminée avec succès!" -ForegroundColor Green

if ($DryRun) {
    Write-Host "ℹ️  Mode Dry Run activé - aucun fichier n'a été modifié" -ForegroundColor Blue
} else {
    Write-Host "📁 Fichiers créés dans:" -ForegroundColor Yellow
    Write-Host "  - internal/validation/" -ForegroundColor White
    Write-Host "  - mocks/" -ForegroundColor White
    Write-Host "  - api/" -ForegroundColor White
    Write-Host "  - pkg/metrics/" -ForegroundColor White
    Write-Host "  - .github/workflows/" -ForegroundColor White
}
