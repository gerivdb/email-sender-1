# 🔗 FRAMEWORK DE BRANCHEMENT 8-NIVEAUX - GUIDE D'INTÉGRATION

## 🎯 INTÉGRATIONS ECOSYSTEM

Ce guide détaille comment intégrer le Framework de Branchement 8-Niveaux avec les outils et systèmes existants dans votre écosystème de développement.

---

## 🛠️ INTÉGRATIONS OUTILS DE DÉVELOPPEMENT

### 🔀 INTÉGRATION GIT (GitHub, GitLab, Bitbucket)

#### GitHub Actions Integration

```yaml
# .github/workflows/branching-framework.yml
name: Smart Branching with Framework

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  smart-branching:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Get Framework Prediction
        id: prediction
        run: |
          PREDICTION=$(curl -X POST http://branching-framework:8090/predict \
            -H "Content-Type: application/json" \
            -d '{
              "repository": "${{ github.repository }}",
              "branch": "${{ github.ref_name }}",
              "pr_size": "${{ github.event.pull_request.additions }}",
              "author": "${{ github.actor }}",
              "files_changed": "${{ github.event.pull_request.changed_files }}"
            }')
          echo "prediction=$PREDICTION" >> $GITHUB_OUTPUT
          
      - name: Apply Framework Recommendations
        run: |
          STRATEGY=$(echo '${{ steps.prediction.outputs.prediction }}' | jq -r '.strategy')
          
          case $STRATEGY in
            "micro-session")
              echo "🚀 Micro-session détectée - Auto-merge activé"
              gh pr merge --auto --squash
              ;;
            "complex-orchestration")
              echo "🎼 Orchestration complexe - Création de branches de travail"
              gh pr comment --body "Framework recommande une approche par phases. Voir détails dans les logs."
              ;;
            "team-coordination")
              echo "👥 Coordination équipe requise"
              gh pr comment --body "⚠️ Cette PR nécessite une coordination équipe. Framework Level 6 activé."
              gh pr request-review --team="senior-developers"
              ;;
          esac
          
      - name: Update Branch Metrics
        run: |
          curl -X POST http://branching-framework:8090/metrics \
            -H "Content-Type: application/json" \
            -d '{
              "repository": "${{ github.repository }}",
              "branch": "${{ github.ref_name }}",
              "metrics": {
                "build_time": "${{ steps.build.outputs.duration }}",
                "test_coverage": "${{ steps.test.outputs.coverage }}",
                "complexity_score": "${{ steps.analysis.outputs.complexity }}"
              }
            }'
```

#### GitLab CI Integration

```yaml
# .gitlab-ci.yml
stages:
  - analyze
  - build
  - test
  - deploy

variables:
  FRAMEWORK_URL: "http://branching-framework:8090"

framework-analysis:
  stage: analyze
  script:
    - |
      PREDICTION=$(curl -X POST $FRAMEWORK_URL/predict \
        -H "Content-Type: application/json" \
        -d "{
          \"repository\": \"$CI_PROJECT_PATH\",
          \"branch\": \"$CI_COMMIT_REF_NAME\",
          \"commit_sha\": \"$CI_COMMIT_SHA\",
          \"pipeline_id\": \"$CI_PIPELINE_ID\"
        }")
      echo $PREDICTION > framework-prediction.json
      
      # Extraction de la stratégie recommandée
      STRATEGY=$(echo $PREDICTION | jq -r '.strategy')
      echo "FRAMEWORK_STRATEGY=$STRATEGY" >> build.env
      
      # Configuration dynamique du pipeline
      case $STRATEGY in
        "micro-session")
          echo "SKIP_INTEGRATION_TESTS=true" >> build.env
          ;;
        "complex-orchestration")
          echo "ENABLE_PARALLEL_BUILDS=true" >> build.env
          echo "REQUIRE_MANUAL_APPROVAL=true" >> build.env
          ;;
      esac
  artifacts:
    reports:
      dotenv: build.env
    paths:
      - framework-prediction.json

build:
  stage: build
  script:
    - echo "Stratégie Framework: $FRAMEWORK_STRATEGY"
    - |
      if [ "$ENABLE_PARALLEL_BUILDS" = "true" ]; then
        make build-parallel
      else
        make build
      fi
  needs:
    - framework-analysis

deploy:
  stage: deploy
  script:
    - |
      if [ "$REQUIRE_MANUAL_APPROVAL" = "true" ]; then
        echo "⚠️ Déploiement nécessite une approbation manuelle"
        exit 1
      fi
    - make deploy
  when: manual
  only:
    variables:
      - $REQUIRE_MANUAL_APPROVAL == "true"
```

