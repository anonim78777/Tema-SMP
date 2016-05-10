include config.inc

;folosirea procedurilor proprii create pt program

include ExternalProcs.inc 

;segmentul de cod
.CODE                

start: 
	;incarca dll-ul
	invoke LoadLibrary,addr LibName 
	.IF eax != NULL ;daca s-a reusit incarcarea lui atunci se poate face unload
		invoke		FreeLibrary,eax 
	 .ENDIF 

	
	invoke		GetModuleHandle, NULL               ; returneaza handlerul de program 									        
	mov			hInstance,eax						; Under Win32, hmodule==hinstance mov hInstance,eax 
	
	invoke		GetCommandLine                      ; obtine linia de comanda. Nu se apeleaza aceasta functie daca programul nu foloseste linia de comanda. 												
	mov			CommandLine,eax 
	
	invoke		WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT        ; apeleaza functia principala
	invoke		ExitProcess, eax                           ; inchiderea programului. Codul de iesire este returnat in eax de WinMain

	
;================================================================================================
;=			Procedura ferestrei MainForm 
;================================================================================================
	WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD 
		LOCAL wc:WNDCLASSEX                                            ; variabile locale in stiva
		LOCAL msg:MSG 
		LOCAL hwnd:HWND
		 ; parametrii sunt alocati dinamic in stiva. Din aceasta cauza trebuie asignati manual.
		mov			wc.cbSize,SIZEOF WNDCLASSEX							;dimensiunea strucurii wndclassex in bytes
		mov			wc.style, CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS	;stilul ferestrei
		mov			wc.lpfnWndProc, OFFSET WndProc						;low pointer to function. adresa procedurii ferestrei responsabile pt crearea ferestrelor din aceasat clasa
		mov			wc.cbClsExtra,NULL									;zona extra de bytes alocati structurii
		mov			wc.cbWndExtra,NULL									;zona extra de bytes alocatii instantei fereastra
		push		hInst												;handlerul de instanta al modulului
		pop			wc.hInstance										;
		mov			wc.hbrBackground,COLOR_APPWORKSPACE					;
		mov			wc.lpszMenuName,OFFSET MenuName						; numele meniului
		mov			wc.lpszClassName,OFFSET ClassName					; numele clasei fereastra
		invoke		LoadIcon,NULL,IdIcon;IDI_APPLICATION						;
		mov			wc.hIcon,eax										;
		mov			wc.hIconSm,eax										;handlerul catre iconul asociat clasei fereastea
		invoke		LoadCursor,NULL,IDC_ARROW							;
		mov			wc.hCursor,eax										;
		invoke		RegisterClassEx, addr wc							; inregistreaza clasa form-ului de windows
		
