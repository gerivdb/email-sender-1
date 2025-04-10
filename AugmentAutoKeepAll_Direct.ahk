#SingleInstance Force
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1  ; Exécution maximale pour une meilleure réactivité

; ========================================================
; Script AutoHotkey avec approche directe pour valider automatiquement 
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
global SetPositionHotkey := "^!p"   ; Ctrl+Alt+P: Définir la position du bouton

; ========== VARIABLES INTERNES ==========
global LastClickTime := 0           ; Horodatage du dernier clic
global KeepAllColor := 0x2EA043     ; Couleur verte du bouton "Keep All"
global KeepAllRelativeX := 0.95     ; Position relative X du bouton "Keep All" (95% de la largeur de la fenêtre)
global KeepAllRelativeY := 0.98     ; Position relative Y du bouton "Keep All" (98% de la hauteur de la fenêtre)

; ========== RACCOURCIS CLAVIER ==========
Hotkey, %ToggleHotkey%, ToggleAutoKeepAll
Hotkey, %ForceClickHotkey%, ForceClickKeepAll
Hotkey, %DebugHotkey%, ToggleDebugMode
Hotkey, %SetPositionHotkey%, SetKeepAllPosition

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
    if (ClickKeepAllButton(true)) {
        ShowTooltip("Keep All cliqué manuellement", 1000)
    } else {
        ShowTooltip("Impossible de trouver le bouton Keep All", 1500)
    }
}

; Fonction pour définir la position du bouton "Keep All"
SetKeepAllPosition() {
    global KeepAllRelativeX, KeepAllRelativeY
    
    ; Obtenir la position actuelle de la souris
    MouseGetPos, MouseX, MouseY
    
    ; Obtenir les dimensions de la fenêtre
    WinGetPos, WinX, WinY, WinWidth, WinHeight, A
    
    ; Calculer les positions relatives
    KeepAllRelativeX := (MouseX - WinX) / WinWidth
    KeepAllRelativeY := (MouseY - WinY) / WinHeight
    
    ; Vérifier la couleur du pixel à cette position
    PixelGetColor, color, MouseX, MouseY, RGB
    
    ShowTooltip("Position définie: " . MouseX . "," . MouseY . 
                "`nPosition relative: " . Round(KeepAllRelativeX * 100) . "%, " . Round(KeepAllRelativeY * 100) . "%" .
                "`nCouleur: " . color, 3000)
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
    
    ClickKeepAllButton(false)
return

; Fonction qui clique sur le bouton "Keep All" à une position fixe
ClickKeepAllButton(force := false) {
    global LastClickTime, ClickCooldown, DebugMode, KeepAllRelativeX, KeepAllRelativeY, KeepAllColor
    
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
    
    ; Calculer la position absolue du bouton "Keep All"
    KeepAllX := WinX + (WinWidth * KeepAllRelativeX)
    KeepAllY := WinY + (WinHeight * KeepAllRelativeY)
    
    ; Vérifier si la couleur à cette position est verte (bouton "Keep All")
    PixelGetColor, color, KeepAllX, KeepAllY, RGB
    
    ; Vérifier si la couleur est proche de la couleur verte du bouton "Keep All"
    isKeepAllButton := IsColorSimilar(color, KeepAllColor, 50)
    
    if (DebugMode) {
        ShowTooltip("Position: " . KeepAllX . "," . KeepAllY . 
                    "`nCouleur: " . color . 
                    "`nBouton Keep All: " . (isKeepAllButton ? "Oui" : "Non"), 1000)
    }
    
    ; Si le bouton est trouvé ou si on force le clic
    if (isKeepAllButton || force) {
        ; Sauvegarder la position actuelle de la souris
        MouseGetPos, OldX, OldY
        
        ; Déplacer la souris et cliquer
        MouseMove, %KeepAllX%, %KeepAllY%, 0
        
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
    startupMsg := "Script Auto Keep All DIRECT démarré`n"
                . "Alt+K: activer/désactiver`n"
                . "Ctrl+Alt+K: forcer un clic`n"
                . "Ctrl+Alt+D: mode débogage`n"
                . "Ctrl+Alt+P: définir la position du bouton"
    
    ShowTooltip(startupMsg, 3000)
}

; Exécuter l'initialisation
InitScript()
