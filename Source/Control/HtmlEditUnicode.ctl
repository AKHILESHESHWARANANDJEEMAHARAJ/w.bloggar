VERSION 5.00
Object = "{35E55124-D2A7-4467-955F-19C1DCB7F1CB}#1.1#0"; "RichEdit.ocx"
Begin VB.UserControl HtmlEdit 
   Alignable       =   -1  'True
   ClientHeight    =   1335
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   2655
   ScaleHeight     =   1335
   ScaleWidth      =   2655
   ToolboxBitmap   =   "HtmlEditUnicode.ctx":0000
   Begin RECtl.RichEdit rtfHTML 
      Height          =   1335
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   2655
      _ExtentX        =   4683
      _ExtentY        =   2355
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   -9999997
      HideSelection   =   -1  'True
   End
End
Attribute VB_Name = "HtmlEdit"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'*    w.bloggar
'*    Copyright (C) 2001-2019 Marcelo Lv Cabral <https://lvcabral.com>
'*
'*    This program is free software; you can redistribute it and/or modify
'*    it under the terms of the GNU General Public License as published by
'*    the Free Software Foundation; either version 2 of the License, or
'*    (at your option) any later version.
'*
'*    This program is distributed in the hope that it will be useful,
'*    but WITHOUT ANY WARRANTY; without even the implied warranty of
'*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'*    GNU General Public License for more details.
'*
'*    You should have received a copy of the GNU General Public License along
'*    with this program; if not, write to the Free Software Foundation, Inc.,
'*    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
Option Explicit

' Private (No Property)
' ********************
Dim mblnNoEvents As Boolean
Dim mblnReturnKeyPressed As Boolean
Dim mblnHasChanged As Boolean

' API-Declarations & Constants
' ****************************
Private Declare Function apiLockWindowUpdate Lib "user32" _
                         Alias "LockWindowUpdate" _
                        (ByVal hwndLock As Long) As Long


Private Declare Function apiSendMessage Lib "user32" _
                         Alias "SendMessageA" _
                        (ByVal hwnd As Long, _
                         ByVal wMsg As Long, _
                         ByVal wParam As Long, _
                         lParam As Any) As Long

Private Const EM_GETLINECOUNT = &HBA
Private Const EM_LINEFROMCHAR = &HC9
Private Const EM_LINEINDEX = &HBB

' Enumarations
' ************
Enum hteFindOptions
   fndWholeWord = 2
   fndMatchCase = 4
   fndNoHighlight = 8
End Enum

Private Const htMaxEntityVal = 63

Public Enum hteEntitySet
   etyQuot = 1
   etySect = 2
   etyAuml = 4
   etyOuml = 8
   etyUuml = 16
   etySzlig = 32
End Enum

' Properties
' **********
Dim mProp_AutoColorize As Boolean
Dim mProp_CommentBold As Boolean
Dim mProp_CommentColor As OLE_COLOR
Dim mProp_CommentItalic As Boolean
Dim mProp_Entities As Boolean
Dim mProp_EntityBold As Boolean
Dim mProp_EntityColor As OLE_COLOR
Dim mProp_EntityItalic As Boolean
Dim mProp_ProgressBar As Object
Dim mProp_PropNameBold As Boolean
Dim mProp_PropNameColor As OLE_COLOR
Dim mProp_PropNameItalic As Boolean
Dim mProp_PropValBold As Boolean
Dim mProp_PropValColor As OLE_COLOR
Dim mProp_PropValItalic As Boolean
Dim mProp_Silent As Boolean
Dim mProp_TagBold As Boolean
Dim mProp_TagColor As OLE_COLOR
Dim mProp_TagItalic As Boolean

' Default Values
' **************
Const mDef_AutoColorize = True
Const mDef_AutoVerbMenu = False
Const mDef_BackColor = vbWindowBackground
Const mDef_CommentBold = False
Const mDef_CommentColor = 32768                          ' = Dark Green
Const mDef_CommentItalic = True
Const mDef_Enabled = True
Const mDef_Entities = True
Const mDef_EntityBold = False
Const mDef_EntityColor = &H404040                        ' = Dark Gray
Const mDef_EntityItalic = False
Const mDef_FileName = ""
Const mDef_Font = Null
Const mDef_HideSelection = False
Const mDef_Locked = False
Const mDef_MaxLength = 0
Const mDef_MouseIcon = Null
Const mDef_MousePointer = vbDefault
Const mDef_ProgressBar = Null                            ' = Nothing
Const mDef_PropNameBold = False
Const mDef_PropNameColor = 8388608                       ' = Dark Blue
Const mDef_PropNameItalic = False
Const mDef_PropValBold = False
Const mDef_PropValColor = 128                            ' = Dark Blue
Const mDef_PropValItalic = False
Const mDef_RightMargin = 0
Const mDef_Silent = True
Const mDef_TagBold = True
Const mDef_TagColor = 16711680                           ' = Light Blue
Const mDef_TagItalic = False
Const mDef_Text = ""

' Events
' ******
Public Event Change()
Attribute Change.VB_MemberFlags = "200"
Public Event Click()
Public Event DblClick()
Public Event KeyDown(KeyCode As Integer, Shift As Integer)
Public Event KeyPress(KeyAscii As Integer)
Public Event KeyUp(KeyCode As Integer, Shift As Integer)
Public Event MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
Public Event MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
Public Event MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
Public Event SelChange()

Private Sub rtfHTML_Change()
   If mblnNoEvents Then Exit Sub
   mblnHasChanged = True
   RaiseEvent Change
End Sub

Private Sub rtfHTML_Click()
   If mblnNoEvents Then Exit Sub
   RaiseEvent Click
End Sub

Private Sub rtfHTML_DblClick(Button As Integer, Shift As Integer, x As Long, y As Long, LinkRange As Range)
   If mblnNoEvents Then Exit Sub
   RaiseEvent DblClick
End Sub

Private Sub rtfHTML_KeyDown(KeyCode As Integer, Shift As Integer)
   If mblnNoEvents Then Exit Sub
   If KeyCode = vbKeyReturn Then
      mblnReturnKeyPressed = True
   ElseIf KeyCode = vbKeyUp Or KeyCode = vbKeyDown Or KeyCode = vbKeyLeft Or KeyCode = vbKeyRight Then
      mblnReturnKeyPressed = True
   ElseIf KeyCode = Asc(">") Then
      mblnReturnKeyPressed = True
   Else
      mblnReturnKeyPressed = False
   End If
   RaiseEvent KeyDown(KeyCode, Shift)
