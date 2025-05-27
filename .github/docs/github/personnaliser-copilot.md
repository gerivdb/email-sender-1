Personnaliser les réponses de chat dans VS Code
Copilot peut vous fournir des réponses adaptées à vos pratiques de codage et aux exigences de votre projet si vous lui donnez le contexte approprié. Les instructions personnalisées vous permettent de définir et d'appliquer automatiquement les directives et les règles pour des tâches telles que la génération de code ou la révision de code. Les fichiers d'invite vous permettent de créer des invites de chat complètes dans des fichiers Markdown, que vous pouvez ensuite consulter dans le chat ou partager avec d'autres personnes. Dans cet article, vous apprendrez à utiliser des instructions personnalisées et des fichiers d'invite pour personnaliser vos réponses de chat dans Visual Studio Code.

Activer les instructions et les fichiers d'invite dans VS Code
Pour activer les instructions et les fichiers d'invite dans VS Code, activez l'optionchat.promptFilesparamètre.

Pour activer ou désactiver ce paramètre de manière centralisée au sein de votre organisation, consultez la section Gérer de manière centralisée les paramètres de VS Code dans la documentation de l'entreprise.

Fichiers d'instructions
Les instructions personnalisées vous permettent de décrire des directives ou des règles communes pour obtenir des réponses adaptées à vos pratiques de codage et à votre pile technologique. Au lieu d'inclure manuellement ce contexte dans chaque requête de chat, les instructions personnalisées intègrent automatiquement ces informations à chaque demande de chat.

VS Code prend en charge plusieurs types d'instructions personnalisées, ciblant différents scénarios : génération de code, génération de test, révision de code, génération de message de validation et instructions de génération de titre et de description de demande d'extraction.

Vous pouvez définir des instructions personnalisées de deux manières :

Fichiers d'instructions : spécifiez les instructions de génération de code dans les fichiers Markdown pour votre espace de travail ou votre profil VS Code .
Paramètres : spécifiez les instructions dans les paramètres utilisateur ou de l’espace de travail de VS Code.
Utiliser les fichiers d'instructions
Les fichiers d'instructions vous permettent de spécifier des instructions personnalisées dans les fichiers Markdown. Vous pouvez les utiliser pour définir vos pratiques de codage, vos technologies préférées et les exigences de votre projet.

Il existe deux types de fichiers d'instructions :

.github/copilot-instructions.md: un fichier d'instructions unique contenant toutes les instructions pour votre espace de travail. Ces instructions sont automatiquement incluses dans chaque demande de chat.

.instructions.mdFichiers : un ou plusieurs fichiers d'invite contenant des instructions personnalisées pour des tâches spécifiques. Vous pouvez joindre des fichiers d'invite individuels à une demande de chat, ou les configurer pour qu'ils soient automatiquement inclus pour des fichiers ou dossiers spécifiques.

Si vous spécifiez les deux types de fichiers d'instructions, ils seront tous deux inclus dans la requête de chat. Aucun ordre ni priorité particulier ne leur est appliqué. Veillez à éviter les conflits d'instructions dans les fichiers.

Note
Les fichiers d'instructions sont uniquement utilisés pour la génération de code et ne sont pas utilisés pour la complétion de code .

Utilisez un fichier .github/copilot-instructions.md
Vous pouvez stocker des instructions personnalisées dans votre espace de travail ou votre référentiel, dans un .github/copilot-instructions.mdfichier, et décrire vos pratiques de codage, vos technologies préférées et les exigences de votre projet en utilisant Markdown. Ces instructions s'appliquent uniquement à l'espace de travail où se trouve le fichier.

VS Code inclut automatiquement les instructions du .github/copilot-instructions.mdfichier à chaque demande de chat et les applique pour générer du code.

Pour utiliser un .github/copilot-instructions.mdfichier :

Réglez legithub.copilot.chat.codeGeneration.useInstructionFilesparamètre permettant trued'indiquer à Copilot dans VS Code d'utiliser le fichier d'instructions personnalisé.

