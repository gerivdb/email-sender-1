#SingleInstance Force
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1  ; Exécution maximale pour une meilleure réactivité

; ========================================================
; Script AutoHotkey ULTIME pour valider automatiquement 
; les boîtes de dialogue "Keep All" dans Augment Agent
; Version corrigée et améliorée pour AutoHotkey v1.1
; ========================================================

; ========== CONFIGURATION ==========
global AutoKeepAllEnabled := true   ; État initial: activé
global CheckInterval := 100         ; Intervalle de vérification en ms (0.1 seconde)
global ClickCooldown := 1000        ; Temps minimum entre deux clics (1 seconde)
global DebugMode := false           ; Mode débogage
global DetectionMethod := 1         ; Méthode de détection (1-4)

; Raccourcis clavier
global ToggleHotkey := "!k"         ; Alt+K: Activer/désactiver la fonctionnalité
global ForceClickHotkey := "^!k"    ; Ctrl+Alt+K: Forcer un clic sur "Keep All"
global DebugHotkey := "^!d"         ; Ctrl+Alt+D: Mode débogage
global SetPositionHotkey := "^!p"   ; Ctrl+Alt+P: Définir la position du bouton
global ChangeMethodHotkey := "^!m"  ; Ctrl+Alt+M: Changer de méthode de détection

; ========== VARIABLES INTERNES ==========
global LastClickTime := 0           ; Horodatage du dernier clic
global LastFoundX := 0              ; Dernière position X où le bouton a été trouvé
global LastFoundY := 0              ; Dernière position Y où le bouton a été trouvé
global KeepAllColor := 0x2EA043     ; Couleur verte du bouton "Keep All" (format RGB)
global KeepAllRelativeX := 0.95     ; Position relative X du bouton "Keep All" (95% de la largeur de la fenêtre)
global KeepAllRelativeY := 0.98     ; Position relative Y du bouton "Keep All" (98% de la hauteur de la fenêtre)
global DetectionAttempts := 0       ; Nombre de tentatives de détection
global LastSuccessTime := 0         ; Horodatage du dernier succès de détection
global MethodNames := ["Recherche globale", "Recherche dans la barre d'état", "Recherche précise", "Position fixe"]

; ========== RACCOURCIS CLAVIER ==========
Hotkey, %ToggleHotkey%, ToggleAutoKeepAll
Hotkey, %ForceClickHotkey%, ForceClickKeepAll
Hotkey, %DebugHotkey%, ToggleDebugMode
Hotkey, %SetPositionHotkey%, SetKeepAllPosition
Hotkey, %ChangeMethodHotkey%, ChangeDetectionMethod

; ========== FONCTIONS PRINCIPALES ==========

; Fonction pour activer/désactiver la fonctionnalité
ToggleAutoKeepAll:
    AutoKeepAllEnabled := !AutoKeepAllEnabled
    
    if (AutoKeepAllEnabled) {
        SetTimer, CheckForKeepAllButton, %CheckInterval%
        ShowTooltip("Auto Keep All: ACTIVÉ", 1500)
    } else {
        SetTimer, CheckForKeepAllButton, Off
        ShowTooltip("Auto Keep All: DÉSACTIVÉ", 1500)
    }
return

; Fonction pour activer/désactiver le mode débogage
ToggleDebugMode:
    DebugMode := !DebugMode
    ShowTooltip("Mode débogage: " . (DebugMode ? "ACTIVÉ" : "DÉSACTIVÉ"), 1500)
return

; Fonction pour changer de méthode de détection
ChangeDetectionMethod:
    DetectionMethod := Mod(DetectionMethod, 4) + 1
    
    ShowTooltip("Méthode de détection: " . DetectionMethod . " - " . MethodNames[DetectionMethod], 1500)
return