---

## 🚀 INTÉGRATIONS CI/CD

### Jenkins Pipeline Integration

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        FRAMEWORK_URL = 'http://branching-framework:8090'
    }
    
    stages {
        stage('Framework Analysis') {
            steps {
                script {
                    def prediction = sh(
                        script: """
                            curl -X POST ${FRAMEWORK_URL}/predict \\
                                -H "Content-Type: application/json" \\
                                -d '{
                                    "repository": "${env.GIT_URL}",
                                    "branch": "${env.BRANCH_NAME}",
                                    "build_number": "${env.BUILD_NUMBER}",
                                    "jenkins_job": "${env.JOB_NAME}"
                                }'
                        """,
                        returnStdout: true
                    ).trim()
                    
                    def frameworkResult = readJSON text: prediction
                    env.FRAMEWORK_STRATEGY = frameworkResult.strategy
                    env.FRAMEWORK_LEVEL = frameworkResult.recommended_level
                    
                    echo "🌿 Framework recommande: ${env.FRAMEWORK_STRATEGY} (Niveau ${env.FRAMEWORK_LEVEL})"
                }
            }
        }
        
        stage('Dynamic Build Strategy') {
            steps {
                script {
                    switch(env.FRAMEWORK_STRATEGY) {
                        case 'micro-session':
                            echo "⚡ Stratégie micro-session - Build rapide"
                            sh 'make build-fast'
                            break
                            
                        case 'complex-orchestration':
                            echo "🎼 Orchestration complexe - Build complet avec tests étendus"
                            sh 'make build-complete'
                            sh 'make test-integration'
                            sh 'make test-e2e'
                            break
                            
                        case 'team-coordination':
                            echo "👥 Coordination équipe - Notification des stakeholders"
                            sh 'make build'
                            emailext(
                                to: '${env.CHANGE_AUTHOR_EMAIL}',
                                subject: 'Framework: Coordination équipe requise',
                                body: 'Le Framework de Branchement recommande une coordination équipe pour cette modification.'
                            )
                            break
                            
                        default:
                            sh 'make build'
                    }
                }
            }
        }
        
        stage('Framework Feedback') {
            steps {
                script {
                    sh """
                        curl -X POST ${FRAMEWORK_URL}/feedback \\
                            -H "Content-Type: application/json" \\
                            -d '{
                                "build_id": "${env.BUILD_NUMBER}",
                                "status": "${currentBuild.currentResult}",
                                "duration": "${currentBuild.duration}",
                                "strategy_used": "${env.FRAMEWORK_STRATEGY}",
                                "metrics": {
                                    "test_count": "${env.TEST_COUNT}",
                                    "coverage": "${env.COVERAGE_PERCENT}"
                                }
                            }'
                    """
                }
            }
        }
    }
}
```

### Azure DevOps Integration

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop
      - feature/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  frameworkUrl: 'http://branching-framework:8090'

stages:
- stage: FrameworkAnalysis
  displayName: 'Framework Analysis'
  jobs:
  - job: GetPrediction
    displayName: 'Get Framework Prediction'
    steps:
    - task: Bash@3
      displayName: 'Request Framework Analysis'
      inputs:
        targetType: 'inline'
        script: |
          PREDICTION=$(curl -X POST $(frameworkUrl)/predict \
            -H "Content-Type: application/json" \
            -d '{
              "repository": "$(Build.Repository.Name)",
              "branch": "$(Build.SourceBranchName)",
              "build_id": "$(Build.BuildId)",
              "requester": "$(Build.RequestedFor)"
            }')
          
          echo "##vso[task.setvariable variable=frameworkPrediction;isOutput=true]$PREDICTION"
          
          STRATEGY=$(echo $PREDICTION | jq -r '.strategy')
          echo "##vso[task.setvariable variable=frameworkStrategy;isOutput=true]$STRATEGY"

- stage: Build
  displayName: 'Build with Framework Strategy'
  dependsOn: FrameworkAnalysis
  variables:
    frameworkStrategy: $[ stageDependencies.FrameworkAnalysis.GetPrediction.outputs['frameworkStrategy'] ]
  jobs:
  - job: Build
    displayName: 'Smart Build'
    steps:
    - task: Bash@3
      displayName: 'Framework-Driven Build'
      inputs:
        targetType: 'inline'
        script: |
          echo "🌿 Utilisation de la stratégie: $(frameworkStrategy)"
          
          case "$(frameworkStrategy)" in
            "micro-session")
              echo "⚡ Build rapide pour micro-session"
              npm run build:fast
              ;;
            "complex-orchestration")
              echo "🎼 Build complet avec orchestration"
              npm run build:complete
              npm run test:integration
              ;;
            *)
              echo "🔄 Build standard"
              npm run build
              ;;
          esac
```