Créez un .github/copilot-instructions.mdfichier à la racine de votre espace de travail. Si nécessaire, créez .githubd'abord un répertoire.

Ajoutez des instructions en langage naturel au fichier. Vous pouvez utiliser le format Markdown.

Les espaces entre les instructions sont ignorés, de sorte que les instructions peuvent être écrites sous forme de paragraphe unique, chacune sur une nouvelle ligne, ou séparées par des lignes vides pour plus de lisibilité.

Note
GitHub Copilot dans Visual Studio et GitHub.com détectent également le .github/copilot-instructions.mdfichier. Si vous utilisez un espace de travail à la fois dans VS Code et Visual Studio, vous pouvez utiliser le même fichier pour définir des instructions personnalisées pour les deux éditeurs.

Utiliser les fichiers .instructions.md
Vous pouvez également créer un ou plusieurs .instructions.mdfichiers pour stocker des instructions personnalisées pour des tâches spécifiques. Par exemple, vous pouvez créer des fichiers d'instructions pour différents langages de programmation, frameworks ou types de projets.

VS Code prend en charge deux types de portées pour les fichiers d'instructions :

Fichiers d'instructions de l'espace de travail : ne sont disponibles que dans l'espace de travail et sont stockés dans le .github/instructionsdossier de l'espace de travail.
Fichiers d'instructions utilisateur : sont disponibles dans plusieurs espaces de travail et sont stockés dans le profil VS Code actuel .
Un fichier d'instructions est un fichier Markdown portant le .instructions.mdsuffixe « file ». Il se compose de deux sections :

(Facultatif) En-tête avec métadonnées (syntaxe Front Matter)

Propriété	Description
applyTo	Spécifiez un modèle global pour les fichiers auxquels les instructions sont automatiquement appliquées. Pour toujours inclure les instructions personnalisées, utilisez ce **modèle.
Par exemple, le fichier d’instructions suivant est toujours appliqué :

---
applyTo: "**"
---
Add a comment at the end of the file: 'Contains AI-generated edits.'
Copie
Corps avec le contenu de l'instruction

Spécifiez les instructions personnalisées en langage naturel grâce au format Markdown. Vous pouvez utiliser des titres, des listes et des blocs de code pour structurer les instructions.

Vous pouvez référencer d'autres fichiers d'instructions en utilisant des liens Markdown. Utilisez des chemins relatifs pour référencer ces fichiers et assurez-vous qu'ils sont corrects en fonction de l'emplacement du fichier d'instructions.

Pour créer un fichier d’instructions :

Exécutez la commande Chat : Nouveau fichier d’instructions à partir de la palette de commandes ( Ctrl+Maj+P ).

Choisissez l’emplacement où le fichier d’instructions doit être créé.

Les fichiers d'instructions utilisateur sont stockés dans le dossier du profil actuel . Vous pouvez synchroniser vos fichiers d'instructions utilisateur sur plusieurs appareils grâce à la synchronisation des paramètres . Assurez-vous de configurer le paramètre « Invites et instructions » dans la commande « Configurer » de la synchronisation des paramètres .

Les fichiers d'instructions de l'espace de travail sont, par défaut, stockés dans le .github/instructionsdossier de votre espace de travail. Ajoutez d'autres dossiers d'instructions à votre espace de travail avec l'outilchat.instructionsFichiersEmplacementsparamètre.

Entrez un nom pour votre fichier d’instructions.

Créez les instructions personnalisées en utilisant le formatage Markdown.

Dans un fichier d'instructions d'espace de travail, référencez des fichiers d'espace de travail supplémentaires sous forme de liens Markdown ( [index](../index.ts)) ou sous forme #index.tsde références dans le fichier d'instructions.

Pour utiliser un fichier d’instructions pour une invite de discussion, vous pouvez :

