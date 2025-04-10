#SingleInstance Force
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1  ; Exécution maximale pour une meilleure réactivité

; ========================================================
; Script AutoHotkey ultra-précis pour valider automatiquement 
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
global CaptureHotkey := "^!c"       ; Ctrl+Alt+C: Capturer la position actuelle du bouton

; ========== VARIABLES INTERNES ==========
global LastClickTime := 0           ; Horodatage du dernier clic
global LastFoundX := 0              ; Dernière position X où le bouton a été trouvé
global LastFoundY := 0              ; Dernière position Y où le bouton a été trouvé
global KeepAllColor := 0x2EA043     ; Couleur verte du bouton "Keep All"
global KeepAllText := "Keep All"    ; Texte du bouton "Keep All"

; ========== RACCOURCIS CLAVIER ==========
Hotkey, %ToggleHotkey%, ToggleAutoKeepAll
Hotkey, %ForceClickHotkey%, ForceClickKeepAll
Hotkey, %DebugHotkey%, ToggleDebugMode
Hotkey, %CaptureHotkey%, CaptureKeepAllPosition

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

; Fonction pour capturer la position actuelle du bouton "Keep All"
CaptureKeepAllPosition() {
    global LastFoundX, LastFoundY
    
    ; Obtenir la position actuelle de la souris
    MouseGetPos, MouseX, MouseY
    
    ; Sauvegarder la position
    LastFoundX := MouseX
    LastFoundY := MouseY
    
    ; Vérifier la couleur du pixel à cette position
    PixelGetColor, color, MouseX, MouseY, RGB
    
    ShowTooltip("Position capturée: " . MouseX . "," . MouseY . "`nCouleur: " . color, 2000)
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
    global LastClickTime, ClickCooldown, DebugMode, LastFoundX, LastFoundY, KeepAllColor
    
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
    
    ; Méthode 1: Recherche par texte "Keep All" dans la barre d'état
    found := false
    FoundX := 0
    FoundY := 0
    
    ; Rechercher spécifiquement le bouton "Keep All" dans la partie droite de la barre d'état
    RightSideX := WinX + WinWidth - 200
    
    ; Rechercher la couleur verte caractéristique du bouton "Keep All"
    Loop, 200 {
        x := RightSideX + A_Index - 1
        
        ; Vérifier chaque pixel dans la barre d'état
        Loop, 30 {
            y := WinY + StatusBarY + A_Index - 1
            
            ; Obtenir la couleur du pixel
            PixelGetColor, color, x, y, RGB
            
            ; Comparer avec la couleur du bouton "Keep All" (avec une tolérance)
            if (IsColorSimilar(color, KeepAllColor, 30)) {
                ; Trouver le centre du bouton en cherchant les limites de la zone verte
                leftX := x
                rightX := x
                topY := y
                bottomY := y
                
                ; Chercher à gauche
                tempX := x
                while (tempX > RightSideX) {
                    tempX--
                    PixelGetColor, tempColor, tempX, y, RGB
                    if (!IsColorSimilar(tempColor, KeepAllColor, 30))
                        break
                    leftX := tempX
                }
                
                ; Chercher à droite
                tempX := x
                while (tempX < WinX + WinWidth) {
                    tempX++
                    PixelGetColor, tempColor, tempX, y, RGB
                    if (!IsColorSimilar(tempColor, KeepAllColor, 30))
                        break
                    rightX := tempX
                }
                
                ; Chercher en haut
                tempY := y
                while (tempY > WinY + StatusBarY) {
                    tempY--
                    PixelGetColor, tempColor, x, tempY, RGB
                    if (!IsColorSimilar(tempColor, KeepAllColor, 30))
                        break
                    topY := tempY
                }
                
                ; Chercher en bas
                tempY := y
                while (tempY < WinY + WinHeight) {
                    tempY++
                    PixelGetColor, tempColor, x, tempY, RGB
                    if (!IsColorSimilar(tempColor, KeepAllColor, 30))
                        break
                    bottomY := tempY
                }
                
                ; Calculer le centre du bouton
                FoundX := leftX + (rightX - leftX) / 2
                FoundY := topY + (bottomY - topY) / 2
                
                found := true
                
                if (DebugMode)
                    ShowTooltip("Bouton Keep All trouvé à " . FoundX . "," . FoundY . "`nDimensions: " . (rightX - leftX) . "x" . (bottomY - topY), 1000)
                
                break 2  ; Sortir des deux boucles
            }
        }
    }
    
    ; Si le bouton n'est pas trouvé et que nous avons une position précédente, essayer à proximité
    if (!found && LastFoundX > 0 && LastFoundY > 0) {
        if (DebugMode)
            ShowTooltip("Recherche à proximité de la dernière position", 500)
        
        ; Vérifier si la couleur à la dernière position connue est toujours verte
        PixelGetColor, lastColor, LastFoundX, LastFoundY, RGB
        
        if (IsColorSimilar(lastColor, KeepAllColor, 30)) {
            FoundX := LastFoundX
            FoundY := LastFoundY
            found := true
            
            if (DebugMode)
                ShowTooltip("Bouton Keep All trouvé à la dernière position", 500)
        } else {
            ; Rechercher dans une zone de 100x50 pixels autour de la dernière position connue
            PixelSearch, FoundX, FoundY, LastFoundX - 50, LastFoundY - 25, LastFoundX + 50, LastFoundY + 25, KeepAllColor, 30, Fast RGB
            
            if (!ErrorLevel) {
                found := true
                if (DebugMode)
                    ShowTooltip("Bouton Keep All trouvé à proximité", 500)
            }
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
    startupMsg := "Script Auto Keep All PRÉCIS démarré`n"
                . "Alt+K: activer/désactiver`n"
                . "Ctrl+Alt+K: forcer un clic`n"
                . "Ctrl+Alt+D: mode débogage`n"
                . "Ctrl+Alt+C: capturer la position du bouton"
    
    ShowTooltip(startupMsg, 3000)
}

; Exécuter l'initialisation
InitScript()