---

## 📊 INTÉGRATIONS MONITORING ET OBSERVABILITÉ

### Prometheus + Grafana

```yaml
# prometheus-config.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'branching-framework'
    static_configs:
      - targets: ['branching-framework:8090']
    metrics_path: '/metrics'
    scrape_interval: 10s
    
  - job_name: 'branching-framework-levels'
    static_configs:
      - targets: 
          - 'branching-framework:8091'  # Level 1
          - 'branching-framework:8092'  # Level 2
          - 'branching-framework:8093'  # Level 3
          - 'branching-framework:8094'  # Level 4
          - 'branching-framework:8095'  # Level 5
          - 'branching-framework:8096'  # Level 6
          - 'branching-framework:8097'  # Level 7
          - 'branching-framework:8098'  # Level 8
    metrics_path: '/metrics'
    scrape_interval: 30s

rule_files:
  - "framework-alerts.yml"
```

### Grafana Dashboard JSON

```json
{
  "dashboard": {
    "title": "Framework de Branchement 8-Niveaux",
    "panels": [
      {
        "title": "Prédictions par Niveau",
        "type": "stat",
        "targets": [
          {
            "expr": "sum by (level) (framework_predictions_total)",
            "legendFormat": "Level {{level}}"
          }
        ]
      },
      {
        "title": "Précision ML",
        "type": "gauge",
        "targets": [
          {
            "expr": "framework_ml_accuracy",
            "legendFormat": "Accuracy"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "min": 0,
            "max": 1,
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 0.8},
                {"color": "green", "value": 0.9}
              ]
            }
          }
        }
      },
      {
        "title": "Temps de Réponse par Endpoint",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "P95"
          }
        ]
      }
    ]
  }
}
```

### ELK Stack Integration

```yaml
# filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/branching-framework/*.log
  fields:
    service: branching-framework
    environment: production
  fields_under_root: true
  
processors:
- add_host_metadata:
    when.not.contains.tags: forwarded

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "branching-framework-%{+yyyy.MM.dd}"
  
setup.template.settings:
  index.number_of_shards: 1
  index.codec: best_compression
```

```json
// Kibana Dashboard - Logstash Pattern
{
  "index_patterns": ["branching-framework-*"],
  "mappings": {
    "properties": {
      "@timestamp": {"type": "date"},
      "level": {"type": "keyword"},
      "message": {"type": "text"},
      "service": {"type": "keyword"},
      "framework_level": {"type": "integer"},
      "prediction_accuracy": {"type": "float"},
      "response_time": {"type": "float"},
      "user_id": {"type": "keyword"},
      "repository": {"type": "keyword"},
      "branch": {"type": "keyword"}
    }
  }
}
```

---

## 💬 INTÉGRATIONS COMMUNICATION

### Slack Integration

