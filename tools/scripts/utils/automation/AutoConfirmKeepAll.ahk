#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Script pour détecter et cliquer automatiquement sur le bouton "Keep All" dans VS Code
; Auteur: Augment Agent
; Date: 2025-04-10

; Activer la surveillance continue
SetTimer, CheckForKeepAllButton, 500  ; Vérifier toutes les 500 ms

; Fonction pour vérifier la présence du bouton "Keep All"
CheckForKeepAllButton:
    ; Vérifier si VS Code est actif
    IfWinActive, ahk_exe Code.exe
    {
        ; Rechercher le bouton "Keep All"
        ControlGetText, ButtonText, Button3, A
        if (ButtonText = "Keep All")
        {
            ; Cliquer sur le bouton "Keep All"
            ControlClick, Button3, A
            OutputDebug, Bouton "Keep All" détecté et cliqué automatiquement.
        }
        
        ; Rechercher également le texte "Keep All" dans d'autres contrôles
        WinGet, ControlList, ControlList, A
        Loop, Parse, ControlList, `n
        {
            ControlGetText, Text, %A_LoopField%, A
            if (InStr(Text, "Keep All"))
            {
                ControlClick, %A_LoopField%, A
                OutputDebug, Contrôle contenant "Keep All" détecté et cliqué automatiquement.
                break
            }
        }
    }
return

; Raccourci pour suspendre/reprendre le script (Ctrl+Alt+P)
^!p::
    Suspend
    if (A_IsSuspended)
        TrayTip, AutoConfirmKeepAll, Script suspendu, 2
    else
        TrayTip, AutoConfirmKeepAll, Script actif, 2
return

; Raccourci pour quitter le script (Ctrl+Alt+Q)
^!q::
    TrayTip, AutoConfirmKeepAll, Arrêt du script, 2
    Sleep, 1000
    ExitApp
return
