MC_Paste:
  Send, ^v
return

MC_Cut:
  ; As an example, my editor doesn't have ^x set to paste, but it does have
  ; +{DEL}, so that's OK.
  IfWinNotActive, Visual SlickEdit
    Send, ^x
  Else
    Send, +{DEL}
return

OnClipboardChange:
  ; Ignore the change if we made it ourself, or if the clipboard doesn't
  ; contain text.
  if (MC_OwnChange)
    return

  if (ErrorLevel <> 1)
    return

  ;MsgBox % "New " . clipboard . "  Old " . MC_Clip%MC_Index%

  ; Save the old array.
  Loop %MC_NumClip%
    MySaveClip%A_Index% := MC_Clip%A_Index%

  ; Put the new value af the front.
  MC_Clip1 := clipboard

  ; Copy the old array to the new, but exclude any duplicates of the new
  ; entry.
  MyNewIndex := 2
  Loop %MC_NumClip%
  {
    if (MySaveClip%A_Index% <> MC_Clip1)
    {
      MC_Clip%MyNewIndex% := MySaveClip%A_Index%
      MyNewIndex := MyNewIndex + 1

      ; If we run out of space, stop - the oldest entry is lost.
      if (MyNewIndex > MC_NumClip)
        Break
    }
  }
return

; Provide a menu choice of the available clipboards.
MC_PasteMenu:
  MyShow := false

  ; Clear any existing menu and add a null item.
  Menu, MC_Temp, Add
  Menu, MC_Temp, Delete

  Loop %MC_NumClip%
  {
    ; Get the next entry.  Display at most MC_MaxLen if it's a long clipboard.
    StringLeft, MyText, MC_Clip%A_Index%, MC_MaxLen

    ; Add this clip to the menu if it isn't blank.
    if (MyText <> "")
    {
      Menu, MC_Temp, Add, %MyText%, MC_Select
      MyShow := true
    }
  }
  
	;A Separator
	Menu, MC_Temp, Add,
  
	; Note which menu index is the first perm clip.
	PermClipStart := A_Index

	Loop %PermclipCount%
	{
	  mytext := PermClip%A_Index% 
	  ; TODO Could use StringLeft like I did to make sure the menu item isn't too long.
	  Menu, MC_Temp, Add, %mytext%, MC_SelectPerm
	}

  ; Now show the menu, provided there's at least one thing on it.
  if (MyShow)
    Menu, MC_Temp, Show
return

MC_SelectPerm:
  ; Work out which perm clip was selected.
  Index := A_ThisMenuItemPos - PermClipStart
  clipboard := Permclip%Index%
  Gosub, MC_Paste
return

; Paste the "next" clipboard.
;
; This compares the current selected text against each clipboard in turn.
;  - If a match is found, replace the current text with the clipboard after the
;    matching one.
;  - If no match is found, or there isn't another clipboard to paste, paste
;    the first clipboard instead.
;
; Hence if this key is pressed multiple times, it cycles through each clipboard
; in turn.
MC_PasteNext:
  ; We need to grab the selected text.  We do this using cut.
  ; We don't want this copy to affect the real clipboard or our ring, so turn
  ; off tracking the clipboard.
  MC_OwnChange := true
  MySaveClip := ClipboardAll
  Gosub, MC_Cut
  MyMatchText := clipboard

  ; The original clipboard is the "default" if we don't find anything better.
  clipboard := MC_Clip1

  Loop %MC_NumClip%
  {
    if (MC_Clip%A_Index% = MyMatchText)
    {
      MyUseIndex := A_Index+1
      MyText := MC_Clip%MyUseIndex%
      if (MyText <> "")
        clipboard := MyText
      Break
    }
  }

  ; Paste.  This is the next clipboard if we found one, or the original
  ; clipboard if not.
  Gosub, MC_Paste

  ; Restore the first clipboard and continue tracking clipboard changes
  clipboard := MySaveClip
  MC_OwnChange := false
return

; Paste the current clipboard as plain text.
MC_PasteAsText:
  clipboard := clipboard
  Gosub, MC_Paste
return

MC_Select:
  clipboard := MC_Clip%A_ThisMenuItemPos%
  Gosub, MC_Paste
return