;CreateWindowExA proto dwExStyle:DWORD,\lpClassName:DWORD,\pWindowName:DWORD,\	dwStyle:DWORD,\X:DWORD,\Y:DWORD,\ nWidth:DWORD,
;\Height:DWORD,\hWndParent:DWORD ,\hMenu:DWORD,\ hInstance:DWORD,\lpParam:DWORD		
;		invoke		CreateWindowEx,NULL,\								
;					ADDR ClassName,\									
;					ADDR AppName,\										
;					WS_OVERLAPPEDWINDOW,\								
;					CW_USEDEFAULT,\										
;					CW_USEDEFAULT,\										
;					CW_USEDEFAULT,\										
;					CW_USEDEFAULT,\										
;					NULL,\												
;					NULL,\												
;					hInst,\												
;					NULL												
		
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,\ 
			WS_OVERLAPPED+WS_CAPTION+WS_SYSMENU+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_VISIBLE,CW_USEDEFAULT,\ 
			CW_USEDEFAULT,1350,460,NULL,NULL,\ 
			hInst,NULL 
		
		mov			hwnd,eax											;dupa ce s-a creat fereastra se returneaza in eax handlerul ferestrei.
		invoke		ShowWindow, hwnd,CmdShow							; afiseaza fereastra 
		invoke		UpdateWindow, hwnd                                  ; updateaza zona ferestrei
		invoke		GetMenu,hwnd
		mov			hMenu,eax
		.WHILE TRUE                                                         ; Enter message loop 
					invoke		GetMessage, ADDR msg,NULL,0,0 
					.BREAK .IF (!eax) 
					invoke		TranslateMessage, ADDR msg 
					invoke		DispatchMessage, ADDR msg 
	   .ENDW 
		mov			eax,msg.wParam                                            ; return exit code in eax 
		ret 
	WinMain endp

	WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
		LOCAL pt:POINT		;obtine coordonatele cursorului pt iconul din system tray
		LOCAL ps:PAINTSTRUCT ;structura pointer pentru desenarea bitmapului
		LOCAL hdc:HDC 
		LOCAL hMemDC:HDC 
		LOCAL rect:RECT 
		LOCAL startInfo:STARTUPINFO ; variabila pentru proces
	
		.IF uMsg == WM_DESTROY  
			invoke		DeleteObject,hBmp 
			invoke		DestroyMenu,hPopupMenu                 
			invoke		PostQuitMessage,NULL             ; inchide aplicatie 
		
		.ELSEIF uMsg == WM_INITMENUPOPUP
			invoke GetExitCodeProcess,ProcessInfo.hProcess,ADDR ExitCode 
			.if eax == TRUE 
				.if ExitCode == STILL_ACTIVE 
					invoke			EnableMenuItem,hMenu,IdCreateProcess,MF_GRAYED 
					invoke			EnableMenuItem,hMenu,IdCloseProcess,MF_ENABLED 
				.else 
					invoke			EnableMenuItem,hMenu,IdCreateProcess,MF_ENABLED 
					invoke			EnableMenuItem,hMenu,IdCloseProcess,MF_GRAYED 
				.endif 
			.else 
				invoke			EnableMenuItem,hMenu,IdCreateProcess,MF_ENABLED 
				invoke			EnableMenuItem,hMenu,IdCloseProcess,MF_GRAYED 
			.endif 

		.ELSEIF uMsg == WM_CREATE
			 invoke		CreateWindowEx,NULL, ADDR BtnClassName,ADDR BtnText,\ 
                        WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
                        75,310,140,25,hWnd,IdBtn1,hInstance,NULL 
			 mov		hBtn,eax 
			;incarca bitmapul
			invoke		LoadBitmap,hInstance,IdPianoBmp 
			mov			hBmp,eax ;salveaza handlerul bitmapului

			;Creaza meniul ascuns pt iconul din system tray
			invoke		CreatePopupMenu 
			mov			hPopupMenu,eax 
			invoke		AppendMenu,hPopupMenu,MF_STRING,IdmRestore,addr RestoreString 
			invoke		AppendMenu,hPopupMenu,MF_STRING,IdmExit,addr ExitString 
			
			
		.ELSEIF uMsg == WM_PAINT ;
			invoke		BeginPaint,hWnd,addr ps 
			mov			hdc,eax 
			invoke		CreateCompatibleDC,hdc ;creaza o suprafata ascunsa pt a desena bitmapul pe ea . la terminarea desenarii imaginii se muta in device contextul actual
			mov			hMemDC,eax ;obtine handlerul unui device context
			invoke		SelectObject,hMemDC,hBmp; deseneaza bitmapul pe suprafata ascunsa creata
			invoke		GetClientRect,hWnd,addr rect 
			invoke		BitBlt,hdc,0,0,rect.right,rect.bottom,hMemDC,0,0,SRCCOPY ; copiaza imaginea desenat in memory device context in device context-ul actual.
;sintaxa este cea de mai jos.
;BitBlt  proto  hdcDest:DWORD, nxDest:DWORD, nyDest:DWORD, nWidth:DWORD, nHeight:DWORD, hdcSrc:DWORD, nxSrc:DWORD, nySrc:DWORD, dwROP:DWORD 
 