```go
// slack-integration.go
package integrations

import (
    "bytes"
    "encoding/json"
    "net/http"
)

type SlackMessage struct {
    Channel     string            `json:"channel"`
    Username    string            `json:"username"`
    Text        string            `json:"text"`
    Attachments []SlackAttachment `json:"attachments"`
}

type SlackAttachment struct {
    Color  string       `json:"color"`
    Title  string       `json:"title"`
    Text   string       `json:"text"`
    Fields []SlackField `json:"fields"`
}

type SlackField struct {
    Title string `json:"title"`
    Value string `json:"value"`
    Short bool   `json:"short"`
}

func SendFrameworkNotification(prediction PredictionResult) error {
    webhook := os.Getenv("SLACK_WEBHOOK_URL")
    
    var color string
    switch prediction.Level {
    case 1, 2:
        color = "good"
    case 3, 4, 5:
        color = "warning"
    default:
        color = "danger"
    }
    
    message := SlackMessage{
        Channel:  "#development",
        Username: "Framework de Branchement",
        Text:     "🌿 Nouvelle prédiction Framework",
        Attachments: []SlackAttachment{
            {
                Color: color,
                Title: fmt.Sprintf("Niveau %d recommandé", prediction.Level),
                Text:  prediction.Strategy,
                Fields: []SlackField{
                    {
                        Title: "Repository",
                        Value: prediction.Repository,
                        Short: true,
                    },
                    {
                        Title: "Branch",
                        Value: prediction.Branch,
                        Short: true,
                    },
                    {
                        Title: "Estimated Duration",
                        Value: prediction.EstimatedDuration,
                        Short: true,
                    },
                    {
                        Title: "Conflict Probability",
                        Value: fmt.Sprintf("%.1f%%", prediction.ConflictProbability*100),
                        Short: true,
                    },
                },
            },
        },
    }
    
    jsonData, err := json.Marshal(message)
    if err != nil {
        return err
    }
    
    resp, err := http.Post(webhook, "application/json", bytes.NewBuffer(jsonData))
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    return nil
}
```

### Microsoft Teams Integration

```go
// teams-integration.go
package integrations

type TeamsMessage struct {
    Type       string                 `json:"@type"`
    Context    string                 `json:"@context"`
    Summary    string                 `json:"summary"`
    Sections   []TeamsSection         `json:"sections"`
    Actions    []TeamsAction          `json:"potentialAction"`
}

type TeamsSection struct {
    ActivityTitle    string       `json:"activityTitle"`
    ActivitySubtitle string       `json:"activitySubtitle"`
    ActivityImage    string       `json:"activityImage"`
    Facts           []TeamsFact   `json:"facts"`
    Markdown        bool          `json:"markdown"`
}

type TeamsFact struct {
    Name  string `json:"name"`
    Value string `json:"value"`
}

type TeamsAction struct {
    Type    string `json:"@type"`
    Name    string `json:"name"`
    Targets []struct {
        OS  string `json:"os"`
        URI string `json:"uri"`
    } `json:"targets"`
}

func SendTeamsNotification(prediction PredictionResult) error {
    webhook := os.Getenv("TEAMS_WEBHOOK_URL")
    
    message := TeamsMessage{
        Type:    "MessageCard",
        Context: "http://schema.org/extensions",
        Summary: "Framework de Branchement - Nouvelle Prédiction",
        Sections: []TeamsSection{
            {
                ActivityTitle:    "🌿 Framework de Branchement",
                ActivitySubtitle: fmt.Sprintf("Niveau %d recommandé", prediction.Level),
                ActivityImage:    "https://example.com/framework-logo.png",
                Facts: []TeamsFact{
                    {"Repository", prediction.Repository},
                    {"Branch", prediction.Branch},
                    {"Stratégie", prediction.Strategy},
                    {"Durée estimée", prediction.EstimatedDuration},
                    {"Probabilité conflit", fmt.Sprintf("%.1f%%", prediction.ConflictProbability*100)},
                },
                Markdown: true,
            },
        },
        Actions: []TeamsAction{
            {
                Type: "OpenUri",
                Name: "Voir détails",
                Targets: []struct {
                    OS  string `json:"os"`
                    URI string `json:"uri"`
                }{
                    {"default", fmt.Sprintf("http://framework-dashboard.company.com/prediction/%s", prediction.ID)},
                },
            },
        },
    }
    
    jsonData, err := json.Marshal(message)
    if err != nil {
        return err
    }
    
    resp, err := http.Post(webhook, "application/json", bytes.NewBuffer(jsonData))
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    return nil
}
```

---

## 🗄️ INTÉGRATIONS BASE DE DONNÉES

### PostgreSQL Schema

