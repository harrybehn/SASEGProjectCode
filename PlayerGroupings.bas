Attribute VB_Name = "Module1"
Dim rawList As Worksheet
Dim ws1 As Worksheet
Dim dict As Object
Dim lastRow As Long
Dim playerID As Variant
Dim tier As String
Dim newWB As Workbook
Dim newrawList As Worksheet
Dim key As Variant
Dim rowNum As Long
Dim sheetName As String
Dim nameFile As String
Dim fileName As String

Sub PlayerGroupings()

'set error handler
On Error GoTo ErrorHandler

Set ws1 = ThisWorkbook.Sheets("sheet1")

'set sheet name of rawList
nameFile = ws1.Cells(5, 2)

'set file name
sheetName = ws1.Cells(2, 2)

'set objects
Set rawList = ThisWorkbook.Sheets(sheetName)

Set dict = CreateObject("Scripting.Dictionary")

'find last row of playerid column
lastRow = rawList.Cells(rawList.Rows.Count, "A").End(xlUp).Row

'populate dictionary
For i = 2 To lastRow

    playerID = rawList.Cells(i, 1) '--> PlayerID
    foodCredits = rawList.Cells(i, 3)    '--> Food Credits

    If Not dict.exists(foodCredits) Then
    dict.Add foodCredits, New Collection
    End If
    
    dict(foodCredits).Add playerID
Next i

'create csv files
For Each key In dict.keys
    Set newWB = Workbooks.Add
    Set newrawList = newWB.Sheets(1)
    
    'create column header
    newrawList.Cells(1, 1) = "PlayerID"
    
    'populate PlayerID column with playerID values from dict
    rowNum = 2
    For Each playerID In dict(key)
        newrawList.Cells(rowNum, 1) = playerID
        rowNum = rowNum + 1
    Next playerID
    
    'save file
    fileName = "Food Credits - " & key & ".csv"
    Application.DisplayAlerts = False
    newWB.SaveAs ThisWorkbook.Path & "\" & fileName, xlCSV
    newWB.Close
    Application.DisplayAlerts = False
    
Next key
MsgBox "Created Groupings Successfully"

Exit Sub

ErrorHandler:
    Select Case Err.Number
        Case 9 ' Subscript out of range
            MsgBox "Sheet not found. Please check the sheet name."
        Case Else
            MsgBox "An unexpected error occurred: " & Err.Description
    End Select

End Sub

