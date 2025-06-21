package conflict

import (
	"go.uber.org/zap"
)

var logger, _ = zap.NewProduction()

// LogStructured logs a structured message.
func LogStructured(msg string, fields ...zap.Field) {
	logger.Info(msg, fields...)
}
