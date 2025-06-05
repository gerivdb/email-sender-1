# DependencyManager Manager Integrations

This document explains how the DependencyManager integrates with other managers in the system to provide enhanced capabilities.

## 1. Integrated Managers

The DependencyManager can integrate with five specialized managers:

1. **SecurityManager**: For vulnerability scanning and security credential management
2. **MonitoringManager**: For operation performance monitoring and alerts
3. **StorageManager**: For persistence of dependency metadata
4. **ContainerManager**: For container compatibility validation and optimization
5. **DeploymentManager**: For deployment readiness validation

## 2. Integration Features

### 2.1 Security Integration

The SecurityManager integration enhances the security capabilities of the DependencyManager:

- **Enhanced Vulnerability Scanning**: More detailed vulnerability checks than the basic Go tooling
- **Private Registry Authentication**: Secure handling of credentials for private module repositories
- **Security Policy Enforcement**: Enforces security policies for dependencies
- **CVE Database Integration**: Access to comprehensive vulnerability databases

**Usage Example**:
```bash
dependency-manager audit --enhanced
```

### 2.2 Monitoring Integration

The MonitoringManager integration provides operational insights:

- **Operation Performance Tracking**: Measures and logs the performance of dependency operations
- **Alert Configuration**: Set up alerts for various events like dependency resolution failures
- **Operation Metrics Collection**: Collects metrics for dependency operations
- **Dependency Operation Anomaly Detection**: Identifies unusual behavior in dependency operations

**Usage Example**:
```bash
dependency-manager add --module github.com/pkg/errors --version v0.9.1 --monitor
dependency-manager update --module github.com/gorilla/mux --monitor
```

### 2.3 Storage Integration

The StorageManager integration provides metadata persistence:

- **Dependency Metadata Storage**: Persists comprehensive metadata about dependencies
- **Metadata Query Capabilities**: Query and retrieve metadata for dependencies
- **Historical Data Tracking**: Track changes to dependencies over time
- **Metadata Synchronization**: Synchronize metadata with external systems

**Usage Example**:
```bash
dependency-manager metadata
dependency-manager list --enhanced
```

### 2.4 Container Integration

The ContainerManager integration provides container compatibility features:

- **Container Compatibility Validation**: Checks if dependencies are compatible with containerized environments
- **Dependency Optimization for Containers**: Optimizes dependencies for container environments
- **Dockerfile Generation**: Generates container definitions based on dependencies
- **Container Build Size Estimation**: Estimates the size of container images

**Usage Example**:
```bash
dependency-manager container
```

### 2.5 Deployment Integration

The DeploymentManager integration provides deployment readiness features:

- **Deployment Compatibility Check**: Validates if dependencies are compatible with target environments
- **Deployment Artifact Metadata**: Generates metadata for deployment artifacts
- **Environment-specific Validation**: Different validations for different environments
- **Lockfile Export**: Creates deployment-specific lockfiles

**Usage Example**:
```bash
dependency-manager deployment --env production
```

## 3. CLI Commands

The following CLI commands leverage the manager integrations:

| Command | Description | Managers Used |
|---------|-------------|--------------|
| `list --enhanced` | Lists dependencies with enhanced metadata | StorageManager |
| `add --monitor` | Adds dependency with performance monitoring | MonitoringManager |
| `update --monitor` | Updates dependency with performance monitoring | MonitoringManager |
| `audit --enhanced` | Enhanced vulnerability scanning | SecurityManager |
| `container` | Container compatibility validation | ContainerManager |
| `deployment` | Deployment readiness validation | DeploymentManager |
| `health` | Health check of all integrated managers | All |
| `metadata` | Synchronize dependency metadata | StorageManager |

## 4. Integration Setup

To initialize all manager integrations:

```bash
dependency-manager --init-managers
```

This will set up connections to all available managers in the system.

## 5. Error Handling

When an integration is not available, the DependencyManager gracefully falls back to basic functionality. Error messages will indicate which manager was unavailable.

## 6. Configuration

Manager integrations can be configured in the `dependency-manager.config.json` file:

```json
{
  "name": "dependency-manager",
  "version": "1.0.0",
  "settings": {
    "logPath": "logs/dependency-manager.log",
    "logLevel": "info",
    "goModPath": "go.mod",
    "autoTidy": true,
    "vulnerabilityCheck": true,
    "backupOnChange": true,
    "integrations": {
      "security": {
        "enabled": true,
        "endpoint": "http://localhost:8080/security-manager"
      },
      "monitoring": {
        "enabled": true,
        "endpoint": "http://localhost:8081/monitoring-manager"
      },
      "storage": {
        "enabled": true,
        "endpoint": "http://localhost:8082/storage-manager"
      },
      "container": {
        "enabled": true,
        "endpoint": "http://localhost:8083/container-manager"
      },
      "deployment": {
        "enabled": true,
        "endpoint": "http://localhost:8084/deployment-manager"
      }
    }
  }
}
```