Dans la vue Chat, sélectionnez Ajouter un contexte > Instructions et sélectionnez le fichier d’instructions dans la sélection rapide.
Exécutez la commande Chat : Joindre des instructions à partir de la palette de commandes ( Ctrl+Maj+P ) et sélectionnez le fichier d’instructions dans la sélection rapide.
Configurez la applyTopropriété dans l’en-tête du fichier d’instructions pour appliquer automatiquement les instructions à des fichiers ou dossiers spécifiques.
Spécifiez des instructions personnalisées dans les paramètres
Vous pouvez également configurer des instructions personnalisées dans vos paramètres utilisateur ou d'espace de travail. Des paramètres spécifiques sont disponibles pour différents scénarios. Les instructions sont automatiquement appliquées à la tâche concernée.

Le tableau suivant répertorie les paramètres pour chaque type d’instruction personnalisée.

Type d'instruction	Nom du paramètre
Génération de code	github.copilot.chat.codeGeneration.instructions
Génération de tests	github.copilot.chat.testGeneration.instructions
Révision du code	github.copilot.chat.reviewSelection.instructions
Génération de messages de validation	github.copilot.chat.commitMessageGeneration.instructions
Génération du titre et de la description de la pull request	github.copilot.chat.pullRequestDescriptionGeneration.instructions
Vous pouvez définir les instructions personnalisées sous forme de texte dans la valeur des paramètres ou référencer un fichier externe dans votre espace de travail.

L'extrait de code suivant montre comment définir un ensemble d'instructions dans le settings.jsonfichier. Pour définir une instruction directement dans les paramètres, configurez la textpropriété. Pour référencer un fichier externe, configurez la filepropriété.

  "github.copilot.chat.codeGeneration.instructions": [
    {
      "text": "Always add a comment: 'Generated by Copilot'."
    },
    {
      "text": "In TypeScript always use underscore for private field names."
    },
    {
      "file": "general.instructions.md" // import instructions from file `general.instructions.md`
    },
    {
      "file": "db.instructions.md" // import instructions from file `db.instructions.md`
    }
  ],
Copie
Exemple d'instructions personnalisées
L'exemple suivant illustre des instructions personnalisées pour la génération de code :

Définissez des directives générales de codage dans un .github/instructions/general-coding.instructions.mdfichier qui s'appliquent à tout le code :

---
applyTo: "**"
---
# Project general coding standards

## Naming Conventions
- Use PascalCase for component names, interfaces, and type aliases
- Use camelCase for variables, functions, and methods
- Prefix private class members with underscore (_)
- Use ALL_CAPS for constants

## Error Handling
- Use try/catch blocks for async operations
- Implement proper error boundaries in React components
- Always log errors with contextual information
Copie
Définissez les directives de codage TypeScript et React dans un .github/instructions/typescript-react.instructions.mdfichier qui s'appliquent au code TypeScript et React, les directives de codage générales sont héritées :

---
applyTo: "**/*.ts,**/*.tsx"
---
# Project coding standards for TypeScript and React

Apply the [general coding guidelines](./general-coding.instructions.md) to all code.

## TypeScript Guidelines
- Use TypeScript for all new code
- Follow functional programming principles where possible
- Use interfaces for data structures and type definitions
- Prefer immutable data (const, readonly)
- Use optional chaining (?.) and nullish coalescing (??) operators

## React Guidelines
- Use functional components with hooks
- Follow the React hooks rules (no conditional hooks)
- Use React.FC type for components with children
- Keep components small and focused
- Use CSS modules for component styling
Copie
Conseils pour définir des instructions personnalisées
Vos instructions doivent être courtes et complètes. Chaque instruction doit être une déclaration simple et unique. Si vous devez fournir plusieurs informations, utilisez plusieurs instructions.

Ne faites pas référence à des ressources externes dans les instructions, telles que des normes de codage spécifiques.

Divisez les instructions en plusieurs fichiers. Cette approche est utile pour organiser les instructions par sujet ou par type de tâche.

