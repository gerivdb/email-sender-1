# Package helper

## Functions

### GetCfgPath

GetCfgPath returns the path to the configuration file.

Priority:
1. If filename is an absolute path, return it directly.
2. Check ./{filename} and ./configs/{filename}
3. Otherwise, fallback to /etc/unla/{filename}


```go
func GetCfgPath(filename string) string
```

### GetPIDPath

GetPIDPath returns the path to the PID file.

Priority:
1. If filename is an absolute path, return it directly.
2. Check ./{filename} and ./configs/{filename}
3. Otherwise, fallback to /var/run/mcp-gateway.pid


```go
func GetPIDPath(filename string) string
```

