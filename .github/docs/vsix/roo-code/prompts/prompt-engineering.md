Votre demande d'addendum pour approfondir le référentiel `plandev-engineer` est prise en compte. 

1. Qu'est-ce qu'une Invite (Prompt) ?
Une invite est essentiellement une entrée fournie à un modèle d'IA Générative (GenAI) pour guider sa sortie. Ces entrées peuvent être diverses, allant du texte simple comme « Écris un poème sur les arbres » à des formes plus complexes incluant des images, de l'audio, des vidéos, ou une combinaison de ces modalités. Bien que la composante textuelle soit prédominante pour les invites actuellement, l'évolution vers des modalités non textuelles est anticipée.
---

### **2. Composants d'une Invite (Prompt)**

Une invite est l'entrée fournie à un modèle d'IA Générative (GenAI) pour guider sa sortie. Pour construire des invites efficaces, il est crucial de comprendre leurs composants fondamentaux. Ces composants aident à structurer l'entrée de manière à maximiser la pertinence et la qualité de la réponse du modèle, un aspect vital pour la granularisation et l'actionnabilité des roadmaps dans le mode `plandev-engineer`.

*   **Directive**
    La directive est l'**intention principale de l'invite, souvent sous forme d'instruction ou de question**. C'est le cœur de ce que l'on attend du modèle. Dans le contexte du mode `plandev-engineer`, les directives sont cruciales pour transformer un plan de développement en une feuille de route actionnable et exhaustive.

    Exemple de directive explicite:
    `Dis-moi cinq bons livres à lire.`

    Les directives peuvent également être implicites, comme dans le cas d'un "one-shot" où la tâche est déduite de l'exemple.
    Pour `plandev-engineer`, la directive principale est toujours implicitement "transforme tout plan de développement en une feuille de route exhaustive, actionnable, automatisable, testée, traçable et continuellement raffinée, alignée sur les standards Roo Code et le mode `plandev-engineer`". Cependant, chaque section du prompt avancé contient des directives spécifiques pour les sous-tâches, comme "Avant toute génération, analyse le contexte, les objectifs...".

*   **Exemples (Exemplars ou Shots)**
    Les exemples sont des **démonstrations qui guident la GenAI pour accomplir une tâche**. Ils sont particulièrement importants pour l'apprentissage en contexte (In-Context Learning - ICL), qui permet au modèle d'apprendre des compétences sans mise à jour des poids. Pour `plandev-engineer`, l'utilisation d'exemples peut affiner la génération de phases, de tâches et de scripts, assurant l'alignement avec les standards Roo Code.

    Un exemple "One-Shot":
    `Nuit: Noche Matin:`
    L'exemple ci-dessus indique au modèle de traduire de l'anglais vers l'espagnol, et le modèle devrait répondre "Mañana".
    Le référentiel `plandev-engineer` lui-même contient un "Exemple de structure avancée" qui sert d'exemplaire pour la génération des roadmaps.

*   **Formatage de la Sortie (Output Formatting)**
    Il est souvent souhaitable que la GenAI produise des informations dans des **formats spécifiques, tels que CSV, Markdown, XML ou même des formats personnalisés**. Bien que cela puisse parfois réduire les performances sur certaines tâches, cela peut aussi les améliorer. Le mode `plandev-engineer` insiste sur un format de sortie enrichi en Markdown Roo.

    Exemple de formatage de sortie en CSV:
    `{PARAGRAPHE} Résume cela en un fichier CSV.`
    Pour les roadmaps `plandev-engineer`, le format Markdown Roo est spécifié pour les "Phases", "Tâches actionnables", "Scripts/Commandes", "Fichiers attendus", "Critères de validation", etc..

*   **Instructions de Style (Style Instructions)**
    Les instructions de style sont un type de formatage de sortie utilisé pour **modifier stylistiquement plutôt que structurellement la sortie**. Elles peuvent influencer le ton, le genre ou la formulation du texte généré.

    Exemple d'instruction de style:
    `Écris un paragraphe clair et concis sur les lamas.`

*   **Rôle (Role ou Persona)**
    Un rôle, également connu sous le nom de persona, est un composant fréquemment utilisé qui peut **améliorer la rédaction et le style du texte**. Cela consiste à assigner un rôle spécifique à la GenAI dans l'invite.

    Exemple de définition de rôle:
    `Fais semblant d'être un berger et écris un limerick sur les lamas.`
    Dans le prompt avancé de `plandev-engineer`, le modèle est instruit d'agir en tant qu'**"architecte logiciel principal, expert Go, CI/CD, TDD, observabilité, GenAI, ingénierie des prompts et alignement IA"**. Ce rôle spécifique façonne non seulement le style, mais aussi l'expertise technique et l'approche de décomposition et de justification des tâches.

*   **Informations Additionnelles (Additional Information)**
    Il est souvent nécessaire d'inclure des informations supplémentaires dans l'invite pour aider la GenAI à générer une réponse appropriée. Bien que parfois appelé "contexte", ce terme est déconseillé en raison de ses significations multiples dans le domaine de l'ingénierie des invites. Ces informations aident à contextualiser la demande.

    Exemple d'informations additionnelles:
    Si la directive est d'écrire un e-mail, on peut inclure le nom et la position pour que la GenAI puisse signer correctement l'e-mail.
    Pour le mode `plandev-engineer`, l'analyse systématique du "contexte, les objectifs, les contraintes, les dépendances et les zones d’ambiguïté" avant toute génération constitue une forme cruciale d'informations additionnelles pour le modèle, lui permettant de créer des roadmaps spécifiques et pertinentes. L'email du professeur dans l'étude de cas est un exemple réel de la façon dont un "contexte" plus riche peut améliorer les performances.

---

