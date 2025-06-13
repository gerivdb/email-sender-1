# Algorithmes de conversion entre formats Roadmap, XML et HTML

Ce document détaille les algorithmes spécifiques pour convertir entre le format Roadmap (Markdown) et les formats XML et HTML.

## 1. Algorithme de conversion de Roadmap vers XML

### Étape 1: Parsing du Markdown

```plaintext
Fonction ParseRoadmapMarkdown(markdownText):
    roadmapData = {
        title: "",
        overview: "",
        sections: []
    }
    
    # Extraire le titre

    titleMatch = RegexMatch(markdownText, "^# (.+)$", MultiLine)

    if titleMatch:
        roadmapData.title = titleMatch.group(1)
    
    # Extraire la vue d'ensemble

    overviewMatch = RegexMatch(markdownText, "^## Vue d'ensemble.+?\n\n(.+?)(?=\n\n## )", DotAll)

    if overviewMatch:
        roadmapData.overview = overviewMatch.group(1)
    
    # Extraire les sections

    sectionMatches = RegexMatchAll(markdownText, "^## (\d+)\. (.+?)\n(.+?)(?=\n\n## |$)", MultiLine | DotAll)

    
    pour chaque sectionMatch dans sectionMatches:
        sectionId = sectionMatch.group(1)
        sectionTitle = sectionMatch.group(2)
        sectionContent = sectionMatch.group(3)
        
        section = {
            id: sectionId,
            title: sectionTitle,
            metadata: {},
            phases: []
        }
        
        # Extraire les métadonnées

        metadataMatches = RegexMatchAll(sectionContent, "\*\*(.+?)\*\*: (.+?)(?=\n\*\*|\n\n)", MultiLine | DotAll)
        pour chaque metadataMatch dans metadataMatches:
            metadataKey = metadataMatch.group(1)
            metadataValue = metadataMatch.group(2)
            section.metadata[metadataKey] = metadataValue
        
        # Extraire les phases

        phaseMatches = RegexMatchAll(sectionContent, "- \[([ x])\] \*\*Phase (\d+): (.+?)\*\*(.+?)(?=\n- \[|$)", MultiLine | DotAll)
        
        pour chaque phaseMatch dans phaseMatches:
            phaseCompleted = (phaseMatch.group(1) == "x")
            phaseId = phaseMatch.group(2)
            phaseTitle = phaseMatch.group(3)
            phaseContent = phaseMatch.group(4)
            
            phase = {
                id: phaseId,
                title: phaseTitle,
                completed: phaseCompleted,
                tasks: [],
                notes: []
            }
            
            # Extraire les tâches

            taskMatches = RegexMatchAll(phaseContent, "\n  - \[([ x])\] (.+?)(?=\n  - \[|\n\n|$)", MultiLine | DotAll)
            
            pour chaque taskMatch dans taskMatches:
                taskCompleted = (taskMatch.group(1) == "x")
                taskContent = taskMatch.group(2)
                
                # Extraire le titre, le temps estimé et la date de début

                taskTitleMatch = RegexMatch(taskContent, "(.+?)(?:\s+\((.+?)\))?(?:\s+-\s+\*(.+?)\*)?$")
                
                task = {
                    title: taskTitleMatch.group(1),
                    estimatedTime: taskTitleMatch.group(2) || "",
                    startDate: taskTitleMatch.group(3) || "",
                    completed: taskCompleted,
                    subtasks: []
                }
                
                # Extraire les sous-tâches

                subtaskMatches = RegexMatchAll(phaseContent, "\n    - \[([ x])\] (.+?)(?=\n    - \[|\n  - \[|\n\n|$)", MultiLine | DotAll)
                
                pour chaque subtaskMatch dans subtaskMatches:
                    subtaskCompleted = (subtaskMatch.group(1) == "x")
                    subtaskTitle = subtaskMatch.group(2)
                    
                    subtask = {
                        title: subtaskTitle,
                        completed: subtaskCompleted
                    }
                    
                    task.subtasks.push(subtask)
                
                phase.tasks.push(task)
            
            # Extraire les notes

            noteMatches = RegexMatchAll(phaseContent, "\n  > \*Note: (.+?)\*(?=\n  >|\n\n|$)", MultiLine | DotAll)
            
            pour chaque noteMatch dans noteMatches:
                noteText = noteMatch.group(1)
                phase.notes.push(noteText)
            
            section.phases.push(phase)
        
        roadmapData.sections.push(section)
    
    retourner roadmapData
```plaintext
### Étape 2: Génération du XML