End Sub

Private Sub rtfHTML_KeyPress(KeyAscii As Integer)
Dim strCode As String, lngPos As Long
   If mblnNoEvents Then Exit Sub
   
   If Not mProp_Entities Then GoTo RaiseKeyPress
   
    Select Case KeyAscii
    'Symbols
    Case Asc("�"): strCode = "&sect;"
    Case Asc("�"): strCode = "&szlig;"
    Case Asc("�"): strCode = "&copy;"
    Case Asc("�"): strCode = "&reg;"
    Case Asc("�"): strCode = "&yen;"
    Case Asc("�"): strCode = "&euro;"
    Case Asc("�"): strCode = "&sup2;"
    Case Asc("�"): strCode = "&sup3;"
    Case Asc("�"): strCode = "&frac14;"
    Case Asc("�"): strCode = "&frac12;"
    Case Asc("�"): strCode = "&frac34;"
    Case Asc("�"): strCode = "&lsquo;"
    Case Asc("�"): strCode = "&rsquo;"
    Case Asc("�"): strCode = "&laquo;"
    Case Asc("�"): strCode = "&raquo;"
    'Upper Case
    Case Asc("�"): strCode = "&Ccedil;"
    Case Asc("�"): strCode = "&Aring;"
    Case Asc("�"): strCode = "&Auml;"
    Case Asc("�"): strCode = "&Euml;"
    Case Asc("�"): strCode = "&Iuml;"
    Case Asc("�"): strCode = "&Ouml;"
    Case Asc("�"): strCode = "&Uuml;"
    Case Asc("�"): strCode = "&Aacute;"
    Case Asc("�"): strCode = "&Eacute;"
    Case Asc("�"): strCode = "&Iacute;"
    Case Asc("�"): strCode = "&Oacute;"
    Case Asc("�"): strCode = "&Uacute;"
    Case Asc("�"): strCode = "&Acirc;"
    Case Asc("�"): strCode = "&Ecirc;"
    Case Asc("�"): strCode = "&Icirc;"
    Case Asc("�"): strCode = "&Ocirc;"
    Case Asc("�"): strCode = "&Ucirc;"
    Case Asc("�"): strCode = "&Agrave;"
    Case Asc("�"): strCode = "&Egrave;"
    Case Asc("�"): strCode = "&Igrave;"
    Case Asc("�"): strCode = "&Ograve;"
    Case Asc("�"): strCode = "&Ugrave;"
    Case Asc("�"): strCode = "&Atilde;"
    Case Asc("�"): strCode = "&Otilde;"
    Case Asc("�"): strCode = "&Ntilde;"
    'Lower Case
    Case Asc("�"): strCode = "&ccedil;"
    Case Asc("�"): strCode = "&aring;"
    Case Asc("�"): strCode = "&auml;"
    Case Asc("�"): strCode = "&euml;"
    Case Asc("�"): strCode = "&iuml;"
    Case Asc("�"): strCode = "&ouml;"
    Case Asc("�"): strCode = "&uuml;"
    Case Asc("�"): strCode = "&aacute;"
    Case Asc("�"): strCode = "&eacute;"
    Case Asc("�"): strCode = "&iacute;"
    Case Asc("�"): strCode = "&oacute;"
    Case Asc("�"): strCode = "&uacute;"
    Case Asc("�"): strCode = "&acirc;"
    Case Asc("�"): strCode = "&ecirc;"
    Case Asc("�"): strCode = "&icirc;"
    Case Asc("�"): strCode = "&ocirc;"
    Case Asc("�"): strCode = "&ucirc;"
    Case Asc("�"): strCode = "&agrave;"
    Case Asc("�"): strCode = "&egrave;"
    Case Asc("�"): strCode = "&igrave;"
    Case Asc("�"): strCode = "&ograve;"
    Case Asc("�"): strCode = "&ugrave;"
    Case Asc("�"): strCode = "&atilde;"
    Case Asc("�"): strCode = "&otilde;"
    Case Asc("�"): strCode = "&ntilde;"
    End Select
    If strCode <> "" Then
        KeyAscii = 0
        lngPos = rtfHTML.Selection.Range.StartPos
        rtfHTML.Selection.TypeText strCode
        Colorize lngPos, lngPos + Len(strCode)
        rtfHTML.Selection.Range.StartPos = lngPos + Len(strCode)
        rtfHTML.Selection.Range.Font.Name = rtfHTML.Font.Name
        rtfHTML.Selection.Range.Font.Size = rtfHTML.Font.Size
        rtfHTML.Selection.Range.Font.ForeColor = vbWindowText
        rtfHTML.Selection.Range.Font.Bold = rtfHTML.Font.Bold
        rtfHTML.Selection.Range.Font.Italic = rtfHTML.Font.Italic
    End If
RaiseKeyPress:
   RaiseEvent KeyPress(KeyAscii)
End Sub

Private Sub rtfHTML_KeyUp(KeyCode As Integer, Shift As Integer)
   If mblnNoEvents Then Exit Sub
   RaiseEvent KeyUp(KeyCode, Shift)
End Sub

Private Sub rtfHTML_MouseDown(Button As Integer, Shift As Integer, x As Long, y As Long, LinkRange As Range)
   If mblnNoEvents Then Exit Sub
   RaiseEvent MouseDown(Button, Shift, CSng(x), CSng(y))
End Sub

Private Sub rtfHTML_MouseUp(Button As Integer, Shift As Integer, x As Long, y As Long, LinkRange As Range)
   If mblnNoEvents Then Exit Sub
   RaiseEvent MouseUp(Button, Shift, CSng(x), CSng(y))
End Sub

Private Sub rtfHTML_OLECompleteDrag(Effect As Long)
    If mProp_AutoColorize Then Colorize
End Sub

Private Sub rtfHTML_OLEDragDrop(Data As RichTextLib.DataObject, Effect As Long, Button As Integer, Shift As Integer, x As Single, y As Single)
'fires when data is dropped on the control
    If Data.GetFormat(vbCFText) Then
        rtfHTML.Selection.TypeText Data.GetData(vbCFText)
    End If
End Sub

