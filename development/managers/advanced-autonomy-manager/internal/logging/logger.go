// Package logging provides logging capabilities for the AdvancedAutonomyManager
package logging

import (
	"fmt"
	"os"
	"time"
)

// LogLevel defines the severity of a log message
type LogLevel int

const (
	// DEBUG is used for detailed diagnostic information
	DEBUG LogLevel = iota
	// INFO is used for general operational information
	INFO
	// WARN is used for potential issues that may not require immediate attention
	WARN
	// ERROR is used for issues that require attention
	ERROR
	// FATAL is used for critical issues that prevent the application from functioning
	FATAL
)

// String returns the string representation of a log level
func (l LogLevel) String() string {
	switch l {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	case FATAL:
		return "FATAL"
	default:
		return "UNKNOWN"
	}
}

// Logger provides logging functionality
type Logger struct {
	minLevel LogLevel
}

// NewLogger creates a new logger with the specified minimum log level
func NewLogger(minLevel LogLevel) *Logger {
	return &Logger{
		minLevel: minLevel,
	}
}

// log writes a log message with the specified level
func (l *Logger) log(level LogLevel, msg string, keyvals ...interface{}) {
	if level < l.minLevel {
		return
	}

	timestamp := time.Now().Format("2006-01-02T15:04:05.000")
	prefix := fmt.Sprintf("%s [%s] ", timestamp, level.String())

	var kvs string
	if len(keyvals) > 0 {
		kvs = " "
		for i := 0; i < len(keyvals); i += 2 {
			key := fmt.Sprintf("%v", keyvals[i])
			if i+1 < len(keyvals) {
				value := fmt.Sprintf("%v", keyvals[i+1])
				kvs += fmt.Sprintf("%s=%s ", key, value)
			} else {
				kvs += fmt.Sprintf("%s=? ", key)
			}
		}
	}

	fmt.Fprintf(os.Stdout, "%s%s%s\n", prefix, msg, kvs)
	if level == FATAL {
		os.Exit(1)
	}
}

// Debug logs a debug message
func (l *Logger) Debug(msg string, keyvals ...interface{}) {
	l.log(DEBUG, msg, keyvals...)
}

// Info logs an informational message
func (l *Logger) Info(msg string, keyvals ...interface{}) {
	l.log(INFO, msg, keyvals...)
}

// Warn logs a warning message
func (l *Logger) Warn(msg string, keyvals ...interface{}) {
	l.log(WARN, msg, keyvals...)
}

// Error logs an error message
func (l *Logger) Error(msg string, keyvals ...interface{}) {
	l.log(ERROR, msg, keyvals...)
}

// Fatal logs a fatal message and exits the application
func (l *Logger) Fatal(msg string, keyvals ...interface{}) {
	l.log(FATAL, msg, keyvals...)
}
