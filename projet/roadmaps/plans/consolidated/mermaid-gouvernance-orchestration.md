# Schéma Mermaid – Gouvernance & Orchestration

```mermaid
flowchart TD
    subgraph Gouvernance
        INV[Inventaire]
        TH[Table Harmonisée]
        PL[Plans Dev]
        DOC[Documentation]
        FEED[Feedback]
        REP[Reporting]
        CHG[Changelog]
    end
    subgraph Orchestration
        TMGR[Template Manager]
        CI[CI/CD]
        VAL[Validation Croisée]
        DEP[Dépendances]
    end
    INV --> TH --> PL --> DOC
    PL --> FEED --> REP --> CHG
    TMGR --> CI --> VAL --> DEP
    CI --> REP
    VAL --> FEED
    DEP --> TH
```

---

Ce schéma illustre la relation entre les artefacts de gouvernance et les processus d’orchestration du template-manager, pour une traçabilité et une automatisation optimale.