Private Sub rtfHTML_OLEDragOver(Data As RichTextLib.DataObject, Effect As Long, Button As Integer, Shift As Integer, x As Single, y As Single, State As Integer)
'fires as data dragged over the control
If Data.GetFormat(vbCFRTF) Or _
    Data.GetFormat(vbCFText) Then
    'copies data unless Shift is down
    If (Shift And vbShiftMask) Then
        Effect = vbDropEffectMove
    Else
        Effect = vbDropEffectCopy
    End If
Else
    Effect = vbDropEffectNone
End If
End Sub

Private Sub rtfHTML_SelChange()
   If mblnNoEvents Then Exit Sub
   Static slngLastLine As Long
   Dim lngCurLine As Long
   Dim lngPosStart As Long
   Dim lngPosEnd As Long
   
   If Not mblnHasChanged Then
      RaiseEvent SelChange
      Exit Sub
   End If
   
   mblnHasChanged = False
   
   mblnNoEvents = True
   
   If slngLastLine = 0 Then slngLastLine = GetLineSelected + 1
   
   If mProp_AutoColorize And mblnReturnKeyPressed Then
      If Not slngLastLine = GetLineSelected + 1 Then
         lngCurLine = GetLineSelected + 1
         If lngCurLine > slngLastLine Then
            lngPosStart = GetLineFirstCharIndex(slngLastLine - 1)
            lngPosEnd = GetLineFirstCharIndex
            If lngPosStart >= 0 And lngPosEnd >= 0 Then
               Colorize lngPosStart, lngPosEnd
            End If
         Else
            lngPosStart = GetLineFirstCharIndex
            lngPosEnd = GetLineFirstCharIndex(slngLastLine)
            If lngPosStart >= 0 And lngPosEnd >= 0 Then
               Colorize lngPosStart, lngPosEnd
            End If
         End If
      End If
   End If
   mblnNoEvents = False
   slngLastLine = GetLineSelected + 1
   RaiseEvent SelChange
End Sub

Private Sub UserControl_InitProperties()
   mProp_AutoColorize = mDef_AutoColorize
   rtfHTML.AutoVerbMenu = mDef_AutoVerbMenu
   rtfHTML.BackColor = mDef_BackColor
   mProp_CommentBold = mDef_CommentBold
   mProp_CommentColor = mDef_CommentColor
   mProp_CommentItalic = mDef_CommentItalic
   UserControl.Enabled = mDef_Enabled
   mProp_Entities = mDef_Entities
   mProp_EntityBold = mDef_EntityBold
   mProp_EntityColor = mDef_EntityColor
   mProp_EntityItalic = mDef_EntityItalic
   rtfHTML.FileName = mDef_FileName
   Set rtfHTML.Font = Ambient.Font
   rtfHTML.HideSelection = mDef_HideSelection
   rtfHTML.Locked = mDef_Locked
   rtfHTML.MaxLength = mDef_MaxLength
   rtfHTML.MouseIcon = Nothing
   rtfHTML.MousePointer = mDef_MousePointer
   Set mProp_ProgressBar = Nothing
   mProp_PropNameBold = mDef_PropNameBold
   mProp_PropNameColor = mDef_PropNameColor
   mProp_PropNameItalic = mDef_PropNameItalic
   mProp_PropValBold = mDef_PropValBold
   mProp_PropValColor = mDef_PropValColor
   mProp_PropValItalic = mDef_PropValItalic
   rtfHTML.RightMargin = mDef_RightMargin
   mProp_Silent = mDef_Silent
   mProp_TagBold = mDef_TagBold
   mProp_TagColor = mDef_TagColor
   mProp_TagItalic = mDef_TagItalic
   rtfHTML.Text = mDef_Text
End Sub

Private Sub UserControl_ReadProperties(PropBag As PropertyBag)
   With PropBag
      mProp_AutoColorize = .ReadProperty("AutoColorize", mDef_AutoColorize)
      'rtfHTML.AutoVerbMenu = .ReadProperty("AutoVerbMenu", mDef_AutoVerbMenu)
      rtfHTML.BackColor = .ReadProperty("BackColor", mDef_BackColor)
      mProp_CommentBold = .ReadProperty("CommentBold", mDef_CommentBold)
      mProp_CommentColor = .ReadProperty("CommentColor", mDef_CommentColor)
      mProp_CommentItalic = .ReadProperty("CommentItalic", mDef_CommentItalic)
      UserControl.Enabled = .ReadProperty("Enabled", mDef_Enabled)
      mProp_Entities = .ReadProperty("Entities", mDef_Entities)
      mProp_EntityBold = .ReadProperty("EntityBold", mDef_EntityBold)
      mProp_EntityColor = .ReadProperty("EntityColor", mDef_EntityColor)
      mProp_EntityItalic = .ReadProperty("EntityItalic", mDef_EntityItalic)
      'rtfHTML.FileName = .ReadProperty("FileName", mDef_FileName)
      Set rtfHTML.Font = .ReadProperty("Font", Ambient.Font)
      rtfHTML.HideSelection = .ReadProperty("HideSelection", mDef_HideSelection)
      rtfHTML.Locked = .ReadProperty("Locked", mDef_Locked)
      rtfHTML.MaxLength = .ReadProperty("MaxLength", mDef_MaxLength)
      'Set rtfHTML.MouseIcon = .ReadProperty("MouseIcon", Nothing)
      'rtfHTML.MousePointer = .ReadProperty("MousePointer", mDef_MousePointer)
      mProp_PropNameBold = .ReadProperty("PropNameBold", mDef_PropNameBold)
      mProp_PropNameColor = .ReadProperty("PropNameColor", mDef_PropNameColor)
      mProp_PropNameItalic = .ReadProperty("PropNameItalic", mDef_PropNameItalic)
      mProp_PropValBold = .ReadProperty("PropValBold", mDef_PropValBold)
      mProp_PropValColor = .ReadProperty("PropValColor", mDef_PropValColor)
      mProp_PropValItalic = .ReadProperty("PropValItalic", mDef_PropValItalic)
      mProp_Silent = .ReadProperty("Silent", mDef_Silent)
      'rtfHTML.RightMargin = .ReadProperty("RightMargin", mDef_RightMargin)
      mProp_TagBold = .ReadProperty("TagBold", mDef_TagBold)
      mProp_TagColor = .ReadProperty("TagColor", mDef_TagColor)
      mProp_TagItalic = .ReadProperty("TagItalic", mDef_TagItalic)
      rtfHTML.Text = .ReadProperty("Text", mDef_Text)
   End With
End Sub

