package converters

import (
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

func TestN8NToGoConverter_Convert(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling:   NullHandlingDefault,
		TypeValidation: true,
	})

	tests := []struct {
		name     string
		input    N8NData
		expected int
		wantErr  bool
	}{
		{
			name: "Simple string conversion",
			input: N8NData{
				{
					JSON: map[string]interface{}{
						"message": "Hello World",
						"count":   42,
						"active":  true,
					},
				},
			},
			expected: 1,
			wantErr:  false,
		},
		{
			name: "Complex nested object",
			input: N8NData{
				{
					JSON: map[string]interface{}{
						"user": map[string]interface{}{
							"name":  "John Doe",
							"age":   30,
							"email": "john@example.com",
						},
						"tags": []interface{}{"tag1", "tag2", "tag3"},
					},
				},
			},
			expected: 1,
			wantErr:  false,
		},
		{
			name: "Multiple items",
			input: N8NData{
				{JSON: map[string]interface{}{"id": 1, "name": "Item 1"}},
				{JSON: map[string]interface{}{"id": 2, "name": "Item 2"}},
				{JSON: map[string]interface{}{"id": 3, "name": "Item 3"}},
			},
			expected: 3,
			wantErr:  false,
		},
		{
			name:     "Empty input",
			input:    N8NData{},
			expected: 0,
			wantErr:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := converter.Convert(tt.input)
			if tt.wantErr {
				assert.Error(t, err)
				return
			}

			require.NoError(t, err)
			assert.Equal(t, tt.expected, len(result.Data))
			assert.Equal(t, len(tt.input), result.Metadata.ItemCount)
			assert.True(t, result.Metadata.ConversionTime > 0)
		})
	}
}

func TestN8NToGoConverter_TypeInference(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
	})

	tests := []struct {
		name     string
		input    interface{}
		expected interface{}
	}{
		{"String to string", "hello", "hello"},
		{"Number string to int", "42", int64(42)},
		{"Float string to float", "42.5", 42.5},
		{"Boolean string to bool", "true", true},
		{"Date string to time", "2023-01-01", mustParseTime("2006-01-02", "2023-01-01")},
		{"RFC3339 string to time", "2023-01-01T12:00:00Z", mustParseTime(time.RFC3339, "2023-01-01T12:00:00Z")},
		{"Integer", 42, int64(42)},
		{"Float", 42.5, 42.5},
		{"Boolean", true, true},
		{"Null", nil, ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := converter.convertValue(tt.input, "test", 0)
			require.NoError(t, err)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestN8NToGoConverter_ArrayConversion(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
	})

	input := N8NData{
		{
			JSON: map[string]interface{}{
				"numbers": []interface{}{1, 2, 3, 4, 5},
				"strings": []interface{}{"a", "b", "c"},
				"mixed":   []interface{}{1, "hello", true, 3.14},
				"nested": []interface{}{
					map[string]interface{}{"id": 1, "name": "Item 1"},
					map[string]interface{}{"id": 2, "name": "Item 2"},
				},
			},
		},
	}

	result, err := converter.Convert(input)
	require.NoError(t, err)
	assert.Equal(t, 1, len(result.Data))

	fields := result.Data[0].Fields
	assert.Contains(t, fields, "numbers")
	assert.Contains(t, fields, "strings")
	assert.Contains(t, fields, "mixed")
	assert.Contains(t, fields, "nested")

	// Check array types
	numbers, ok := fields["numbers"].([]interface{})
	assert.True(t, ok)
	assert.Equal(t, 5, len(numbers))

	nested, ok := fields["nested"].([]interface{})
	assert.True(t, ok)
	assert.Equal(t, 2, len(nested))
}