> **🛠️ Adaptation par mode Roo**
>
> - **plandev-engineer** : Chaque composant de prompt doit être aligné sur la structure Roo (phases, tâches, scripts, validation, rollback, etc.). Voir le référentiel [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md:1).
> - **orchestrator** : Les prompts doivent permettre la délégation multi-modes et la traçabilité des sous-tâches. Voir [`rules-orchestration.md`](.roo/rules/rules-orchestration.md:1).
> - **debug** : Les invites doivent guider la reproduction, l’isolation et la documentation des bugs. Voir [`rules-debug.md`](.roo/rules/rules-debug.md:1).
> - **documentation-writer** : Privilégier la clarté, la modularité et l’intégration de liens croisés. Voir [`rules-documentation.md`](.roo/rules/rules-documentation.md:1).
>
> **🔗 Liens Roo utiles** :  
> - [Principes transverses Roo](.roo/rules/rules.md:1)  
> - [AGENTS.md](AGENTS.md:1)  
> - [workflows-matrix.md](.roo/rules/workflows-matrix.md:1)
### **3. Processus d'Ingénierie des Invites (Prompt Engineering)**

L'ingénierie des invites (Prompt Engineering) est le **processus itératif de développement d'une invite en modifiant ou en changeant la technique d'invitation utilisée**. Ce processus est fondamental pour le mode `plandev-engineer`, qui vise des feuilles de route "continuellement raffinées".

*   **Nature Itérative**
    L'ingénierie des invites est intrinsèquement un **processus cyclique**. Elle implique de tester une invite, d'évaluer sa performance et de la modifier pour l'améliorer. Cette approche itérative est en ligne avec les principes de raffinement continu et d'auto-critique du référentiel `plandev-engineer`.

    Le processus se compose de trois étapes répétées:
    1.  **Réaliser l'inférence sur un jeu de données**: Le modèle génère des sorties basées sur l'invite.
    2.  **Évaluer les performances**: Les sorties sont évaluées par rapport aux critères souhaités (par exemple, la précision, la conformité au format).
    3.  **Modifier la template de l'invite**: L'invite est ajustée en fonction des résultats de l'évaluation.

> **🛠️ Adaptation par mode Roo**
>
> - **plandev-engineer** : Le cycle d’itération sur les prompts doit intégrer explicitement les phases d’auto-critique, de validation croisée et de raffinement continu, conformément au référentiel [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md:1). Chaque modification de prompt doit être documentée et testée sur des cas réels de génération de roadmap.
> - **orchestrator** : L’itération sur les prompts doit permettre la coordination entre modes, la traçabilité des ajustements et la synchronisation des sous-tâches. Voir [`rules-orchestration.md`](.roo/rules/rules-orchestration.md:1).
> - **debug** : Le processus d’itération doit inclure la reproduction systématique des bugs, la documentation des hypothèses et la validation par tests unitaires. Voir [`rules-debug.md`](.roo/rules/rules-debug.md:1).
> - **documentation-writer** : Privilégier la traçabilité des versions de prompts, l’intégration de feedback utilisateur et la clarté des changements apportés. Voir [`rules-documentation.md`](.roo/rules/rules-documentation.md:1).
>
> **🔗 Liens Roo utiles** :  
> - [Principes transverses Roo](.roo/rules/rules.md:1)  
> - [AGENTS.md](AGENTS.md:1)  
> - [workflows-matrix.md](.roo/rules/workflows-matrix.md:1)
    Pour `plandev-engineer`, cela signifie que les prompts générant les roadmaps doivent être régulièrement évalués pour leur granularité, leur actionnabilité, leur traçabilité et leur alignement. La section "Auto-critique & raffinement" du prompt avancé encourage explicitement ce cycle en suggérant des améliorations et en demandant un feedback.

    Exemple du processus itératif issu de l'étude de cas sur la détection de l'entrapment:
    Le processus a impliqué **47 étapes de développement enregistrées**, cumulant environ 20 heures de travail, avec des scores F1 variant considérablement. Cela démontre la nature itérative et exploratoire de l'ingénierie des invites, où des ajustements mineurs peuvent avoir un impact significatif sur la performance.

---

### **4. Apprentissage en Contexte (In-Context Learning - ICL)**

> **🛠️ Adaptation Roo-Code par mode :**
>
> - **plandev-engineer** : L’ICL est utilisé pour fournir des exemples structurés de phases, tâches et critères de validation. Les prompts doivent intégrer des exemplaires issus du référentiel [`plandev-engineer-reference.md`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md:1).
> - **orchestrator** : Les exemples doivent illustrer la délégation multi-modes et la synchronisation des sous-tâches ([rules-orchestration.md](.roo/rules/rules-orchestration.md:1)).
> - **debug** : Utiliser des exemples de scénarios d’erreur et de résolution pour guider la reproduction et la correction ([rules-debug.md](.roo/rules/rules-debug.md:1)).
> - **documentation-writer** : Illustrer chaque technique par des exemples concrets et des liens croisés ([rules-documentation.md](.roo/rules/rules-documentation.md:1)).
>
> **🔗 Liens Roo utiles** :
> - [Principes transverses Roo](.roo/rules/rules.md:1)
> - [AGENTS.md](AGENTS.md:1)
> - [workflows-matrix.md](.roo/rules/workflows-matrix.md:1)

L'Apprentissage en Contexte (ICL) fait référence à la **capacité des GenAI à acquérir des compétences et des tâches en leur fournissant des exemples (exemplars) et/ou des instructions pertinentes directement dans l'invite, sans nécessiter de mises à jour de poids ou de réentraînement**. L'ICL peut simplement être une spécification de tâche, où les compétences ne sont pas nécessairement nouvelles mais ont déjà été incluses dans les données d'entraînement.