; Fonction pour forcer un clic sur "Keep All"
ForceClickKeepAll:
    ; Sauvegarder la méthode actuelle
    originalMethod := DetectionMethod
    
    ; Essayer chaque méthode jusqu'à ce qu'une réussisse
    Loop, 4 {
        i := A_Index
        DetectionMethod := i
        if (FindAndClickKeepAll(true)) {
            ShowTooltip("Keep All cliqué avec méthode " . i, 1000)
            ; Restaurer la méthode originale
            DetectionMethod := originalMethod
            return
        }
    }
    
    ; Restaurer la méthode originale
    DetectionMethod := originalMethod
    ShowTooltip("Impossible de trouver le bouton Keep All", 1500)
return

; Fonction pour définir la position du bouton "Keep All"
SetKeepAllPosition:
    ; Obtenir la position actuelle de la souris
    MouseGetPos, MouseX, MouseY
    
    ; Obtenir les dimensions de la fenêtre
    WinGetPos, WinX, WinY, WinWidth, WinHeight, A
    
    ; Calculer les positions relatives
    KeepAllRelativeX := (MouseX - WinX) / WinWidth
    KeepAllRelativeY := (MouseY - WinY) / WinHeight
    
    ; Sauvegarder la position absolue
    LastFoundX := MouseX
    LastFoundY := MouseY
    
    ; Vérifier la couleur du pixel à cette position
    PixelGetColor, color, MouseX, MouseY, RGB
    
    ; Calculer les pourcentages
    relativeXPercent := KeepAllRelativeX * 100
    relativeYPercent := KeepAllRelativeY * 100
    
    ; Arrondir les valeurs
    relativeXPercent := Floor(relativeXPercent)
    relativeYPercent := Floor(relativeYPercent)
    
    ShowTooltip("Position définie: " . MouseX . "," . MouseY . 
                "`nPosition relative: " . relativeXPercent . "%, " . relativeYPercent . "%" .
                "`nCouleur: " . color . " (Attendu: " . KeepAllColor . ")", 3000)
    
    ; Mettre à jour la couleur du bouton si elle est différente
    if (color != KeepAllColor) {
        KeepAllColor := color
        ShowTooltip("Couleur du bouton mise à jour: " . color, 1500)
    }
return

; Fonction pour afficher une infobulle temporaire
ShowTooltip(text, duration) {
    Tooltip, %text%
    SetTimer, RemoveTooltip, %duration%
}

; Fonction pour supprimer l'infobulle
RemoveTooltip:
    Tooltip
return

; Fonction principale qui vérifie et clique sur le bouton "Keep All"
CheckForKeepAllButton:
    if (!AutoKeepAllEnabled)
        return
    
    ; Incrémenter le compteur de tentatives
    DetectionAttempts++
    
    ; Calculer le temps écoulé depuis le dernier succès
    currentTime := A_TickCount
    timeSinceLastSuccess := currentTime - LastSuccessTime
    
    ; Changer de méthode toutes les 20 tentatives si aucun bouton n'a été trouvé récemment
    if (Mod(DetectionAttempts, 20) = 0 && (LastSuccessTime = 0 || timeSinceLastSuccess > 10000)) {
        DetectionMethod := Mod(DetectionMethod, 4) + 1
        if (DebugMode)
            ShowTooltip("Changement automatique de méthode: " . DetectionMethod . " - " . MethodNames[DetectionMethod], 500)
    }
    
    FindAndClickKeepAll(false)
return

