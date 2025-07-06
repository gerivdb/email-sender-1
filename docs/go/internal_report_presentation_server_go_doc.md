# Package presentation

Package presentation provides web presentation functionality for reports


## Types

### Server

Server represents a web presentation server


#### Methods

##### Server.AddReport

AddReport adds a report to the server


```go
func (s *Server) AddReport(r *report.Report)
```

##### Server.Start

Start starts the web server


```go
func (s *Server) Start() error
```

