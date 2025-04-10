#SingleInstance Force
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1  ; Exécution maximale pour une meilleure réactivité

; ========================================================
; Script AutoHotkey corrigé pour valider automatiquement 
; les boîtes de dialogue "Keep All" dans Augment Agent
; ========================================================

; ========== CONFIGURATION ==========
global AutoKeepAllEnabled := true   ; État initial: activé
global CheckInterval := 100         ; Intervalle de vérification en ms (0.1 seconde)
global ClickCooldown := 1000        ; Temps minimum entre deux clics (1 seconde)
global DebugMode := false           ; Mode débogage

; Raccourcis clavier
global ToggleHotkey := "!k"         ; Alt+K: Activer/désactiver la fonctionnalité
global ForceClickHotkey := "^!k"    ; Ctrl+Alt+K: Forcer un clic sur "Keep All"
global DebugHotkey := "^!d"         ; Ctrl+Alt+D: Mode débogage

; ========== VARIABLES INTERNES ==========
global LastClickTime := 0           ; Horodatage du dernier clic
global LastFoundX := 0              ; Dernière position X où le bouton a été trouvé
global LastFoundY := 0              ; Dernière position Y où le bouton a été trouvé

; ========== RACCOURCIS CLAVIER ==========
Hotkey, %ToggleHotkey%, ToggleAutoKeepAll
Hotkey, %ForceClickHotkey%, ForceClickKeepAll
Hotkey, %DebugHotkey%, ToggleDebugMode

; ========== FONCTIONS PRINCIPALES ==========

; Fonction pour activer/désactiver la fonctionnalité
ToggleAutoKeepAll() {
    global AutoKeepAllEnabled, CheckInterval
    AutoKeepAllEnabled := !AutoKeepAllEnabled
    
    if (AutoKeepAllEnabled) {
        SetTimer, CheckForKeepAllButton, %CheckInterval%
        ShowTooltip("Auto Keep All: ACTIVÉ", 1500)
    } else {
        SetTimer, CheckForKeepAllButton, Off
        ShowTooltip("Auto Keep All: DÉSACTIVÉ", 1500)
    }
}

; Fonction pour activer/désactiver le mode débogage
ToggleDebugMode() {
    global DebugMode
    DebugMode := !DebugMode
    ShowTooltip("Mode débogage: " . (DebugMode ? "ACTIVÉ" : "DÉSACTIVÉ"), 1500)
}

; Fonction pour forcer un clic sur "Keep All"
ForceClickKeepAll() {
    if (FindAndClickKeepAll(true)) {
        ShowTooltip("Keep All cliqué manuellement", 1000)
    } else {
        ShowTooltip("Impossible de trouver le bouton Keep All", 1500)
    }
}

; Fonction pour afficher une infobulle temporaire
ShowTooltip(text, duration) {
    Tooltip, %text%
    SetTimer, RemoveTooltip, %duration%
}

; Fonction pour supprimer l'infobulle
RemoveTooltip() {
    Tooltip
}

; Fonction principale qui vérifie et clique sur le bouton "Keep All"
CheckForKeepAllButton:
    if (!AutoKeepAllEnabled)
        return
    
    FindAndClickKeepAll(false)
return

; Fonction qui trouve et clique sur le bouton "Keep All"
FindAndClickKeepAll(force := false) {
    global LastClickTime, ClickCooldown, DebugMode, LastFoundX, LastFoundY
    
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
    
    ; Zone de recherche: barre d'état en bas de la fenêtre
    StatusBarY := WinHeight - 30
    
    ; Méthode 1: Recherche par pixel de couleur verte dans la barre d'état
    found := false
    FoundX := 0
    FoundY := 0
    
    ; Rechercher le bouton "Keep All" (couleur verte) dans la barre d'état
    PixelSearch, FoundX, FoundY, WinX, WinY + StatusBarY, WinX + WinWidth, WinY + WinHeight, 0x2EA043, 20, Fast RGB
    
    if (!ErrorLevel) {
        found := true
        if (DebugMode)
            ShowTooltip("Bouton Keep All trouvé à " . FoundX . "," . FoundY, 500)
    }
    
    ; Si le bouton n'est pas trouvé et que nous avons une position précédente, essayer à proximité
    if (!found && LastFoundX > 0 && LastFoundY > 0) {
        if (DebugMode)
            ShowTooltip("Recherche à proximité de la dernière position", 500)
        
        ; Rechercher dans une zone de 100x50 pixels autour de la dernière position connue
        PixelSearch, FoundX, FoundY, LastFoundX - 50, LastFoundY - 25, LastFoundX + 50, LastFoundY + 25, 0x2EA043, 20, Fast RGB
        
        if (!ErrorLevel) {
            found := true
            if (DebugMode)
                ShowTooltip("Bouton Keep All trouvé à proximité", 500)
        }
    }
    
    ; Méthode 2: Recherche spécifique dans la zone où le bouton "Keep All" apparaît généralement
    if (!found) {
        ; Rechercher dans la partie droite de la barre d'état
        RightSideX := WinX + WinWidth - 200
        PixelSearch, FoundX, FoundY, RightSideX, WinY + StatusBarY, WinX + WinWidth, WinY + WinHeight, 0x2EA043, 20, Fast RGB
        
        if (!ErrorLevel) {
            found := true
            if (DebugMode)
                ShowTooltip("Bouton Keep All trouvé dans la partie droite", 500)
        }
    }
    
    ; Si le bouton est trouvé, cliquer dessus
    if (found) {
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
        
        ; Revenir à la position précédente de la souris
        MouseMove, %OldX%, %OldY%, 0
        
        ; Afficher une notification
        if (!DebugMode)
            ShowTooltip("Keep All validé", 1000)
        
        return true
    }
    
    return false
}

; ========== INITIALISATION ==========
InitScript() {
    global AutoKeepAllEnabled, CheckInterval
    
    ; Démarrer la vérification périodique
    if (AutoKeepAllEnabled)
        SetTimer, CheckForKeepAllButton, %CheckInterval%
    
    ; Afficher un message de démarrage
    startupMsg := "Script Auto Keep All CORRIGÉ démarré`n"
                . "Alt+K: activer/désactiver`n"
                . "Ctrl+Alt+K: forcer un clic`n"
                . "Ctrl+Alt+D: mode débogage"
    
    ShowTooltip(startupMsg, 3000)
}

; Exécuter l'initialisation
InitScript()