; Fonction qui trouve et clique sur le bouton "Keep All"
FindAndClickKeepAll(force := false) {
    global LastClickTime, ClickCooldown, DebugMode, LastFoundX, LastFoundY, KeepAllColor
    global KeepAllRelativeX, KeepAllRelativeY, DetectionMethod, LastSuccessTime, DetectionAttempts
    
    ; Vérifier le cooldown sauf si forcé
    if (!force) {
        currentTime := A_TickCount
        if (currentTime - LastClickTime < ClickCooldown)
            return false
    }
    
    ; Vérifier si VS Code est actif
    if (!WinActive("ahk_exe Code.exe") && !WinActive("ahk_exe VSCodium.exe"))
        return false
    
    ; Obtenir les dimensions de la fenêtre
    WinGetPos, WinX, WinY, WinWidth, WinHeight, A
    
    ; Variables pour stocker la position trouvée
    found := false
    FoundX := 0
    FoundY := 0
    
    ; Utiliser différentes méthodes de détection selon la configuration
    if (DetectionMethod = 1) {
        ; Méthode 1: Recherche globale
        if (DebugMode)
            ShowTooltip("Méthode 1: Recherche globale", 300)
        
        ; Rechercher la couleur verte dans toute la fenêtre
        PixelSearch, FoundX, FoundY, WinX, WinY, WinX + WinWidth, WinY + WinHeight, %KeepAllColor%, 30, Fast RGB
        
        if (!ErrorLevel) {
            found := true
            if (DebugMode)
                ShowTooltip("Bouton trouvé (méthode 1) à " . FoundX . "," . FoundY, 500)
        }
    }
    else if (DetectionMethod = 2) {
        ; Méthode 2: Recherche dans la barre d'état
        if (DebugMode)
            ShowTooltip("Méthode 2: Recherche dans la barre d'état", 300)
        
        ; Zone de recherche: barre d'état en bas de la fenêtre (ajustée pour être plus flexible)
        StatusBarY := WinHeight - 40
        
        ; Rechercher la couleur verte dans la barre d'état
        PixelSearch, FoundX, FoundY, WinX, WinY + StatusBarY, WinX + WinWidth, WinY + WinHeight, %KeepAllColor%, 30, Fast RGB
        
        if (!ErrorLevel) {
            found := true
            if (DebugMode)
                ShowTooltip("Bouton trouvé (méthode 2) à " . FoundX . "," . FoundY, 500)
        }
    }
    else if (DetectionMethod = 3) {
        ; Méthode 3: Recherche précise
        if (DebugMode)
            ShowTooltip("Méthode 3: Recherche précise", 300)
        
        ; Rechercher spécifiquement dans la partie droite de la barre d'état
        StatusBarY := WinHeight - 40
        RightSideX := WinX + WinWidth - 300  ; Élargi pour être plus flexible
        
        ; Rechercher la couleur verte dans cette zone
        PixelSearch, FoundX, FoundY, RightSideX, WinY + StatusBarY, WinX + WinWidth, WinY + WinHeight, %KeepAllColor%, 30, Fast RGB
        
        if (!ErrorLevel) {
            found := true
            if (DebugMode)
                ShowTooltip("Bouton trouvé (méthode 3) à " . FoundX . "," . FoundY, 500)
        }
    }
    else if (DetectionMethod = 4) {
        ; Méthode 4: Position fixe
        if (DebugMode)
            ShowTooltip("Méthode 4: Position fixe", 300)
        
        ; Calculer la position absolue du bouton "Keep All"
        FoundX := WinX + (WinWidth * KeepAllRelativeX)
        FoundY := WinY + (WinHeight * KeepAllRelativeY)
        
        ; Vérifier si la couleur à cette position est verte
        PixelGetColor, color, FoundX, FoundY, RGB
        
        if (IsColorSimilar(color, KeepAllColor, 50)) {
            found := true
            if (DebugMode)
                ShowTooltip("Bouton trouvé (méthode 4) à " . FoundX . "," . FoundY, 500)
        }
    }
    
    ; Si le bouton n'est pas trouvé et que nous avons une position précédente, essayer à proximité
    if (!found && LastFoundX > 0 && LastFoundY > 0) {
        if (DebugMode)
            ShowTooltip("Recherche à proximité de la dernière position", 300)
        
        ; Vérifier si la couleur à la dernière position connue est toujours verte
        PixelGetColor, lastColor, LastFoundX, LastFoundY, RGB
        
        if (IsColorSimilar(lastColor, KeepAllColor, 30)) {
            FoundX := LastFoundX
            FoundY := LastFoundY
            found := true
            
            if (DebugMode)
                ShowTooltip("Bouton trouvé à la dernière position", 500)
        } else {
            ; Rechercher dans une zone de 100x50 pixels autour de la dernière position connue
            PixelSearch, FoundX, FoundY, LastFoundX - 50, LastFoundY - 25, LastFoundX + 50, LastFoundY + 25, %KeepAllColor%, 30, Fast RGB
            
            if (!ErrorLevel) {
                found := true
                if (DebugMode)
                    ShowTooltip("Bouton trouvé à proximité", 500)
            }
        }
    }
    
    ; Si le bouton est trouvé ou si on force le clic
    if (found || force) {
        ; Si on force le clic mais qu'aucun bouton n'a été trouvé, utiliser la dernière position connue
        if (force && !found && LastFoundX > 0 && LastFoundY > 0) {
            FoundX := LastFoundX
            FoundY := LastFoundY
        }
        ; Si on force le clic mais qu'aucune position n'est connue, utiliser la position relative
        else if (force && !found) {
            FoundX := WinX + (WinWidth * KeepAllRelativeX)
            FoundY := WinY + (WinHeight * KeepAllRelativeY)
        }
        
        ; Sauvegarder la position actuelle de la souris
        MouseGetPos, OldX, OldY
        
        ; Sauvegarder la position du bouton pour les recherches futures
        LastFoundX := FoundX
        LastFoundY := FoundY
        
        ; Déplacer la souris et cliquer
        MouseMove, %FoundX%, %FoundY%, 0
        
        ; Attendre un court instant pour s'assurer que la souris est bien positionnée
        Sleep, 50
        
        ; Cliquer
        Click
        
        ; Mettre à jour l'horodatage du dernier clic
        LastClickTime := A_TickCount
        
        ; Mettre à jour l'horodatage du dernier succès
        LastSuccessTime := A_TickCount
        
        ; Réinitialiser le compteur de tentatives
        DetectionAttempts := 0
        
        ; Revenir à la position précédente de la souris
        MouseMove, %OldX%, %OldY%, 0
        
        ; Afficher une notification
        if (!DebugMode)
            ShowTooltip("Keep All validé (méthode " . DetectionMethod . ")", 1000)
        
        return true
    }
    
    return false
}

