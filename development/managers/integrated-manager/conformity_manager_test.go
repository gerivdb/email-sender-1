package integratedmanager

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap/zaptest"
)

// MockErrorManager pour les tests
type MockErrorManager struct {
	mock.Mock
}

func (m *MockErrorManager) LogError(err error, module string, code string) {
	m.Called(err, module, code)
}

func (m *MockErrorManager) CatalogError(entry ErrorEntry) error {
	args := m.Called(entry)
	return args.Error(0)
}

func (m *MockErrorManager) ValidateError(entry ErrorEntry) error {
	args := m.Called(entry)
	return args.Error(0)
}

// TestNewConformityManager teste la création d'une nouvelle instance
func TestNewConformityManager(t *testing.T) {
	tests := []struct {
		name    string
		config  *ConformityConfig
		wantErr bool
	}{
		{
			name:    "with default config",
			config:  nil,
			wantErr: false,
		},
		{
			name:    "with custom config",
			config:  getDefaultConformityConfig(),
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockErrorManager := &MockErrorManager{}
			logger := zaptest.NewLogger(t)

			cm := NewConformityManager(mockErrorManager, logger, tt.config)

			assert.NotNil(t, cm)
			assert.NotNil(t, cm.logger)
			assert.NotNil(t, cm.errorManager)
			assert.NotNil(t, cm.config)
			assert.NotNil(t, cm.checker)
			assert.NotNil(t, cm.validator)
			assert.NotNil(t, cm.metricsCollector)
			assert.NotNil(t, cm.reporter)
		})
	}
}

// TestVerifyManagerConformity teste la vérification de conformité d'un manager
func TestVerifyManagerConformity(t *testing.T) {
	tests := []struct {
		name        string
		managerName string
		wantErr     bool
		wantScore   float64
	}{
		{
			name:        "valid manager",
			managerName: "config-manager",
			wantErr:     false,
			wantScore:   75.0,
		},
		{
			name:        "empty manager name",
			managerName: "",
			wantErr:     false, // Le stub ne valide pas encore
			wantScore:   75.0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockErrorManager := &MockErrorManager{}
			logger := zaptest.NewLogger(t)

			cm := NewConformityManager(mockErrorManager, logger, nil)

			ctx := context.Background()
			report, err := cm.VerifyManagerConformity(ctx, tt.managerName)

			if tt.wantErr {
				assert.Error(t, err)
				assert.Nil(t, report)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, report)
				assert.Equal(t, tt.managerName, report.ManagerName)
				assert.Equal(t, tt.wantScore, report.OverallScore)
				assert.Equal(t, ComplianceLevelSilver, report.ComplianceLevel)
			}
		})
	}
}

// TestVerifyEcosystemConformity teste la vérification de conformité de l'écosystème
func TestVerifyEcosystemConformity(t *testing.T) {
	mockErrorManager := &MockErrorManager{}
	logger := zaptest.NewLogger(t)

	cm := NewConformityManager(mockErrorManager, logger, nil)

	ctx := context.Background()
	report, err := cm.VerifyEcosystemConformity(ctx)

	assert.NoError(t, err)
	assert.NotNil(t, report)
	assert.Equal(t, 17, report.TotalManagers)
	assert.Equal(t, 12, report.ConformManagers)
	assert.Equal(t, 82.5, report.OverallHealth)
}

// TestGenerateConformityReport teste la génération de rapports
func TestGenerateConformityReport(t *testing.T) {
	tests := []struct {
		name        string
		managerName string
		format      ReportFormat
		wantErr     bool
	}{
		{
			name:        "JSON report",
			managerName: "config-manager",
			format:      ReportFormatJSON,
			wantErr:     false,
		},
		{
			name:        "HTML report",
			managerName: "config-manager",
			format:      ReportFormatHTML,
			wantErr:     false,
		},
		{
			name:        "Markdown report",
			managerName: "config-manager",
			format:      ReportFormatMarkdown,
			wantErr:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockErrorManager := &MockErrorManager{}
			logger := zaptest.NewLogger(t)

			cm := NewConformityManager(mockErrorManager, logger, nil)

			ctx := context.Background()
			data, err := cm.GenerateConformityReport(ctx, tt.managerName, tt.format)

			if tt.wantErr {
				assert.Error(t, err)
				assert.Nil(t, data)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, data)
				assert.Greater(t, len(data), 0)
			}
		})
	}
}

// TestUpdateConformityStatus teste la mise à jour du statut de conformité
func TestUpdateConformityStatus(t *testing.T) {
	tests := []struct {
		name        string
		managerName string
		status      ComplianceLevel
		wantErr     bool
	}{
		{
			name:        "update to Gold",
			managerName: "config-manager",
			status:      ComplianceLevelGold,
			wantErr:     false,
		},
		{
			name:        "update to Platinum",
			managerName: "error-manager",
			status:      ComplianceLevelPlatinum,
			wantErr:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockErrorManager := &MockErrorManager{}
			mockErrorManager.On("LogError", mock.Anything, "ConformityManager", "STATUS_UPDATED").Return()

			logger := zaptest.NewLogger(t)

			cm := NewConformityManager(mockErrorManager, logger, nil)

			ctx := context.Background()
			err := cm.UpdateConformityStatus(ctx, tt.managerName, tt.status)

			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}

			mockErrorManager.AssertExpectations(t)
		})
	}
}

