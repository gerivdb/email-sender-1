# Validation documentaire par PowerShell (`pwsh`)

Ce guide décrit les commandes validées pour automatiser la validation documentaire Roo-Code/SOTA via PowerShell.

## 1. Vérification et configuration de la politique d’exécution

```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```
Permet d’exécuter des scripts locaux non signés dans la session courante.

## 2. Exécution du script de validation documentaire

```powershell
pwsh -File .\scripts\manual-validation.ps1 -PlanFile "projet/roadmaps/plans/audits/2025-0808-Transfo-SOTa/projet/3-dispatch-documentaire.md" -DetailedOutput
```
Lance le script de validation documentaire avec paramètres personnalisés.

## 3. Vérification du résultat et du rapport

- Le script génère un rapport documentaire (JSON, Markdown ou log selon configuration).
- Les logs d’exécution et les erreurs sont affichés dans la console.

## 4. Relance et debug

- Si une erreur survient, vérifier la politique d’exécution et relancer la commande.
- Utiliser les logs pour diagnostiquer et corriger les éventuels problèmes.

---

**Toutes ces commandes sont compatibles avec PowerShell Core (`pwsh`) sous Windows 10, et validées pour l’intégration CI/CD documentaire.**

Pour plus de détails, voir [`scripts/manual-validation.ps1`](scripts/manual-validation.ps1:1).