Simplifiez le partage d'instructions personnalisées avec votre équipe ou entre vos projets en les stockant dans des fichiers d'instructions. Vous pouvez également gérer les versions des fichiers pour suivre les modifications au fil du temps.

Utilisez la applyTopropriété dans l’en-tête du fichier d’instructions pour appliquer automatiquement les instructions à des fichiers ou dossiers spécifiques.

Faites référence à des instructions personnalisées dans vos fichiers d'invite pour garder vos invites propres et ciblées, et pour éviter de dupliquer des instructions pour différentes tâches.

Fichiers d'invite (expérimental)
Les fichiers d'invite vous permettent de créer des invites complètes dans des fichiers Markdown, auxquelles vous pouvez ensuite vous référer dans le chat. Contrairement aux instructions personnalisées qui complètent vos invites existantes, les fichiers d'invite sont des invites autonomes que vous pouvez stocker dans votre espace de travail et partager avec d'autres. Grâce aux fichiers d'invite, vous pouvez créer des modèles réutilisables pour les tâches courantes, stocker l'expertise du domaine dans votre base de code et standardiser les interactions avec l'IA au sein de votre équipe.

VS Code prend en charge deux types de portées pour les fichiers d'invite :

Fichiers d'invite de l'espace de travail : ne sont disponibles que dans l'espace de travail et sont stockés dans le .github/promptsdossier de l'espace de travail.
Fichiers d'invite utilisateur : sont disponibles dans plusieurs espaces de travail et sont stockés dans le profil VS Code actuel .
Les cas d’utilisation courants incluent :

Génération de code : créez des invites réutilisables pour les composants, les tests ou les migrations (par exemple, les formulaires React ou les simulations d'API).
Expertise du domaine : partagez des connaissances spécialisées via des invites, telles que les pratiques de sécurité ou les contrôles de conformité.
Collaboration d'équipe : modèles et directives de documents avec références aux spécifications et à la documentation.
Intégration : créez des guides étape par étape pour des processus complexes ou des modèles spécifiques à un projet.
Structure du fichier d'invite
Un fichier d'invite est un fichier Markdown avec le .prompt.mdsuffixe de fichier.

Le fichier d'invite se compose de deux sections :

(Facultatif) En-tête avec métadonnées (syntaxe Front Matter)

Propriété	Description
mode	Le mode de discussion à utiliser lors de l'exécution de l'invite : ask, edit, ou agent(par défaut).
tools	Liste des outils utilisables en mode agent. Tableau de noms d'outils, par exemple terminalLastCommandou githubRepo. Le nom de l'outil s'affiche lorsque vous saisissez du texte #dans le champ de saisie du chat.
Si un outil n'est pas disponible, il est ignoré lors de l'exécution de l'invite.
description	Une brève description de l'invite.
Corps avec le contenu de l'invite

Les fichiers d'invite reproduisent le format des invites de chat. Cela permet d'intégrer des instructions en langage naturel, du contexte supplémentaire et même des liens vers d'autres fichiers d'invite comme dépendances. Vous pouvez utiliser le formatage Markdown pour structurer le contenu des invites, notamment les titres, les listes et les blocs de code.

Vous pouvez référencer d'autres fichiers d'invite ou d'instructions en utilisant des liens Markdown. Utilisez des chemins relatifs pour référencer ces fichiers et assurez-vous qu'ils sont corrects en fonction de l'emplacement du fichier d'invite.

Dans un fichier d'invite, vous pouvez référencer des variables en utilisant la ${variableName}syntaxe. Vous pouvez référencer les variables suivantes :

Variables de l'espace de travail - ${workspaceFolder},${workspaceFolderBasename}
Variables de sélection - ${selection},${selectedText}
Variables de contexte de fichier - ${file}, ${fileBasename}, ${fileDirname},${fileBasenameNoExtension}
Variables d'entrée - ${input:variableName}, ${input:variableName:placeholder}(transmettre des valeurs à l'invite à partir du champ de saisie de chat)
Exemples de fichiers d'invite
Demander une tâche réutilisable pour générer un formulaire React :

