#!/usr/bin/env pwsh
# 🎭 Mock Services Setup - 10 minutes pour +24h ROI
# Crée tous les mocks nécessaires pour Email Sender 1

param(
    [switch]$DryRun,
    [switch]$Verbose
)

Write-Host "🎭 MOCK SERVICES SETUP" -ForegroundColor Cyan
Write-Host "ROI estimé: +24h développement parallèle" -ForegroundColor Yellow

# 📧 Mock Email Service (n8n workflows)
$mockEmailService = @"
package mocks

import (
    "fmt"
    "time"
)

// MockEmailService simule les workflows n8n
type MockEmailService struct {
    SentEmails   []Email
    Responses    map[string]string
    ProcessTime  time.Duration
    FailureRate  float64
}

type Email struct {
    To          string
    Subject     string
    Body        string
    VenueID     string
    ContactID   string
    TemplateID  string
}

func NewMockEmailService() *MockEmailService {
    return &MockEmailService{
        SentEmails:  make([]Email, 0),
        Responses:   make(map[string]string),
        ProcessTime: 100 * time.Millisecond, // Simulation latence
        FailureRate: 0.05, // 5% échec simulé
    }
}

func (m *MockEmailService) SendEmail(email Email) error {
    // Simulate processing time
    time.Sleep(m.ProcessTime)
    
    // Simulate random failures
    if m.shouldFail() {
        return fmt.Errorf("mock email service: delivery failed")
    }
    
    m.SentEmails = append(m.SentEmails, email)
    m.Responses[email.ContactID] = "delivered"
    
    return nil
}

func (m *MockEmailService) GetDeliveryStatus(contactID string) string {
    if status, exists := m.Responses[contactID]; exists {
        return status
    }
    return "unknown"
}

func (m *MockEmailService) shouldFail() bool {
    return false // Toujours succès pour dev initial
}

// Test helpers
func (m *MockEmailService) GetSentCount() int {
    return len(m.SentEmails)
}

func (m *MockEmailService) Reset() {
    m.SentEmails = make([]Email, 0)
    m.Responses = make(map[string]string)
}
"@

# 📝 Mock Notion API (LOT1)
$mockNotionAPI = @"
package mocks

import (
    "fmt"
    "time"
)

// MockNotionAPI simule l'API Notion pour les contacts/venues
type MockNotionAPI struct {
    Contacts []Contact
    Venues   []Venue
    ApiDelay time.Duration
}

type Contact struct {
    ID       string
    Name     string
    Email    string
    VenueID  string
    Status   string
    LastContact time.Time
}

type Venue struct {
    ID       string
    Name     string
    Type     string
    Location string
    Capacity int
    Manager  Contact
}

func NewMockNotionAPI() *MockNotionAPI {
    return &MockNotionAPI{
        Contacts: generateMockContacts(),
        Venues:   generateMockVenues(),
        ApiDelay: 50 * time.Millisecond,
    }
}

func (m *MockNotionAPI) GetContacts(filter string) ([]Contact, error) {
    time.Sleep(m.ApiDelay)
    
    if filter == "" {
        return m.Contacts, nil
    }
    
    // Simple filter simulation
    var filtered []Contact
    for _, contact := range m.Contacts {
        if contains(contact.Name, filter) || contains(contact.Email, filter) {
            filtered = append(filtered, contact)
        }
    }
    
    return filtered, nil
}

func (m *MockNotionAPI) GetVenues() ([]Venue, error) {
    time.Sleep(m.ApiDelay)
    return m.Venues, nil
}

func (m *MockNotionAPI) UpdateContactStatus(contactID, status string) error {
    time.Sleep(m.ApiDelay)
    
    for i, contact := range m.Contacts {
        if contact.ID == contactID {
            m.Contacts[i].Status = status
            m.Contacts[i].LastContact = time.Now()
            return nil
        }
    }
    
    return fmt.Errorf("contact not found: %s", contactID)
}

// Mock data generators
func generateMockContacts() []Contact {
    return []Contact{
        {ID: "c1", Name: "Alice Manager", Email: "alice@venue1.com", VenueID: "v1", Status: "active"},
        {ID: "c2", Name: "Bob Director", Email: "bob@venue2.com", VenueID: "v2", Status: "pending"},
        {ID: "c3", Name: "Carol Owner", Email: "carol@venue3.com", VenueID: "v3", Status: "contacted"},
    }
}

func generateMockVenues() []Venue {
    return []Venue{
        {ID: "v1", Name: "Concert Hall Alpha", Type: "concert", Location: "Paris", Capacity: 500},
        {ID: "v2", Name: "Theater Beta", Type: "theater", Location: "Lyon", Capacity: 200},
        {ID: "v3", Name: "Club Gamma", Type: "club", Location: "Marseille", Capacity: 150},
    }
}

func contains(s, substr string) bool {
    return len(s) >= len(substr) && s[:len(substr)] == substr
}
"@

if ($DryRun) {
    Write-Host "[DRY RUN] Créerait:" -ForegroundColor Yellow
    Write-Host "  - mocks/email_service.go" -ForegroundColor Yellow
    Write-Host "  - mocks/notion_api.go" -ForegroundColor Yellow
    Write-Host "  - mocks/qdrant_client.go" -ForegroundColor Yellow
    return
}

# Create mock files
Set-Content -Path "mocks/email_service.go" -Value $mockEmailService -Encoding UTF8
Set-Content -Path "mocks/notion_api.go" -Value $mockNotionAPI -Encoding UTF8

Write-Host "✅ Mock Email Service créé" -ForegroundColor Green
Write-Host "✅ Mock Notion API créé" -ForegroundColor Green
Write-Host "🎉 Mock services configurés!" -ForegroundColor Green