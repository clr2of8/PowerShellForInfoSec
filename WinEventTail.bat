@echo off
SETLOCAL EnableDelayedExpansion

FOR /L %%L IN (0,0,1) DO @(
	REM get UTC times modified from: https://stackoverflow.com/questions/9871499/how-to-get-utc-time-with-windows-batch-file
	for /f %%a in ('wmic Path Win32_UTCTime get Year^,Month^,Day^,Hour^,Minute^,Second /Format:List ^| findstr "="') do (
	set %%a
	)
	Set Second=0!Second:~0,-1!
	Set Second=!Second:~-2!
	Set Minute=0!Minute:~0,-1!
	Set Minute=!Minute:~-2!
	Set Hour=0!Hour:~0,-1!
	Set Hour=!Hour:~-2!
	Set Day=0!Day:~0,-1!
	Set Day=!Day:~-2!
	Set Month=0!Month:~0,-1!
	Set Month=!Month:~-2!
	Set Year=0!Year:~0,-1!
	
	set lastdate=!lastdate!
	set currentdate=!Year!-!Month!-!Day!T!Hour!:!Minute!:!Second!

	wevtutil qe "Microsoft-Windows-PowerShell/Operational" /q:"*[System[TimeCreated[@SystemTime>='!lastdate!' and @SystemTime<'!currentdate!']]]" /c:3 /rd:true /f:text

	set lastdate=!currentdate!
	ping -n 2 127.0.0.1>NUL
)