Private Sub UserControl_Resize()
   On Error Resume Next
   rtfHTML.Move 0, 0, ScaleWidth, ScaleHeight
End Sub

Private Sub UserControl_WriteProperties(PropBag As PropertyBag)
   With PropBag
      .WriteProperty "AutoColorize", mProp_AutoColorize, mDef_AutoColorize
      .WriteProperty "AutoVerbMenu", rtfHTML.AutoVerbMenu, mDef_AutoVerbMenu
      .WriteProperty "BackColor", rtfHTML.BackColor, mDef_BackColor
      .WriteProperty "CommentBold", mProp_CommentBold, mDef_CommentBold
      .WriteProperty "CommentColor", mProp_CommentColor, mDef_CommentColor
      .WriteProperty "CommentItalic", mProp_CommentItalic, mDef_CommentItalic
      .WriteProperty "Enabled", UserControl.Enabled, mDef_Enabled
      .WriteProperty "Entities", mProp_Entities, mDef_Entities
      .WriteProperty "EntityBold", mProp_EntityBold, mDef_EntityBold
      .WriteProperty "EntityColor", mProp_EntityColor, mDef_EntityColor
      .WriteProperty "EntityItalic", mProp_EntityItalic, mDef_EntityItalic
      .WriteProperty "FileName", rtfHTML.FileName, mDef_FileName
      .WriteProperty "Font", rtfHTML.Font, Ambient.Font
      .WriteProperty "HideSelection", rtfHTML.HideSelection, mDef_HideSelection
      .WriteProperty "Locked", rtfHTML.Locked, mDef_Locked
      .WriteProperty "MaxLength", rtfHTML.MaxLength, mDef_MaxLength
      .WriteProperty "MouseIcon", rtfHTML.MouseIcon, mDef_MouseIcon
      .WriteProperty "MousePointer", rtfHTML.MousePointer, mDef_MousePointer
      .WriteProperty "PropNameBold", mProp_PropNameBold, mDef_PropNameBold
      .WriteProperty "PropNameColor", mProp_PropNameColor, mDef_PropNameColor
      .WriteProperty "PropNameItalic", mProp_PropNameItalic, mDef_PropNameItalic
      .WriteProperty "PropValBold", mProp_PropValBold, mDef_PropValBold
      .WriteProperty "PropValColor", mProp_PropValColor, mDef_PropValColor
      .WriteProperty "PropValItalic", mProp_PropValItalic, mDef_PropValItalic
      .WriteProperty "Silent", mProp_Silent, mDef_Silent
      .WriteProperty "RightMargin", rtfHTML.RightMargin, mDef_RightMargin
      .WriteProperty "TagBold", mProp_TagBold, mDef_TagBold
      .WriteProperty "TagColor", mProp_TagColor, mDef_TagColor
      .WriteProperty "TagItalic", mProp_TagItalic, mDef_TagItalic
      .WriteProperty "Text", rtfHTML.Text, mDef_Text
   End With
End Sub

Public Property Get AutoColorize() As Boolean
Attribute AutoColorize.VB_ProcData.VB_Invoke_Property = ";Verhalten"
   AutoColorize = mProp_AutoColorize
End Property

Public Property Let AutoColorize(ByVal blnNewValue As Boolean)
   mProp_AutoColorize = blnNewValue
End Property

Public Property Get AutoVerbMenu() As Boolean
Attribute AutoVerbMenu.VB_ProcData.VB_Invoke_Property = ";Verhalten"
   AutoVerbMenu = rtfHTML.AutoVerbMenu
End Property

Public Property Let AutoVerbMenu(ByVal blnNewValue As Boolean)
   rtfHTML.AutoVerbMenu = blnNewValue
   PropertyChanged "AutoVerbMenu"
End Property

Public Property Get BackColor() As OLE_COLOR
Attribute BackColor.VB_ProcData.VB_Invoke_Property = ";Darstellung"
Attribute BackColor.VB_UserMemId = -501
   BackColor = rtfHTML.BackColor
End Property

Public Property Let BackColor(ByVal oleNewValue As OLE_COLOR)
   rtfHTML.BackColor = oleNewValue
   PropertyChanged "BackColor"
End Property

Public Property Get CommentBold() As Boolean
Attribute CommentBold.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   CommentBold = mProp_CommentBold
End Property

Public Property Let CommentBold(ByVal blnNewValue As Boolean)
   mProp_CommentBold = blnNewValue
   PropertyChanged "CommentBold"
End Property

Public Property Get CommentColor() As OLE_COLOR
Attribute CommentColor.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   CommentColor = mProp_CommentColor
End Property

Public Property Let CommentColor(ByVal oleNewValue As OLE_COLOR)
   mProp_CommentColor = oleNewValue
   PropertyChanged "CommentColor"
End Property

Public Property Get CommentItalic() As Boolean
Attribute CommentItalic.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   CommentItalic = mProp_CommentItalic
End Property

Public Property Let CommentItalic(ByVal blnNewValue As Boolean)
   mProp_CommentItalic = blnNewValue
   PropertyChanged "CommentItalic"
End Property

Public Property Get Enabled() As Boolean
Attribute Enabled.VB_UserMemId = -514
   Enabled = UserControl.Enabled
End Property

Public Property Let Enabled(ByVal blnNewValue As Boolean)
   UserControl.Enabled = blnNewValue
   PropertyChanged "Enabled"
End Property

Public Property Get Entities() As Boolean
Attribute Entities.VB_ProcData.VB_Invoke_Property = ";Verhalten"
   Entities = mProp_Entities
End Property

Public Property Let Entities(ByVal lngNewValue As Boolean)
   mProp_Entities = lngNewValue
End Property

Public Property Get EntityBold() As Boolean
Attribute EntityBold.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   EntityBold = mProp_EntityBold
End Property

Public Property Let EntityBold(ByVal blnNewValue As Boolean)
   mProp_EntityBold = blnNewValue
   PropertyChanged "EntityBold"
End Property

Public Property Get EntityColor() As OLE_COLOR
Attribute EntityColor.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   EntityColor = mProp_EntityColor
End Property

Public Property Let EntityColor(ByVal oleNewValue As OLE_COLOR)
   mProp_EntityColor = oleNewValue
   PropertyChanged "EntityColor"
End Property

Public Property Get EntityItalic() As Boolean
Attribute EntityItalic.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   EntityItalic = mProp_EntityItalic
End Property

