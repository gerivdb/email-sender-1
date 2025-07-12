# Diagramme Mermaid – Architecture cible Roadmap/Qdrant

```mermaid
flowchart TD
    subgraph Source Unique
        A[Markdown Roadmap]
        B[PostgreSQL]
        C[Qdrant (Vector DB)]
    end
    subgraph Outils
        D[ROADMAP-CLI]
        E[TaskMaster-CLI]
        F[TUI/HTML Visualizer]
        G[n8n Workflows]
    end
    A <--> D
    D <--> C
    E <--> C
    C <--> F
    G <--> C
    B <--> D
    B <--> E
    F <--> B
    A <--> C
```
