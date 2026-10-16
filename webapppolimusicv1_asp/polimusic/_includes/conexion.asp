<%
'==================================================================================
' PoliMusic - Capa de Acceso a Datos (DAL)
' Archivo: _includes/conexion.asp
' Descripcion: Gestiona la conexion ADODB hacia SQL Server y expone helpers
'              reutilizables para el resto de la aplicacion (query, scalar,
'              execute y saneamiento de entradas).
'
' NOTA sobre Option Explicit:
'   Option Explicit debe ser la PRIMERA instruccion del script compilado. Como este
'   archivo se incorpora via #include DESPUES de config.asp, declararlo aqui provoca
'   el error de compilacion VBScript '800a0400 Se esperaba una instruccion'.
'   Por eso NO se usa en los includes: todas las variables se declaran con Dim de
'   forma explicita en cada procedimiento.
'==================================================================================

' --- Cadena de conexion oficial de PoliMusic (SQL Server en contenedor) ---------
Const POLIMUSIC_CONN_STRING = "Provider=MSOLEDBSQL;Server=localhost,14333;Database=BDD_PoliMusic;User Id=usr_PoliMusic;Password=Politecnica1;Encrypt=true;TrustServerCertificate=true;"

' --- Constantes de dominio -----------------------------------------------------
Const USER_TYPE_STANDARD = 0
Const USER_TYPE_ADMIN    = 1

Const PLAYLIST_TYPE_PUBLIC  = 0
Const PLAYLIST_TYPE_PRIVATE = 1

Const SESSION_TIMEOUT_MINUTES = 30

'----------------------------------------------------------------------------------
' AbrirConexion
' Crea y devuelve un objeto Connection ya abierto. Si el proveedor MSOLEDBSQL
' no estuviera disponible en el servidor, se degrada automaticamente al
' proveedor SQLOLEDB (legado) para mantener compatibilidad.
'----------------------------------------------------------------------------------
Function AbrirConexion()
    Dim conn, connString
    connString = POLIMUSIC_CONN_STRING

    On Error Resume Next
    Set conn = Server.CreateObject("ADODB.Connection")
    If Err.Number <> 0 Then
        Err.Clear
        Set conn = Nothing
        Set AbrirConexion = Nothing
        Exit Function
    End If

    conn.ConnectionTimeout = 15
    conn.CommandTimeout = 30
    conn.Open connString

    If Err.Number <> 0 Then
        Dim primerError
        primerError = Err.Description
        Err.Clear

        ' Fallback: proveedor OLE DB legado (no soporta Encrypt/TrustServerCertificate)
        Set conn = Server.CreateObject("ADODB.Connection")
        conn.ConnectionTimeout = 15
        conn.CommandTimeout = 30
        conn.Open "Provider=SQLOLEDB;Server=localhost,14333;Database=BDD_PoliMusic;User Id=usr_PoliMusic;Password=Politecnica1;"
        If Err.Number <> 0 Then
            Err.Clear
            Set conn = Nothing
            Set AbrirConexion = Nothing
            Exit Function
        End If
    End If
    On Error GoTo 0

    Set AbrirConexion = conn
End Function

'----------------------------------------------------------------------------------
' CerrarConexion
' Cierra y libera una conexion abierta de forma segura.
'----------------------------------------------------------------------------------
Sub CerrarConexion(ByRef conn)
    On Error Resume Next
    If IsObject(conn) Then
        If Not conn Is Nothing Then
            If conn.State = 1 Then conn.Close
        End If
    End If
    Set conn = Nothing
    On Error GoTo 0
End Sub

'----------------------------------------------------------------------------------
' Esc
' Escapa comillas simples para prevenir inyeccion SQL. Todos los valores
' provenientes del usuario deben pasar por esta funcion.
'----------------------------------------------------------------------------------
Function Esc(ByVal valor)
    If IsNull(valor) Or IsEmpty(valor) Then
        Esc = ""
    Else
        Esc = Replace(CStr(valor), "'", "''")
    End If
End Function

'----------------------------------------------------------------------------------
' EscInt
' Fuerza la conversion a entero. Devuelve 0 cuando el valor no es numerico.
'----------------------------------------------------------------------------------
Function EscInt(ByVal valor)
    If IsNull(valor) Or IsEmpty(valor) Or Trim(CStr(valor)) = "" Then
        EscInt = 0
    ElseIf IsNumeric(valor) Then
        EscInt = CLng(valor)
    Else
        EscInt = 0
    End If