---
mode: 'agent'
tools: ['githubRepo', 'codebase']
description: 'Generate a new React form component'
---
Your goal is to generate a new React form component based on the templates in #githubRepo contoso/react-templates.

Ask for the form name and fields if not provided.

Requirements for the form:
* Use form design system components: [design-system/Form.md](../docs/design-system/Form.md)
* Use `react-hook-form` for form state management:
* Always define TypeScript types for your form data
* Prefer *uncontrolled* components using register
* Use `defaultValues` to prevent unnecessary rerenders
* Use `yup` for validation:
* Create reusable validation schemas in separate files
* Use TypeScript types to ensure type safety
* Customize UX-friendly validation rules
Copie
Invite à effectuer un examen de sécurité d'une API REST :

---
mode: 'edit'
description: 'Perform a REST API security review'
---
Perform a REST API security review:

* Ensure all endpoints are protected by authentication and authorization
* Validate all user inputs and sanitize data
* Implement rate limiting and throttling
* Implement logging and monitoring for security events
Copie
Conseil
Faites référence à des fichiers de contexte supplémentaires tels que des spécifications API ou de la documentation en utilisant des liens Markdown pour fournir à Copilot des informations plus complètes.

Créer un fichier d'invite d'espace de travail
Les fichiers d’invite de l’espace de travail sont stockés dans votre espace de travail et ne sont disponibles que dans cet espace de travail.

Par défaut, les fichiers d'invite se trouvent dans le .github/promptsrépertoire de votre espace de travail. Vous pouvez spécifier des emplacements supplémentaires pour ces fichiers à l'aide de l'optionchat.promptFilesLocationsparamètre.

Pour créer un fichier d’invite d’espace de travail :

Exécutez la commande Chat : Nouveau fichier d’invite à partir de la palette de commandes ( Ctrl+Maj+P ).

Choisissez l’emplacement où le fichier d’invite doit être créé.

Par défaut, seul le .github/promptsdossier est disponible. Ajoutez d'autres dossiers d'invite à votre espace de travail avec l'optionchat.promptFilesLocationsparamètre.

Entrez un nom pour votre fichier d’invite.

Alternativement, vous pouvez créer directement un .prompt.mdfichier dans le dossier des invites de votre espace de travail.

Créez l'invite de discussion en utilisant le format Markdown.

Dans un fichier d'invite, référencez des fichiers d'espace de travail supplémentaires sous forme de liens Markdown ( [index](../index.ts)) ou sous forme #index.tsde références dans le fichier d'invite.

Vous pouvez également référencer d'autres .prompt.mdfichiers pour créer une hiérarchie d'invites. Vous pouvez également référencer des fichiers d'instructions de la même manière.

Créer un fichier d'invite utilisateur
Les fichiers d'invite utilisateur sont stockés dans votre profil utilisateur . Grâce à eux, vous pouvez partager des invites réutilisables entre plusieurs espaces de travail.

Pour créer un fichier d’invite utilisateur :

Sélectionnez la commande Chat : Nouveau fichier d’invite dans la palette de commandes ( Ctrl+Maj+P ).

Sélectionnez le dossier de données utilisateur comme emplacement pour le fichier d’invite.

Si vous utilisez plusieurs profils VS Code , le fichier d'invite est créé dans le dossier de données utilisateur du profil actuel.

Entrez un nom pour votre fichier d’invite.

Créez l'invite de discussion en utilisant le format Markdown.

Vous pouvez également référencer d’autres fichiers d’invite utilisateur ou fichiers d’instructions utilisateur.

Synchroniser les fichiers d'invite utilisateur sur tous les appareils
VS Code peut synchroniser vos fichiers d'invite utilisateur sur plusieurs appareils à l'aide de la synchronisation des paramètres .

