<%
'==================================================================================
' PoliMusic - Control de Sesion y Roles
' Archivo: _includes/sesion.asp
' Descripcion: Valida el estado de la sesion, expone los datos del usuario
'              autenticado y aplica las reglas de control de acceso por rol.
'              Debe incluirse DESPUES de conexion.asp.
'==================================================================================

'----------------------------------------------------------------------------------
' HaySesion
' Indica si existe un usuario autenticado en la sesion actual.
'----------------------------------------------------------------------------------
Function HaySesion()
    HaySesion = (Session("ID_USER") <> "" And Not IsEmpty(Session("ID_USER")))
    If HaySesion Then
        If EscInt(Session("ID_USER")) <= 0 Then HaySesion = False
    End If
End Function

'----------------------------------------------------------------------------------
' EsAdmin
' Devuelve True cuando el usuario en sesion tiene rol Administrador.
'----------------------------------------------------------------------------------
Function EsAdmin()
    EsAdmin = (HaySesion() And EscInt(Session("USER_TYPE")) = USER_TYPE_ADMIN)
End Function

'----------------------------------------------------------------------------------
' EsEstandar
' Devuelve True cuando el usuario en sesion tiene rol Estandar.
'----------------------------------------------------------------------------------
Function EsEstandar()
    EsEstandar = (HaySesion() And EscInt(Session("USER_TYPE")) = USER_TYPE_STANDARD)
End Function

'----------------------------------------------------------------------------------
' RequerirSesion
' Bloquea la ejecucion y redirige al login cuando no hay sesion activa.
'----------------------------------------------------------------------------------
Sub RequerirSesion()
    If Not HaySesion() Then
        Response.Redirect "login.asp?msg=" & Server.URLEncode("Debe iniciar sesion para continuar.")
    End If
End Sub

'----------------------------------------------------------------------------------
' RequerirAdmin
' Bloquea la ejecucion y redirige al dashboard cuando el rol no es Admin.
'----------------------------------------------------------------------------------
Sub RequerirAdmin()
    RequerirSesion()
    If Not EsAdmin() Then
        Response.Redirect "dashboard.asp?msg=" & Server.URLEncode("Acceso denegado: se requieren privilegios de administrador.")
    End If
End Sub

'----------------------------------------------------------------------------------
' NombreRol
' Etiqueta legible del rol del usuario en sesion.
'----------------------------------------------------------------------------------
Function NombreRol()
    If EsAdmin() Then
        NombreRol = "Administrador"
    Else
        NombreRol = "Estandar"
    End If
End Function

'----------------------------------------------------------------------------------
' IniciarSesionUsuario
' Registra en sesion los datos del usuario autenticado y regenera el token.
'----------------------------------------------------------------------------------
Sub IniciarSesionUsuario(ByVal idUser, ByVal username, ByVal rolCodigo, ByVal foto, ByVal email)
    Session("ID_USER") = EscInt(idUser)
    Session("USERNAME") = CStr(username)
    Session("USER_TYPE") = EscInt(rolCodigo)
    Session("USER_PHOTO") = CStr(foto)
    Session("USER_EMAIL") = CStr(email)
    Session("LOGIN_TIME") = Now()
    Session.Timeout = SESSION_TIMEOUT_MINUTES
    ' Token anti-fijacion de sesion: se regenera en cada autenticacion
    Session("CSRF_TOKEN") = GenerarToken()
End Sub

'----------------------------------------------------------------------------------
' CerrarSesionUsuario
' Destruye por completo el estado de la sesion autenticada.
'----------------------------------------------------------------------------------
Sub CerrarSesionUsuario()
    Session.Contents.RemoveAll()
    Session.Abandon()
End Sub

'----------------------------------------------------------------------------------
' GenerarToken
' Genera un token pseudoaleatorio para validacion de formularios (CSRF).
'
' NOTA IMPORTANTE: la variable del indice aleatorio NO puede llamarse 'rnd'.
' En VBScript, 'Dim rnd' ensombrece la funcion incorporada Rnd() del propio
' modulo, y la linea 'Int(Rnd() * ...)' pasa a leer la variable vacia en lugar
' de invocar la funcion -> error de tiempo de ejecucion 800a000d
' "No coinciden los tipos: 'rnd'". Por eso se usa 'indice'.
'----------------------------------------------------------------------------------
Function GenerarToken()
    Dim semilla, i, buf, indice
    Randomize
    buf = ""
    semilla = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    For i = 1 To 32
        indice = Int(Rnd() * Len(semilla)) + 1
        buf = buf & Mid(semilla, indice, 1)
    Next
    GenerarToken = buf & CStr(CLng(Timer * 1000))
End Function

'----------------------------------------------------------------------------------
' ValidarToken
' Comprueba que el token enviado coincida con el de la sesion.
'----------------------------------------------------------------------------------
Function ValidarToken(ByVal tokenRecibido)
    Dim t
    t = CStr(Session("CSRF_TOKEN"))
    If t = "" Then
        ValidarToken = False
    Else
        ValidarToken = (t = CStr(tokenRecibido))
    End If
End Function

'----------------------------------------------------------------------------------
' RefrescarToken
' Reemite el token de sesion (se usa tras operaciones exitosas).
'----------------------------------------------------------------------------------
Sub RefrescarToken()
    Session("CSRF_TOKEN") = GenerarToken()
End Sub

'----------------------------------------------------------------------------------
' TokenActual
' Devuelve el token vigente de la sesion.
'----------------------------------------------------------------------------------
Function TokenActual()
    TokenActual = CStr(Session("CSRF_TOKEN"))
End Function
%>
