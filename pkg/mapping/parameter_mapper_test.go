package mapping

import (
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

func TestParameterMapper_MapN8NParameters(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	tests := []struct {
		name     string
		params   map[string]interface{}
		expected *MappingResult
	}{
		{
			name: "Basic string parameter",
			params: map[string]interface{}{
				"template": "welcome-email",
			},
			expected: &MappingResult{
				Arguments:   []string{"--template", "welcome-email"},
				Environment: map[string]string{},
				InputData:   map[string]interface{}{"template": "welcome-email"},
				Errors:      []string{},
				Warnings:    []string{},
			},
		},
		{
			name: "Number parameter",
			params: map[string]interface{}{
				"batchSize": 50,
			},
			expected: &MappingResult{
				Arguments:   []string{"--batch-size", "50"},
				Environment: map[string]string{},
				InputData:   map[string]interface{}{"batchSize": 50},
				Errors:      []string{},
				Warnings:    []string{},
			},
		},
		{
			name: "Boolean parameter",
			params: map[string]interface{}{
				"enableRetry": true,
			},
			expected: &MappingResult{
				Arguments:   []string{"--enable-retry", "true"},
				Environment: map[string]string{},
				InputData:   map[string]interface{}{"enableRetry": true},
				Errors:      []string{},
				Warnings:    []string{},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := mapper.MapN8NParameters(tt.params)
			require.NoError(t, err)

			assert.Equal(t, tt.expected.Arguments, result.Arguments)
			assert.Equal(t, tt.expected.Environment, result.Environment)
			assert.Equal(t, tt.expected.InputData, result.InputData)
			assert.Empty(t, result.Errors)
		})
	}
}

func TestParameterMapper_SensitiveParameterHandling(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	// Test sensitive parameter detection
	params := map[string]interface{}{
		"apiKey":      "secret123",
		"password":    "mypassword",
		"normalParam": "normalvalue",
	}

	result, err := mapper.MapN8NParameters(params)
	require.NoError(t, err)

	// API key should be mapped to environment variable
	assert.Contains(t, result.Environment, "APIKEY")
	assert.Equal(t, "secret123", result.Environment["APIKEY"])

	// Password should be mapped to environment variable
	assert.Contains(t, result.Environment, "PASSWORD")
	assert.Equal(t, "mypassword", result.Environment["PASSWORD"])

	// Normal parameter should be in arguments
	assert.Contains(t, result.Arguments, "--normal-param")
	assert.Contains(t, result.Arguments, "normalvalue")

	// Should have warnings about sensitive parameters
	assert.Contains(t, result.Warnings, "Credential apiKey mapped to environment variable APIKEY")
	assert.Contains(t, result.Warnings, "Credential password mapped to environment variable PASSWORD")
}

func TestParameterMapper_ParameterValidation(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	tests := []struct {
		name      string
		param     Parameter
		expectErr bool
	}{
		{
			name: "Valid string parameter",
			param: Parameter{
				Name:  "test",
				Type:  ParameterTypeString,
				Value: "hello",
				Validation: &Validation{
					MinLength: intPtr(1),
					MaxLength: intPtr(10),
				},
			},
			expectErr: false,
		},
		{
			name: "String too short",
			param: Parameter{
				Name:  "test",
				Type:  ParameterTypeString,
				Value: "",
				Validation: &Validation{
					MinLength: intPtr(1),
				},
			},
			expectErr: true,
		},
		{
			name: "String too long",
			param: Parameter{
				Name:  "test",
				Type:  ParameterTypeString,
				Value: "this string is way too long",
				Validation: &Validation{
					MaxLength: intPtr(5),
				},
			},
			expectErr: true,
		},
		{
			name: "Valid number parameter",
			param: Parameter{
				Name:  "test",
				Type:  ParameterTypeNumber,
				Value: 50.0,
				Validation: &Validation{
					MinValue: float64Ptr(0),
					MaxValue: float64Ptr(100),
				},
			},
			expectErr: false,
		},
		{
			name: "Number too small",
			param: Parameter{
				Name:  "test",
				Type:  ParameterTypeNumber,
				Value: -5.0,
				Validation: &Validation{
					MinValue: float64Ptr(0),
				},
			},
			expectErr: true,
		},
		{
			name: "Number too large",
			param: Parameter{
				Name:  "test",
				Type:  ParameterTypeNumber,
				Value: 150.0,
				Validation: &Validation{
					MaxValue: float64Ptr(100),
				},
			},
			expectErr: true,
		},
		{
			name: "Required parameter missing",
			param: Parameter{
				Name:     "test",
				Type:     ParameterTypeString,
				Value:    nil,
				Required: true,
			},
			expectErr: true,
		},
		{
			name: "Optional parameter missing",
			param: Parameter{
				Name:     "test",
				Type:     ParameterTypeString,
				Value:    nil,
				Required: false,
			},
			expectErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := mapper.validateParameter(&tt.param)
			if tt.expectErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestParameterMapper_TypeInference(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	tests := []struct {
		name     string
		value    interface{}
		expected ParameterType
	}{
		{"String", "hello", ParameterTypeString},
		{"Number int", 42, ParameterTypeNumber},
		{"Number float", 42.5, ParameterTypeNumber},
		{"Boolean true", true, ParameterTypeBoolean},
		{"Boolean false", false, ParameterTypeBoolean},
		{"Array", []interface{}{1, 2, 3}, ParameterTypeArray},
		{"Object", map[string]interface{}{"key": "value"}, ParameterTypeObject},
		{"File path", "/path/to/file.json", ParameterTypeFile},
		{"Windows path", "C:\\path\\to\\file.yml", ParameterTypeFile},
		{"Credential password", "mypassword123", ParameterTypeCredential},
		{"Credential secret", "mysecretkey", ParameterTypeCredential},
		{"Credential token", "bearer-token", ParameterTypeCredential},
		{"Date", time.Now(), ParameterTypeDate},
		{"Nil", nil, ParameterTypeString},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := mapper.inferParameterType(tt.value)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestParameterMapper_ConvertToString(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	tests := []struct {
		name      string
		value     interface{}
		paramType ParameterType
		expected  string
		expectErr bool
	}{
		{"String", "hello", ParameterTypeString, "hello", false},
		{"Number int", 42, ParameterTypeNumber, "42", false},
		{"Number float", 42.5, ParameterTypeNumber, "42.5", false},
		{"Boolean true", true, ParameterTypeBoolean, "true", false},
		{"Boolean false", false, ParameterTypeBoolean, "false", false},
		{"Array", []string{"a", "b"}, ParameterTypeArray, `["a","b"]`, false},
		{"Object", map[string]string{"key": "value"}, ParameterTypeObject, `{"key":"value"}`, false},
		{"Date", time.Date(2025, 6, 19, 12, 0, 0, 0, time.UTC), ParameterTypeDate, "2025-06-19T12:00:00Z", false},
		{"Nil", nil, ParameterTypeString, "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := mapper.convertToString(tt.value, tt.paramType)
			if tt.expectErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, tt.expected, result)
			}
		})
	}
}

func TestParameterMapper_SecurityTests(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	// Test sensitive key detection
	sensitiveKeys := []string{
		"password", "secret", "token", "key", "credential",
		"auth", "api_key", "access_token", "private",
	}

	for _, key := range sensitiveKeys {
		t.Run("Sensitive key: "+key, func(t *testing.T) {
			assert.True(t, mapper.isSensitiveKey(key))
			assert.True(t, mapper.isSensitiveKey(strings.ToUpper(key)))
			assert.True(t, mapper.isSensitiveKey("prefix_"+key))
			assert.True(t, mapper.isSensitiveKey(key+"_suffix"))
		})
	}

	// Test non-sensitive keys
	nonSensitiveKeys := []string{
		"username", "email", "name", "id", "count", "template",
	}

	for _, key := range nonSensitiveKeys {
		t.Run("Non-sensitive key: "+key, func(t *testing.T) {
			assert.False(t, mapper.isSensitiveKey(key))
		})
	}
}

func TestParameterMapper_MaskValue(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	tests := []struct {
		name     string
		value    string
		expected string
	}{
		{"Short value", "abc", "****"},
		{"Medium value", "password", "pa****rd"},
		{"Long value", "verylongpassword", "ve****rd"},
		{"Empty value", "", "****"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := mapper.maskValue(tt.value)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestParameterMapper_FormatArgumentName(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{"camelCase", "camelCase", "camel-case"},
		{"PascalCase", "PascalCase", "pascal-case"},
		{"snake_case", "snake_case", "snake_case"},
		{"lowercase", "lowercase", "lowercase"},
		{"UPPERCASE", "UPPERCASE", "u-p-p-e-r-c-a-s-e"},
		{"mixedCASE", "mixedCASE", "mixed-c-a-s-e"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := mapper.formatArgumentName(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestParameterMapper_BuildCommandLine(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	result := &MappingResult{
		Arguments: []string{"--template", "welcome", "--count", "50"},
	}

	cmdLine := mapper.BuildCommandLine("/usr/bin/cli", "email-send", result)

	expected := []string{"/usr/bin/cli", "execute", "email-send", "--template", "welcome", "--count", "50"}
	assert.Equal(t, expected, cmdLine)
}

func TestParameterMapper_BuildEnvironment(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	baseEnv := map[string]string{
		"PATH": "/usr/bin",
		"HOME": "/home/user",
	}

	result := &MappingResult{
		Environment: map[string]string{
			"API_KEY": "secret123",
			"TOKEN":   "bearer-token",
		},
	}

	env := mapper.BuildEnvironment(result, baseEnv)

	expected := map[string]string{
		"PATH":    "/usr/bin",
		"HOME":    "/home/user",
		"API_KEY": "secret123",
		"TOKEN":   "bearer-token",
	}

	assert.Equal(t, expected, env)
}

func TestParameterMapper_EncryptionHandling(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	// Test without encryption key
	params := map[string]interface{}{
		"password": "secret123",
	}

	result, err := mapper.MapN8NParameters(params)
	require.NoError(t, err)

	assert.Equal(t, "secret123", result.Environment["PASSWORD"])
	assert.Contains(t, result.Warnings, "Sensitive parameter password processed without encryption")

	// Test with encryption key
	mapper.SetEncryptionKey([]byte("encryption-key-32-bytes-length"))

	result, err = mapper.MapN8NParameters(params)
	require.NoError(t, err)

	assert.Contains(t, result.Environment["PASSWORD"], "encrypted:")
	assert.Contains(t, result.Warnings, "Parameter password was encrypted")
}

func TestParameterMapper_CustomSensitiveKeys(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	// Set custom sensitive keys
	mapper.SetSensitiveKeys([]string{"customSecret", "internalKey"})

	params := map[string]interface{}{
		"customSecret": "value1",
		"internalKey":  "value2",
		"normalParam":  "value3",
		"password":     "value4", // Should still be detected as sensitive
	}

	result, err := mapper.MapN8NParameters(params)
	require.NoError(t, err)

	// Custom sensitive keys should be in environment
	assert.Contains(t, result.Environment, "CUSTOMSECRET")
	assert.Contains(t, result.Environment, "INTERNALKEY")
	assert.Contains(t, result.Environment, "PASSWORD")

	// Normal parameter should be in arguments
	assert.Contains(t, result.Arguments, "--normal-param")
}

// Security test for parameter injection
func TestParameterMapper_SecurityParameterInjection(t *testing.T) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	// Test potential injection attempts
	maliciousParams := map[string]interface{}{
		"command":  "; rm -rf /",                    // Command injection
		"filename": "../../../etc/passwd",           // Path traversal
		"script":   "<script>alert('xss')</script>", // XSS
		"sql":      "'; DROP TABLE users; --",       // SQL injection
	}

	result, err := mapper.MapN8NParameters(maliciousParams)
	require.NoError(t, err)

	// Parameters should be properly escaped in arguments
	assert.Contains(t, result.Arguments, "--command")
	assert.Contains(t, result.Arguments, "; rm -rf /")
	assert.Contains(t, result.Arguments, "--filename")
	assert.Contains(t, result.Arguments, "../../../etc/passwd")

	// Values should be in InputData for JSON processing
	assert.Equal(t, "; rm -rf /", result.InputData["command"])
	assert.Equal(t, "../../../etc/passwd", result.InputData["filename"])
}

// Benchmark tests
func BenchmarkParameterMapper_MapN8NParameters(b *testing.B) {
	logger := zap.NewNop()
	mapper := NewParameterMapper(logger)

	params := map[string]interface{}{
		"template":    "welcome-email",
		"batchSize":   50,
		"enableRetry": true,
		"apiKey":      "secret123",
		"timeout":     30.5,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := mapper.MapN8NParameters(params)
		if err != nil {
			b.Fatal(err)
		}
	}
}

// Helper functions
func intPtr(i int) *int {
	return &i
}

func float64Ptr(f float64) *float64 {
	return &f
}