Pour synchroniser vos fichiers d'invite utilisateur, activez la synchronisation des paramètres pour les fichiers d'invite et d'instructions :

Assurez-vous que la synchronisation des paramètres est activée.

Exécutez la synchronisation des paramètres : Configurer à partir de la palette de commandes ( Ctrl+Maj+P ).

Sélectionnez Invites et instructions dans la liste des paramètres à synchroniser.

Utiliser un fichier d'invite dans le chat
Vous disposez de plusieurs options pour exécuter un fichier d’invite :

Exécutez la commande Chat : Exécuter l’invite à partir de la palette de commandes ( Ctrl+Maj+P ) et sélectionnez un fichier d’invite à partir de la sélection rapide.

Dans la vue Chat, saisissez /suivi du nom du fichier d'invite dans le champ de saisie du chat.

Cette option vous permet de saisir des informations supplémentaires dans le champ de saisie du chat. Par exemple : /create-react-formou /create-react-form: formName=MyForm.

Ouvrez le fichier d'invite dans l'éditeur et appuyez sur le bouton de lecture dans la zone de titre de l'éditeur. Vous pouvez choisir d'exécuter l'invite dans la session de chat en cours ou d'en ouvrir une nouvelle.

Cette option est utile pour tester et itérer rapidement sur vos fichiers d'invite.

Paramètres
Paramètres d'instructions personnalisées
chat.promptFiles (Expérimental) : activer les fichiers d'invite et d'instructions réutilisables.

github.copilot.chat.codeGeneration.useInstructionFiles: contrôle si les instructions de code .github/copilot-instructions.mdsont ajoutées aux requêtes Copilot.

chat.instructionsFichiersEmplacements (Expérimental) : liste des dossiers contenant les fichiers d'instructions. Les chemins relatifs sont résolus à partir du ou des dossiers racine de votre espace de travail. Prise en charge des modèles glob pour les chemins de fichiers.

Réglage de la valeur	Description
["/path/to/folder"]	Activez les fichiers d'instructions pour un chemin spécifique. Spécifiez un ou plusieurs dossiers où se trouvent les fichiers d'instructions. Les chemins relatifs sont résolus à partir du ou des dossiers racines de votre espace de travail.
Par défaut, .github/copilot-instructionscette option est ajoutée, mais désactivée.
github.copilot.chat.codeGeneration.instructions (Expérimental) : ensemble d'instructions qui seront ajoutées aux requêtes Copilot qui génèrent du code.

github.copilot.chat.testGeneration.instructions (Expérimental) : ensemble d'instructions qui seront ajoutées aux requêtes Copilot qui génèrent des tests.

github.copilot.chat.reviewSelection.instructions (Aperçu) : ensemble d'instructions qui seront ajoutées aux demandes Copilot pour examiner la sélection d'éditeur actuelle.

github.copilot.chat.commitMessageGeneration.instructions (Expérimental) : ensemble d'instructions qui seront ajoutées aux requêtes Copilot qui génèrent des messages de validation.

github.copilot.chat.pullRequestDescriptionGeneration.instructions (Expérimental) : ensemble d'instructions qui seront ajoutées aux requêtes Copilot qui génèrent des titres et des descriptions de requêtes d'extraction.

Paramètres des fichiers d'invite (expérimentaux)
chat.promptFiles (Expérimental) : activer les fichiers d'invite et d'instructions réutilisables.

chat.promptFilesLocations (Expérimental) : liste des dossiers contenant les fichiers d'invite. Les chemins relatifs sont résolus à partir du ou des dossiers racines de votre espace de travail. Prise en charge des modèles glob pour les chemins de fichiers.

Réglage de la valeur	Description
["/path/to/folder"]	Activez les fichiers d'invite pour un chemin spécifique. Spécifiez un ou plusieurs dossiers où se trouvent les fichiers d'invite. Les chemins relatifs sont résolus à partir du ou des dossiers racines de votre espace de travail.
Par défaut, .github/promptscette option est ajoutée, mais désactivée.