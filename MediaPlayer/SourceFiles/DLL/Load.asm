include loadConfig.inc

.code

DllEntry proc hInst:DWORD, reason:DWORD, reserved1:DWORD 
   .if reason == DLL_PROCESS_ATTACH  ; When the dll is loaded 
      push			hInst 
      pop			hInstance 
      call			ShowBitMap 
   .endif
   mov			eax,TRUE
   ret 
DllEntry Endp 

ShowBitMap proc 
        LOCAL wc:WNDCLASSEX 
        LOCAL msg:MSG 
        LOCAL hwnd:HWND 
        mov			wc.cbSize,SIZEOF WNDCLASSEX 
        mov			wc.style, CS_HREDRAW or CS_VREDRAW 
        mov			wc.lpfnWndProc, OFFSET WndProc 
        mov			wc.cbClsExtra,NULL 
        mov			wc.cbWndExtra,NULL 
        push		hInstance 
        pop			wc.hInstance 
        mov			wc.hbrBackground,COLOR_WINDOW+1 
        mov			wc.lpszMenuName,NULL 
        mov			wc.lpszClassName,OFFSET ClassName 
        invoke		LoadIcon,NULL,IDI_APPLICATION 
        mov			wc.hIcon,eax 
        mov			wc.hIconSm,0 
        invoke		LoadCursor,NULL,IDC_ARROW 
        mov			wc.hCursor,eax 
        invoke		RegisterClassEx, addr wc 
        INVOKE		CreateWindowEx,NULL,ADDR ClassName,NULL,\ 
					WS_POPUP,CW_USEDEFAULT,\ 
					CW_USEDEFAULT,645,362,NULL,NULL,\ 
					hInstance,NULL 
        mov			hwnd,eax 
        INVOKE		ShowWindow, hwnd,SW_SHOWNORMAL 
        .WHILE TRUE 
                INVOKE		GetMessage, ADDR msg,NULL,0,0 
                .BREAK .IF (!eax) 
                INVOKE		TranslateMessage, ADDR msg 
                INVOKE		DispatchMessage, ADDR msg 
        .ENDW 
        mov     eax,msg.wParam 
        ret 
ShowBitMap endp 
WndProc proc hWnd:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD 
        LOCAL ps:PAINTSTRUCT 
        LOCAL hdc:HDC 
        LOCAL hMemoryDC:HDC 
        LOCAL hOldBmp:DWORD 
        LOCAL bitmap:BITMAP 
        LOCAL DlgHeight:DWORD 
        LOCAL DlgWidth:DWORD 
        LOCAL DlgRect:RECT 
        LOCAL DesktopRect:RECT

        .if uMsg == WM_DESTROY 
                .if hBitMap!=0 
                        invoke		DeleteObject,hBitMap 
                .endif 
                invoke		PostQuitMessage,NULL 
        .elseif uMsg == WM_CREATE 
                invoke		GetWindowRect,hWnd,addr DlgRect 
                invoke		GetDesktopWindow 
                mov			ecx,eax 
                invoke		GetWindowRect,ecx,addr DesktopRect 
                push		0 
                mov			eax,DlgRect.bottom 
                sub			eax,DlgRect.top 
                mov			DlgHeight,eax 
                push		eax 
                mov			eax,DlgRect.right 
                sub			eax,DlgRect.left 
                mov			DlgWidth,eax 
                push		eax 
                mov			eax,DesktopRect.bottom 
                sub			eax,DlgHeight 
                shr			eax,1 
                push		eax 
                mov			eax,DesktopRect.right 
                sub			eax,DlgWidth 
                shr			eax,1 
                push		eax 
                push		hWnd 
                call		MoveWindow 
                invoke		LoadBitmap,hInstance,addr BmpName 
                mov			hBitMap,eax 
                invoke		SetTimer,hWnd,1,2000,NULL 
                mov			TimerID,eax 
        .elseif uMsg == WM_TIMER 
                invoke		SendMessage,hWnd,WM_LBUTTONDOWN,NULL,NULL 
                invoke		KillTimer,hWnd,TimerID 
        .elseif uMsg == WM_PAINT 
                invoke		BeginPaint,hWnd,addr ps 
                mov			hdc,eax 
                invoke		CreateCompatibleDC,hdc 
                mov			hMemoryDC,eax 
                invoke		SelectObject,eax,hBitMap 
                mov			hOldBmp,eax 
                invoke		GetObject,hBitMap,sizeof BITMAP,addr bitmap 
                invoke		StretchBlt,hdc,0,0,645,362,\ 
							hMemoryDC,0,0,bitmap.bmWidth,bitmap.bmHeight,SRCCOPY 
                invoke		SelectObject,hMemoryDC,hOldBmp 
                invoke		DeleteDC,hMemoryDC 
                invoke		EndPaint,hWnd,addr ps 
        .elseif uMsg == WM_LBUTTONDOWN 
                invoke		DestroyWindow,hWnd 
        .else 
                invoke		DefWindowProc,hWnd,uMsg,wParam,lParam 
                ret 
        .endif 
        xor eax,eax 
        ret 
WndProc endp

End DllEntry

