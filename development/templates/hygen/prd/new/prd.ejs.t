---
to: <%= path %>
---
# Product Requirements Document: <%= title %>
*Version <%= version %> - <%= date %>*

<% if (has_introduction) { %>
## 1. Introduction

### 1.1 Objectif
<%= description %>

### 1.2 Portée
[Définir la portée du projet/module et ses limites]

### 1.3 Définitions
- **Terme 1** : Définition du terme 1
- **Terme 2** : Définition du terme 2
- **Terme 3** : Définition du terme 3
<% } %>

<% if (has_user_stories) { %>
## 2. User Stories / Cas d'utilisation

### 2.1 User Stories

1. **En tant qu'**[utilisateur], **je veux** [action] **afin de** [bénéfice].
   
2. **En tant qu'**[utilisateur], **je veux** [action] **afin d'**[bénéfice].
   
3. **En tant que**[utilisateur], **je veux** [action] **afin de** [bénéfice].

### 2.2 Cas d'utilisation

1. **UC1: [Nom du cas d'utilisation]**
   - [Étape 1]
   - [Étape 2]
   - [Étape 3]
   - [Résultat attendu]

2. **UC2: [Nom du cas d'utilisation]**
   - [Étape 1]
   - [Étape 2]
   - [Étape 3]
   - [Résultat attendu]
<% } %>

<% if (has_functional_specs) { %>
## 3. Spécifications fonctionnelles

### 3.1 [Fonctionnalité 1]

- **Entrée**: [Description des données d'entrée]
- **Traitement**: [Description du traitement]
- **Sortie**: [Description des données de sortie]

### 3.2 [Fonctionnalité 2]

- **Entrée**: [Description des données d'entrée]
- **Traitement**: [Description du traitement]
- **Sortie**: [Description des données de sortie]

### 3.3 [Fonctionnalité 3]

- **Entrée**: [Description des données d'entrée]
- **Traitement**: [Description du traitement]
- **Sortie**: [Description des données de sortie]
<% } %>

<% if (has_technical_specs) { %>
## 4. Spécifications techniques

### 4.1 Architecture

```
[Diagramme d'architecture ou description textuelle]
```

### 4.2 Interfaces

#### 4.2.1 [Interface 1]

```powershell
# Exemple de code ou de structure d'interface
function Example-Function {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Parameter1,
        
        [Parameter(Mandatory = $false)]
        [int]$Parameter2 = 0
    )
    
    # Description du comportement
}
```

#### 4.2.2 [Interface 2]

```powershell
# Exemple de code ou de structure d'interface
```

### 4.3 Contraintes techniques

- [Contrainte 1]
- [Contrainte 2]
- [Contrainte 3]

### 4.4 Intégration

- [Intégration 1]
- [Intégration 2]
- [Intégration 3]
<% } %>

<% if (has_acceptance_criteria) { %>
## 5. Critères d'acceptation

### 5.1 Tests fonctionnels

1. **[Test 1]**
   - [Critère 1]
   - [Critère 2]
   - [Critère 3]

2. **[Test 2]**
   - [Critère 1]
   - [Critère 2]
   - [Critère 3]

### 5.2 Tests de performance

- [Critère de performance 1]
- [Critère de performance 2]
- [Critère de performance 3]

### 5.3 Documentation

- [Exigence de documentation 1]
- [Exigence de documentation 2]
- [Exigence de documentation 3]
<% } %>

<% if (has_dependencies) { %>
## 6. Dépendances et intégrations

### 6.1 Dépendances

- [Dépendance 1]
- [Dépendance 2]
- [Dépendance 3]

### 6.2 Intégrations

- [Intégration 1]
- [Intégration 2]
- [Intégration 3]
<% } %>

<% if (has_timeline) { %>
## 7. Livrables

1. [Livrable 1]
2. [Livrable 2]
3. [Livrable 3]

## 8. Calendrier

- Phase 1: [Description] ([Durée])
- Phase 2: [Description] ([Durée])
- Phase 3: [Description] ([Durée])
<% } %>

<% if (has_approval) { %>
## 9. Approbation

| Rôle | Nom | Date | Signature |
|------|-----|------|-----------|
| Product Owner | | | |
| Lead Developer | | | |
| QA Lead | | | |
<% } %>

---

*Document généré par Hygen le <%= date %> par <%= author %>*