```plaintext
Fonction GenerateXML(roadmapData):
    # Créer un document XML

    xmlDoc = CreateXMLDocument()
    
    # Créer l'élément racine

    rootElement = xmlDoc.createElement("roadmap")
    rootElement.setAttribute("title", roadmapData.title)
    xmlDoc.appendChild(rootElement)
    
    # Ajouter la vue d'ensemble

    overviewElement = xmlDoc.createElement("overview")
    overviewElement.textContent = roadmapData.overview
    rootElement.appendChild(overviewElement)
    
    # Ajouter les sections

    pour chaque section dans roadmapData.sections:
        sectionElement = xmlDoc.createElement("section")
        sectionElement.setAttribute("id", section.id)
        sectionElement.setAttribute("title", section.title)
        
        # Ajouter les métadonnées

        metadataElement = xmlDoc.createElement("metadata")
        
        pour chaque key, value dans section.metadata:
            metadataItemElement = xmlDoc.createElement(ConvertToValidXmlName(key))
            metadataItemElement.textContent = value
            metadataElement.appendChild(metadataItemElement)
        
        sectionElement.appendChild(metadataElement)
        
        # Ajouter les phases

        pour chaque phase dans section.phases:
            phaseElement = xmlDoc.createElement("phase")
            phaseElement.setAttribute("id", phase.id)
            phaseElement.setAttribute("title", phase.title)
            phaseElement.setAttribute("completed", phase.completed.toString())
            
            # Ajouter les tâches

            pour chaque task dans phase.tasks:
                taskElement = xmlDoc.createElement("task")
                taskElement.setAttribute("title", task.title)
                
                si task.estimatedTime:
                    taskElement.setAttribute("estimatedTime", task.estimatedTime)
                
                si task.startDate:
                    taskElement.setAttribute("startDate", task.startDate)
                
                taskElement.setAttribute("completed", task.completed.toString())
                
                # Ajouter les sous-tâches

                pour chaque subtask dans task.subtasks:
                    subtaskElement = xmlDoc.createElement("subtask")
                    subtaskElement.setAttribute("title", subtask.title)
                    subtaskElement.setAttribute("completed", subtask.completed.toString())
                    taskElement.appendChild(subtaskElement)
                
                phaseElement.appendChild(taskElement)
            
            # Ajouter les notes

            pour chaque note dans phase.notes:
                noteElement = xmlDoc.createElement("note")
                noteElement.textContent = note
                phaseElement.appendChild(noteElement)
            
            sectionElement.appendChild(phaseElement)
        
        rootElement.appendChild(sectionElement)
    
    retourner xmlDoc
```plaintext
## 2. Algorithme de conversion de Roadmap vers HTML

### Étape 1: Parsing du Markdown

```plaintext
# Utiliser la même fonction ParseRoadmapMarkdown que pour la conversion vers XML

```plaintext
### Étape 2: Génération du HTML

