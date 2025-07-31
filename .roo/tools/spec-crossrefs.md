# Spécification du format de section "Références croisées" Roo-Code

- **Section à ajouter en fin de chaque fichier de règles Roo-Code**
- **Format standardisé :**

```markdown
## Références croisées

- [Nom du fichier lié](chemin/vers/fichier.md) : Description ou usage
```

## Ordre des liens

- Les liens sont triés par ordre alphabétique du nom de fichier.
- Les dépendances directes (usages, imports, héritages) sont listées en premier.
- Les liens documentaires ou contextuels suivent.

## Dépendances

- Chaque lien doit indiquer le type de dépendance :  
  - `usage` : le fichier est utilisé/importé  
  - `documentation` : lien contextuel ou explicatif  
  - `extension` : plugin, point d’extension  
- Exemple :  
  - `[rules-code.md](rules-code.md) : usage`  
  - `[AGENTS.md](../AGENTS.md) : documentation`  
  - `[rules-plugins.md](rules-plugins.md) : extension`

## Synchronisation

- La section doit être générée et mise à jour automatiquement lors des scans et audits.
- Toute modification manuelle doit être validée par un scan ultérieur.

## Exemple de section générée

```markdown
## Références croisées

- [rules-code.md](rules-code.md) : usage
- [AGENTS.md](../AGENTS.md) : documentation
- [rules-plugins.md](rules-plugins.md) : extension
```

## Validation

- La conformité du format est vérifiée par le module de scan et le test de parsing.
- Toute section non conforme est signalée dans le rapport d’écart.

## Traçabilité

- Historique des spécifications archivé dans `.roo/tools/spec-crossrefs.md`
- Log des validations à conserver pour suivi des évolutions.
