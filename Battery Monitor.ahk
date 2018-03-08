#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force
#Persistent
	
Menu, Tray, NoStandard
Menu, Tray, DeleteAll
Menu, Tray, Add, &Settings, Settings
Menu, Tray, Add, Re&load, ScriptReload
Menu, Tray, Add, &About, About
Menu, Tray, Add, E&xit, Exit
Menu, Tray, Icon, %A_ScriptDir%/SysTrayIcon.ico, 1
Menu, Tray, Tip, Battery Monitor

global triggerPercentage := ""
global pollingInterval := ""
global suppressWarning := ""
global warningSound := ""
global runOnStartup := ""

SetTimer, CheckBatState, %pollingInterval%
goto, CheckIni

ReadInteger( p_address, p_offset, p_size, p_hex=true )
{
  value = 0
  old_FormatInteger := a_FormatInteger
  if ( p_hex )
    SetFormat, integer, hex
  else
    SetFormat, integer, dec
  loop, %p_size%
    value := value+( *( ( p_address+p_offset )+( a_Index-1 ) ) << ( 8* ( a_Index-1 ) ) )
  SetFormat, integer, %old_FormatInteger%
  return, value
}

CheckIni:
IniRead, triggerPercentage, IndicatorConfig.ini, settings, triggerPercentage
IniRead, pollingInterval, IndicatorConfig.ini, settings, pollingInterval
IniRead, suppressWarning, IndicatorConfig.ini, settings, supressWarningTime
IniRead, warningSound, IndicatorConfig.ini, settings, warningSound
IniRead, runOnStartup, IndicatorConfig.ini, settings, runOnStartup
if (runOnStartup = 1)
{
	if !FileExist("%A_Startup%\Battery Monitor.lnk")
	{
		FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\Battery Monitor.lnk, %A_ScriptDir%
	}
} else {
	FileDelete, %A_Startup%\Battery Monitor.lnk
}
return


CheckBatState:
	VarSetCapacity(powerstatus, 1+1+1+1+4+4)
	success := DllCall("kernel32.dll\GetSystemPowerStatus", "uint", &powerstatus)
	
	acLineStatus:=ReadInteger(&powerstatus,0,1,false)
	batteryFlag:=ReadInteger(&powerstatus,1,1,false)
	batteryLifePercent:=ReadInteger(&powerstatus,2,1,false)
	batteryLifeTime:=ReadInteger(&powerstatus,4,4,false)
	batteryFullLifeTime:=ReadInteger(&powerstatus,8,4,false)
	if (batteryLifePercent <= triggerPercentage and acLineStatus != 1)
	{
		if (warningSound = 1)
		{
			SoundPlay, *48
		}
		MsgBox, 4, Battery Warning, You have %batteryLifePercent% percent battery remaining. Get your charger %A_ComputerName%. If you would like to stop temporarily this warning , press "No". Otherwise, press "Yes".
		IfMsgBox No
			Sleep, %suppressWarning%
	}
	return
	
Settings:
	Run, IndicatorConfig.ini
	return
	
Exit:
	ExitApp
	return
	
About:
	Run, chrome.exe README.md
	return
	
ScriptReload:
	Reload
	return