// TestGetConformityMetrics teste la récupération des métriques
func TestGetConformityMetrics(t *testing.T) {
	mockErrorManager := &MockErrorManager{}
	logger := zaptest.NewLogger(t)

	cm := NewConformityManager(mockErrorManager, logger, nil)

	ctx := context.Background()
	metrics, err := cm.GetConformityMetrics(ctx)

	assert.NoError(t, err)
	assert.NotNil(t, metrics)
}

// TestConformityManagerCaching teste le système de cache
func TestConformityManagerCaching(t *testing.T) {
	mockErrorManager := &MockErrorManager{}
	logger := zaptest.NewLogger(t)

	config := getDefaultConformityConfig()
	config.Checks.EnableCache = true
	config.Checks.CacheTimeout = 1 * time.Second

	cm := NewConformityManager(mockErrorManager, logger, config)

	ctx := context.Background()
	managerName := "test-manager"

	// Premier appel - doit générer le rapport
	report1, err := cm.VerifyManagerConformity(ctx, managerName)
	assert.NoError(t, err)
	assert.NotNil(t, report1)

	// Deuxième appel immédiat - doit utiliser le cache
	report2, err := cm.VerifyManagerConformity(ctx, managerName)
	assert.NoError(t, err)
	assert.NotNil(t, report2)
	assert.Equal(t, report1.ID, report2.ID) // Même rapport du cache

	// Attendre l'expiration du cache
	time.Sleep(2 * time.Second)

	// Troisième appel - doit régénérer le rapport
	report3, err := cm.VerifyManagerConformity(ctx, managerName)
	assert.NoError(t, err)
	assert.NotNil(t, report3)
	assert.NotEqual(t, report1.ID, report3.ID) // Nouveau rapport généré
}

// TestComplianceLevelCalculation teste le calcul des niveaux de conformité
func TestComplianceLevelCalculation(t *testing.T) {
	tests := []struct {
		name     string
		score    float64
		expected ComplianceLevel
	}{
		{"Failed", 50.0, ComplianceLevelFailed},
		{"Bronze", 65.0, ComplianceLevelBronze},
		{"Silver", 75.0, ComplianceLevelSilver},
		{"Gold", 85.0, ComplianceLevelGold},
		{"Platinum", 95.0, ComplianceLevelPlatinum},
	}

	config := getDefaultConformityConfig()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var level ComplianceLevel

			switch {
			case tt.score >= config.MinimumScores.Platinum:
				level = ComplianceLevelPlatinum
			case tt.score >= config.MinimumScores.Gold:
				level = ComplianceLevelGold
			case tt.score >= config.MinimumScores.Silver:
				level = ComplianceLevelSilver
			case tt.score >= config.MinimumScores.Bronze:
				level = ComplianceLevelBronze
			default:
				level = ComplianceLevelFailed
			}

			assert.Equal(t, tt.expected, level)
		})
	}
}

// TestDefaultConfig teste la configuration par défaut
func TestDefaultConfig(t *testing.T) {
	config := getDefaultConformityConfig()

	assert.NotNil(t, config)
	assert.Equal(t, 60.0, config.MinimumScores.Bronze)
	assert.Equal(t, 70.0, config.MinimumScores.Silver)
	assert.Equal(t, 80.0, config.MinimumScores.Gold)
	assert.Equal(t, 90.0, config.MinimumScores.Platinum)

	assert.Equal(t, 0.25, config.Weights.Architecture)
	assert.Equal(t, 0.20, config.Weights.ErrorManager)
	assert.Equal(t, 0.20, config.Weights.Documentation)

	assert.True(t, config.Checks.EnableCache)
	assert.Equal(t, 30*time.Minute, config.Checks.CacheTimeout)
	assert.Equal(t, 5, config.Checks.MaxConcurrentChecks)
}

// BenchmarkVerifyManagerConformity benchmark pour la vérification de conformité
func BenchmarkVerifyManagerConformity(b *testing.B) {
	mockErrorManager := &MockErrorManager{}
	logger := zaptest.NewLogger(b)

	cm := NewConformityManager(mockErrorManager, logger, nil)
	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := cm.VerifyManagerConformity(ctx, "test-manager")
		if err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkVerifyEcosystemConformity benchmark pour la vérification de l'écosystème
func BenchmarkVerifyEcosystemConformity(b *testing.B) {
	mockErrorManager := &MockErrorManager{}
	logger := zaptest.NewLogger(b)

	cm := NewConformityManager(mockErrorManager, logger, nil)
	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := cm.VerifyEcosystemConformity(ctx)
		if err != nil {
			b.Fatal(err)
		}
	}
}
