' RSA/MD5 implementation
'
' Version 1.0.1
' Date: 14th April, 2003
' Author: Chris Read
' Home page: http://users.bigpond.net.au/mrjolly/
'
' Most ASP MD5 implementations look relatively the same, the exception with this one is that
' it is a class. Other than that, it's massaged from the RFC1321 C code and simplified a little.
'
' There are two properties
'	Text - String, text to encode
'	HEXMD5 - String, read-only, MD5 value of Text above
' There are no methods
'
' Private to this class
Private Const S11	=	&H007
Private Const S12	=	&H00C
Private Const S13	=	&H011
Private Const S14	=	&H016
Private Const S21	=	&H005
Private Const S22	=	&H009
Private Const S23	=	&H00E
Private Const S24	=	&H014
Private Const S31	=	&H004
Private Const S32	=	&H00B
Private Const S33	=	&H010
Private Const S34	=	&H017
Private Const S41	=	&H006
Private Const S42	=	&H00A
Private Const S43	=	&H00F
Private Const S44	=	&H015

Class MD5
	' Public methods and properties
	
	' Text property
	Public Text

	' Text value in Hex, read-only
	Public Property Get HEXMD5()
		Dim lArray
		Dim lIndex
		Dim AA
		Dim BB
		Dim CC
		Dim DD
		Dim lStatus0
		Dim lStatus1
		Dim lStatus2
		Dim lStatus3

		lArray = ConvertToWordArray(Text)

		lStatus0 = &H67452301
		lStatus1 = &HEFCDAB89
		lStatus2 = &H98BADCFE
		lStatus3 = &H10325476

		For lIndex = 0 To UBound(lArray) Step 16
			AA = lStatus0
			BB = lStatus1
			CC = lStatus2
			DD = lStatus3

			FF lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 0),	S11,&HD76AA478
			FF lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 1),	S12,&HE8C7B756
			FF lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 2),	S13,&H242070DB
			FF lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 3),	S14,&HC1BDCEEE
			FF lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 4),	S11,&HF57C0FAF
			FF lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 5),	S12,&H4787C62A
			FF lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 6),	S13,&HA8304613
			FF lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 7),	S14,&HFD469501
			FF lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 8),	S11,&H698098D8
			FF lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 9),	S12,&H8B44F7AF
			FF lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 10),	S13,&HFFFF5BB1
			FF lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 11),	S14,&H895CD7BE
			FF lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 12),	S11,&H6B901122
			FF lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 13),	S12,&HFD987193
			FF lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 14),	S13,&HA679438E
			FF lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 15),	S14,&H49B40821

			GG lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 1),	S21,&HF61E2562
			GG lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 6),	S22,&HC040B340
			GG lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 11),	S23,&H265E5A51
			GG lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 0),	S24,&HE9B6C7AA
			GG lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 5),	S21,&HD62F105D
			GG lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 10),	S22,&H2441453
			GG lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 15),	S23,&HD8A1E681
			GG lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 4),	S24,&HE7D3FBC8
			GG lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 9),	S21,&H21E1CDE6
			GG lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 14),	S22,&HC33707D6
			GG lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 3),	S23,&HF4D50D87
			GG lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 8),	S24,&H455A14ED
			GG lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 13),	S21,&HA9E3E905
			GG lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 2),	S22,&HFCEFA3F8
			GG lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 7),	S23,&H676F02D9
			GG lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 12),	S24,&H8D2A4C8A
			        
			HH lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 5),	S31,&HFFFA3942
			HH lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 8),	S32,&H8771F681
			HH lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 11),	S33,&H6D9D6122
			HH lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 14),	S34,&HFDE5380C
			HH lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 1),	S31,&HA4BEEA44
			HH lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 4),	S32,&H4BDECFA9
			HH lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 7),	S33,&HF6BB4B60
			HH lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 10),	S34,&HBEBFBC70
			HH lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 13),	S31,&H289B7EC6
			HH lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 0),	S32,&HEAA127FA
			HH lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 3),	S33,&HD4EF3085
			HH lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 6),	S34,&H4881D05
			HH lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 9),	S31,&HD9D4D039
			HH lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 12),	S32,&HE6DB99E5
			HH lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 15),	S33,&H1FA27CF8
			HH lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 2),	S34,&HC4AC5665

			II lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 0),	S41,&HF4292244
			II lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 7),	S42,&H432AFF97
			II lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 14),	S43,&HAB9423A7
			II lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 5),	S44,&HFC93A039
			II lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 12),	S41,&H655B59C3
			II lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 3),	S42,&H8F0CCC92
			II lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 10),	S43,&HFFEFF47D
			II lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 1),	S44,&H85845DD1
			II lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 8),	S41,&H6FA87E4F
			II lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 15),	S42,&HFE2CE6E0
			II lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 6),	S43,&HA3014314
			II lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 13),	S44,&H4E0811A1
			II lStatus0,lStatus1,lStatus2,lStatus3,lArray(lIndex + 4),	S41,&HF7537E82
			II lStatus3,lStatus0,lStatus1,lStatus2,lArray(lIndex + 11),	S42,&HBD3AF235
			II lStatus2,lStatus3,lStatus0,lStatus1,lArray(lIndex + 2),	S43,&H2AD7D2BB
			II lStatus1,lStatus2,lStatus3,lStatus0,lArray(lIndex + 9),	S44,&HEB86D391

			lStatus0 = Add32(lStatus0,AA)
			lStatus1 = Add32(lStatus1,BB)
			lStatus2 = Add32(lStatus2,CC)
			lStatus3 = Add32(lStatus3,DD)
		Next
		  
		HEXMD5 = LCase(WordToHex(lStatus0) & WordToHex(lStatus1) & WordToHex(lStatus2) & WordToHex(lStatus3))
	End Property

	' Private methods and properties
	Private m_lMask()
	Private m_lPow()

	Private Function F(lX, lY, lZ)
		F = (lX And lY) Or ((Not lX) And lZ)
	End Function

	Private Function G(lX, lY, lZ)
		G = (lX And lZ) Or (lY And (Not lZ))
	End Function

	Private Function H(lX, lY, lZ)
		H = lX Xor lY Xor lZ
	End Function

	Private Function I(lX, lY, lZ)
		I = lY Xor (lX Or (Not lZ))
	End Function

	Private Sub FF(lA, lB, lC, lD, lX, lS, lAC)
		lA = Add32(lA,Add32(Add32(F(lB,lC,lD),lX),lAC))
		lA = RotateLeft32(lA,lS)
		lA = Add32(lA,lB)
	End Sub

	Private Sub GG(lA, lB, lC, lD, lX, lS, lAC)
		lA = Add32(lA,Add32(Add32(G(lB,lC,lD),lX),lAC))
		lA = RotateLeft32(lA,lS)
		lA = Add32(lA,lB)
	End Sub

	Private Sub HH(lA, lB, lC, lD, lX, lS, lAC)
		lA = Add32(lA,Add32(Add32(H(lB,lC,lD),lX),lAC))
		lA = RotateLeft32(lA,lS)
		lA = Add32(lA,lB)
	End Sub

	Private Sub II(lA, lB, lC, lD, lX, lS, lAC)
		lA = Add32(lA,Add32(Add32(I(lB,lC,lD),lX),lAC))
		lA = RotateLeft32(lA,lS)
		lA = Add32(lA,lB)
	End Sub

	Private Function ConvertToWordArray(sText)
		Dim lTextLength
		Dim lNumberOfWords
		Dim lWordArray()
		Dim lBytePosition
		Dim lByteCount
		Dim lWordCount
		  
		lTextLength = Len(sText)
		  
		lNumberOfWords = (((lTextLength + 8) \ 64) + 1) * 16

		ReDim lWordArray(lNumberOfWords - 1)
		  
		lBytePosition = 0
		lByteCount = 0
		
		Do Until lByteCount >= lTextLength
			lWordCount = lByteCount \ 4
			lBytePosition = (lByteCount Mod 4) * 8
			lWordArray(lWordCount) = lWordArray(lWordCount) Or ShiftLeft(Asc(Mid(sText,lByteCount + 1,1)),lBytePosition)
			lByteCount = lByteCount + 1
		Loop

		lWordCount = lByteCount \ 4
		lBytePosition = (lByteCount Mod 4) * 8

		lWordArray(lWordCount) = lWordArray(lWordCount) Or ShiftLeft(&H80,lBytePosition)

		lWordArray(lNumberOfWords - 2) = ShiftLeft(lTextLength,3)
		lWordArray(lNumberOfWords - 1) = ShiftRight(lTextLength,29)
		  
		ConvertToWordArray = lWordArray
	End Function

	Private Function WordToHex(lValue)
		Dim lTemp

		For lTemp = 0 To 3
			WordToHex = WordToHex & Right("00" & Hex(ShiftRight(lValue,lTemp * 8) And m_lMask(7)),2)
		Next
	End Function

	' Unsigned value arithmetic functions for rotating, shifting and adding
	Private Function ShiftLeft(lValue,iBits)
		' Guilty until proven innocent
		ShiftLeft = 0

		If iBits = 0 then
			ShiftLeft = lValue ' No shifting to do
		ElseIf iBits = 31 Then ' Quickly shift left if there is a value, being aware of the sign
			If lValue And 1 Then
				ShiftLeft = &H80000000
			End If
		Else ' Shift left x bits, being careful with the sign
			If (lValue And m_lPow(31 - iBits)) Then
				ShiftLeft = ((lValue And m_lMask(31 - (iBits + 1))) * m_lPow(iBits)) Or &H80000000
			Else
				ShiftLeft = ((lValue And m_lMask(31 - iBits)) * m_lPow(iBits))
			End If
		End If
	End Function

	Private Function ShiftRight(lValue,iBits)
		' Guilty until proven innocent
		ShiftRight = 0
		
		If iBits = 0 then
			ShiftRight = lValue ' No shifting to do
		ElseIf iBits = 31 Then ' Quickly shift to the right if there is a value in the sign
			If lValue And &H80000000 Then
				ShiftRight = 1
			End If
		Else
			ShiftRight = (lValue And &H7FFFFFFE) \ m_lPow(iBits)

			If (lValue And &H80000000) Then
				ShiftRight = (ShiftRight Or (&H40000000 \ m_lPow(iBits - 1)))
			End If
		End If
	End Function

	Private Function RotateLeft32(lValue,iBits)
		RotateLeft32 = ShiftLeft(lValue,iBits) Or ShiftRight(lValue,(32 - iBits))
	End Function

	Private Function Add32(lA,lB)
		Dim lA4
		Dim lB4
		Dim lA8
		Dim lB8
		Dim lA32
		Dim lB32
		Dim lA31
		Dim lB31
		Dim lTemp

		lA32 = lA And &H80000000
		lB32 = lB And &H80000000
		lA31 = lA And &H40000000
		lB31 = lB And &H40000000

		lTemp = (lA And &H3FFFFFFF) + (lB And &H3FFFFFFF)

		If lA31 And lB31 Then
			lTemp = lTemp Xor &H80000000 Xor lA32 Xor lB32
		ElseIf lA31 Or lB31 Then
			If lTemp And &H40000000 Then
				lTemp = lTemp Xor &HC0000000 Xor lA32 Xor lB32
			Else
				lTemp = lTemp Xor &H40000000 Xor lA32 Xor lB32
			End If
		Else
			lTemp = lTemp Xor lA32 Xor lB32
		End If

		Add32 = lTemp
	End Function

	' Class initialization
	Private Sub Class_Initialize()
		Text = ""
		
		Redim m_lMask(30)
		Redim m_lPow(30)
		
		' Make arrays of these values to save some time during the calculation
		m_lMask(0)	=	CLng(&H00000001&)
		m_lMask(1)	=	CLng(&H00000003&)
		m_lMask(2)	=	CLng(&H00000007&)
		m_lMask(3)	=	CLng(&H0000000F&)
		m_lMask(4)	=	CLng(&H0000001F&)
		m_lMask(5)	=	CLng(&H0000003F&)
		m_lMask(6)	=	CLng(&H0000007F&)
		m_lMask(7)	=	CLng(&H000000FF&)
		m_lMask(8)	=	CLng(&H000001FF&)
		m_lMask(9)	=	CLng(&H000003FF&)
		m_lMask(10)	=	CLng(&H000007FF&)
		m_lMask(11)	=	CLng(&H00000FFF&)
		m_lMask(12)	=	CLng(&H00001FFF&)
		m_lMask(13)	=	CLng(&H00003FFF&)
		m_lMask(14)	=	CLng(&H00007FFF&)
		m_lMask(15)	=	CLng(&H0000FFFF&)
		m_lMask(16)	=	CLng(&H0001FFFF&)
		m_lMask(17)	=	CLng(&H0003FFFF&)
		m_lMask(18)	=	CLng(&H0007FFFF&)
		m_lMask(19)	=	CLng(&H000FFFFF&)
		m_lMask(20)	=	CLng(&H001FFFFF&)
		m_lMask(21)	=	CLng(&H003FFFFF&)
		m_lMask(22)	=	CLng(&H007FFFFF&)
		m_lMask(23)	=	CLng(&H00FFFFFF&)
		m_lMask(24)	=	CLng(&H01FFFFFF&)
		m_lMask(25)	=	CLng(&H03FFFFFF&)
		m_lMask(26)	=	CLng(&H07FFFFFF&)
		m_lMask(27)	=	CLng(&H0FFFFFFF&)
		m_lMask(28)	=	CLng(&H1FFFFFFF&)
		m_lMask(29)	=	CLng(&H3FFFFFFF&)
		m_lMask(30)	=	CLng(&H7FFFFFFF&)

		' Power operations always take time to calculate
		m_lPow(0)	=	CLng(&H00000001&)
		m_lPow(1)	=	CLng(&H00000002&)
		m_lPow(2)	=	CLng(&H00000004&)
		m_lPow(3)	=	CLng(&H00000008&)
		m_lPow(4)	=	CLng(&H00000010&)
		m_lPow(5)	=	CLng(&H00000020&)
		m_lPow(6)	=	CLng(&H00000040&)
		m_lPow(7)	=	CLng(&H00000080&)
		m_lPow(8)	=	CLng(&H00000100&)
		m_lPow(9)	=	CLng(&H00000200&)
		m_lPow(10)	=	CLng(&H00000400&)
		m_lPow(11)	=	CLng(&H00000800&)
		m_lPow(12)	=	CLng(&H00001000&)
		m_lPow(13)	=	CLng(&H00002000&)
		m_lPow(14)	=	CLng(&H00004000&)
		m_lPow(15)	=	CLng(&H00008000&)
		m_lPow(16)	=	CLng(&H00010000&)
		m_lPow(17)	=	CLng(&H00020000&)
		m_lPow(18)	=	CLng(&H00040000&)
		m_lPow(19)	=	CLng(&H00080000&)
		m_lPow(20)	=	CLng(&H00100000&)
		m_lPow(21)	=	CLng(&H00200000&)
		m_lPow(22)	=	CLng(&H00400000&)
		m_lPow(23)	=	CLng(&H00800000&)
		m_lPow(24)	=	CLng(&H01000000&)
		m_lPow(25)	=	CLng(&H02000000&)
		m_lPow(26)	=	CLng(&H04000000&)
		m_lPow(27)	=	CLng(&H08000000&)
		m_lPow(28)	=	CLng(&H10000000&)
		m_lPow(29)	=	CLng(&H20000000&)
		m_lPow(30)	=	CLng(&H40000000&)
	End Sub
End Class

Set Hash = New MD5
Hash.Text = WScript.Arguments(0)
WScript.Echo Hash.HEXMD5