```plaintext
Fonction GenerateHTML(roadmapData):
    # Créer un document HTML

    htmlDoc = CreateHTMLDocument()
    
    # Ajouter le titre et les styles CSS

    htmlDoc.head.innerHTML = `
        <title>${roadmapData.title}</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .section { margin-bottom: 30px; }
            .metadata { margin-bottom: 15px; }
            .phase { margin-left: 20px; margin-bottom: 20px; }
            .task { margin-left: 40px; margin-bottom: 10px; }
            .subtask { margin-left: 60px; margin-bottom: 5px; }
            .completed { color: #666; }

            .completed h3, .completed p { text-decoration: line-through; }
            .note { margin-left: 40px; color: #888; font-style: italic; }

        </style>
    `
    
    # Ajouter le titre

    titleElement = htmlDoc.createElement("h1")
    titleElement.textContent = roadmapData.title
    htmlDoc.body.appendChild(titleElement)
    
    # Ajouter la vue d'ensemble

    overviewElement = htmlDoc.createElement("p")
    overviewElement.textContent = roadmapData.overview
    htmlDoc.body.appendChild(overviewElement)
    
    # Ajouter les sections

    pour chaque section dans roadmapData.sections:
        sectionElement = htmlDoc.createElement("div")
        sectionElement.className = "section"
        
        # Ajouter le titre de la section

        sectionTitleElement = htmlDoc.createElement("h2")
        sectionTitleElement.textContent = section.id + ". " + section.title
        sectionElement.appendChild(sectionTitleElement)
        
        # Ajouter les métadonnées

        metadataElement = htmlDoc.createElement("div")
        metadataElement.className = "metadata"
        
        pour chaque key, value dans section.metadata:
            metadataItemElement = htmlDoc.createElement("p")
            metadataItemElement.innerHTML = `<strong>${key}</strong>: ${value}`
            metadataElement.appendChild(metadataItemElement)
        
        sectionElement.appendChild(metadataElement)
        
        # Ajouter les phases

        pour chaque phase dans section.phases:
            phaseElement = htmlDoc.createElement("div")
            phaseElement.className = "phase"
            
            si phase.completed:
                phaseElement.classList.add("completed")
            
            # Ajouter le titre de la phase

            phaseTitleElement = htmlDoc.createElement("h3")
            phaseTitleElement.innerHTML = `
                <input type="checkbox" ${phase.completed ? "checked" : ""} disabled>
                Phase ${phase.id}: ${phase.title}
            `
            phaseElement.appendChild(phaseTitleElement)
            
            # Ajouter les tâches

            pour chaque task dans phase.tasks:
                taskElement = htmlDoc.createElement("div")
                taskElement.className = "task"
                
                si task.completed:
                    taskElement.classList.add("completed")
                
                # Ajouter le titre de la tâche

                taskTitleElement = htmlDoc.createElement("p")
                taskTitleText = task.title
                
                si task.estimatedTime:
                    taskTitleText += ` (${task.estimatedTime})`
                
                si task.startDate:
                    taskTitleText += ` - <em>${task.startDate}</em>`
                
                taskTitleElement.innerHTML = `
                    <input type="checkbox" ${task.completed ? "checked" : ""} disabled>
                    ${taskTitleText}
                `
                taskElement.appendChild(taskTitleElement)
                
                # Ajouter les sous-tâches

                pour chaque subtask dans task.subtasks:
                    subtaskElement = htmlDoc.createElement("div")
                    subtaskElement.className = "subtask"
                    
                    si subtask.completed:
                        subtaskElement.classList.add("completed")
                    
                    # Ajouter le titre de la sous-tâche

                    subtaskTitleElement = htmlDoc.createElement("p")
                    subtaskTitleElement.innerHTML = `
                        <input type="checkbox" ${subtask.completed ? "checked" : ""} disabled>
                        ${subtask.title}
                    `
                    subtaskElement.appendChild(subtaskTitleElement)
                    
                    taskElement.appendChild(subtaskElement)
                
                phaseElement.appendChild(taskElement)
            
            # Ajouter les notes

            pour chaque note dans phase.notes:
                noteElement = htmlDoc.createElement("div")
                noteElement.className = "note"
                
                noteTextElement = htmlDoc.createElement("p")
                noteTextElement.innerHTML = `<em>Note: ${note}</em>`
                noteElement.appendChild(noteTextElement)
                
                phaseElement.appendChild(noteElement)
            
            sectionElement.appendChild(phaseElement)
        
        htmlDoc.body.appendChild(sectionElement)
    
    retourner htmlDoc
```plaintext
## 3. Algorithme de conversion de XML vers Roadmap

### Étape 1: Parsing du XML

```plaintext
Fonction ParseRoadmapXML(xmlDoc):
    roadmapData = {
        title: "",
        overview: "",
        sections: []
    }
    
    # Extraire le titre

    rootElement = xmlDoc.documentElement
    roadmapData.title = rootElement.getAttribute("title")
    
    # Extraire la vue d'ensemble

    overviewElement = rootElement.getElementsByTagName("overview")[0]
    si overviewElement:
        roadmapData.overview = overviewElement.textContent
    
    # Extraire les sections

    sectionElements = rootElement.getElementsByTagName("section")
    
    pour chaque sectionElement dans sectionElements:
        section = {
            id: sectionElement.getAttribute("id"),
            title: sectionElement.getAttribute("title"),
            metadata: {},
            phases: []
        }
        
        # Extraire les métadonnées

        metadataElement = sectionElement.getElementsByTagName("metadata")[0]
        si metadataElement:
            pour chaque metadataItemElement dans metadataElement.childNodes:
                si metadataItemElement.nodeType == ELEMENT_NODE:
                    section.metadata[metadataItemElement.nodeName] = metadataItemElement.textContent
        
        # Extraire les phases

        phaseElements = sectionElement.getElementsByTagName("phase")
        
        pour chaque phaseElement dans phaseElements:
            phase = {
                id: phaseElement.getAttribute("id"),
                title: phaseElement.getAttribute("title"),
                completed: (phaseElement.getAttribute("completed") == "true"),
                tasks: [],
                notes: []
            }
            
            # Extraire les tâches

            taskElements = phaseElement.getElementsByTagName("task")
            
            pour chaque taskElement dans taskElements:
                task = {
                    title: taskElement.getAttribute("title"),
                    estimatedTime: taskElement.getAttribute("estimatedTime") || "",
                    startDate: taskElement.getAttribute("startDate") || "",
                    completed: (taskElement.getAttribute("completed") == "true"),
                    subtasks: []
                }
                
                # Extraire les sous-tâches

                subtaskElements = taskElement.getElementsByTagName("subtask")
                
                pour chaque subtaskElement dans subtaskElements:
                    subtask = {
                        title: subtaskElement.getAttribute("title"),
                        completed: (subtaskElement.getAttribute("completed") == "true")
                    }
                    
                    task.subtasks.push(subtask)
                
                phase.tasks.push(task)
            
            # Extraire les notes

            noteElements = phaseElement.getElementsByTagName("note")
            
            pour chaque noteElement dans noteElements:
                phase.notes.push(noteElement.textContent)
            
            section.phases.push(phase)
        
        roadmapData.sections.push(section)
    
    retourner roadmapData
```plaintext
### Étape 2: Génération du Markdown

```plaintext
Fonction GenerateMarkdown(roadmapData):
    markdown = ""
    
    # Ajouter le titre

    markdown += "# " + roadmapData.title + "\n\n"

    
    # Ajouter la vue d'ensemble

    si roadmapData.overview:
        markdown += "## Vue d'ensemble des taches par priorite et complexite\n\n"

        markdown += roadmapData.overview + "\n\n"
    
    # Ajouter les sections

    pour chaque section dans roadmapData.sections:
        markdown += "## " + section.id + ". " + section.title + "\n"

        
        # Ajouter les métadonnées

        pour chaque key, value dans section.metadata:
            markdown += "**" + key + "**: " + value + "\n"
        
        markdown += "\n"
        
        # Ajouter les phases

        pour chaque phase dans section.phases:
            markdown += "- [" + (phase.completed ? "x" : " ") + "] **Phase " + phase.id + ": " + phase.title + "**\n"
            
            # Ajouter les tâches

            pour chaque task dans phase.tasks:
                markdown += "  - [" + (task.completed ? "x" : " ") + "] " + task.title
                
                si task.estimatedTime:
                    markdown += " (" + task.estimatedTime + ")"
                
                si task.startDate:
                    markdown += " - *" + task.startDate + "*"
                
                markdown += "\n"
                
                # Ajouter les sous-tâches

                pour chaque subtask dans task.subtasks:
                    markdown += "    - [" + (subtask.completed ? "x" : " ") + "] " + subtask.title + "\n"
            
            # Ajouter les notes

            pour chaque note dans phase.notes:
                markdown += "  > *Note: " + note + "*\n"
            
            markdown += "\n"
    
    retourner markdown
```plaintext
## 4. Algorithme de conversion de HTML vers Roadmap

### Étape 1: Parsing du HTML

```plaintext
Fonction ParseRoadmapHTML(htmlDoc):
    roadmapData = {
        title: "",
        overview: "",
        sections: []
    }
    
    # Extraire le titre

    titleElement = htmlDoc.querySelector("h1")
    si titleElement:
        roadmapData.title = titleElement.textContent
    
    # Extraire la vue d'ensemble

    overviewElement = htmlDoc.querySelector("h1 + p")
    si overviewElement:
        roadmapData.overview = overviewElement.textContent
    
    # Extraire les sections

    sectionElements = htmlDoc.querySelectorAll(".section")
    
    pour chaque sectionElement dans sectionElements:
        # Extraire l'ID et le titre

        sectionTitleElement = sectionElement.querySelector("h2")
        sectionTitleMatch = RegexMatch(sectionTitleElement.textContent, "^(\d+)\. (.+)$")
        
        section = {
            id: sectionTitleMatch.group(1),
            title: sectionTitleMatch.group(2),
            metadata: {},
            phases: []
        }
        
        # Extraire les métadonnées

        metadataElement = sectionElement.querySelector(".metadata")
        si metadataElement:
            metadataItemElements = metadataElement.querySelectorAll("p")
            
            pour chaque metadataItemElement dans metadataItemElements:
                metadataMatch = RegexMatch(metadataItemElement.textContent, "^(.+?): (.+)$")
                si metadataMatch:
                    section.metadata[metadataMatch.group(1)] = metadataMatch.group(2)
        
        # Extraire les phases

        phaseElements = sectionElement.querySelectorAll(".phase")
        
        pour chaque phaseElement dans phaseElements:
            # Extraire le titre et l'état

            phaseTitleElement = phaseElement.querySelector("h3")
            phaseCheckbox = phaseTitleElement.querySelector("input[type=checkbox]")
            phaseTitleMatch = RegexMatch(phaseTitleElement.textContent.trim(), "^Phase (\d+): (.+)$")
            
            phase = {
                id: phaseTitleMatch.group(1),
                title: phaseTitleMatch.group(2),
                completed: phaseCheckbox.checked,
                tasks: [],
                notes: []
            }
            
            # Extraire les tâches

            taskElements = phaseElement.querySelectorAll(".task")
            
            pour chaque taskElement dans taskElements:
                # Extraire le titre, l'état et les métadonnées

                taskTitleElement = taskElement.querySelector("p")
                taskCheckbox = taskTitleElement.querySelector("input[type=checkbox]")
                
                # Extraire le texte sans les éléments enfants

                taskTitleText = taskTitleElement.textContent.trim()
                
                # Extraire le temps estimé et la date de début

                taskTitleMatch = RegexMatch(taskTitleText, "^(.+?)(?:\s+\((.+?)\))?(?:\s+-\s+(.+?))?$")
                
                task = {
                    title: taskTitleMatch.group(1),
                    estimatedTime: taskTitleMatch.group(2) || "",
                    startDate: taskTitleMatch.group(3) || "",
                    completed: taskCheckbox.checked,
                    subtasks: []
                }
                
                # Extraire les sous-tâches

                subtaskElements = taskElement.querySelectorAll(".subtask")
                
                pour chaque subtaskElement dans subtaskElements:
                    # Extraire le titre et l'état

                    subtaskTitleElement = subtaskElement.querySelector("p")
                    subtaskCheckbox = subtaskTitleElement.querySelector("input[type=checkbox]")
                    
                    subtask = {
                        title: subtaskTitleElement.textContent.trim(),
                        completed: subtaskCheckbox.checked
                    }
                    
                    task.subtasks.push(subtask)
                
                phase.tasks.push(task)
            
            # Extraire les notes

            noteElements = phaseElement.querySelectorAll(".note")
            
            pour chaque noteElement dans noteElements:
                noteTextElement = noteElement.querySelector("p")
                noteMatch = RegexMatch(noteTextElement.textContent, "^Note: (.+)$")
                si noteMatch:
                    phase.notes.push(noteMatch.group(1))
            
            section.phases.push(phase)
        
        roadmapData.sections.push(section)
    
    retourner roadmapData
```plaintext
### Étape 2: Génération du Markdown

```plaintext
# Utiliser la même fonction GenerateMarkdown que pour la conversion depuis XML

```plaintext
## 5. Optimisations et considérations

### 5.1 Optimisation des expressions régulières

- Utiliser des expressions régulières compilées pour améliorer les performances
- Limiter l'utilisation de constructions coûteuses comme les lookbehinds et lookaheads
- Utiliser des groupes de capture nommés pour améliorer la lisibilité

### 5.2 Gestion de la mémoire

- Utiliser des techniques de streaming pour les fichiers volumineux
- Libérer les ressources non utilisées dès que possible
- Éviter de charger l'intégralité du document en mémoire pour les fichiers très volumineux

### 5.3 Gestion des erreurs

- Valider les entrées avant de commencer la conversion
- Gérer les cas où les expressions régulières ne correspondent pas
- Fournir des messages d'erreur clairs et utiles

### 5.4 Extensibilité

- Concevoir les algorithmes de manière à pouvoir facilement ajouter de nouveaux formats
- Utiliser des interfaces communes pour les différents parsers et générateurs
- Séparer clairement les étapes de parsing et de génération
