---
title: "Mode N8N Integration"
description: "Integration et tests avec n8n"
behavior:
  temperature: 0.2
  maxTokens: 1024
tags: ["n8n", "integration", "workflow"]
---

# Mode N8N - Intégration n8n

## 🎯 Objectif
Gérer l'intégration et les tests avec n8n dans le contexte d'EMAIL_SENDER_1

## 📋 Composants n8n
```yaml
integration:
  - workflows:
      - Email Processing
      - Data Analysis
      - Error Handling
  - data:
      - Storage Configuration
      - Credentials Management
  - testing:
      - Workflow Tests
      - Integration Tests
```

## 🔄 Processus d'Intégration
1. **Configuration Workflow**
   ```powershell
   # Test d'un workflow n8n
   .\test_runner.ps1 -Component "n8n" -WorkflowPath "./n8n-unified/workflows/email-process.json"
   ```

2. **Validation Data**
   ```powershell
   # Vérification des données
   .\check_n8n_data.ps1 -DataPath "./n8n-unified/data"
   ```

## 📊 Métriques
- Performance des workflows
- Taux de succès des emails
- Latence de traitement
- Utilisation des ressources

## 🔗 Intégration avec Autres Modes
- **ARCHI**: Validation de l'architecture n8n
- **DEV-R**: Développement des workflows
- **CHECK**: Tests d'intégration
- **DEBUG**: Résolution des problèmes workflow