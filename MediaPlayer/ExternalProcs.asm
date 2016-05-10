


include			config.inc


.CODE
	EnumChild proc uses edi hwndChild:DWORD,lParam:DWORD 
		LOCAL bufferTip[256]:BYTE 
		mov			edi,lParam 
		assume		edi:ptr TOOLINFO 
		push		hwndChild 
		pop			[edi].uId 
		or			[edi].uFlags,TTF_IDISHWND 
		invoke		GetWindowText,hwndChild,addr bufferTip,255 
		lea			eax,bufferTip 
		mov			[edi].lpszText,eax 
		invoke		SendMessage,hwndTool,TTM_ADDTOOL,NULL,edi 
		assume		edi:nothing 
		ret 
	EnumChild endp

	DlgProc proc hDlg:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
			LOCAL toolInfo:TOOLINFO
			LOCAL idTool:DWORD
			LOCAL rectTool:RECT
		.if uMsg == WM_INITDIALOG
			invoke			InitCommonControls
			invoke			CreateWindowEx,NULL,ADDR ToolTipsClassName,NULL,\
							TTS_ALWAYSTIP,CW_USEDEFAULT,\
							CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,\
							hInstance,NULL
			mov				hwndTool,eax
			mov				idTool,0
			mov				toolInfo.cbSize,sizeof TOOLINFO
			mov				toolInfo.uFlags,TTF_SUBCLASS
			push			hDlg
			pop				toolInfo.hWnd
			invoke			GetWindowRect,hDlg,addr rectTool
			invoke			EnumChildWindows,hDlg,addr EnumChild,addr toolInfo
		.elseif uMsg == WM_CLOSE
			invoke			EndDialog,hDlg,NULL
		.else
			mov				eax,FALSE
			ret
		.endif
		mov			eax,TRUE
		ret
	DlgProc endp

end