```sql
-- Schema pour intégration avec systèmes existants
CREATE SCHEMA IF NOT EXISTS branching_framework;

-- Table de prédictions
CREATE TABLE branching_framework.predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository VARCHAR(255) NOT NULL,
    branch VARCHAR(255) NOT NULL,
    level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 8),
    strategy VARCHAR(100) NOT NULL,
    confidence DECIMAL(3,2) NOT NULL,
    estimated_duration INTERVAL,
    conflict_probability DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    actual_duration INTERVAL,
    success BOOLEAN,
    
    -- Index pour performance
    INDEX idx_predictions_repo_branch (repository, branch),
    INDEX idx_predictions_created (created_at),
    INDEX idx_predictions_level (level)
);

-- Table de métriques
CREATE TABLE branching_framework.metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prediction_id UUID REFERENCES branching_framework.predictions(id),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,4) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    INDEX idx_metrics_prediction (prediction_id),
    INDEX idx_metrics_name_time (metric_name, timestamp)
);

-- Vue pour reporting
CREATE VIEW branching_framework.prediction_summary AS
SELECT 
    DATE_TRUNC('day', created_at) as date,
    level,
    strategy,
    COUNT(*) as total_predictions,
    AVG(confidence) as avg_confidence,
    SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful_predictions,
    AVG(EXTRACT(EPOCH FROM actual_duration)) as avg_duration_seconds
FROM branching_framework.predictions
WHERE completed_at IS NOT NULL
GROUP BY DATE_TRUNC('day', created_at), level, strategy
ORDER BY date DESC, level;
```

### MongoDB Integration

```javascript
// mongodb-integration.js
const { MongoClient } = require('mongodb');

class FrameworkMongoIntegration {
    constructor(connectionString) {
        this.client = new MongoClient(connectionString);
        this.db = this.client.db('branching_framework');
    }
    
    async savePrediction(prediction) {
        const collection = this.db.collection('predictions');
        
        const document = {
            ...prediction,
            timestamp: new Date(),
            metadata: {
                framework_version: process.env.FRAMEWORK_VERSION,
                environment: process.env.NODE_ENV
            }
        };
        
        return await collection.insertOne(document);
    }
    
    async getPredictionHistory(repository, branch, limit = 100) {
        const collection = this.db.collection('predictions');
        
        return await collection
            .find({ repository, branch })
            .sort({ timestamp: -1 })
            .limit(limit)
            .toArray();
    }
    
    async getMetricsByLevel(level, startDate, endDate) {
        const collection = this.db.collection('predictions');
        
        return await collection.aggregate([
            {
                $match: {
                    level: level,
                    timestamp: {
                        $gte: startDate,
                        $lte: endDate
                    }
                }
            },
            {
                $group: {
                    _id: {
                        $dateToString: {
                            format: "%Y-%m-%d",
                            date: "$timestamp"
                        }
                    },
                    total_predictions: { $sum: 1 },
                    avg_confidence: { $avg: "$confidence" },
                    success_rate: {
                        $avg: {
                            $cond: [{ $eq: ["$success", true] }, 1, 0]
                        }
                    }
                }
            },
            { $sort: { "_id": 1 } }
        ]).toArray();
    }
}

module.exports = FrameworkMongoIntegration;
```

---

## 🔌 SDK ET CLIENTS

### JavaScript/TypeScript SDK