Public Property Let EntityItalic(ByVal blnNewValue As Boolean)
   mProp_EntityItalic = blnNewValue
   PropertyChanged "EntityItalic"
End Property

Public Property Get FileName() As String
Attribute FileName.VB_ProcData.VB_Invoke_Property = ";Text"
   FileName = rtfHTML.FileName
End Property

Public Property Let FileName(ByVal strNewValue As String)
   rtfHTML.FileName = strNewValue
   PropertyChanged "FileName"
End Property

Public Function Find(ByVal strString As String, Optional ByVal lngStart As Long = False, Optional ByVal lngEnd As Long = False, Optional ByVal fndOptions As hteFindOptions = False)
   If lngStart = False And lngEnd = False Then
      Find = rtfHTML.Find(strString, , , fndOptions)
   ElseIf lngStart = False Then
      Find = rtfHTML.Find(strString, , lngEnd, fndOptions)
   ElseIf lngEnd = False Then
      Find = rtfHTML.Find(strString, lngStart, , fndOptions)
   Else
      Find = rtfHTML.Find(strString, lngStart, lngEnd, fndOptions)
   End If
   
End Function

Public Property Get Font() As StdFont
Attribute Font.VB_ProcData.VB_Invoke_Property = ";Schriftart"
Attribute Font.VB_UserMemId = -512
   Set Font = rtfHTML.Font
End Property

Public Property Set Font(ByVal mnewFont As StdFont)
   With rtfHTML.Font
      .Bold = mnewFont.Bold
      .Italic = mnewFont.Italic
      .Name = mnewFont.Name
      .Size = mnewFont.Size
      .Strikethrough = mnewFont.Strikethrough
      .Underline = mnewFont.Underline
      .Weight = mnewFont.Weight
      .Charset = mnewFont.Charset
   End With
   PropertyChanged "Font"
End Property

Private Function GetPercentVal(ByVal lngValue As Long, ByVal lngMax As Long) As Byte
   GetPercentVal = CByte(1 / (lngMax / lngValue) * 100)
End Function

Public Function GetLineCount() As Long
   GetLineCount = apiSendMessage(rtfHTML.hwnd, EM_GETLINECOUNT, 0, 0&)
End Function

Public Function GetLineFirstCharIndex(Optional ByVal lngLineIndex As Long = -1) As Long
   GetLineFirstCharIndex = apiSendMessage(rtfHTML.hwnd, EM_LINEINDEX, lngLineIndex, 0&)
End Function

Public Function GetLineFromChar(ByVal lngCharIndex As Long) As Long
   GetLineFromChar = rtfHTML.GetLineFromChar(lngCharIndex)
End Function

Public Function GetLineSelected() As Long
   GetLineSelected = apiSendMessage(rtfHTML.hwnd, EM_LINEFROMCHAR, -1, 0&)
End Function

Public Property Get HideSelection() As Boolean
Attribute HideSelection.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   HideSelection = rtfHTML.HideSelection
End Property

Public Property Let HideSelection(ByVal blnNewValue As Boolean)
   rtfHTML.HideSelection = blnNewValue
   PropertyChanged "HideSelection"
End Property

Public Property Get hwnd() As Long
Attribute hwnd.VB_ProcData.VB_Invoke_Property = ";Verschiedenes"
Attribute hwnd.VB_UserMemId = -515
Attribute hwnd.VB_MemberFlags = "400"
   hwnd = rtfHTML.hwnd
End Property

Public Function LoadFile(ByVal strFilePath As String)
   rtfHTML.LoadFile strFilePath, rtfText
End Function

Public Property Get Locked() As Boolean
Attribute Locked.VB_ProcData.VB_Invoke_Property = ";Verhalten"
   Locked = rtfHTML.Locked
End Property

Public Property Let Locked(ByVal blnNewValue As Boolean)
   rtfHTML.Locked = blnNewValue
   PropertyChanged "Locked"
End Property

Public Property Get MaxLength() As Long
Attribute MaxLength.VB_ProcData.VB_Invoke_Property = ";Verhalten"
   MaxLength = rtfHTML.MaxLength
End Property

Public Property Let MaxLength(ByVal lngNewValue As Long)
   rtfHTML.MaxLength = lngNewValue
   PropertyChanged "MaxLength"
End Property

Public Property Get MouseIcon() As StdPicture
Attribute MouseIcon.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   Set MouseIcon = rtfHTML.MouseIcon
End Property

Public Property Set MouseIcon(ByVal stdNewValue As StdPicture)
   Set rtfHTML.MouseIcon = stdNewValue
   PropertyChanged "MouseIcon"
End Property

Public Property Get MousePointer() As MousePointerConstants
Attribute MousePointer.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   MousePointer = rtfHTML.MousePointer
End Property

Public Property Let MousePointer(ByVal mpcNewValue As MousePointerConstants)
   rtfHTML.MousePointer = mpcNewValue
   PropertyChanged "MousePointer"
End Property

Public Property Get ProgressBar() As Object
Attribute ProgressBar.VB_MemberFlags = "400"
   Set ProgressBar = mProp_ProgressBar
End Property

Public Property Set ProgressBar(ByVal objNewValue As Object)
   Set mProp_ProgressBar = objNewValue
End Property

Public Property Get PropNameBold() As Boolean
Attribute PropNameBold.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   PropNameBold = mProp_PropNameBold
End Property

Public Property Let PropNameBold(ByVal blnNewValue As Boolean)
   mProp_PropNameBold = blnNewValue
   PropertyChanged "PropNameBold"
End Property

Public Property Get PropNameColor() As OLE_COLOR
Attribute PropNameColor.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   PropNameColor = mProp_PropNameColor
End Property

Public Property Let PropNameColor(ByVal oleNewValue As OLE_COLOR)
   mProp_PropNameColor = oleNewValue
   PropertyChanged "PropNameColor"
End Property

Public Property Get PropNameItalic() As Boolean
Attribute PropNameItalic.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   PropNameItalic = mProp_PropNameItalic
End Property

Public Property Let PropNameItalic(ByVal blnNewValue As Boolean)
   mProp_PropNameItalic = blnNewValue
   PropertyChanged "PropNameItalic"
End Property

Public Property Get PropValBold() As Boolean
Attribute PropValBold.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   PropValBold = mProp_PropValBold
End Property

Public Property Let PropValBold(ByVal blnNewValue As Boolean)
   mProp_PropValBold = blnNewValue
   PropertyChanged "PropValBold"
End Property

