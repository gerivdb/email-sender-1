## Correspondance entre Personas et Modes Roo

<!-- ⚠️ Section générée automatiquement depuis .roo/modes-inventory.md. Ne pas modifier manuellement. -->
```mermaid
graph TD
    Dev[Développeur] --> Code[💻 Code]
    Dev --> Debug[🪲 Debug]
    Dev --> DocumentationWriter[✍️ Documentation Writer]
    Contrib[Contributeur] --> Code[💻 Code]
    Contrib --> DocumentationWriter[✍️ Documentation Writer]
    Contrib --> UserStoryCreator[📝 User Story Creator]
    Archi[Architecte] --> Architect[🏗️ Architect]
    Archi --> Orchestrator[🪃 Orchestrator]
    Archi --> ProjectResearch[🔍 Project Research]
    PO[Product Owner] --> UserStoryCreator[📝 User Story Creator]
    PO --> ProjectResearch[🔍 Project Research]
    PO --> DocumentationWriter[✍️ Documentation Writer]
    QA[QA/Testeur] --> Debug[🪲 Debug]
    QA --> DocumentationWriter[✍️ Documentation Writer]
    QA --> ProjectResearch[🔍 Project Research]
```

Chaque persona est associé à un ou plusieurs modes Roo selon ses besoins :  
- **Développeur** : implémentation, debug, documentation technique  
- **Contributeur** : contribution code, documentation, user stories  
- **Architecte** : planification, orchestration, recherche  
- **Product Owner** : user stories, recherche, documentation  
- **QA/Testeur** : debug, documentation, analyse

Voir la [matrice des workflows](rules/workflows-matrix.md) pour plus de détails.