; Fonction pour comparer deux couleurs avec une tolérance
IsColorSimilar(color1, color2, tolerance) {
    ; Extraire les composantes RGB
    r1 := (color1 >> 16) & 0xFF
    g1 := (color1 >> 8) & 0xFF
    b1 := color1 & 0xFF
    
    r2 := (color2 >> 16) & 0xFF
    g2 := (color2 >> 8) & 0xFF
    b2 := color2 & 0xFF
    
    ; Calculer la différence
    rDiff := Abs(r1 - r2)
    gDiff := Abs(g1 - g2)
    bDiff := Abs(b1 - b2)
    
    ; Vérifier si la différence est inférieure à la tolérance
    return (rDiff <= tolerance && gDiff <= tolerance && bDiff <= tolerance)
}

; ========== INITIALISATION ==========
InitScript() {
    global AutoKeepAllEnabled, CheckInterval
    
    ; Démarrer la vérification périodique
    if (AutoKeepAllEnabled)
        SetTimer, CheckForKeepAllButton, %CheckInterval%
    
    ; Afficher un message de démarrage
    startupMsg := "Script Auto Keep All ULTIME démarré`n"
                . "Alt+K: activer/désactiver`n"
                . "Ctrl+Alt+K: forcer un clic`n"
                . "Ctrl+Alt+D: mode débogage`n"
                . "Ctrl+Alt+P: définir la position du bouton`n"
                . "Ctrl+Alt+M: changer de méthode de détection"
    
    ShowTooltip(startupMsg, 3000)
}

; Exécuter l'initialisation
InitScript()
