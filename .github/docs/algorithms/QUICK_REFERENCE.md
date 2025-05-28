# 📚 EMAIL_SENDER_1 Algorithms - Quick Reference

## 🚀 **Native Go Orchestrator Commands**

### **Main Orchestrator**
```bash
# Run all algorithms in sequence
go run email_sender_orchestrator.go

# Run specific algorithm
go run email_sender_orchestrator.go -algorithm <algorithm-name>

# Custom configuration
go run email_sender_orchestrator.go -config <config-file>

# Verbose output
go run email_sender_orchestrator.go -verbose
```

### **Individual Algorithm Commands**
```bash
# Algorithm implementations wrapper
go run algorithms_implementations.go <algorithm> <project_path> [options]
```

## 🎯 **Algorithm Reference**

| ID | Algorithm | Command | Purpose |
|---|---|---|---|
| 1 | **error-triage** | `go run algorithms_implementations.go error-triage /path/to/project` | Multi-stack error classification |
| 2 | **binary-search** | `go run algorithms_implementations.go binary-search /path/to/project` | Component failure isolation |
| 3 | **dependency-analysis** | `go run algorithms_implementations.go dependency-analysis /path/to/project` | Circular dependency detection |
| 4 | **progressive-build** | `go run algorithms_implementations.go progressive-build /path/to/project` | Incremental build strategy |
| 5 | **auto-fix** | `go run algorithms_implementations.go auto-fix /path/to/project` | Automated error correction |
| 6 | **analysis-pipeline** | `go run algorithms_implementations.go analysis-pipeline /path/to/project` | Static analysis pipeline |
| 7 | **config-validator** | `go run algorithms_implementations.go config-validator /path/to/project` | Configuration validation |
| 8 | **dependency-resolution** | `go run algorithms_implementations.go dependency-resolution /path/to/project [output.json]` | Dependency conflict resolution |

## 🔧 **Configuration Files**

- **Main Config**: `email_sender_orchestrator_config.json` - Complete orchestrator configuration
- **Test Config**: `test_config.json` - Test environment configuration
- **Go Module**: `go.mod` - Dependencies and module definition

## 📁 **Directory Structure**

```
algorithms/
├── email_sender_orchestrator.go      # Main native Go orchestrator
├── algorithms_implementations.go     # Algorithm wrappers
├── email_sender_orchestrator_config.json # Configuration
├── go.mod                            # Go module
├── shared/                           # Shared libraries
│   ├── types.go                      # Common types
│   └── utils.go                      # Utilities
├── error-triage/                     # Algorithm 1
├── binary-search/                    # Algorithm 2
├── dependency-analysis/              # Algorithm 3
├── progressive-build/                # Algorithm 4
├── auto-fix/                         # Algorithm 5
├── analysis-pipeline/                # Algorithm 6
├── config-validator/                 # Algorithm 7
└── dependency-resolution/            # Algorithm 8
```

## ⚡ **Performance Features**

- **Native Go**: 10x faster than PowerShell orchestration
- **Concurrent Execution**: Parallel algorithm processing
- **Memory Efficient**: Optimized data structures
- **Cross-Platform**: Windows, Linux, macOS support
- **Zero External Dependencies**: Pure Go implementation

## 🧪 **Testing**

```bash
# Run test suite
go run test_main.go

# Test specific algorithm
go test ./error-triage/
go test ./dependency-resolution/

# Build all modules
go mod tidy && go build ./...
```

## 🎯 **EMAIL_SENDER_1 Specific Features**

### **Component Priority Scoring**
- **RAG_Engine**: Priority 9 (Critical)
- **N8N_Workflows**: Priority 8 (High)
- **Gmail_Processing**: Priority 7 (Important)
- **Standard Components**: Priority 5 (Normal)

### **Multi-Language Support**
- Go modules and dependencies
- Native Go orchestration (PowerShell eliminated)
- JavaScript/N8N workflow dependencies
- Configuration file validation (JSON, YAML, ENV)

## 🔍 **Common Use Cases**

### **Debug Session**
```bash
# 1. Start with error triage
go run algorithms_implementations.go error-triage ./

# 2. If components fail, use binary search
go run algorithms_implementations.go binary-search ./

# 3. Check dependencies
go run algorithms_implementations.go dependency-analysis ./

# 4. Resolve conflicts
go run algorithms_implementations.go dependency-resolution ./
```

### **Pre-Deployment Validation**
```bash
# Complete validation pipeline
go run email_sender_orchestrator.go

# Or step by step
go run algorithms_implementations.go config-validator ./
go run algorithms_implementations.go analysis-pipeline ./
go run algorithms_implementations.go dependency-resolution ./
```

## 📊 **Output Formats**

- **JSON**: Structured data for automation
- **Console**: Human-readable output
- **Reports**: Detailed analysis files
- **Health Scores**: 0-100 scoring system

## 🆘 **Troubleshooting**

### **Common Issues**
- **"Algorithm not found"**: Check algorithm ID spelling
- **"Project path not found"**: Ensure valid project directory
- **"Config file error"**: Validate JSON syntax
- **"Go build errors"**: Run `go mod tidy`

### **Debug Mode**
```bash
go run email_sender_orchestrator.go -verbose -algorithm <name>
```