End Function

'----------------------------------------------------------------------------------
' EjecutarConsulta
' Devuelve un Recordset desconectado (client-side cursor) listo para recorrer.
' GARANTIA: o devuelve un Recordset ABIERTO y con datos listos para leer, o devuelve
' Nothing. Nunca devuelve un Recordset cerrado: llamar a .EOF sobre un Recordset
' cerrado lanzaria el error de tiempo de ejecucion 800a01b6
' ("El objeto no acepta esta propiedad o metodo: 'EOF'").
'----------------------------------------------------------------------------------
Function EjecutarConsulta(ByVal sql)
    Dim conn, rs
    Set conn = AbrirConexion()
    If conn Is Nothing Then
        Set EjecutarConsulta = Nothing
        Exit Function
    End If

    On Error Resume Next
    Set rs = Server.CreateObject("ADODB.Recordset")
    If Err.Number <> 0 Then
        Err.Clear
        CerrarConexion conn
        Set EjecutarConsulta = Nothing
        Exit Function
    End If

    rs.CursorLocation = 3   ' adUseClient
    rs.Open sql, conn, 1, 1 ' adOpenKeyset, adLockReadOnly

    If Err.Number <> 0 Then
        ' La consulta fallo: se descarta el Recordset y se devuelve Nothing
        Err.Clear
        On Error GoTo 0
        If IsObject(rs) Then
            On Error Resume Next
            rs.Close
            On Error GoTo 0
        End If
        Set rs = Nothing
        CerrarConexion conn
        Set EjecutarConsulta = Nothing
        Exit Function
    End If

    ' Cursor desconectado: se libera la referencia a la conexion
    Set rs.ActiveConnection = Nothing
    If Err.Number <> 0 Then Err.Clear

    ' Verificacion final: si por cualquier motivo el Recordset quedo cerrado, se
    ' descarta para no devolver un objeto invalido (evita el 800a01b6).
    ' adStateOpen = 1
    Dim estadoOk, estadoReal
    estadoOk = False
    estadoReal = 0
    On Error Resume Next
    estadoReal = rs.State
    If Err.Number = 0 And estadoReal <> 0 Then estadoOk = True
    Err.Clear
    On Error GoTo 0

    CerrarConexion conn

    If Not estadoOk Then
        If IsObject(rs) Then
            On Error Resume Next
            rs.Close
            On Error GoTo 0
        End If
        Set rs = Nothing
    End If

    Set EjecutarConsulta = rs
End Function

'----------------------------------------------------------------------------------
' EjecutarComando
' Ejecuta una sentencia INSERT/UPDATE/DELETE. Devuelve True si no hubo error.
'----------------------------------------------------------------------------------
Function EjecutarComando(ByVal sql)
    Dim conn
    Set conn = AbrirConexion()
    If conn Is Nothing Then
        EjecutarComando = False
        Exit Function
    End If

    On Error Resume Next
    conn.Execute sql
    EjecutarComando = (Err.Number = 0)
    If Err.Number <> 0 Then Err.Clear
    On Error GoTo 0

    CerrarConexion conn
End Function

'----------------------------------------------------------------------------------
' EjecutarEscalar
' Devuelve el primer campo de la primera fila de una consulta.
'----------------------------------------------------------------------------------
Function EjecutarEscalar(ByVal sql)
    Dim rs, valor
    valor = Null
    Set rs = EjecutarConsulta(sql)
    If RsValido(rs) Then
        If Not rs.EOF Then valor = rs.Fields(0).Value
        rs.Close
        Set rs = Nothing
    End If
    EjecutarEscalar = valor
End Function

'----------------------------------------------------------------------------------
' H
' Codifica texto para salida segura en HTML (anti XSS).
'----------------------------------------------------------------------------------
Function H(ByVal texto)
    If IsNull(texto) Or IsEmpty(texto) Then
        H = ""
    Else
        H = Server.HTMLEncode(CStr(texto))
    End If
End Function