Public Property Get PropValColor() As OLE_COLOR
Attribute PropValColor.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   PropValColor = mProp_PropValColor
End Property

Public Property Let PropValColor(ByVal oleNewValue As OLE_COLOR)
   mProp_PropValColor = oleNewValue
   PropertyChanged "PropValColor"
End Property

Public Property Get PropValItalic() As Boolean
Attribute PropValItalic.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   PropValItalic = mProp_PropValItalic
End Property

Public Property Let PropValItalic(ByVal blnNewValue As Boolean)
   mProp_PropValItalic = blnNewValue
   PropertyChanged "PropValItalic"
End Property

Public Property Get RightMargin() As Single
Attribute RightMargin.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   RightMargin = rtfHTML.RightMargin
End Property

Public Sub Refresh()
Attribute Refresh.VB_UserMemId = -550
   rtfHTML.Refresh
End Sub

Public Property Let RightMargin(ByVal sngNewValue As Single)
   rtfHTML.RightMargin = sngNewValue
   PropertyChanged "RightMargin"
End Property

Public Sub SaveFile(ByVal strFilePath As String)
   rtfHTML.SaveFile strFilePath, rtfText
End Sub

Public Property Get SelLength() As Long
Attribute SelLength.VB_ProcData.VB_Invoke_Property = ";Verhalten"
Attribute SelLength.VB_MemberFlags = "400"
   SelLength = rtfHTML.Selection.Range.length
End Property

Public Property Let SelLength(ByVal lngNewValue As Long)
On Error GoTo ErrorHandler
   rtfHTML.Selection.Range.length = lngNewValue
   Exit Property
ErrorHandler:
    Err.Raise Err.Number, Err.Source, Err.Description
End Property

Public Sub SelPrint(ByVal hdc As Long)
   rtfHTML.SelPrint hdc
End Sub

Public Property Get SelStart() As Long
Attribute SelStart.VB_ProcData.VB_Invoke_Property = ";Text"
Attribute SelStart.VB_MemberFlags = "400"
   SelStart = rtfHTML.Selection.Range.StartPos
End Property

Public Property Let SelStart(ByVal lngNewValue As Long)
On Error GoTo ErrorHandler
   rtfHTML.Selection.Range.StartPos = lngNewValue
   Exit Property
ErrorHandler:
    Err.Raise Err.Number, Err.Source, Err.Description
End Property

Public Property Get SelTabCount() As Variant
Attribute SelTabCount.VB_ProcData.VB_Invoke_Property = ";Text"
Attribute SelTabCount.VB_MemberFlags = "400"
   SelTabCount = rtfHTML.SelTabCount
End Property

Public Property Let SelTabCount(ByVal vntNewValue As Variant)
On Error GoTo ErrorHandler
   rtfHTML.SelTabCount = vntNewValue
   Exit Property
ErrorHandler:
    Err.Raise Err.Number, Err.Source, Err.Description
End Property

Public Property Get SelTabs(ByVal Index As Integer) As Variant
Attribute SelTabs.VB_ProcData.VB_Invoke_Property = ";Text"
Attribute SelTabs.VB_MemberFlags = "400"
   SelTabs(Index) = rtfHTML.SelTabs(Index)
End Property

Public Property Let SelTabs(ByVal Index As Integer, ByVal vntNewValue As Variant)
On Error GoTo ErrorHandler
   rtfHTML.SelTabs(Index) = vntNewValue
   Exit Property
ErrorHandler:
    Err.Raise Err.Number, Err.Source, Err.Description
End Property

Public Property Get SelText() As String
Attribute SelText.VB_ProcData.VB_Invoke_Property = ";Text"
Attribute SelText.VB_MemberFlags = "400"
   SelText = rtfHTML.Selection.Range.Text
End Property

Public Property Let SelText(ByVal strNewValue As String)
   rtfHTML.Selection.TypeText strNewValue
End Property

Public Property Get Silent() As Boolean
Attribute Silent.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   Silent = mProp_Silent
End Property

Public Property Let Silent(ByVal blnNewValue As Boolean)
   mProp_Silent = blnNewValue
   PropertyChanged "Silent"
End Property

Public Sub Span(ByVal strString As String, Optional ByVal blnGoForward As Boolean = True, Optional ByVal blnNegate As Boolean = False)
On Error GoTo ErrorHandler
   rtfHTML.Span strString, blnGoForward, blnNegate
   Exit Sub
ErrorHandler:
    Err.Raise Err.Number, Err.Source, Err.Description
End Sub

Public Property Get TagBold() As Boolean
Attribute TagBold.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   TagBold = mProp_TagBold
End Property

Public Property Let TagBold(ByVal blnNewValue As Boolean)
   mProp_TagBold = blnNewValue
   PropertyChanged "TagBold"
End Property

Public Property Get TagColor() As OLE_COLOR
Attribute TagColor.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   TagColor = mProp_TagColor
End Property

Public Property Let TagColor(ByVal oleNewValue As OLE_COLOR)
   mProp_TagColor = oleNewValue
   PropertyChanged "TagColor"
End Property

Public Property Get TagItalic() As Boolean
Attribute TagItalic.VB_ProcData.VB_Invoke_Property = ";Darstellung"
   TagItalic = mProp_TagItalic
End Property

Public Property Let TagItalic(ByVal blnNewValue As Boolean)
   mProp_TagItalic = blnNewValue
   PropertyChanged "TagItalic"
End Property

Public Property Get Text() As String
Attribute Text.VB_ProcData.VB_Invoke_Property = ";Text"
Attribute Text.VB_UserMemId = 0
Attribute Text.VB_MemberFlags = "200"
   Text = rtfHTML.Text
End Property

Public Property Let Text(ByVal strNewValue As String)
   rtfHTML.Text = strNewValue
   PropertyChanged "Text"
   PropertyChanged "TextRTF"
End Property

Public Property Get TextRTF() As String
Attribute TextRTF.VB_ProcData.VB_Invoke_Property = ";Text"
   TextRTF = rtfHTML.TextRTF
End Property

Public Property Let TextRTF(ByVal strNewValue As String)
   rtfHTML.TextRTF = strNewValue
   PropertyChanged "TextRTF"
   PropertyChanged "Text"
End Property

Public Sub UpTo(ByVal strString As String, Optional ByVal blnGoForward As Boolean = True, Optional ByVal blnNegate As Boolean = False)
On Error GoTo ErrorHandler
   rtfHTML.UpTo strString, blnGoForward, blnNegate
   Exit Sub
