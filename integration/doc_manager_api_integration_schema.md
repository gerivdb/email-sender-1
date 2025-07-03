# Schéma d'intégration de l'API du Doc Manager

## Introduction
Ce schéma visualise les points d'intégration clés entre notre système et l'API du Doc Manager.

## Schéma Mermaid

```mermaid
graph TD
    subgraph Notre Système
        A[Go Backend] --> B(Module DocManager)
        B --> C{Adaptateur API Doc Manager}
        D[Scripts PowerShell] --> E(Hooks Git)
        E --> C
    end

    subgraph API Doc Manager
        F[Endpoint Authentification]
        G[Endpoint Synchronisation]
        H[Endpoint Mise à Jour]
    end

    C -- Requête Authentification --> F
    C -- Requête Synchronisation --> G
    C -- Requête Mise à Jour --> H

    G -- Réponse Succès/Erreur --> C
    H -- Réponse Succès/Erreur --> C
    F -- Réponse Token --> C

    B -- Appelle --> C
    E -- Déclenche --> C

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style B fill:#bbf,stroke:#333,stroke-width:2px
    style C fill:#ccf,stroke:#333,stroke-width:2px
    style D fill:#fcf,stroke:#333,stroke-width:2px
    style E fill:#cff,stroke:#333,stroke-width:2px
    style F fill:#bfb,stroke:#333,stroke-width:2px
    style G fill:#bfb,stroke:#333,stroke-width:2px
    style H fill:#bfb,stroke:#333,stroke-width:2px
```

## Points d'intégration identifiés

- **Authentification:** Notre système (via l'adaptateur Go) se connectera à l'endpoint d'authentification pour obtenir un jeton.
- **Synchronisation:** Le module `DocManager` Go, potentiellement déclenché par des hooks Git via PowerShell, enverra des requêtes de synchronisation.
- **Mise à Jour:** Des requêtes de mise à jour spécifiques pourront être envoyées pour des documents individuels.
