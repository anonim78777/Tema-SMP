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



end start