ErrorHandler:
    Err.Raise Err.Number, Err.Source, Err.Description
End Sub

Public Sub RefreshFont()
On Error GoTo ErrorHandler
   Dim lngOldSelStart As Long
   Dim lngOldSelLength As Long
   lngOldSelStart = rtfHTML.Selection.Range.StartPos
   lngOldSelLength = rtfHTML.Selection.Range.length
   apiLockWindowUpdate rtfHTML.hwnd
   mblnNoEvents = True
   
   rtfHTML.Selection.Range.StartPos = 0
   rtfHTML.Selection.Range.length = Len(rtfHTML.Text)
   rtfHTML.Selection.Range.Font.Name = rtfHTML.Font.Name
   rtfHTML.Selection.Range.Font.Size = rtfHTML.Font.Size
   
   On Error Resume Next
   Err.Clear
   rtfHTML.Selection.Range.StartPos = lngOldSelStart
   rtfHTML.Selection.Range.length = lngOldSelLength
   If Err.Number <> 0 Then rtfHTML.Selection.Range.StartPos = lngOldSelStart
   Err.Clear
   On Error GoTo ErrorHandler
   
   mblnNoEvents = False
   apiLockWindowUpdate 0
   mblnHasChanged = False
   Exit Sub
ErrorHandler:
    Err.Raise Err.Number, Err.Source, Err.Description
End Sub