*   **Définition et types (Zero-Shot, One-Shot, Few-Shot)**
    L'ICL englobe différentes approches selon le nombre d'exemples fournis:
    *   **Zero-Shot Prompting**: N'utilise **aucun exemple**. Le modèle prédit la réponse en se basant uniquement sur une description en langage naturel de la tâche.
        Exemple:
        `Traduire l'anglais vers le français: cheese`
        Le modèle est censé comprendre la tâche sans avoir vu d'exemples de traduction.

    *   **One-Shot Prompting**: Inclut un **unique exemple** de la tâche dans l'invite.
        Exemple:
        `Night: Noche Morning:`
        Le modèle déduit de cet unique exemple qu'il doit traduire le mot "Morning".

    *   **Few-Shot Prompting**: Fournit un **petit nombre d'exemples** (généralement de 10 à 100) pour guider le modèle.
        Exemple:
        `2+2: four 4+5: nine 8+0:`
        Le modèle utilise ces exemples pour apprendre le format et le type de réponse attendue.
        Dans le contexte de `plandev-engineer`, l'intégration d'exemplaires dans le prompt (comme la "structure avancée" ou les "exemples de section") peut grandement améliorer la conformité et la qualité des roadmaps générées en montrant au modèle la forme et le contenu attendus pour les tâches, les livrables et les critères de validation.

*   **Décisions de Conception pour le Few-Shot Prompting**
    La sélection des exemples pour une invite "few-shot" est complexe et dépend de plusieurs facteurs qui influencent la qualité de la sortie.

    *   **Quantité d'Exemplaires**
        **Augmenter la quantité d'exemplaires améliore généralement les performances du modèle**, surtout pour les grands modèles. Cependant, les avantages peuvent diminuer au-delà d'une vingtaine d'exemplaires. Pour les LLM avec des contextes longs, des exemplaires supplémentaires continuent d'améliorer les performances, mais l'efficacité varie selon la tâche.

    *   **Ordre des Exemplaires**
        L'ordre des exemplaires affecte le comportement du modèle. Sur certaines tâches, **l'ordre peut faire varier la précision de moins de 50% à plus de 90%**. Cela souligne l'importance de l'expérimentation avec l'ordre des exemples pour `plandev-engineer` afin d'optimiser la génération de roadmaps.

    *   **Distribution des Labels des Exemplaires**
        Comme en apprentissage automatique supervisé traditionnel, la distribution des labels des exemples dans l'invite affecte le comportement. Une distribution déséquilibrée peut **biaiser le modèle** vers la classe surreprésentée.

    *   **Qualité des Labels des Exemplaires**
        La nécessité de démonstrations strictement valides n'est pas toujours claire. Certains travaux suggèrent que l'exactitude des labels est sans importance, tandis que d'autres montrent un impact significatif sur les performances dans certains contextes. Les modèles plus grands gèrent mieux les labels incorrects ou non pertinents.

    *   **Format des Exemplaires**
        Le format des exemplaires affecte également les performances. Un format courant est "Q: {input}, A: {label}", mais le format optimal peut varier. Les formats courants dans les données d'entraînement tendent à mieux fonctionner. Les exemples de structure dans `plandev-engineer` fournissent un format clair pour les tâches et les livrables.

    *   **Similitude des Exemplaires**
        **Sélectionner des exemplaires similaires à l'échantillon de test est généralement bénéfique**. Cependant, dans certains cas, des exemplaires plus diversifiés peuvent améliorer les performances.

    *   **Sélection des Instructions**
        Bien que les instructions soient nécessaires pour guider les LLM en "zero-shot", les bénéfices d'ajouter des instructions avant les exemples en "few-shot" sont moins clairs. Des instructions génériques peuvent améliorer la précision de la classification et de la réponse aux questions par rapport à des instructions spécifiques à la tâche.

*   **Techniques de Few-Shot Prompting**
    Pour une implémentation efficace du Few-Shot Prompting, diverses techniques ont été développées:

    *   **K-Nearest Neighbor (KNN)**: Sélectionne des exemplaires similaires à l'échantillon de test pour améliorer la performance. Efficace, mais peut être coûteux en temps et en ressources.
    *   **Vote-K**: Une méthode pour sélectionner des exemplaires similaires, où un modèle propose des candidats non étiquetés pour l'annotation, puis les exemplaires étiquetés sont utilisés pour le Few-Shot Prompting. Assure également la diversité des exemplaires.
    *   **Self-Generated In-Context Learning (SG-ICL)**: Utilise une GenAI pour générer automatiquement des exemplaires. Moins efficace que les données réelles, mais utile si les données d'entraînement ne sont pas disponibles.
    *   **Prompt Mining**: Processus de découverte des "mots intermédiaires" optimaux dans les invites via l'analyse de corpus. Les formats plus fréquents dans le corpus améliorent la performance.