;hdcDest is the handle of the device context that serves as the destination of bitmap transfer operation 
;nxDest, nyDest are the coordinate of the upper left corner of the output area 
;nWidth, nHeight are the width and height of the output area 
;hdcSrc is the handle of the device context that serves as the source of bitmap transfer operation 
;nxSrc, nySrc are the coordinate of the upper left corner of the source rectangle. 
;dwROP is the raster-operation code (hence the acronym ROP) that governs how to combine the color data of the bitmap to the existing color data on the output area to achieve the final result. Most of the time, you only want to overwrite the existing color data with the new one.
			invoke		DeleteDC,hMemDC 
			invoke		EndPaint,hWnd,addr ps 
	 
		.ELSEIF uMsg == WM_SIZE 
			.IF wParam == SIZE_MINIMIZED ;daca se minimizeaza  se duce in system tray
				mov			note.cbSize,sizeof NOTIFYICONDATA 
				push		hWnd 
				pop			note.hwnd 
				mov			note.uID,IdiTray 
				mov			note.uFlags,NIF_ICON+NIF_MESSAGE+NIF_TIP 
				mov			note.uCallbackMessage,WM_SHELLNOTIFY 
				invoke		LoadIcon,NULL,IDI_WINLOGO 
				mov			note.hIcon,eax 
				invoke		lstrcpy,addr note.szTip,addr AppName 
				invoke		ShowWindow,hWnd,SW_HIDE 
				invoke		Shell_NotifyIcon,NIM_ADD,addr note 
			.ENDIF 
		.ELSEIF uMsg == WM_CHAR 
			push wParam 
			pop  char
			.IF char == "1"
				invoke		PlaySound,OFFSET Note1,NULL,SND_ASYNC
			.ELSEIF char == "!"
				invoke		PlaySound,OFFSET Note1sharp,NULL,SND_ASYNC 
			.ELSEIF char == "2"
				invoke		PlaySound,OFFSET Note2,NULL,SND_ASYNC 
			.ELSEIF char == "@"
				invoke		PlaySound,OFFSET Note2sharp,NULL,SND_ASYNC 
			.ELSEIF char == "3"
				invoke		PlaySound,OFFSET Note3,NULL,SND_ASYNC 
			.ELSEIF char == "4"
				invoke		PlaySound,OFFSET Note4,NULL,SND_ASYNC 
			.ELSEIF char == "$"
				invoke		PlaySound,OFFSET Note4sharp,NULL,SND_ASYNC 
			.ELSEIF char == "5"
				invoke		PlaySound,OFFSET Note5,NULL,SND_ASYNC 
			.ELSEIF char == "%"
				invoke		PlaySound,OFFSET Note5sharp,NULL,SND_ASYNC 
			.ELSEIF char == "6"
				invoke		PlaySound,OFFSET Note6,NULL,SND_ASYNC 
			.ELSEIF char == "^"
				invoke		PlaySound,OFFSET Note6sharp,NULL,SND_ASYNC 
			.ELSEIF char == "7"
				invoke		PlaySound,OFFSET Note7,NULL,SND_ASYNC 
			.ELSEIF char == "8"
				invoke		PlaySound,OFFSET Note8,NULL,SND_ASYNC 
			.ELSEIF char == "*"
				invoke		PlaySound,OFFSET Note8sharp,NULL,SND_ASYNC 
			.ELSEIF char == "9"
				invoke		PlaySound,OFFSET Note9,NULL,SND_ASYNC 
			.ELSEIF char == "("
				invoke		PlaySound,OFFSET Note9sharp,NULL,SND_ASYNC 
			.ELSEIF char == "0"
				invoke		PlaySound,OFFSET Note0,NULL,SND_ASYNC 
			
			.ELSEIF char == "q"
				invoke		PlaySound,OFFSET Noteq,NULL,SND_ASYNC 
			.ELSEIF char == "Q"
				invoke		PlaySound,OFFSET Noteqsharp,NULL,SND_ASYNC 
			.ELSEIF char == "w"
				invoke		PlaySound,OFFSET Notew,NULL,SND_ASYNC 
			.ELSEIF char == "W"
				invoke		PlaySound,OFFSET Notewsharp,NULL,SND_ASYNC 
			.ELSEIF char == "e"
				invoke		PlaySound,OFFSET Notee,NULL,SND_ASYNC 
			.ELSEIF char == "E"
				invoke		PlaySound,OFFSET Noteesharp,NULL,SND_ASYNC 
			.ELSEIF char == "r"
				invoke		PlaySound,OFFSET Noter,NULL,SND_ASYNC 
			.ELSEIF char == "t"
				invoke		PlaySound,OFFSET Notet,NULL,SND_ASYNC 
			.ELSEIF char == "T"
				invoke		PlaySound,OFFSET Notetsharp,NULL,SND_ASYNC 
			.ELSEIF char == "y"
				invoke		PlaySound,OFFSET Notey,NULL,SND_ASYNC 
			.ELSEIF char == "Y"
				invoke		PlaySound,OFFSET Noteysharp,NULL,SND_ASYNC 
			.ELSEIF char == "u"
				invoke		PlaySound,OFFSET Noteu,NULL,SND_ASYNC 
			
			.ELSEIF char == "i"
				invoke		PlaySound,OFFSET Notei,NULL,SND_ASYNC 
			.ELSEIF char == "I"
				invoke		PlaySound,OFFSET Noteisharp,NULL,SND_ASYNC 
			.ELSEIF char == "o"
				invoke		PlaySound,OFFSET Noteo,NULL,SND_ASYNC 
			.ELSEIF char == "O"
				invoke		PlaySound,OFFSET Noteosharp,NULL,SND_ASYNC 
			.ELSEIF char == "p"
				invoke		PlaySound,OFFSET Notep,NULL,SND_ASYNC 
			.ELSEIF char == "P"
				invoke		PlaySound,OFFSET Notepsharp,NULL,SND_ASYNC 
			.ELSEIF char == "a"
				invoke		PlaySound,OFFSET Notea,NULL,SND_ASYNC 
			.ELSEIF char == "s"
				invoke		PlaySound,OFFSET Notes,NULL,SND_ASYNC 
			.ELSEIF char == "S"
				invoke		PlaySound,OFFSET Notessharp,NULL,SND_ASYNC 
			.ELSEIF char == "d"
				invoke		PlaySound,OFFSET Noted,NULL,SND_ASYNC 
			.ELSEIF char == "D"
				invoke		PlaySound,OFFSET Notedsharp,NULL,SND_ASYNC 
			.ELSEIF char == "f"
				invoke		PlaySound,OFFSET Notef,NULL,SND_ASYNC 
			
			.ELSEIF char == "g"
				invoke		PlaySound,OFFSET Noteg,NULL,SND_ASYNC 
			.ELSEIF char == "G"
				invoke		PlaySound,OFFSET Notegsharp,NULL,SND_ASYNC 
			.ELSEIF char == "h"
				invoke		PlaySound,OFFSET Noteh,NULL,SND_ASYNC 
			.ELSEIF char == "H"
				invoke		PlaySound,OFFSET Notehsharp,NULL,SND_ASYNC 
			.ELSEIF char == "j"
				invoke		PlaySound,OFFSET Notej,NULL,SND_ASYNC 
			.ELSEIF char == "J"
				invoke		PlaySound,OFFSET Notejsharp,NULL,SND_ASYNC 
			.ELSEIF char == "k"
				invoke		PlaySound,OFFSET Notek,NULL,SND_ASYNC 
			.ELSEIF char == "l"
				invoke		PlaySound,OFFSET Notel,NULL,SND_ASYNC 
			.ELSEIF char == "L"
				invoke		PlaySound,OFFSET Notelsharp,NULL,SND_ASYNC 
			.ELSEIF char == "z"
				invoke		PlaySound,OFFSET Notez,NULL,SND_ASYNC 
			.ELSEIF char == "Z"
				invoke		PlaySound,OFFSET Notezsharp,NULL,SND_ASYNC 
			.ELSEIF char == "x"
				invoke		PlaySound,OFFSET Notex,NULL,SND_ASYNC 
			
			.ELSEIF char == "c"
				invoke		PlaySound,OFFSET Notec,NULL,SND_ASYNC 
			.ELSEIF char == "C"
				invoke		PlaySound,OFFSET Notecsharp,NULL,SND_ASYNC 
			.ELSEIF char == "v"
				invoke		PlaySound,OFFSET Notev,NULL,SND_ASYNC 
			.ELSEIF char == "V"
				invoke		PlaySound,OFFSET Notevsharp,NULL,SND_ASYNC 
			.ELSEIF char == "b"
				invoke		PlaySound,OFFSET Noteb,NULL,SND_ASYNC 
			.ELSEIF char == "B"
				invoke		PlaySound,OFFSET Notebsharp,NULL,SND_ASYNC 
			.ELSEIF char == "n"
				invoke		PlaySound,OFFSET Noten,NULL,SND_ASYNC 
			.ELSEIF char == "m"
				invoke		PlaySound,OFFSET Notem,NULL,SND_ASYNC 	
			.ENDIF 
		.ELSEIF uMsg == WM_COMMAND ;verifica id-urile de meniu pt a vedea ce optiune a fost selectata
			mov		eax,wParam
			.IF lParam == 0
				invoke		Shell_NotifyIcon,NIM_DELETE,addr note 
				mov			eax,wParam 
				.IF ax == IdmRestore 
					invoke		ShowWindow,hWnd,SW_RESTORE 
				.ELSEIF ax == IdmExit 
					invoke		DestroyWindow,hWnd 
				.ENDIF
				.IF ax == Id_Help
					invoke		MessageBox, NULL, ADDR HelpString, OFFSET AppName, MB_OK
				.ELSEIF ax == IdOpen;acces la disc. Deschide un open file name pentru a accesa un fisier
					mov				ofn.lStructSize,SIZEOF ofn ;initializare structura open file name
					push			hWnd 
					pop				ofn.hwndOwner 
					push			hInstance 
					pop				ofn.hInstance 
					mov				ofn.lpstrFilter, OFFSET FilterString 
					mov				ofn.lpstrFile, OFFSET buffer 
					mov				ofn.nMaxFile,MAXSIZE 

					mov				ofn.Flags, OFN_FILEMUSTEXIST or \ 
									OFN_PATHMUSTEXIST or OFN_LONGNAMES or\ 
									OFN_EXPLORER or OFN_HIDEREADONLY 
					mov				ofn.lpstrTitle, OFFSET OpenFileTitle 
					invoke			GetOpenFileName, ADDR ofn 
					.IF eax	==	TRUE 
						invoke			lstrcat,offset OutputString,OFFSET Path 
						invoke			lstrcat,offset OutputString,ofn.lpstrFile 
						invoke			lstrcat,offset OutputString,offset CrLf 
						invoke			lstrcat,offset OutputString,offset FileName 
						mov				eax,ofn.lpstrFile 
						push			ebx 
						xor				ebx,ebx 
						mov				bx,ofn.nFileOffset 
						add				eax,ebx 
						pop				ebx 
						invoke			lstrcat,offset OutputString,eax 
						invoke			lstrcat,offset OutputString,offset CrLf 
						invoke			lstrcat,offset OutputString,offset Extension 
						mov				eax,ofn.lpstrFile 
						push			ebx 
						xor				ebx,ebx 
						mov				bx,ofn.nFileExtension 
						add				eax,ebx 
						pop				ebx 
						invoke			lstrcat,offset OutputString,eax 
						invoke			MessageBox,hWnd,OFFSET OutputString,ADDR AppName,MB_OK 
						invoke			RtlZeroMemory,offset OutputString,OUTPUTSIZE 
					.ENDIF 
				.ELSEIF ax == IdCreateProcess; exectua procesul
					.if ProcessInfo.hProcess!=0
						invoke CloseHandle,ProcessInfo.hProcess
						mov ProcessInfo.hProcess,0
					.endif
					invoke GetStartupInfo,ADDR startInfo
					invoke CreateProcess,ADDR PrgName,NULL,NULL,NULL,FALSE,\
											NORMAL_PRIORITY_CLASS,\
											NULL,NULL,ADDR startInfo,ADDR ProcessInfo
					invoke CloseHandle,ProcessInfo.hThread
				.ELSEIF ax == IdCloseProcess
					invoke GetExitCodeProcess,ProcessInfo.hProcess,ADDR ExitCode
					.if ExitCode==STILL_ACTIVE
						invoke TerminateProcess,ProcessInfo.hProcess,0
					.endif
					invoke CloseHandle,ProcessInfo.hProcess
					mov ProcessInfo.hProcess,0
				.ELSEIF ax == IdToolMenu
					invoke DialogBoxParam,hInstance,IdDialog,NULL,addr DlgProc,NULL
				.ELSEIF ax == IdSave
					
				.ELSEIF ax == IdSaveAs

				.ELSEIF ax == IdPlayfile

				.ELSEIF ax == IdPlayUrl

				.ELSEIF ax == IdPlayFolder

				.ELSEIF ax == IdOpenPlaylist

				.ELSEIF ax == IdPrevious

				.ELSEIF ax == Id_Play

				.ELSEIF ax == IdPause

				.ELSEIF ax == IdStope

				.ELSEIF ax == IdRepeat

				.ELSEIF ax == IdShuffle
 					;invoke DialogBoxParam,hInstance,IDD_MAINDIALOG,NULL,addr DlgProc,NULL 
				.ELSEIF ax == IdExit
					invoke DestroyWindow,hWnd
				.ENDIF
			.ELSE
				.IF ax == IdBtn1 
					shr eax,16 
					.IF ax == BN_CLICKED 
						;invoke SendMessage,hWnd,WM_COMMAND,IdBtn1,0 
					.ENDIF 
				.ENDIF
            .ENDIF
		.ELSEIF uMsg == WM_SHELLNOTIFY ;necesar pt lucrul cu System Tray
        .IF wParam == IdiTray
            .IF lParam == WM_RBUTTONDOWN ;daca se apasa click dreapta afiseaza meniul
                invoke		GetCursorPos,addr pt 
                invoke		SetForegroundWindow,hWnd 
                invoke		TrackPopupMenu,hPopupMenu,TPM_RIGHTALIGN,pt.x,pt.y,NULL,hWnd,NULL 
                invoke		PostMessage,hWnd,WM_NULL,0,0 
            .ELSEIF lParam == WM_LBUTTONDBLCLK 
                invoke SendMessage,hWnd,WM_COMMAND,IdmRestore,0 
            .endif 
        .endif 
		.ELSE 
			invoke		DefWindowProc,hWnd,uMsg,wParam,lParam     ; Default message processing 
			ret 
		.ENDIF 
		xor eax,eax 
		ret 
	WndProc endp
		
end start