func TestN8NToGoConverter_BinaryDataHandling(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
	})

	input := N8NData{
		{
			JSON: map[string]interface{}{
				"message": "Hello World",
			},
			Binary: map[string]interface{}{
				"file1": map[string]interface{}{
					"fileName": "test.txt",
					"mimeType": "text/plain",
					"fileSize": 1024,
					"data":     "base64encodeddata",
				},
			},
		},
	}

	result, err := converter.Convert(input)
	require.NoError(t, err)
	assert.Equal(t, 1, len(result.Data))

	fields := result.Data[0].Fields
	assert.Contains(t, fields, "_binary")

	binaryData, ok := fields["_binary"].(map[string]interface{})
	assert.True(t, ok)
	assert.Contains(t, binaryData, "file1")

	file1, ok := binaryData["file1"].(map[string]interface{})
	assert.True(t, ok)
	assert.Equal(t, "test.txt", file1["file_name"])
	assert.Equal(t, "text/plain", file1["mime_type"])
	assert.Equal(t, 1024, file1["file_size"])
	assert.Equal(t, true, file1["has_data"])
}

func TestN8NToGoConverter_NullHandling(t *testing.T) {
	logger := zap.NewNop()

	tests := []struct {
		name         string
		nullStrategy NullHandlingStrategy
		input        interface{}
		expectError  bool
		expected     interface{}
	}{
		{
			name:         "Skip null values",
			nullStrategy: NullHandlingSkip,
			input:        nil,
			expectError:  false,
			expected:     nil,
		},
		{
			name:         "Default null values",
			nullStrategy: NullHandlingDefault,
			input:        nil,
			expectError:  false,
			expected:     "",
		},
		{
			name:         "Error on null values",
			nullStrategy: NullHandlingError,
			input:        nil,
			expectError:  true,
			expected:     nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			converter := NewN8NToGoConverter(logger, ConversionOptions{
				NullHandling: tt.nullStrategy,
			})

			result, err := converter.convertValue(tt.input, "test", 0)
			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, tt.expected, result)
			}
		})
	}
}

func TestN8NToGoConverter_DeepNesting(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
	})

	// Create deeply nested object
	deepObject := map[string]interface{}{
		"level1": map[string]interface{}{
			"level2": map[string]interface{}{
				"level3": map[string]interface{}{
					"level4": map[string]interface{}{
						"level5": map[string]interface{}{
							"value": "deep value",
						},
					},
				},
			},
		},
	}

	input := N8NData{
		{JSON: deepObject},
	}

	result, err := converter.Convert(input)
	require.NoError(t, err)
	assert.Equal(t, 1, len(result.Data))

	// Navigate to deep value
	fields := result.Data[0].Fields
	level1, ok := fields["level1"].(map[string]interface{})
	assert.True(t, ok)
	level2, ok := level1["level2"].(map[string]interface{})
	assert.True(t, ok)
	level3, ok := level2["level3"].(map[string]interface{})
	assert.True(t, ok)
	level4, ok := level3["level4"].(map[string]interface{})
	assert.True(t, ok)
	level5, ok := level4["level5"].(map[string]interface{})
	assert.True(t, ok)
	assert.Equal(t, "deep value", level5["value"])
}

func TestN8NToGoConverter_JSONNumber(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
	})

	tests := []struct {
		name     string
		number   json.Number
		expected interface{}
	}{
		{"Integer JSON number", json.Number("42"), int64(42)},
		{"Float JSON number", json.Number("42.5"), 42.5},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := converter.convertJSONNumber(tt.number)
			require.NoError(t, err)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestN8NToGoConverter_Validation(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling:   NullHandlingDefault,
		TypeValidation: true,
	})

	t.Run("Valid result passes validation", func(t *testing.T) {
		result := &ConversionResult{
			Data: []GoStruct{
				{Fields: map[string]interface{}{"test": "value"}},
			},
			Metadata: Metadata{ItemCount: 1},
		}

		err := converter.ValidateConversion(result)
		assert.NoError(t, err)
	})

	t.Run("Nil result fails validation", func(t *testing.T) {
		err := converter.ValidateConversion(nil)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "nil")
	})

	t.Run("Result with errors fails validation", func(t *testing.T) {
		result := &ConversionResult{
			Errors:   []string{"error 1", "error 2"},
			Metadata: Metadata{ItemCount: 2},
		}

		err := converter.ValidateConversion(result)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "2 errors")
	})

	t.Run("No converted items fails validation", func(t *testing.T) {
		result := &ConversionResult{
			Data:     []GoStruct{},
			Metadata: Metadata{ItemCount: 5},
		}

		err := converter.ValidateConversion(result)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "no items were converted")
	})
}

