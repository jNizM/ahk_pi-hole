; GLOBAL SETTINGS ===============================================================================================================

#NoEnv
#SingleInstance Force
#NoTrayIcon

SetBatchLines -1

global app := { author: "jNizM", licence: "MIT", ahk: "1.1.29.01", version: "18.07.28", name: "pi-hole" }

global api     := "http://pi.hole/admin/api.php?summaryRaw&topItems&getForwardDestinations&getQueryTypes&auth="
global auth    := ""  ; <-- WEBPASSWORD in /etc/pihole/setupVars.conf
global refresh := 2000
global WINVER  := RtlGetVersion()


; GUI ===========================================================================================================================

pi := json(DownloadToString(api . auth))

Gui, +hWndhMainGUI
Gui, Margin, 0, 0

Gui, Add, Pic, xm+10 ym+10 w150 h56 0x4E hwndhPic01
CreateGradient(hPic01, 150, 56, ["0x00A65A"]*)
Gui, Font, s11 cFFFFFF, Calibri
Gui, Add, Text, xm+10 yp w150 h24 0x201 BackgroundTrans, % "Total queries"
Gui, Font, s18 cFFFFFF, Calibri
Gui, Add, Text, xm+10 y+2 w150 h30 0x201 vTotalQueries BackgroundTrans, % GetNumberFormatEx(pi.dns_queries_today, -3)

Gui, Add, Pic, x+10 ym+10 w150 h56 0x4E hwndhPic02
CreateGradient(hPic02, 150, 56, ["0xDD4B39"]*)
Gui, Font, s11 cFFFFFF, Calibri
Gui, Add, Text, xp yp w150 h24 0x201 BackgroundTrans, % "Queries blocked"
Gui, Font, s18 cFFFFFF, Calibri
Gui, Add, Text, xp y+2 w150 h30 0x201 vAdsBlocked BackgroundTrans, % GetNumberFormatEx(pi.ads_blocked_today, -3)

Gui, Add, Pic, x+10 ym+10 w150 h56 0x4E hwndhPic03
CreateGradient(hPic03, 150, 56, ["0x00C0EF"]*)
Gui, Font, s11 cFFFFFF, Calibri
Gui, Add, Text, xp yp w150 h24 0x201 BackgroundTrans, % "Percent blocked"
Gui, Font, s18 cFFFFFF, Calibri
Gui, Add, Text, xp y+2 w150 h30 0x201 vAdsPercentage BackgroundTrans, % GetNumberFormatEx(pi.ads_percentage_today, -1) " %"

Gui, Add, Pic, x+10 ym+10 w150 h56 0x4E hwndhPic04
CreateGradient(hPic04, 150, 56, ["0xF39C12"]*)
Gui, Font, s11 cFFFFFF, Calibri
Gui, Add, Text, xp yp w150 h24 0x201 BackgroundTrans, % "Domains on Blocklist"
Gui, Font, s18 cFFFFFF, Calibri
Gui, Add, Text, xp y+2 w150 h30 0x201 vBlockList BackgroundTrans, % GetNumberFormatEx(pi.domains_being_blocked, -3)

Gui, Font, s11 c00000, Calibri
Gui, Add, ListView, xm+10 y+10 w310 r10 vLVTD hWndhMyLV1, % "Top Domains|Hits"
SetWindowTheme(hMyLV1)
for queries, counts in pi.top_queries
	LV_Add("", queries, counts)
LV_ModifyCol(1, 242)
LV_ModifyCol(2, 60 " SortDesc Integer")

Gui, Font, s11 c00000, Calibri
Gui, Add, ListView, x+10 yp w310 r10 vLVTB hWndhMyLV2, % "Top Blocked Domains|Hits"
SetWindowTheme(hMyLV2)
for ads, counts in pi.top_ads
	LV_Add("", ads, counts)
LV_ModifyCol(1, 242)
LV_ModifyCol(2, 60 " SortDesc Integer")

Gui, Add, Pic, xm y+10 w650 h5 0x4E hwndhPic05
if (pi.status = "enabled")
	CreateGradient(hPic05, 150, 5, ["0x00A65A"]*)
else
	CreateGradient(hPic05, 150, 5, ["0xDD4B39"]*)

Gui, Show, AutoSize
HideFocusBorder(hMainGUI)
SetTimer, GET_SUMMARY, % refresh
return


; WINDOW EVENTS =================================================================================================================

GuiEscape:
GuiClose:
ExitApp


; SCRIPT ========================================================================================================================

