;In acest fisier se declara variabilele de start ale programului


;Steps to create a windows form:
;1 Get the instance handle of your program (required)
;2 Get the command line (not required unless your program wants to process a command line)
;3 Register window class (required ,unless you use predefined window types, eg. MessageBox or a dialog box)
;4 Create the window (required)
;5 Show the window on the desktop (required unless you don't want to show the window immediately)
;6 Refresh the client area of the window
;7 Enter an infinite loop, checking for messages from Windows
;8 If messages arrive, they are processed by a specialized function that is responsible for the window
;9 Quit program if the user closes the window

;Exista 4 directive ce impart spatiul de adrese in segmente logice. 
;.DATA   -Contine variabilele de initializare ale programului.
;.DATA?	 -Contine variabilele care nu sunt initializate
;.CONST  -Contine constantele
;.CODE	 -segmentul in care se scrie codul aplicatie

;=======================================================================================================================
;	General
;=======================================================================================================================

.386											;directiva assamblor pentru setul de instructiuni
.model flat,stdcall								;indica modelul memoriei. Sub win32 exista doar modelul flat. stdcall indica modul de pasare al parametrilor
option casemap:none								;activeaza optiunea de Case-sensitive pentru label-uri. Astfel Start si start vor fi diferite.

;adaugarea librariilor si a prototipurilor de functii si rutine din masm32
include			e:\masm32\include\windows.inc 
include			e:\masm32\include\user32.inc 
includelib		e:\masm32\lib\user32.lib            
include			e:\masm32\include\kernel32.inc 
includelib		e:\masm32\lib\kernel32.lib
include			e:\masm32\include\shell32.inc 
includelib		e:\masm32\lib\shell32.lib
include			e:\masm32\include\comctl32.inc 
includelib		e:\masm32\lib\comctl32.lib 
include			e:\masm32\include\gdi32.inc
includelib		e:\masm32\lib\gdi32.lib

;Variabilele necesare utilizarii tray icon-ului
WM_SHELLNOTIFY		equ WM_USER+5 
IdiTray				equ 0 
IdmRestore			equ 20000 
IdmExit				equ 20001

;=======================================================================================================================
;segmentul de date initializate si neinitializate
;=======================================================================================================================

.DATA										 
ClassName			db "MainForm",0					 ; numele clasei fereastra
AppName				db "Media Player",0					 ; numele ferestrei

BtnClassName		db "button",0
BtnName				db "Button1",0
BtnText				db "Button1",0
EdClassName			db "edit",0
	
MenuName			db "MainMenu",0					 ;numele meniului din fisierul de resurse
HelpString			db "Acest proiect este dezvoltat de ARX10 pentru tema din cadrul cursului de SMP, anul III, facultatea de Automatica si Calculatoare din cadrul Universitatii Politehnica Bucuresti.",0

; stringuri pt  popup menu-ul utilizat la tray icon
;In momentul in care se da click dreapta pe icon-ul din system tray se afiseaza un menu. Aceste stringuri reprezinta optiunile meniului.
RestoreString		db "&Restore",0 
ExitString			db "&Exit Program",0

;incarca dll-ul ce este folosit pentru afisarea loadingscreen-ului
LibName				db "LoadScreen.dll",0

;numele clasei si stringurile folosite pentru tooltip
ToolTipsClassName	db "Tooltips_class32",0 
MainDialogText1		db "This is the upper left area of the dialog",0 
MainDialogText2		db "This is the upper right area of the dialog",0 
MainDialogText3		db "This is the lower left area of the dialog",0 
MainDialogText4		db "This is the lower right area of the dialog",0 

;pentru incarcarea bitmapului
;PianoBmpName		db "PianoBmp",0

;=======================================================================================================================
;segmentul de date neinitializate. 
;=======================================================================================================================

.DATA?            
;HINSTANCE si LPTSR sunt de tip DWORD si se definesc in windows.inc   
hInstance			dd ?         ;handler-ul instantei al programului
CommandLine			LPSTR ? 

;handler butoane
hBtn				HWND ?
hEdit				HWND ?
;buffer				db 512 dup(?)

;instantele nedaclarate utilizate pt crearea tray ico-ului  din system tray si a meniului ascuns.

note NOTIFYICONDATA <> 
hPopupMenu			dd ?

;handlerul tooltip-ului
hwndTool			dd ?

;handler bitmap
hBmp				dd ?

;=======================================================================================================================
;segmentul de constante 
;=======================================================================================================================

.CONST 

;Butoane 

IdBtn1				equ			60000

;edit
IdEdit				equ			100

;Icons and bmps
IdIcon				equ			15000
IdPianoBmp			equ			15001

;tooltip
IDD_MAINDIALOG		equ			65000

;declarare id-uri meniu
IdFile				equ			1000
IdPlayfile			equ			1001
IdPlayUrl			equ			1002
IdPlayFolder		equ			1003
IdOpenPlaylist		equ			1004
IdOpen				equ			1005
IdSave				equ			1006
IdSaveAs			equ			1007
IdExit				equ			1100
IdPlay				equ			2000
IdPrevious			equ			2001
Id_Play				equ			2002
IdPause				equ			2003
IdStope				equ			2004
IdNext				equ			2005
IdRepeat			equ			2006
IdShuffle			equ			2007
IdHelp				equ			10000
Id_Help				equ			10001