# Stratégies complètes pour éliminer chaque famille d’erreurs Go constatée

> **Principes clés**  
> 1. Corriger les erreurs de syntaxe avant tout : tant qu’un fichier ne se compile pas, les autres diagnostics peuvent être faussés.  
> 2. Harmoniser l’organisation des modules (go.mod), des paquets et de l’arborescence : la majorité des « BrokenImport », « DuplicateDecl » et « MismatchedPkgName » en découlent.  
> 3. Avancer itérativement : corriger une classe d’erreurs, exécuter `go test ./...`, puis passer à la suivante.

## 1. Erreurs de syntaxe (« expected … », « found EOF », « found » …)

Méthodes de résolution :
1. Exécuter `go vet ./...` puis ouvrir chaque fichier signalé ; les points d’interruption (`>`, `>>>`, blocs inachevés) proviennent souvent de merges ou générateurs interrompus.  
2. Formater automatiquement le code : `gofmt -w .` ou intégration IDE.  
3. Vérifier que chaque bloc `package / import / func / type / var` est fermé par **}** et qu’aucune chaîne n’est ouverte sans guillemet fermant.  
4. Si le code a été généré, régénérer la source (swag, protobuf, mockgen, etc.).  

## 2. Paquets incohérents (« found packages X and Y », « MismatchedPkgName »)

1. Dans **un même dossier** il ne doit exister qu’un seul nom de paquet (hors fichiers `*_test.go` qui peuvent utiliser `mypkg_test`).  
2. Renommer :  
   -  soit le champ `package` en haut des fichiers,  
   -  soit déplacer les fichiers vers des dossiers séparés quand il faut plusieurs paquets (ex. `cmd/foo` et `pkg/foo`).  
3. Relancer `go list ./...` pour vérifier.

## 3. Redéfinitions et duplications (« redeclared in this block », « DuplicateDecl »)

1. Rechercher toutes les définitions du symbole : `go build` liste déjà le fichier original.  
2. Choisir la définition canonique, supprimer/renommer les doublons.  
3. Pour les symboles `main`, placer chaque programme dans **son propre répertoire** `cmd/appname`, tous déclarés `package main`.  

## 4. Imports brisés (« BrokenImport », « could not import … no required module provides … »)

1. Vérifier le `module` au début de **go.mod** : il doit correspondre au préfixe réel des import internes (`github.com/gerivdb/email-sender-1` par ex.).  
2. Ajouter les dépendances :  
   `go get github.com/spf13/cobra`  
   `go get gopkg.in/yaml.v2`  
3. Si le dépôt est privé :  
   -  définir `GOPRIVATE`, par ex. `export GOPRIVATE=github.com/gerivdb/**`.  
   -  utiliser un `replace` dans go.mod :  
     ```go
     replace github.com/gerivdb/email-sender-1 => ../email-sender-1
     ```
4. Pour un mono‐repo multi‐modules : créer un fichier **go.work** et exécuter `go work use ./...` afin que les modules locaux se résolvent.  
5. Lancer `go mod tidy` : supprime les imports orphelins et ajoute ceux manquants.  

## 5. Noms non déclarés / méthodes manquantes (« undefined », « MissingFieldOrMethod », « MissingLitField »)

1. Confirmer l’import correct de la bibliothèque qui expose le symbole (point 4).  
2. Mettre à jour la bibliothèque : la signature peut avoir changé (`go get -u pkg@latest`).  
3. Vérifier la casse : Go est sensible à la majuscule initiale pour l’export.  
4. Pour les méthodes manquantes sur un *struct* local :  
   -  Ajouter la méthode,  
   -  OU passer un pointeur/valeur correcte (`*T` vs `T`).  

## 6. Appels incorrects (« WrongArgCount », « MismatchedTypes »)

1. Ouvrir la définition de la fonction et aligner exactement le nombre et le type des paramètres.  
2. Ajouter les conversions explicites nécessaires (`time.Duration(x)`, `float64(y)`, etc.).  
3. Refactoriser le code d’appel ou écrire une fonction d’adaptation si l’API tierce a changé.  

## 7. Imports inutilisés / variables inutilisées (« UnusedVar », tags `[1]`)

1. Supprimer ou préfixer par `_` :  
   ```go
   _ = logger
   ```
2. Exécuter `goimports -w .` pour enlever automatiquement les imports non utilisés.  

## 8. Problèmes de modules *test* et `*_test.go`

1. Les fichiers de test d’un paquet *foo* doivent être `package foo` ou `package foo_test`.  
2. Éviter `package main_test` sauf pour tester le binaire.  
3. Les tests dans `cmd/...` devraient être placés dans un dossier séparé si le binaire contient déjà `package main`.

## 9. Gestion des paquets externes générés (Swagger, protobuf, mocks)

1. Ajouter aux scripts de build :  
   -  `go generate ./...`  
   -  ou Makefile avec `swag init`, `mockgen`, `protoc …`.  
2. Commiter les fichiers générés ou fournir un script CI qui les régénère pour éviter des `undefined: MockXYZ`.  

## 10. Structure recommandée pour un monorepo Go

```
email-sender-1/
│ go.work
│
├─ core/              (bibliothèques partagées)
├─ pkg/               (packages exportés)
├─ internal/          (packages non exportés)
├─ cmd/
│   ├─ email-server/
│   │   main.go
│   └─ ...
└─ third_party/       (protos, générés, etc.)
```

Chaque sous-dossier **cmd/** contient un *unique* `package main` et aucune autre définition de `main` ailleurs.

## 11. Outils à mettre dans la boucle CI

| Outil | Rôle principal |
|-------|----------------|
| `go vet ./...` | Analyse statique de base |
| `staticcheck ./...` | Analyse avancée, code mort, appels douteux |
| `golangci-lint run` | Agrégation de linters |
| `go test ./... -count=1` | S’assure que le projet compile et les tests passent |
| `go mod verify` | Intégrité des dépendances |
| `gofumpt` / `goimports` | Formatage et tri des imports |

Intégrez-les dans un workflow GitHub / GitLab pour prévenir la réintroduction d’erreurs.

## 12. Procédure pas-à-pas conseillée

1. **Nettoyage syntaxique**  
   `gofmt -w . && go vet ./...`
2. **Rationalisation des paquets**  
   Harmoniser les `package` par dossier.  
3. **Réparation du graphe de dépendances**  
   `go mod tidy`, `go work use ./...`, `go get ...`  
4. **Suppression des duplications**  
   Refactoriser ou supprimer les symboles en double.  
5. **Compilation incrémentale**  
   `go test ./core/...` puis élargir progressivement.  
6. **Intégration continue**  
   Ajouter linters et tests au pipeline.

### Résultat attendu

En appliquant ces méthodes :
* Tous les `BrokenImport` disparaissent une fois les modules correctement déclarés et téléchargés.  
* Les `DuplicateDecl` et `main redeclared` sont éliminés en isolant chaque binaire et en supprimant les doubles définitions.  
* Les `Undefined`, `MissingFieldOrMethod`, `WrongArgCount` sont corrigés après mise à jour des signatures et des imports.  
* Le projet compile sans avertissement, et les tests passent.

[1] https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/58286568/ba0e6fc3-a60a-4c78-915d-2765f130ba28/paste.txt