GET_SUMMARY:
	pi := json(DownloadToString(api . auth))
	GuiControl,, TotalQueries,  % GetNumberFormatEx(pi.dns_queries_today, -3)
	GuiControl,, AdsBlocked,    % GetNumberFormatEx(pi.ads_blocked_today, -3)
	GuiControl,, AdsPercentage, % GetNumberFormatEx(pi.ads_percentage_today, -1) " %"
	GuiControl,, BlockList,     % GetNumberFormatEx(pi.domains_being_blocked, -3)

	Gui, ListView, LVTD
	LV_Delete()
	for queries, counts in pi.top_queries
		LV_Add("", queries, counts)
	LV_ModifyCol(2, 60 " SortDesc Integer")

	Gui, ListView, LVTB
	LV_Delete()
	for ads, counts in pi.top_ads
		LV_Add("", ads, counts)
	LV_ModifyCol(2, 60 " SortDesc Integer")

	if (pi.status = "enabled")
		CreateGradient(hPic05, 150, 5, ["0x00A65A"]*)
	else
		CreateGradient(hPic05, 150, 5, ["0xDD4B39"]*)
return


; FUNCTIONS =====================================================================================================================

CreateGradient(handle, width, height, colors*)  ; by SKAN | modified by jNizM & 'just me'
{
	size := VarSetCapacity(bits, (ClrCnt := colors.MaxIndex()) * 2 * 4, 0)
	addr := &bits
	for each, color in colors
		addr := NumPut(color, NumPut(color, addr + 0, "uint"), "uint")
	hBitmap := DllCall("CreateBitmap", "int", 2, "int", ClrCnt, "uint", 1, "uint", 32, "ptr", 0, "ptr")
	hBitmap := DllCall("CopyImage", "ptr", hBitmap, "uint", 0, "int", 0, "int", 0, "uint", 0x2008, "ptr")
	DllCall("SetBitmapBits", "ptr", hBitmap, "uint", size, "ptr", &bits)
	hBitmap := DllCall("CopyImage", "ptr", hBitmap, "uint", 0, "int", width, "int", height, "uint", 0x2008, "ptr")
	DllCall("SendMessage", "ptr", handle, "uint", 0x0172, "ptr", 0, "ptr", hBitmap, "ptr")
	return true
}

DownloadToString(url, encoding := "utf-8")  ; by Bentschi
{
	static a := "AutoHotkey/" A_AhkVersion
	if (!DllCall("LoadLibrary", "str", "wininet") || !(h := DllCall("wininet\InternetOpen", "str", a, "uint", 1, "ptr", 0, "ptr", 0, "uint", 0, "ptr")))
		return 0
	c := s := 0, o := ""
	if (f := DllCall("wininet\InternetOpenUrl", "ptr", h, "str", url, "ptr", 0, "uint", 0, "uint", 0x80003000, "ptr", 0, "ptr"))
	{
		while (DllCall("wininet\InternetQueryDataAvailable", "ptr", f, "uint*", s, "uint", 0, "ptr", 0) && s > 0)
		{
			VarSetCapacity(b, s, 0)
			DllCall("wininet\InternetReadFile", "ptr", f, "ptr", &b, "uint", s, "uint*", r)
			o .= StrGet(&b, r >> (encoding = "utf-16" || encoding = "cp1200"), encoding)
		}
		DllCall("wininet\InternetCloseHandle", "ptr", f)
	}
	DllCall("wininet\InternetCloseHandle", "ptr", h)
	return o
}

GetNumberFormatEx(VarIn, Decimal := "", locale := "!x-sys-default-locale")  ; by jNizM
{
	if !(size := DllCall("GetNumberFormatEx", "ptr", &locale, "uint", 0, "ptr", &VarIn, "ptr", 0, "ptr", 0, "int", 0))
		throw Exception("GetNumberFormatEx", -1)
	VarSetCapacity(buf, size << 1, 0)
	if !(DllCall("GetNumberFormatEx", "ptr", &locale, "uint", 0, "ptr", &VarIn, "ptr", 0, "str", buf, "int", size))
		throw Exception("GetNumberFormatEx", -1)
	return (Decimal) ? SubStr(buf, 1, Decimal) : buf
}