Public Sub Colorize(Optional ByVal lngStartPos As Long, Optional ByVal lngEndPos As Long)
On Error GoTo ErrorHandler
   Const posText = 1
   Const posTag = 2
   Const posPropName = 4
   Const posPropVal = 8
   Const posComment = 16
   Const posStyleTag = 32
   Const posScriptTag = 64

   Const prgIsNothing = 0
   Const prgIsMicrosoft = 1
   Const prgIsHeTill = 2

   Dim strText As String
   Dim lngTextPos As Long
   Dim bytSelPos As Byte: bytSelPos = posText
   Dim lngTagStart As Long
   Dim lngPropNameStart As Long
   Dim lngPropValStart As Long
   Dim lngOldSelStart As Long
   Dim lngOldEndPos As Long
   Dim blnPropWithQuotes As Boolean
   Dim blnSpecialTag As Boolean
   Dim blnStyleTag As Boolean
   Dim blnScriptTag As Boolean
   Dim lngEntityCounter As Long
   Dim bytOldPrg As Byte
   Dim bytCurPrg As Byte
   Dim bytPrgBar As Byte
   strText = rtfHTML.Text

   If lngStartPos = 0 Then lngStartPos = 1
   If lngEndPos = 0 Then lngEndPos = Len(rtfHTML.Text)
      
   mblnNoEvents = True
     
   lngOldSelStart = rtfHTML.Selection.Range.StartPos
   lngOldEndPos = rtfHTML.Selection.Range.length

   If mProp_Silent Then apiLockWindowUpdate rtfHTML.hwnd

   On Error Resume Next
   Err.Clear
   rtfHTML.Selection.Range.StartPos = lngStartPos - 1
   If Err.Number <> 0 Then rtfHTML.Selection.Range.StartPos = lngStartPos
   On Error GoTo ErrorHandler
   rtfHTML.Selection.Range.EndPos = lngEndPos '- lngStartPos + IIf(Err.Number <> 0, 0, 1)
   rtfHTML.Selection.Range.Font.Name = rtfHTML.Font.Name
   rtfHTML.Selection.Range.Font.Size = rtfHTML.Font.Size
   rtfHTML.Selection.Range.Font.ForeColor = vbWindowText
   rtfHTML.Selection.Range.Font.Bold = rtfHTML.Font.Bold
   rtfHTML.Selection.Range.Font.Italic = rtfHTML.Font.Italic
   
   If TypeName(mProp_ProgressBar) = "ProgressBar" Then
      mProp_ProgressBar.Min = 0
      mProp_ProgressBar.Max = 100
      mProp_ProgressBar.Value = 0
      bytPrgBar = prgIsMicrosoft
   ElseIf TypeName(mProp_ProgressBar) = "htPrgBar" Then
      mProp_ProgressBar.Percent = 0
      bytPrgBar = prgIsHeTill
   End If

   On Error Resume Next
   For lngTextPos = lngStartPos To lngEndPos
      Select Case bytSelPos
      Case posText
         If Mid$(strText, lngTextPos, 4) = "<!--" Then
            bytSelPos = posComment
            lngTagStart = lngTextPos
         ElseIf Mid$(strText, lngTextPos, 1) = "<" Then
            bytSelPos = posTag
            lngTagStart = lngTextPos
            blnSpecialTag = (Mid$(strText, lngTextPos + 1, 1) = "!")
            blnStyleTag = (UCase$(Mid$(strText, lngTextPos + 1, 5)) = "STYLE")
            blnScriptTag = (UCase$(Mid$(strText, lngTextPos + 1, 6)) = "SCRIPT")
         End If
      Case posTag
         If Mid$(strText, lngTextPos, 1) = ">" Then
            bytSelPos = posText
            If Not lngTagStart = -1 Then
               rtfHTML.Selection.Range.StartPos = lngTagStart
               rtfHTML.Selection.Range.EndPos = lngTextPos '- lngTagStart - 1
               rtfHTML.Selection.Range.Font.Bold = mProp_TagBold
               rtfHTML.Selection.Range.Font.Italic = mProp_TagItalic
               rtfHTML.Selection.Range.Font.ForeColor = mProp_TagColor
            End If
            If blnStyleTag Or blnScriptTag Then
               bytSelPos = IIf(blnStyleTag, posStyleTag, posScriptTag)
            End If
         ElseIf Mid$(strText, lngTextPos, 1) = " " And Not blnSpecialTag Then
            bytSelPos = posPropName
            lngPropNameStart = lngTextPos
            If Not lngTagStart = -1 Then
               rtfHTML.Selection.Range.StartPos = lngTagStart
               rtfHTML.Selection.Range.EndPos = lngTextPos '- lngTagStart - 1
               rtfHTML.Selection.Range.Font.Bold = mProp_TagBold
               rtfHTML.Selection.Range.Font.Italic = mProp_TagItalic
               rtfHTML.Selection.Range.Font.ForeColor = mProp_TagColor
            End If
         End If
      Case posComment
         If Mid$(strText, lngTextPos, 3) = "-->" Then
            bytSelPos = posText
            rtfHTML.Selection.Range.StartPos = lngTagStart + 3
            rtfHTML.Selection.Range.EndPos = lngTextPos - 3 ' - lngTagStart - 4
            rtfHTML.Selection.Range.Font.Bold = mProp_CommentBold
            rtfHTML.Selection.Range.Font.Italic = mProp_CommentItalic
            rtfHTML.Selection.Range.Font.ForeColor = mProp_CommentColor
         End If
      Case posPropName
         If Mid$(strText, lngTextPos, 1) = "=" Then
            bytSelPos = posPropVal
            rtfHTML.Selection.Range.StartPos = lngPropNameStart
            rtfHTML.Selection.Range.EndPos = lngTextPos '- lngPropNameStart - 1
            rtfHTML.Selection.Range.Font.Bold = mProp_PropNameBold
            rtfHTML.Selection.Range.Font.Italic = mProp_PropNameItalic
            rtfHTML.Selection.Range.Font.ForeColor = mProp_PropNameColor
            lngPropValStart = lngTextPos
            blnPropWithQuotes = (Mid$(strText, lngTextPos + 1, 1) = """")
         ElseIf Mid$(strText, lngTextPos, 1) = " " Then
            bytSelPos = posTag
            rtfHTML.Selection.Range.StartPos = lngPropNameStart
            rtfHTML.Selection.Range.EndPos = lngTextPos '- lngPropNameStart - 1
            rtfHTML.Selection.Range.Font.Bold = mProp_PropValBold
            rtfHTML.Selection.Range.Font.Italic = mProp_PropValItalic
            rtfHTML.Selection.Range.Font.ForeColor = mProp_PropValColor
            lngTextPos = lngTextPos - 1
            lngTagStart = -1
         ElseIf Mid$(strText, lngTextPos, 1) = ">" Then
            bytSelPos = posText
            rtfHTML.Selection.Range.StartPos = lngPropNameStart
            rtfHTML.Selection.Range.EndPos = lngTextPos '- lngPropNameStart - 1
            rtfHTML.Selection.Range.Font.Bold = mProp_PropValBold
            rtfHTML.Selection.Range.Font.Italic = mProp_PropValItalic
            rtfHTML.Selection.Range.Font.ForeColor = mProp_PropValColor
            lngTagStart = -1
            If blnStyleTag Or blnScriptTag Then
               bytSelPos = IIf(blnStyleTag, posStyleTag, posScriptTag)
            End If
         End If
      Case posPropVal
         If Mid$(strText, lngTextPos + (-blnPropWithQuotes), 1) = " " Then
            If blnPropWithQuotes Eqv Mid$(strText, lngTextPos, 1) = """" Then
               bytSelPos = posTag
               rtfHTML.Selection.Range.StartPos = lngPropValStart - blnPropWithQuotes
               rtfHTML.Selection.Range.EndPos = lngTextPos + blnPropWithQuotes ' - lngPropValStart - 1 + blnPropWithQuotes
               rtfHTML.Selection.Range.Font.Bold = mProp_PropValBold
               rtfHTML.Selection.Range.Font.Italic = mProp_PropValItalic
               rtfHTML.Selection.Range.Font.ForeColor = mProp_PropValColor
               lngTagStart = -1
               lngTextPos = lngTextPos - 1
            End If
         ElseIf Mid$(strText, lngTextPos + (-blnPropWithQuotes), 1) = ">" Then
            bytSelPos = posText
            rtfHTML.Selection.Range.StartPos = lngPropValStart + (-blnPropWithQuotes)
            rtfHTML.Selection.Range.EndPos = lngTextPos + blnPropWithQuotes '- lngPropValStart - 1 + blnPropWithQuotes
            rtfHTML.Selection.Range.Font.Bold = mProp_PropValBold
            rtfHTML.Selection.Range.Font.Italic = mProp_PropValItalic
            rtfHTML.Selection.Range.Font.ForeColor = mProp_PropValColor
            If blnStyleTag Or blnScriptTag Then
               bytSelPos = IIf(blnStyleTag, posStyleTag, posScriptTag)
            End If
         End If
      Case posStyleTag, posScriptTag
         If UCase$(Mid$(strText, lngTextPos, IIf(bytSelPos = posStyleTag, 6, 7))) = IIf(bytSelPos = posStyleTag, "/STYLE", "/SCRIPT") Then
            bytSelPos = posTag
            lngTagStart = lngTextPos - 1
            blnScriptTag = False: blnStyleTag = False
         End If
      End Select
      If Mid$(strText, lngTextPos, 1) = "&" Then
         For lngEntityCounter = lngTextPos + 1 To lngTextPos + 8
            If Mid$(strText, lngEntityCounter, 1) = ";" Then
               rtfHTML.Selection.Range.StartPos = lngTextPos - 1
               rtfHTML.Selection.Range.EndPos = lngEntityCounter  '- lngTextPos + 1
               rtfHTML.Selection.Range.Font.Bold = mProp_EntityBold
               rtfHTML.Selection.Range.Font.Italic = mProp_EntityItalic
               rtfHTML.Selection.Range.Font.ForeColor = mProp_EntityColor
               Exit For
            End If
         Next lngEntityCounter
      End If
      
      If bytPrgBar <> prgIsNothing Then
         bytCurPrg = GetPercentVal(lngTextPos, lngEndPos)
         If bytCurPrg > bytOldPrg Then
            bytOldPrg = bytCurPrg
            
            Select Case bytPrgBar
            Case prgIsMicrosoft
               mProp_ProgressBar.Value = bytCurPrg
            Case prgIsHeTill
               mProp_ProgressBar.Percent = bytCurPrg
            End Select
         End If
      End If
   Next lngTextPos

   Err.Clear
   rtfHTML.Selection.Range.StartPos = lngOldSelStart
   rtfHTML.Selection.Range.EndPos = lngOldEndPos
   If Err.Number <> 0 Then rtfHTML.Selection.Range.StartPos = lngOldSelStart
   Err.Clear
   On Error GoTo ErrorHandler
   
   mblnNoEvents = False
   If mProp_Silent Then apiLockWindowUpdate 0
   mblnHasChanged = False
   Exit Sub
ErrorHandler:
    Err.Raise Err.Number, Err.Source, Err.Description
End Sub

Public Property Get NoEvents() As Boolean
    NoEvents = mblnNoEvents
End Property
