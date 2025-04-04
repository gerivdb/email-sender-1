# Instructions pour tester l'intégration d'Augment avec le terminal

Après avoir redémarré VS Code avec les nouveaux paramètres, suivez ces étapes pour tester l'intégration d'Augment avec le terminal :

## 1. Vérification des paramètres

1. Ouvrez les paramètres VS Code (Ctrl+,)
2. Vérifiez que les paramètres du terminal ont été correctement appliqués :
   - `terminal.integrated.defaultProfile.windows` doit être défini sur "PowerShell"
   - `terminal.integrated.env.windows` doit contenir `AUGMENT_TERMINAL_INTEGRATION: true`

## 2. Test de l'intégration

1. Ouvrez un nouveau terminal dans VS Code (Ctrl+Shift+`)
2. Demandez à Augment d'exécuter une commande simple dans le terminal, par exemple :
   ```
   Peux-tu exécuter la commande "dir" dans le terminal ?
   ```
3. Vérifiez si Augment peut interagir correctement avec le terminal

## 3. Vérification des privilèges

Si l'intégration ne fonctionne toujours pas, vérifiez la cohérence des privilèges :

1. Assurez-vous que VS Code et PowerShell sont exécutés avec le même niveau de privilèges
2. Si nécessaire, fermez VS Code et redémarrez-le en mode administrateur (clic droit > Exécuter en tant qu'administrateur)

## 4. Redémarrage du système

Si les problèmes persistent :

1. Fermez VS Code
2. Redémarrez votre ordinateur
3. Ouvrez VS Code et testez à nouveau l'intégration

## 5. Vérification des journaux

Si l'intégration échoue toujours, vérifiez les journaux d'Augment :

1. Ouvrez la palette de commandes (Ctrl+Shift+P)
2. Tapez "Developer: Open Logs Folder" et sélectionnez cette option
3. Recherchez les fichiers de journal liés à Augment pour identifier d'éventuelles erreurs