func TestN8NToGoConverter_Statistics(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
	})

	result := &ConversionResult{
		Data: []GoStruct{
			{Fields: map[string]interface{}{"field1": "value1", "field2": "value2"}},
			{Fields: map[string]interface{}{"field3": "value3"}},
		},
		Errors:   []string{"error1"},
		Warnings: []string{"warning1", "warning2"},
		Metadata: Metadata{
			ItemCount:       5,
			ConversionTime:  time.Millisecond * 100,
			ConvertedFields: 3,
			SkippedFields:   []string{"skipped1"},
		},
	}

	stats := converter.GetStatistics(result)
	require.NotNil(t, stats)

	assert.Equal(t, 5, stats["input_items"])
	assert.Equal(t, 2, stats["converted_items"])
	assert.Equal(t, 40.0, stats["success_rate"]) // 2/5 * 100
	assert.Equal(t, "100ms", stats["conversion_time"])
	assert.Equal(t, 1, stats["errors"])
	assert.Equal(t, 2, stats["warnings"])
	assert.Equal(t, 3, stats["converted_fields"])
	assert.Equal(t, 1, stats["skipped_fields"])
}

func TestN8NToGoConverter_ConvertWithValidation(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling:   NullHandlingDefault,
		TypeValidation: true,
	})

	input := N8NData{
		{JSON: map[string]interface{}{"message": "Hello", "count": 42}},
	}

	result, err := converter.ConvertWithValidation(input)
	require.NoError(t, err)
	assert.Equal(t, 1, len(result.Data))
	assert.Empty(t, result.Errors)
}

func TestN8NToGoConverter_CustomTypeMapping(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
		CustomTypeMapping: map[string]string{
			"custom_string": "custom_type",
		},
	})

	assert.Equal(t, "custom_type", converter.typeMapping["custom_string"])
	assert.Equal(t, "string", converter.typeMapping["string"]) // Default mapping preserved
}

func TestN8NToGoConverter_MaxDepthProtection(t *testing.T) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
	})

	// This should trigger max depth protection
	_, err := converter.convertValue("test", "field", 11)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "maximum field depth exceeded")
}

// Benchmark tests
func BenchmarkN8NToGoConverter_Convert(b *testing.B) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
	})

	input := N8NData{
		{
			JSON: map[string]interface{}{
				"message": "Hello World",
				"count":   42,
				"active":  true,
				"user": map[string]interface{}{
					"name":  "John Doe",
					"email": "john@example.com",
				},
				"tags": []interface{}{"tag1", "tag2", "tag3"},
			},
		},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := converter.Convert(input)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkN8NToGoConverter_LargeArray(b *testing.B) {
	logger := zap.NewNop()
	converter := NewN8NToGoConverter(logger, ConversionOptions{
		NullHandling: NullHandlingDefault,
	})

	// Create large array
	largeArray := make([]interface{}, 1000)
	for i := 0; i < 1000; i++ {
		largeArray[i] = map[string]interface{}{
			"id":   i,
			"name": fmt.Sprintf("Item %d", i),
			"data": []interface{}{i, i * 2, i * 3},
		}
	}

	input := N8NData{
		{JSON: map[string]interface{}{"items": largeArray}},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := converter.Convert(input)
		if err != nil {
			b.Fatal(err)
		}
	}
}

// Helper function
func mustParseTime(layout, value string) time.Time {
	t, err := time.Parse(layout, value)
	if err != nil {
		panic(err)
	}
	return t
}
