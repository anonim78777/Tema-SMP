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
include			e:\masm32\include\comdlg32.inc ;dialog box
includelib		e:\masm32\lib\comdlg32.lib
include			e:\masm32\include\winmm.inc
includelib 		e:\masm32\lib\winmm.lib

;Variabilele necesare utilizarii tray icon-ului
WM_SHELLNOTIFY		equ			WM_USER+5 
IdiTray				equ			0 
IdmRestore			equ			20000 
IdmExit				equ			20001


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
IdDialog			equ			19000
IdDialOk			equ			19001
IdDialExit			equ			19002

;constante open file
MAXSIZE				equ			260 
OUTPUTSIZE			equ			512

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
IdReport			equ			3000
IdCreateProcess		equ			3001
IdCloseProcess		equ			3002
IdToolMenu			equ			3003
IdHelp				equ			10000
Id_Help				equ			10001
;=======================================================================================================================
;segmentul de date initializate 
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

;numele clasei folosite pentru tooltip
ToolTipsClassName	db "Tooltips_class32",0 

;acces i/o
ofn					OPENFILENAME <>
FilterString		db "All Files",0,"*.*",0 
					db "Text Files",0,"*.txt",0,0 
buffer				db MAXSIZE dup(0)  
OpenFileTitle		db "Chose file to open",0
Path				db "Cale fisier: ",0
FileName			db "Fisier: ",0
Extension			db "Extensie fisier: ",0
OutputString		db OUTPUTSIZE dup(0) 
CrLf				db 0Dh,0Ah,0
;pentru proces
ProcessInfo			PROCESS_INFORMATION <>
PrgName				db "MediaPlayer.exe",0
;memoreaza caracterul primit de la tastatura
char				WPARAM 20h 
;Sunetele de pian ce vor fi apelate.
Note1				db "note1.wav",0
Note1sharp			db "note1#.wav",0
Note2				db "note2.wav",0
Note2sharp			db "note2#.wav",0
Note3				db "note3.wav",0
Note4				db "note4.wav",0
Note4sharp			db "note4#.wav",0
Note5				db "note5.wav",0
Note5sharp			db "note5#.wav",0
Note6				db "note6.wav",0
Note6sharp			db "note6#.wav",0
Note7				db "note7.wav",0
Note8				db "note8.wav",0
Note8sharp			db "note8#.wav",0
Note9				db "note9.wav",0
Note9sharp			db "note9#.wav",0
Note0				db "note0.wav",0
Noteq				db "noteq.wav",0
Noteqsharp			db "noteq#.wav",0
Notew				db "notew.wav",0
Notewsharp			db "notew#.wav",0
Notee				db "notee.wav",0
Noteesharp			db "notee#.wav",0
Noter				db "noter.wav",0
Notet				db "notet.wav",0
Notetsharp			db "notet#.wav",0
Notey				db "notey.wav",0
Noteysharp			db "notey#.wav",0
Noteu				db "noteu.wav",0

Notei				db "notei.wav",0
Noteisharp			db "notei#.wav",0
Noteo				db "noteo.wav",0
Noteosharp			db "noteo#.wav",0
Notep				db "notep.wav",0
Notepsharp			db "notep#.wav",0
Notea				db "notea.wav",0
Notes				db "notes.wav",0
Notessharp			db "notes#.wav",0
Noted				db "noted.wav",0
Notedsharp			db "noted#.wav",0
Notef				db "notef.wav",0

Noteg				db "noteg.wav",0
Notegsharp			db "noteg#.wav",0
Noteh				db "noteh.wav",0
Notehsharp			db "noteh#.wav",0
Notej				db "notej.wav",0
Notejsharp			db "notej#.wav",0
Notek				db "notek.wav",0
Notel				db "notel.wav",0
Notelsharp			db "notel#.wav",0
Notez				db "notez.wav",0
Notezsharp			db "notez#.wav",0
Notex				db "notex.wav",0

Notec				db "notec.wav",0
Notecsharp			db "notec#.wav",0
Notev				db "notev.wav",0
Notevsharp			db "notev#.wav",0
Noteb				db "noteb.wav",0
Notebsharp			db "noteb#.wav",0
Noten				db "noten.wav",0
Notem				db "notem.wav",0

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

;contine codul de iesire al procesului
ExitCode			DWORD ?
hMenu				HANDLE ?