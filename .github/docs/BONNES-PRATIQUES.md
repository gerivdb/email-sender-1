# ✅ Exemples, Cas d’Erreur & Bonnes Pratiques

Ce guide synthétise les exemples d’appels API, de scripts, la gestion d’erreurs, les limites connues et les checklists de validation/troubleshooting pour l’écosystème Email Sender.

---

## 1. Exemples d’appels API & scripts

**Gmail (Node.js) :**

```js
const { google } = require('googleapis');
const gmail = google.gmail('v1');
// ... authentification ...
gmail.users.messages.send({ userId: 'me', requestBody: { /* ... */ } });
```

**Gestion d’erreur (Python) :**

```python
try:
    send_email()
except Exception as e:
    print(f"Erreur lors de l'envoi: {e}")
```

---

## 2. Limites, cas particuliers & comportements inattendus

- Gmail : Limite d’envoi à 500 emails/jour pour les comptes standards.
- Notion : Certains types de blocs ne sont pas supportés par l’API.
- OpenRouter : Quota de tokens par minute, modèles parfois instables.

---

## 3. Checklist de validation intégration

- [ ] Les clés API sont-elles valides et présentes ?
- [ ] Les quotas ne sont-ils pas dépassés ?
- [ ] Les logs d’exécution sont-ils consultables ?
- [ ] Les erreurs sont-elles correctement gérées et affichées ?

---

## 4. Checklist troubleshooting rapide

- [ ] Redémarrer le workflow n8n
- [ ] Vérifier les permissions OAuth/Notion
- [ ] Consulter les logs d’erreur détaillés
- [ ] Tester avec des données minimales

---

## 5. Pour aller plus loin

- Voir [SCRIPTS-OUTILS.md](SCRIPTS-OUTILS.md) pour la liste complète des scripts et outils annexes.
- Compléter ce guide à chaque ajout d’exemple ou de cas d’erreur significatif.