*   **Techniques de Zero-Shot Prompting**
    Ces techniques n'utilisent aucun exemplaire et se basent uniquement sur l'instruction.

    *   **Role Prompting** (ou Persona Prompting): **Assigne un rôle spécifique à la GenAI** dans l'invite (par exemple, "agir comme Madonna" ou "un écrivain de voyage"). Peut créer des sorties plus désirables pour les tâches ouvertes et parfois améliorer la précision.
        Ceci est directement appliqué dans le prompt `plandev-engineer` en instruisant le modèle d'agir en tant qu'architecte logiciel principal.

    *   **Style Prompting**: Spécifie le style, le ton ou le genre souhaité dans l'invite pour façonner la sortie. Un effet similaire peut être obtenu avec le rôle.

    *   **Emotion Prompting**: Intègre des phrases de pertinence psychologique (par exemple, "Ceci est important pour ma carrière") dans l'invite pour potentiellement améliorer les performances des LLM.

    *   **System 2 Attention (S2A)**: Demande d'abord à un LLM de réécrire l'invite en supprimant les informations non pertinentes, puis passe cette nouvelle invite à un autre LLM pour la réponse finale.

    *   **SimToM**: Traite les questions complexes impliquant plusieurs personnes ou objets en établissant l'ensemble des faits qu'une personne connaît, puis répond en se basant uniquement sur ces faits.

    *   **Rephrase and Respond (RaR)**: Demande au LLM de paraphraser et d'élargir la question avant de générer la réponse finale. A démontré des améliorations sur plusieurs benchmarks.

    *   **Re-reading (RE2)**: Ajoute la phrase "Relisez la question:" à l'invite en plus de répéter la question. Malgré sa simplicité, a montré une amélioration dans les benchmarks de raisonnement.
        L'étude de cas a accidentellement découvert un effet similaire en dupliquant un email de contexte, ce qui a eu des effets positifs significatifs sur les performances.

    *   **Self-Ask**: Demande aux LLM de décider d'abord s'ils ont besoin de poser des questions de suivi, puis de générer et de répondre à ces questions avant de répondre à la question originale.

---

### **5. Génération de Pensée (Thought Generation)**

> **🛠️ Adaptation Roo-Code par mode :**
>
> - **plandev-engineer** : Les prompts doivent inciter à la justification détaillée (CoT, arbitrages, alternatives) pour chaque phase de roadmap ([plandev-engineer-reference.md](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md:1)).
> - **orchestrator** : Favoriser la traçabilité du raisonnement lors de l’agrégation des sous-tâches ([rules-orchestration.md](.roo/rules/rules-orchestration.md:1)).
> - **debug** : Utiliser le raisonnement étape par étape pour documenter la résolution des bugs ([rules-debug.md](.roo/rules/rules-debug.md:1)).
> - **documentation-writer** : Expliquer les choix structurants et les alternatives dans les guides ([rules-documentation.md](.roo/rules/rules-documentation.md:1)).
>
> **🔗 Liens Roo utiles** :
> - [Principes transverses Roo](.roo/rules/rules.md:1)
> - [AGENTS.md](AGENTS.md:1)
> - [workflows-matrix.md](.roo/rules/workflows-matrix.md:1)

La génération de pensée englobe une gamme de techniques qui incitent le LLM à **articuler son raisonnement tout en résolvant un problème**. Ces techniques sont directement alignées avec la demande du mode `plandev-engineer` de décomposer les objectifs en phases logiques et sous-tâches atomiques, en explicitant les justifications (CoT, arbitrages).

*   **Chain-of-Thought (CoT) Prompting**
    Le CoT Prompting **tire parti du "few-shot prompting" pour encourager le LLM à exprimer son processus de pensée avant de donner sa réponse finale**. Cette technique améliore significativement les performances des LLM dans les tâches de mathématiques et de raisonnement. Un prompt CoT inclut un exemple avec une question, un chemin de raisonnement et la bonne réponse.

    Exemple de prompt CoT One-Shot:
    `Q: Jack a deux paniers, chacun contenant trois balles. Combien de balles Jack a-t-il en tout? R: Un panier contient 3 balles, donc deux paniers contiennent 3 * 2 = 6 balles. Q: {QUESTION} R:`

*   **Zero-Shot CoT**
    La version la plus simple du CoT ne contient **aucun exemple**. Elle consiste à **ajouter une phrase incitant à la réflexion** comme "Réfléchissons étape par étape." à l'invite.

    Exemple:
    `Réfléchissons étape par étape.`
    Cette technique est attrayante car elle ne nécessite pas d'exemplaires et est généralement agnostique à la tâche.

    *   **Step-Back Prompting**: Modification du CoT où le LLM est d'abord interrogé sur des concepts ou faits pertinents de haut niveau avant d'aborder le raisonnement détaillé. A amélioré les performances sur plusieurs benchmarks de raisonnement.
    *   **Analogical Prompting**: Génère automatiquement des exemples incluant des chaînes de pensée (CoT). A démontré des améliorations dans le raisonnement mathématique et la génération de code.
    *   **Thread-of-Thought (ThoT) Prompting**: Une phrase d'incitation à la pensée améliorée pour le raisonnement CoT, comme "Parcourez ce contexte en parties gérables étape par étape, en résumant et en analysant au fur et à mesure.". Efficace pour la réponse aux questions et la récupération.
    *   **Tabular Chain-of-Thought (Tab-CoT)**: Un prompt Zero-Shot CoT qui fait en sorte que le LLM produise son raisonnement sous forme de tableau Markdown. Cette conception tabulaire améliore la structure et donc le raisonnement de la sortie.
        La structuration en tableau est un format privilégié par le mode `plandev-engineer` pour les informations.

*   **Few-Shot CoT**
    Cet ensemble de techniques présente au LLM **plusieurs exemplaires qui incluent des chaînes de pensée**, ce qui peut significativement améliorer les performances.

    *   **Contrastive CoT Prompting**: Ajoute des exemples avec des explications incorrectes et correctes au prompt CoT pour montrer au LLM comment *ne pas* raisonner. A montré une amélioration significative dans l'arithmétique et la QA factuelle.
    *   **Uncertainty-Routed CoT Prompting**: Échantillonne plusieurs chemins de raisonnement CoT, puis sélectionne la majorité si elle dépasse un certain seuil.
    *   **Complexity-based Prompting**: Sélectionne des exemples complexes pour l'annotation et l'inclusion dans le prompt, et échantillonne plusieurs chaînes de raisonnement en utilisant un vote majoritaire.
    *   **Active Prompting**: Commence avec des questions/exemplaires d'entraînement, demande au LLM de les résoudre, calcule l'incertitude, et demande à des annotateurs humains de réécrire les exemplaires avec la plus grande incertitude.
    *   **Memory-of-Thought Prompting**: Utilise des exemplaires d'entraînement non étiquetés pour construire des prompts Few-Shot CoT au moment du test.
    *   **Automatic Chain-of-Thought (Auto-CoT) Prompting**: Utilise un prompt Zero-Shot pour générer automatiquement des chaînes de pensée, qui sont ensuite utilisées pour construire un prompt Few-Shot CoT.
        L'étude de cas a utilisé AutoDiCoT, une variation d'Auto-CoT, pour générer des explications et améliorer le prompt.

