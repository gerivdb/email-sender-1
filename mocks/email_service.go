package mocks

import (
	"fmt"
	"time"
)

// MockEmailService simule les workflows n8n pour Email Sender 1
// ROI: +10h développement parallèle sans attendre n8n
type MockEmailService struct {
	SentEmails   []Email
	Responses    map[string]string
	ProcessTime  time.Duration
	FailureRate  float64
}

type Email struct {
	To          string            `json:"to"`
	Subject     string            `json:"subject"`
	Body        string            `json:"body"`
	VenueID     string            `json:"venue_id"`
	ContactID   string            `json:"contact_id"`
	TemplateID  string            `json:"template_id"`
	Metadata    map[string]string `json:"metadata"`
}

func NewMockEmailService() *MockEmailService {
	return &MockEmailService{
		SentEmails:  make([]Email, 0),
		Responses:   make(map[string]string),
		ProcessTime: 100 * time.Millisecond, // Simulation latence réaliste
		FailureRate: 0.0, // 0% échec pour dev initial
	}
}

func (m *MockEmailService) SendEmail(email Email) error {
	// Simulate processing time
	time.Sleep(m.ProcessTime)
	
	// Simulate random failures
	if m.shouldFail() {
		return fmt.Errorf("mock email service: delivery failed for %s", email.To)
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
	return false // Toujours succès pour développement
}

// Test helpers
func (m *MockEmailService) GetSentCount() int {
	return len(m.SentEmails)
}

func (m *MockEmailService) Reset() {
	m.SentEmails = make([]Email, 0)
	m.Responses = make(map[string]string)
}

func (m *MockEmailService) GetLastEmail() *Email {
	if len(m.SentEmails) == 0 {
		return nil
	}
	return &m.SentEmails[len(m.SentEmails)-1]
}
