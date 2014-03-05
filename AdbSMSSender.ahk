/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance ignore
global DebugConsole := true

IniRead, LastIP, AdbSMSSender.ini, settings, IP
IniRead, LastIP, AdbSMSSender.ini, settings, IP
IniRead, LastAdbPath, AdbSMSSender.ini, settings, adbpath
IniRead, LastNumbers, AdbSMSSender.ini, settings, numbers
IniRead, LastSMS, AdbSMSSender.ini, settings, SMS
IniRead, connect, AdbSMSSender.ini, settings, connect
IniRead, disconnect, AdbSMSSender.ini, settings, disconnect
IniRead, command, AdbSMSSender.ini, settings, command
IniRead, wait, AdbSMSSender.ini, settings, wait
WSShell := ComObjCreate("WScript.Shell")
;ComObjError(false)
Gui, Font, , Tahoma

Gui, Add, Text, , IP Adress: 
Gui, Add, Text, , Adb Path:
Gui, Add, Text,  , Number`(s`):`n a,b,c
Gui, Add, Text,  , Message: 

Gui, Add, Edit, vIP ym
Gui, Add, Edit, vAdbPath w350
Gui, Add, Edit, vNumbers w350
Gui, Add, Edit, vSMS h200 w350

Gui, Add, Button, x5   y250 w65, Send
Gui, Add, Button, x210 y5   w100 gConnectDisconnect vButtonText, Connect

Gui, Show, x100 y100, AdbSMSSender

GuiControl, , IP, %LastIP%
GuiControl, , AdbPath, %LastAdbPath%
GuiControl, , Numbers, %LastNumbers%
GuiControl, , SMS, %LastSMS%
gosub, Test
Menu, TRAY, NoStandard
Menu, TRAY, add, Exit , GuiClose
return  

GuiClose:
	GuiControlGet, Numbers
	GuiControlGet, SMS
	GuiControlGet, IP
	GuiControlGet, AdbPath
	IniWrite, %IP%, AdbSMSSender.ini, settings, IP
	IniWrite, %AdbPath%, AdbSMSSender.ini, settings, adbpath
	IniWrite, %Numbers%, AdbSMSSender.ini, settings, numbers
	IniWrite, %SMS%, AdbSMSSender.ini, settings, SMS
	Gui, Destroy
	COM_Release(WSShell) 

ExitApp

ButtonSend:
	GuiControlGet, Numbers
	GuiControlGet, SMS
	GuiControlGet, AdbPath
	AdbShell := WSShell.Exec(AdbPath " shell" )
	loop, Parse, command, |
	{
		StringReplace, temp, A_LoopField, $sms, %SMS%
		StringReplace, temp, temp, $number, %Numbers%
		if (A_Index > 1 )
			Sleep, %wait%
		AdbShell.StdIn.Write(temp . "`n")
	}
	AdbShell.StdIn.Write("exit`n")
	ConsoleOutput := AdbShell.StdOut.ReadAll()
	AdbShell.Terminate
	DebugConsole(ConsoleOutput)
return

ConnectDisconnect:
	GuiControlGet, IP
	GuiControlGet, AdbPath
	GuiControlGet, ButtonText
	If ( ButtonText = "Connect" )
		temp := adbpath " " connect
	else
		temp := adbpath " " disconnect
	StringReplace, temp, temp, $IP, %IP%
	DebugConsole(temp)
	ConsoleOutput := WSShell.Exec(temp).StdOut.ReadAll()
	DebugConsole(ConsoleOutput)
	gosub, Test
return

Test:
	DebugConsole("Starting test process..." )
	GuiControlGet, IP
	GuiControlGet, AdbPath 
	RunWait, % ComSpec " /c " """" AdbPath """" " devices"
	ConsoleOutput := WSShell.Exec("""" AdbPath """" . " devices" ).StdOut.ReadAll()
	DebugConsole(ConsoleOutput)
	IPFoundAt := Instr(ConsoleOutput, LastIP)
	if (IPFoundAt != 0 and (IP != "") ){
		DebugConsole("Device is connected :)" )
		GuiControl,, ButtonText, Disconnect
		Gui, Font, cGreen Bold, Tahoma
	}
	else{
		DebugConsole("Device " IP " has not been found!" )
		GuiControl,, ButtonText, Connect
		Gui, Font, cRed Bold, Tahoma
	}
	GuiControl, Font, IP
return

DebugConsole(Text) {
	global
	if !DebugConsole
		return
	if (ahk_id hDebugControl = "") {
		Gui, DebugConsole:Font, , Tahoma
		Gui, DebugConsole:Add, Edit, hwndhDebugControl vDebugControl w500 h200
		y := A_ScreenHeight-250
		x := A_ScreenWidth-550
		Gui, DebugConsole:Show, x%x% y%y% , DebugConsole
		Sleep, 200
	}
	Text .= "`n"
    SendMessage, 0x000E, 0, 0,, ahk_id %hDebugControl% ;WM_GETTEXTLENGTH
    SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hDebugControl% ;EM_SETSEL
    SendMessage, 0x00C2, False, &Text,, ahk_id %hDebugControl% ;EM_REPLACESEL
	return  

}