HideFocusBorder(wParam, lParam := "", Msg := "", handle := "")  ; by 'just me'
{
	static Affected         := []
	static WM_UPDATEUISTATE := 0x0128
	static SET_HIDEFOCUS    := 0x00010001  ; UIS_SET << 16 | UISF_HIDEFOCUS
	static init             := OnMessage(WM_UPDATEUISTATE, Func("HideFocusBorder"))

	if (Msg = WM_UPDATEUISTATE) {
		if (wParam = SET_HIDEFOCUS)
			Affected[handle] := true
		else if Affected[handle]
			DllCall("user32\PostMessage", "ptr", handle, "uint", WM_UPDATEUISTATE, "ptr", SET_HIDEFOCUS, "ptr", 0)
	}
	else if (DllCall("IsWindow", "ptr", wParam, "uint"))
		DllCall("user32\PostMessage", "ptr", wParam, "uint", WM_UPDATEUISTATE, "ptr", SET_HIDEFOCUS, "ptr", 0)
}

json(i)  ; by Bentschi
{
	if (RegExMatch(i, "s)^__chr(A|W):(.*)", m))
	{
		VarSetCapacity(b, 4, 0), NumPut(m2, b, 0, "int")
		return StrGet(&b, 1, (m1 = "A") ? "cp28591" : "utf-16")
	}
	if (RegExMatch(i, "s)^__str:((\\""|[^""])*)", m))
	{
		str := m1
		for p, r in {b:"`b", f:"`f", n:"`n", 0:"", r:"`r", t:"`t", v:"`v", "'":"'", """":"""", "/":"/"}
			str := RegExReplace(str, "\\" p, r)
		while (RegExMatch(str, "s)^(.*?)\\x([0-9a-fA-F]{2})(.*)", m))
			str := m1 json("__chrA:0x" m2) m3
		while (RegExMatch(str, "s)^(.*?)\\u([0-9a-fA-F]{4})(.*)", m))
			str := m1 json("__chrW:0x" m2) m3
		while (RegExMatch(str, "s)^(.*?)\\([0-9]{1,3})(.*)", m))
			str := m1 json("__chrA:" m2) m3
		return RegExReplace(str, "\\\\", "\")
	}
	str := [], obj := []
	while (RegExMatch(i, "s)^(.*?[^\\])""((\\""|[^""])*?[^\\]|)""(.*)$", m))
		str.Push(json("__str:" m2)), i := m1 "__str<" str.MaxIndex() ">" m4
	while (RegExMatch(RegExReplace(i, "\s+", ""), "s)^(.*?)(\{|\[)([^\{\[\]\}]*?)(\}|\])(.*)$", m))
	{
		a := (m2="{") ? 0 : 1, c := m3, i := m1 "__obj<" ((obj.MaxIndex() + 1) ? obj.MaxIndex() + 1 : 1) ">" m5, tmp := []
		while (RegExMatch(c, "^(.*?),(.*)$", m))
			tmp.Push(m1), c := m2
		tmp.Push(c), tmp2 := {}, obj.Push(cobj := {})
		for k, v in tmp
		{
			if (RegExMatch(v, "^(.*?):(.*)$", m))
				tmp2[m1] := m2
			else
				tmp2.Push(v)
		}
		for k, v in tmp2
		{
			for x, y in str
				k := RegExReplace(k, "__str<" x ">", y), v := RegExReplace(v, "__str<" x ">", y)
			for x, y in obj
				v := RegExMatch(v, "^__obj<" x ">$") ? y : v
			cobj[k] := v
		}
	}
	return obj[obj.MaxIndex()]
}

RtlGetVersion()  ; https://docs.microsoft.com/en-us/windows/desktop/DevNotes/rtlgetversion
{
	; 0x0A00 - Windows 10
	; 0x0603 - Windows 8.1
	; 0x0602 - Windows 8 / Windows Server 2012
	; 0x0601 - Windows 7 / Windows Server 2008 R2
	static RTL_OSV_EX, init := NumPut(VarSetCapacity(RTL_OSV_EX, 284, 0), RTL_OSV_EX, "uint")
	if (DllCall("ntdll\RtlGetVersion", "ptr", &RTL_OSV_EX) != 0)
		throw Exception("RtlGetVersion failed", -1)
	return ((NumGet(RTL_OSV_EX, 4, "uint") << 8) | NumGet(RTL_OSV_EX, 8, "uint"))
}

SetWindowTheme(handle)  ; https://docs.microsoft.com/en-us/windows/desktop/api/uxtheme/nf-uxtheme-setwindowtheme
{
	global WINVER

	if (WINVER >= 0x0600) {
		VarSetCapacity(ClassName, 1024, 0)
		if (DllCall("user32\GetClassName", "ptr", handle, "str", ClassName, "int", 512, "int"))
			if (ClassName = "SysListView32") || (ClassName = "SysTreeView32")
				if !(DllCall("uxtheme\SetWindowTheme", "ptr", handle, "wstr", "Explorer", "ptr", 0))
					return true
	}
	return false
}


; ===============================================================================================================================