```typescript
// framework-sdk.ts
export interface PredictionRequest {
    repository: string;
    branch: string;
    task?: string;
    estimated_duration?: string;
    complexity?: 'low' | 'medium' | 'high';
    team_size?: number;
    dependencies?: string[];
}

export interface PredictionResponse {
    id: string;
    recommended_level: number;
    strategy: string;
    confidence: number;
    estimated_completion: string;
    conflict_probability: number;
    recommendations: string[];
}

export class BranchingFrameworkSDK {
    private baseUrl: string;
    private apiKey?: string;
    
    constructor(baseUrl: string, apiKey?: string) {
        this.baseUrl = baseUrl.replace(/\/$/, '');
        this.apiKey = apiKey;
    }
    
    private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
        const url = `${this.baseUrl}${endpoint}`;
        const headers: HeadersInit = {
            'Content-Type': 'application/json',
            ...options.headers,
        };
        
        if (this.apiKey) {
            headers['Authorization'] = `Bearer ${this.apiKey}`;
        }
        
        const response = await fetch(url, {
            ...options,
            headers,
        });
        
        if (!response.ok) {
            throw new Error(`Framework API error: ${response.status} ${response.statusText}`);
        }
        
        return response.json();
    }
    
    async predict(request: PredictionRequest): Promise<PredictionResponse> {
        return this.request<PredictionResponse>('/predict', {
            method: 'POST',
            body: JSON.stringify(request),
        });
    }
    
    async getStatus(): Promise<{ status: string; levels: number[] }> {
        return this.request<{ status: string; levels: number[] }>('/health');
    }
    
    async optimize(repository: string, branch: string): Promise<{ optimizations: string[] }> {
        return this.request<{ optimizations: string[] }>('/optimize', {
            method: 'PUT',
            body: JSON.stringify({ repository, branch }),
        });
    }
    
    async getMetrics(level?: number): Promise<any> {
        const endpoint = level ? `/metrics?level=${level}` : '/metrics';
        return this.request(endpoint);
    }
}

// Usage example
const framework = new BranchingFrameworkSDK('http://localhost:8090', 'your-api-key');

const prediction = await framework.predict({
    repository: 'company/awesome-project',
    branch: 'feature/new-authentication',
    task: 'Implement OAuth2 authentication',
    estimated_duration: '3 days',
    complexity: 'medium',
    team_size: 3
});

console.log(`Niveau recommandé: ${prediction.recommended_level}`);
console.log(`Stratégie: ${prediction.strategy}`);
```

### Python SDK

```python
# framework_sdk.py
import requests
from typing import Optional, Dict, Any, List
from dataclasses import dataclass
from datetime import datetime

@dataclass
class PredictionRequest:
    repository: str
    branch: str
    task: Optional[str] = None
    estimated_duration: Optional[str] = None
    complexity: Optional[str] = None
    team_size: Optional[int] = None
    dependencies: Optional[List[str]] = None

@dataclass 
class PredictionResponse:
    id: str
    recommended_level: int
    strategy: str
    confidence: float
    estimated_completion: str
    conflict_probability: float
    recommendations: List[str]

class BranchingFrameworkSDK:
    def __init__(self, base_url: str, api_key: Optional[str] = None):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({'Authorization': f'Bearer {api_key}'})
        
    def _request(self, method: str, endpoint: str, **kwargs) -> Dict[str, Any]:
        url = f"{self.base_url}{endpoint}"
        response = self.session.request(method, url, **kwargs)
        response.raise_for_status()
        return response.json()
    
    def predict(self, request: PredictionRequest) -> PredictionResponse:
        data = {
            'repository': request.repository,
            'branch': request.branch,
            'task': request.task,
            'estimated_duration': request.estimated_duration,
            'complexity': request.complexity,
            'team_size': request.team_size,
            'dependencies': request.dependencies
        }
        
        # Remove None values
        data = {k: v for k, v in data.items() if v is not None}
        
        result = self._request('POST', '/predict', json=data)
        return PredictionResponse(**result)
    
    def get_status(self) -> Dict[str, Any]:
        return self._request('GET', '/health')
    
    def optimize(self, repository: str, branch: str) -> Dict[str, Any]:
        data = {'repository': repository, 'branch': branch}
        return self._request('PUT', '/optimize', json=data)
    
    def get_metrics(self, level: Optional[int] = None) -> Dict[str, Any]:
        endpoint = f'/metrics?level={level}' if level else '/metrics'
        return self._request('GET', endpoint)

# Usage example
framework = BranchingFrameworkSDK('http://localhost:8090', 'your-api-key')

prediction = framework.predict(PredictionRequest(
    repository='company/awesome-project',
    branch='feature/new-authentication',
    task='Implement OAuth2 authentication',
    estimated_duration='3 days',
    complexity='medium',
    team_size=3
))

print(f"Niveau recommandé: {prediction.recommended_level}")
print(f"Stratégie: {prediction.strategy}")
print(f"Confiance: {prediction.confidence:.2%}")
```

Ce guide d'intégration fournit tout le nécessaire pour connecter le Framework de Branchement 8-Niveaux avec votre écosystème existant, incluant les outils de développement, CI/CD, monitoring et communication.
