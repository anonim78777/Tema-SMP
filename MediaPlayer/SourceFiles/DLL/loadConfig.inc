.386											;directiva assamblor pentru setul de instructiuni
.model flat,stdcall								;indica modelul memoriei. Sub win32 exista doar modelul flat. stdcall indica modul de pasare al parametrilor
;option casemap:none							;activeaza optiunea de Case-sensitive pentru label-uri. Astfel Start si start vor fi diferite.

;adaugarea librariilor si a prototipurilor de functii si rutine din masm32
include			e:\masm32\include\windows.inc 
include			e:\masm32\include\user32.inc 
includelib		e:\masm32\lib\user32.lib            
include			e:\masm32\include\kernel32.inc 
includelib		e:\masm32\lib\kernel32.lib
include			e:\masm32\include\shell32.inc 
includelib		e:\masm32\lib\shell32.lib

.data
BmpName			db "LoadScrnBMP",0 ;legatura catre imaginea bmp
ClassName		db "LoadScrnWndClass",0;numele clasei
hBitMap			dd 0
TimerId			dd 0

.data
hInstance		dd ?