---

### **6. Décomposition (Decomposition)**

> **🛠️ Adaptation Roo-Code par mode :**
>
> - **plandev-engineer** : La décomposition en phases logiques et tâches atomiques est obligatoire pour chaque plan ([plandev-engineer-reference.md](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md:1)).
> - **orchestrator** : Découper les tâches complexes en sous-tâches actionnables et déléguer à chaque mode ([rules-orchestration.md](.roo/rules/rules-orchestration.md:1)).
> - **debug** : Décomposer les bugs en étapes de reproduction et de correction ([rules-debug.md](.roo/rules/rules-debug.md:1)).
> - **documentation-writer** : Structurer les guides en étapes séquentielles et actionnables ([rules-documentation.md](.roo/rules/rules-documentation.md:1)).
>
> **🔗 Liens Roo utiles** :
> - [Principes transverses Roo](.roo/rules/rules.md:1)
> - [AGENTS.md](AGENTS.md:1)
> - [workflows-matrix.md](.roo/rules/workflows-matrix.md:1)

La décomposition est une stratégie de résolution de problèmes qui **transforme des problèmes complexes en sous-questions plus simples**. Ceci est explicitement demandé dans le prompt avancé de `plandev-engineer` sous "Décomposition avancée".

*   **Least-to-Most Prompting**: Demande à un LLM de décomposer un problème en sous-problèmes sans les résoudre initialement, puis de les résoudre séquentiellement en ajoutant les réponses du modèle à l'invite à chaque fois. A montré des améliorations significatives dans les tâches de manipulation symbolique et de raisonnement mathématique.
*   **Decomposed Prompting (DECOMP)**: Utilise le Few-Shot Prompting pour montrer à un LLM comment utiliser certaines fonctions (par exemple, le fractionnement de chaînes, la recherche sur Internet). Le LLM décompose alors son problème original en sous-problèmes qu'il envoie à différentes fonctions.
*   **Plan-and-Solve Prompting**: Un prompt Zero-Shot CoT amélioré, "Commençons par comprendre le problème et élaborons un plan pour le résoudre. Ensuite, exécutons le plan et résolvons le problème étape par étape". Génère des processus de raisonnement plus robustes.
    Cela résonne fortement avec la structuration des roadmaps `plandev-engineer` en phases logiques et tâches atomiques.

