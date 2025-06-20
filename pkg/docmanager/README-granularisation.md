# Granularisation ultra-détaillée : ConflictResolverImpl

## Commandes de validation

```bash
cd pkg/docmanager
bash build_and_test.sh
```

## Rollback

```bash
cd pkg/docmanager
bash rollback_conflict_resolver.sh
```

## Points de contrôle

- Interface, struct, méthodes Detect/Resolve/Score : OK
- Scripts build/test/lint : OK
- Script rollback : OK
- Tests unitaires : voir conflict_resolver_test.go