'----------------------------------------------------------------------------------
' Js
' Escapa texto para ser embebido dentro de una cadena JavaScript.
'----------------------------------------------------------------------------------
Function Js(ByVal texto)
    Dim s
    If IsNull(texto) Or IsEmpty(texto) Then
        Js = ""
        Exit Function
    End If
    s = CStr(texto)
    s = Replace(s, "\", "\\")
    s = Replace(s, "'", "\'")
    s = Replace(s, """", "\""")
    s = Replace(s, Chr(13), "")
    s = Replace(s, Chr(10), " ")
    Js = s
End Function

'----------------------------------------------------------------------------------
' RsValido
' Indica si una variable contiene un Recordset UTILIZABLE (objeto, no Nothing y con
' estado abierto). Es la unica guarda segura antes de tocar .EOF / .Fields:
'   If RsValido(rs) Then Do While Not rs.EOF ... Loop
' Llamar a rs.EOF sobre un Recordset cerrado lanza 800a01b6, por eso NUNCA debe
' usarse 'If Not rs Is Nothing' como unica comprobacion.
'----------------------------------------------------------------------------------
Function RsValido(ByRef rs)
    Dim est
    RsValido = False
    On Error Resume Next
    If IsObject(rs) Then
        If Not rs Is Nothing Then
            est = rs.State
            If Err.Number = 0 And est <> 0 Then RsValido = True
        End If
    End If
    Err.Clear
    On Error GoTo 0
End Function

'----------------------------------------------------------------------------------
' ResolverRecurso
' Normaliza las rutas almacenadas en la base de datos (formato ~/carpeta/archivo)
' hacia rutas web relativas utilizables por el navegador.
'   ~/songFiles/x.mp3     -> resources/SongFiles/x.mp3
'   ~/userImages/x.png    -> resources/UserImages/x.png
'   ~/albumImages/x.png   -> resources/AlbumImages/x.png
'   ~/artistImages/x.jpg  -> resources/ArtistImages/x.jpg
'   ~/playlistImages/x    -> resources/PlaylistImages/x
'----------------------------------------------------------------------------------
Function ResolverRecurso(ByVal ruta, ByVal baseUrl)
    Dim r, archivo, pos, carpeta
    ResolverRecurso = ""
    If IsNull(ruta) Or IsEmpty(ruta) Then Exit Function

    r = Trim(CStr(ruta))
    If r = "" Then Exit Function

    ' Rutas absolutas web o externas se devuelven tal cual
    If Left(r, 7) = "http://" Or Left(r, 8) = "https://" Or Left(r, 2) = "//" Then
        ResolverRecurso = r
        Exit Function
    End If

    ' Detectar la carpeta destino segun el segmento presente en la ruta
    pos = InStr(LCase(r), "songfiles")
    If pos > 0 Then
        carpeta = "SongFiles"
    Else
        pos = InStr(LCase(r), "playlistimages")
        If pos > 0 Then
            carpeta = "PlaylistImages"
        Else
            pos = InStr(LCase(r), "artistimages")
            If pos > 0 Then
                carpeta = "ArtistImages"
            Else
                pos = InStr(LCase(r), "albumimages")
                If pos > 0 Then
                    carpeta = "AlbumImages"
                Else
                    pos = InStr(LCase(r), "userimages")
                    If pos > 0 Then
                        carpeta = "UserImages"
                    Else
                        carpeta = ""
                    End If
                End If
            End If
        End If
    End If

    If carpeta = "" Then
        ' Ruta no reconocida: se interpreta como relativa a resources
        r = Replace(r, "~/", "")
        r = Replace(r, "\", "/")
        ResolverRecurso = baseUrl & "resources/" & r
        Exit Function
    End If

    ' Extraer el nombre de archivo (todo lo que sigue a la carpeta detectada)
    archivo = Mid(r, pos + Len(carpeta))
    archivo = Replace(archivo, "\", "/")
    Do While Left(archivo, 1) = "/"
        archivo = Mid(archivo, 2)
    Loop

    If archivo = "" Then
        ResolverRecurso = baseUrl & "resources/" & carpeta & "/default.jpg"
    Else
        ResolverRecurso = baseUrl & "resources/" & carpeta & "/" & archivo
    End If
End Function

'----------------------------------------------------------------------------------
' ImagenSegura
' Devuelve la ruta de la imagen o un placeholder si la ruta esta vacia.
'----------------------------------------------------------------------------------
Function ImagenSegura(ByVal ruta, ByVal baseUrl, ByVal carpeta, ByVal placeholder)
    Dim res
    res = ResolverRecurso(ruta, baseUrl)
    If res = "" Then
        res = baseUrl & "resources/" & carpeta & "/" & placeholder
    End If
    ImagenSegura = res
End Function

'----------------------------------------------------------------------------------
' FechaCorta
' Formatea una fecha a dd/mm/yyyy para presentacion.
'----------------------------------------------------------------------------------
Function FechaCorta(ByVal f)
    If IsNull(f) Or IsEmpty(f) Then
        FechaCorta = "&mdash;"
    ElseIf IsDate(f) Then
        FechaCorta = Right("0" & Day(f), 2) & "/" & Right("0" & Month(f), 2) & "/" & Year(f)
    Else
        FechaCorta = "&mdash;"
    End If
End Function

'----------------------------------------------------------------------------------
' IIf
' Operador ternario para VBScript. Devuelve verdadero o falso segun la condicion.
'----------------------------------------------------------------------------------
Function IIf(ByVal condicion, ByVal siVerdadero, ByVal siFalso)
    If condicion Then
        IIf = siVerdadero
    Else
        IIf = siFalso
    End If
End Function

'----------------------------------------------------------------------------------
' Sha1Hex
' Calcula el hash SHA-1 en hexadecimal mayusculas (compatible con el formato
' almacenado en TBL_USER.PASSWORD para credenciales cifradas).
'
' NOTA: las variables se llaman oAsc / oHash / oTextoHex y NUNCA 'asc' / 'hex' /
' 'stream' genericos, porque 'Dim asc' ensombreceria la funcion Asc() y
' 'Dim hex' ensombreceria Hex(), provocando el error 800a000d al invocarlas.
'----------------------------------------------------------------------------------
Function Sha1Hex(ByVal texto)
    Dim oAsc, oEnc, bytes, oTextoHex, oHash, oByteHex, i, b
    Sha1Hex = ""
    If IsNull(texto) Or texto = "" Then Exit Function

    Set oAsc = Server.CreateObject("System.Text.ASCIIEncoding")
    bytes = oAsc.GetBytes_4(CStr(texto))

    Set oEnc = Server.CreateObject("System.Security.Cryptography.SHA1CryptoServiceProvider")
    oHash = oEnc.ComputeHash_2(bytes)

    oTextoHex = ""
    For i = 0 To UBound(oHash)
        b = Hex(AscB(MidB(oHash, i + 1, 1)))
        If Len(b) = 1 Then b = "0" & b
        oTextoHex = oTextoHex & b
    Next
    Sha1Hex = UCase(oTextoHex)
End Function

'----------------------------------------------------------------------------------
' RegistrarBitacoraAcceso
' Deja constancia del intento de acceso en la bitacora de la aplicacion.
' No interrumpe el flujo si falla.
'----------------------------------------------------------------------------------
Sub RegistrarBitacoraAcceso(ByVal evento, ByVal usuario, ByVal ip, ByVal resultado)
    On Error Resume Next
    Dim fso, f, carpeta, ruta, linea
    Set fso = Server.CreateObject("Scripting.FileSystemObject")

    carpeta = Server.MapPath("_logs")
    If Not fso.FolderExists(carpeta) Then fso.CreateFolder(carpeta)

    ruta = carpeta & "\accesos_" & Year(Date()) & "-" & Right("0" & Month(Date()), 2) & ".log"
    linea = FormatDateTime(Now(), 2) & " | " & evento & " | " & usuario & " | " & ip & " | " & resultado & vbCrLf

    If fso.FileExists(ruta) Then
        Set f = fso.OpenTextFile(ruta, 8, True)
    Else
        Set f = fso.OpenTextFile(ruta, 2, True)
    End If
    f.Write linea
    f.Close
    Set f = Nothing
    Set fso = Nothing
    Err.Clear
    On Error GoTo 0
End Sub

'----------------------------------------------------------------------------------
' Iniciales
' Genera iniciales a partir de un nombre para avatares genericos.
'----------------------------------------------------------------------------------
Function Iniciales(ByVal nombre)
    Dim partes, i, res, p
    res = ""
    If IsNull(nombre) Or IsEmpty(nombre) Then
        Iniciales = "?"
        Exit Function
    End If
    partes = Split(Trim(CStr(nombre)), " ")
    For i = 0 To UBound(partes)
        p = Trim(partes(i))
        If p <> "" And Len(res) < 2 Then res = res & UCase(Left(p, 1))
    Next
    If res = "" Then res = "?"
    Iniciales = res
End Function
%>