*   **Tree-of-Thought (ToT)**: Crée un problème de recherche arborescent en générant plusieurs étapes possibles sous forme de pensées (comme à partir d'un CoT). Évalue la progression de chaque étape vers la résolution du problème et décide quelles étapes poursuivre. Très efficace pour les tâches nécessitant recherche et planification.
*   **Recursion-of-Thought**: Similaire au CoT, mais chaque fois qu'un problème compliqué est rencontré au milieu de la chaîne de raisonnement, il est envoyé dans une autre invite/appel LLM, puis la réponse est insérée dans l'invite originale. Permet de résoudre récursivement des problèmes complexes.
*   **Program-of-Thoughts (PAL)**: Utilise les LLM pour générer du code de programmation comme étapes de raisonnement, exécuté par un interpréteur de code pour obtenir la réponse finale. Excellente pour les tâches mathématiques et de programmation.
    Cela s'aligne avec la section "Scripts/Commandes" du mode `plandev-engineer`.

*   **Faithful Chain-of-Thought**: Génère un CoT qui contient un raisonnement en langage naturel et symbolique (par exemple, Python), utilisant différents types de langages symboliques en fonction de la tâche.
*   **Skeleton-of-Thought**: Accélère la vitesse de réponse par la parallélisation. Un LLM crée un squelette de la réponse (sous-problèmes à résoudre), puis ces questions sont envoyées en parallèle à un LLM et les sorties sont concaténées pour une réponse finale.
*   **Metacognitive Prompting**: Tente de faire en sorte que le LLM reproduise les processus métacognitifs humains avec une chaîne d'invites en cinq parties, incluant la clarification de la question, le jugement préliminaire, l'évaluation de la réponse, la confirmation de la décision et l'évaluation de la confiance.

---

### **7. Auto-Critique (Self-Criticism)**

> **🛠️ Adaptation Roo-Code par mode :**
>
> - **plandev-engineer** : L’auto-critique et le raffinement sont requis en fin de chaque phase, avec boucle de feedback utilisateur ([plandev-engineer-reference.md](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md:1)).
> - **orchestrator** : Appliquer l’auto-critique à la synthèse globale des résultats ([rules-orchestration.md](.roo/rules/rules-orchestration.md:1)).
> - **debug** : Utiliser Self-Verification pour valider la correction et documenter les limites ([rules-debug.md](.roo/rules/rules-debug.md:1)).
> - **documentation-writer** : Intégrer une boucle de relecture systématique et de calibration documentaire ([rules-documentation.md](.roo/rules/rules-documentation.md:1)).
>
> **🔗 Liens Roo utiles** :
> - [Principes transverses Roo](.roo/rules/rules.md:1)
> - [AGENTS.md](AGENTS.md:1)
> - [workflows-matrix.md](.roo/rules/workflows-matrix.md:1)

L'auto-critique implique que les LLM **critiquent leurs propres sorties**. Cela peut être un jugement (par exemple, si la sortie est correcte) ou un retour d'information pour améliorer la réponse. Cette capacité est directement liée à la section "Auto-critique & raffinement" du prompt [`plandev-engineer`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md#version-avancée-du-prompt), qui vise à identifier les limites du plan et les axes d'amélioration continue.

*   **Self-Calibration**: Demande à un LLM de répondre à une question, puis construit une nouvelle invite incluant la question, la réponse du LLM et une instruction supplémentaire demandant si la réponse est correcte. Utile pour évaluer les niveaux de confiance.
*   **Self-Refine**: Un cadre itératif où, après une première réponse, le même LLM est invité à fournir un feedback sur cette réponse, puis à l'améliorer en fonction du feedback. Ce processus itératif se poursuit jusqu'à une condition d'arrêt. A démontré des améliorations dans les tâches de raisonnement, de codage et de génération.
*   **Reversing Chain-of-Thought (RCoT)**: Demande aux LLM de reconstruire le problème à partir d'une réponse générée, puis génère des comparaisons fines entre le problème original et le problème reconstruit pour vérifier les incohérences. Ces incohérences sont ensuite converties en feedback pour réviser la réponse.
*   **Self-Verification**: Génère plusieurs solutions candidates avec CoT, puis évalue chaque solution en masquant certaines parties de la question originale et en demandant à un LLM de les prédire en se basant sur le reste de la question et la solution générée.
*   **Chain-of-Verification (COVE)**: Utilise d'abord un LLM pour générer une réponse, puis crée une liste de questions connexes pour vérifier la justesse de la réponse. Chaque question est ensuite traitée par le LLM, et toutes les informations sont utilisées pour produire la réponse finale révisée.
*   **Cumulative Reasoning**: Génère plusieurs étapes potentielles pour répondre à une question, fait évaluer ces étapes par un LLM (acceptation/rejet), et vérifie si la réponse finale a été atteinte. A démontré des améliorations dans les tâches d'inférence logique et de problèmes mathématiques.

> **🛠️ Adaptation Roo-Code par mode :**
>
> - **plandev-engineer** : L’auto-critique est obligatoire en fin de chaque phase (voir [exemple de structure avancée](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md#exemple-de-structure-avancée)). Utiliser Self-Refine ou COVE pour générer des suggestions d’amélioration continue.
> - **orchestrator** : L’auto-critique doit être appliquée à la synthèse globale, en croisant les résultats des sous-tâches (voir [rules-orchestration.md](.roo/rules/rules-orchestration.md)).
> - **debug** : Privilégier Self-Verification pour valider la correction des bugs et documenter les limites dans la checklist de débogage ([rules-debug.md](.roo/rules/rules-debug.md)).
> - **documentation-writer** : Intégrer une boucle de relecture/raffinement systématique, en s’appuyant sur Self-Calibration pour garantir la clarté documentaire ([rules-documentation.md](.roo/rules/rules-documentation.md)).

---

### **8. Problèmes d'Alignement: Sensibilité des Invites et Biais**

L'alignement est essentiel pour s'assurer que les LLM répondent aux besoins des utilisateurs sans produire de contenu nuisible, de réponses incohérentes ou de biais. Le référentiel [`plandev-engineer`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md#version-avancée-du-prompt) aborde explicitement ces risques dans sa section "Risques & mitigation" et met l'accent sur l'alignement IA dans ses techniques d'ingénierie de prompt.

*   **Sensibilité des Invites (Prompt Sensitivity)**
    Les LLM sont **très sensibles à l'invite d'entrée**, même de subtils changements pouvant entraîner des sorties très différentes.

    *   **Petits Changements dans l'Invite**: Des modifications mineures comme des espaces supplémentaires, des changements de majuscules, des modifications de délimiteurs ou des remplacements de synonymes peuvent impacter significativement les performances. Par exemple, pour LLaMA2-7B, de petits changements peuvent faire varier les performances de près de 0 à 0.804 sur certaines tâches.

    *   **Format de la Tâche (Task Format)**: Différentes manières de formuler la même tâche (par exemple, "classer une critique comme 'positive' ou 'négative'" vs. "Est-ce que cette critique est positive?" pour une réponse "oui" ou "non") peuvent modifier la précision de GPT-3 jusqu'à 30%.

    *   **Dérive de l'Invite (Prompt Drift)**: Se produit lorsque le modèle derrière une API change au fil du temps, de sorte que la même invite peut produire des résultats différents sur le modèle mis à jour. Nécessite une surveillance continue de la performance de l'invite.
        Pour [`plandev-engineer`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md#version-avancée-du-prompt), cela souligne la nécessité de "surveillance automatisée du pipeline" et de "raffinement continu" pour détecter et corriger toute dérive dans la génération des roadmaps due aux mises à jour des modèles sous-jacents.

*   **Biais, Stéréotypes et Culture**
    Les LLM doivent être équitables envers tous les utilisateurs, sans perpétuer de biais, de stéréotypes ou de préjudices culturels. Le référentiel [`plandev-engineer`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md#version-avancée-du-prompt) inclut la "gestion des risques IA, drift, sycophancy, biais".

    *   **Vanilla Prompting**: Consiste simplement en une instruction dans l'invite disant au LLM d'être impartial. Également appelé "correction morale auto-dirigée".
    *   **Sélection d'Exemples Équilibrés**: La sélection d'exemples équilibrés peut réduire les biais dans les sorties des LLM.
    *   **Conscience Culturelle (Cultural Awareness)**: Peut être injectée dans les invites pour aider les LLM à s'adapter culturellement. Cela peut se faire en demandant au LLM de raffiner sa propre sortie et de lui donner des instructions d'utiliser des mots culturellement pertinents.
    *   **AttrPrompt**: Une technique de prompting conçue pour éviter de produire du texte biaisé vers certains attributs lors de la génération de données synthétiques. Demande au LLM de générer des attributs spécifiques importants pour la diversité (par exemple, la localisation), puis le modèle génère des données synthétiques en variant chacun de ces attributs.

*   **Ambiguïté**
    Les questions ambiguës peuvent être interprétées de plusieurs manières, chaque interprétation pouvant entraîner une réponse différente. Le prompt [`plandev-engineer`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md#version-avancée-du-prompt) insiste sur l'**"analyse systématique, clarification & gestion de l’ambiguïté"**.

    *   **Démonstrations Ambigües**: Inclure des exemples avec un ensemble de labels ambigu peut améliorer les performances de l'ICL.
    *   **Clarification de Questions**: Permet au LLM d'identifier les questions ambiguës et de générer des questions de clarification à poser à l'utilisateur. Une fois clarifiées, le LLM peut régénérer sa réponse. Cela peut impliquer un pipeline où le LLM génère une réponse initiale, classe si des questions de clarification sont nécessaires, décide quelles questions poser, puis génère une réponse finale.
        Cette approche est directement applicable à la phase d'analyse du mode [`plandev-engineer`](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md#version-avancée-du-prompt) où le modèle doit "formuler une question de clarification structurée" si un point est flou.

> **🛠️ Adaptation Roo-Code par mode :**
>
> - **plandev-engineer** : L’alignement, la gestion des biais et la clarification sont obligatoires dans chaque phase (voir [Risques & mitigation](.roo/rules/rules-plandev-engineer/plandev-engineer-reference.md#version-avancée-du-prompt)).
> - **orchestrator** : Surveiller la dérive de prompt et la cohérence des résultats lors de l’agrégation multi-modes ([rules-orchestration.md](.roo/rules/rules-orchestration.md)).
> - **debug** : Documenter explicitement les ambiguïtés et biais détectés lors du diagnostic ([rules-debug.md](.roo/rules/rules-debug.md)).
> - **documentation-writer** : Privilégier la neutralité, la diversité des exemples et la clarification systématique dans les guides ([rules-documentation.md](.roo/rules/rules-documentation.md)).

---


### 1. Ingénierie de Prompt et ses Composants Détaillés

L'ingénierie de prompt est un processus itératif essentiel pour développer un prompt en modifiant ou en changeant la technique de prompting utilisée.

*   **Composants fondamentaux d'un prompt**:
    *   **Directive** : L'instruction ou la question principale qui définit l'intention du prompt (par exemple, "Donne-moi cinq bons livres à lire."). Les directives peuvent être explicites ou implicites.
    *   **Exemples (Exemplars ou Shots)** : Des démonstrations qui guident le GenAI dans l'exécution d'une tâche. Cela inclut le "One-Shot" (un exemple) ou le "Few-Shot" (quelques exemples).
    *   **Format de sortie** : Spécifier la structure de la réponse souhaitée (par exemple, CSV, Markdown, XML). Les **instructions de style** sont un type de formatage de sortie utilisé pour modifier stylistiquement la sortie (par exemple, "Écris un paragraphe clair et concis sur les lamas.").
    *   **Rôle (Persona)** : Attribuer un rôle spécifique au GenAI dans le prompt (par exemple, "Fais comme si tu étais un berger...") peut améliorer le style et la qualité de la sortie. Ce point est **crucial pour "vsix RooCode"** comme détaillé ci-dessous.
    *   **Informations additionnelles (Contexte)** : Inclure des données supplémentaires nécessaires à la tâche. Le terme "contexte" est parfois ambigu, il est donc préférable de parler d'informations additionnelles.

### 2. Diversité Linguistique et Utilisation des Personas

Les LLMs actuels peuvent montrer une performance "cassante" (brittle performance) face à des styles d'écriture non standard, et les variations de style et de formatage des prompts ont un impact significatif sur la performance du LLM, même pour un contenu sémantique identique.

*   **Impact de la diversité stylistique** :
    *   Les benchmarks actuels manquent de diversité de styles d'écriture, se concentrant souvent sur des conventions standardisées, ce qui peut rendre les LLMs peu performants face à des entrées "non standard".
    *   Même avec un contenu sémantique identique, les variations de style d'écriture et de formatage de prompt **impactent significativement la performance** estimée du LLM.
    *   Certains styles d'écriture (par exemple, des personas ayant un niveau d'éducation "inférieur au lycée" ou des personas "âgées") entraînent **systématiquement une baisse de performance** pour la majorité des modèles, indépendamment de leur famille, taille ou date de publication.
    *   Les personas les plus performantes ont tendance à utiliser un **langage plus académique et technique**, avec une meilleure lisibilité Flesch et des structures de phrase plus complexes.
    *   L'intégration d'attributs sociodémographiques (langue maternelle, niveau d'éducation, âge, identité de genre/sexuelle) dans les personas peut générer **plus de variation de performance** que l'utilisation de personas de base différentes.
*   **Implications pour "vsix RooCode"** :
    *   Il est essentiel de tester la robustesse du système "vsix RooCode" face à une **variété de styles d'interaction utilisateur** et potentiellement d'intégrer des mécanismes pour adapter les prompts ou les réponses en fonction du style détecté.
    *   Les lacunes des benchmarks existants en termes de diversité linguistique signifient que "vsix RooCode" ne devrait pas se fier uniquement aux scores de performance standards pour la sélection des modèles, mais aussi considérer la **population d'utilisateurs cible**.
    *   L'instabilité du classement des modèles due aux variations de style d'écriture est un point critique, car des changements minimes (par exemple, 5 points de pourcentage) peuvent **altérer considérablement le classement** d'un modèle.

### 3. Techniques de Prompting Avancées

*   **In-Context Learning (ICL)** : Capacité des GenAIs à apprendre des compétences à partir d'exemples ou d'instructions fournis dans le prompt, **sans mise à jour des poids du modèle**. La quantité, l'ordre, la distribution et la qualité des exemples influencent la performance. La sélection d'exemples similaires à l'instance de test est généralement bénéfique.
*   **Génération de Pensées (Thought Generation)** : Incite le LLM à articuler son raisonnement avant de donner une réponse finale, comme le **"Chain-of-Thought (CoT) Prompting"**. Des variantes comme "Zero-Shot CoT" (avec des phrases comme "Réfléchissons étape par étape.") et "Few-Shot CoT" (avec des exemples incluant des chaînes de pensée) existent.
*   **Décomposition** : Décomposer des problèmes complexes en sous-questions plus simples, par exemple avec le "Least-to-Most Prompting" ou "Tree-of-Thought".
*   **Ensembling** : Utiliser plusieurs prompts pour résoudre le même problème et agréger les réponses pour une sortie finale plus robuste (souvent par vote majoritaire, "Self-Consistency").
*   **Auto-critique (Self-Criticism)** : Demander aux LLMs de critiquer leurs propres sorties pour améliorer la qualité de la réponse ("Self-Refine", "Chain-of-Verification").

### 4. Processus d'Ingénierie de Prompt et d'Answer Engineering

*   **Processus itératif** : L'ingénierie de prompt est un processus itératif qui implique l'inférence sur un ensemble de données, l'évaluation de la performance et la modification du template de prompt.
*   **Ingénierie de Réponse (Answer Engineering)** : Se concentre sur l'extraction de la réponse finale à partir de la sortie du LLM, en définissant la **forme** (par exemple, un jeton, une étendue de jetons), l'**espace** (le domaine des valeurs) et un **extracteur** (par exemple, une expression régulière ou un LLM séparé). Ceci est crucial lorsque le contrôle total de l'espace de réponse est impossible.

### 5. Aspects Multilingues et Multimodaux

*   Les GenAIs sont souvent principalement entraînés avec des **données en anglais**, ce qui entraîne une disparité de qualité dans d'autres langues.
*   Des techniques multilingues spécifiques ont émergé, comme le "Translate First Prompting" ou des extensions de CoT et ICL pour des contextes multilingues.
*   La **sélection de la langue du template de prompt** peut influencer la performance du modèle, l'anglais étant souvent plus efficace en raison de la prédominance des données d'entraînement.
*   Les modèles GenAI évoluent au-delà du texte, nécessitant des techniques de prompting multimodales pour les images, l'audio, la vidéo et la 3D.

### 6. Extensions du Prompting : Les Agents

*   Les LLMs peuvent être dotés d'un accès à des **outils externes** (calculatrice, interpréteur de code, recherche Internet) pour surmonter leurs lacunes, transformant ainsi la prompt en un moteur d'agent.
*   Des exemples incluent les agents d'utilisation d'outils (comme MRKL System), les agents de génération de code (PAL, ToRA), les agents basés sur l'observation (ReAct, Reflexion), et les systèmes de **Retrieval Augmented Generation (RAG)**, qui récupèrent des informations d'une source externe et les insèrent dans le prompt. Pour "vsix RooCode", l'intégration d'outils (comme un interpréteur de code ou un accès à une base de code externe) est essentielle.

### 7. Problèmes de Prompting (Sécurité et Alignement)

*   **Sécurité**:
    *   **Prompt Hacking** (injection de prompt, jailbreaking).
    *   **Risques de fuite de données** d'entraînement ou de prompt.
    *   **Préoccupations liées à la génération de code** (hallucination de paquets, bugs).
    *   **Mesures de durcissement** : Les défenses basées sur les prompts, les détecteurs et les "Guardrails" (garde-fous) peuvent aider à atténuer ces risques, bien qu'ils ne soient pas toujours entièrement sécurisés. "vsix RooCode" doit intégrer ces mesures pour garantir la sécurité du code généré.
*   **Alignement**:
    *   **Sensibilité aux prompts** : De petits changements (espaces, majuscules, délimiteurs) peuvent avoir un impact significatif sur la performance.
    *   **Dérive du prompt (Prompt Drift)** : Le comportement des modèles peut changer avec le temps, nécessitant une surveillance continue de la performance des prompts.
    *   **Surconfiance et Calibrage** : Les LLMs peuvent être trop confiants, ce qui peut entraîner une sur-dépendance de l'utilisateur.
    *   **Biais, Stéréotypes et Culture** : Les LLMs peuvent perpétuer des biais (par exemple, culturels ou de stéréotypes) dans leurs sorties. L'utilisation de **personas** dans l'évaluation (comme vu dans le nouveau document) met en évidence cette sensibilité.
    *   **Ambiguïté** : Les questions ambiguës peuvent être interprétées de plusieurs façons, ce qui représente un défi pour les modèles.

### 8. Évaluation des Réponses de l'LLM

*   Il est crucial de savoir comment évaluer les sorties des agents et des techniques de prompting pour garantir l'exactitude et éviter les hallucinations.
*   Les LLMs peuvent être utilisés comme évaluateurs eux-mêmes, en bénéficiant de techniques comme l'ICL, le CoT ou l'évaluation basée sur les rôles.
*   Le **format de sortie** (échelle linéaire, binaire, Likert) peut affecter significativement la performance de l'évaluation.

En résumé, pour "vsix RooCode", au-delà des composants de base du prompting, il est impératif de se concentrer sur la **robustesse du système face à la diversité des styles d'écriture des utilisateurs (via l'étude des personas)**, l'intégration intelligente d'outils externes pour les capacités d'agent, et la mise en place de **mesures de sécurité et d'alignement rigoureuses**. L'itération constante et l'évaluation méticuleuse des prompts et des réponses sont la clé pour un système fiable et performant.