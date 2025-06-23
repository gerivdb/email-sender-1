// core/docmanager/dependency_analyzer.go
// Détection des dépendances pour DocManager v66

package docmanager

func DetectDependencies(managerName string) ([]string, error) {
// Stub : retourne une dépendance fictive pour chaque manager
switch managerName {
case "security":
return []string{"audit", "interfaces"}, nil
case "audit":
return []string{"security"}, nil
case "interfaces":
return []string{"apigateway"}, nil
case "orchestrator":
return []string{"loadbalancer", "replication"}, nil
case "loadbalancer":
return []string{"orchestrator"}, nil
case "apigateway":
return []string{"interfaces"}, nil
case "replication":
return []string{"orchestrator"}, nil
default:
return []string{}, nil
}
}
