<%
'==================================================================================
' PoliMusic - Cierre de Sesion
' Archivo: logout.asp
' Descripcion: Destruye el estado de la sesion autenticada y redirige al login.
'==================================================================================
%>
<!--#include virtual="/polimusic/_includes/config.asp"-->
<!--#include virtual="/polimusic/_includes/conexion.asp"-->
<!--#include virtual="/polimusic/_includes/sesion.asp"-->
<%
EnviarCabecerasNoCache

If HaySesion() Then
    RegistrarBitacoraAcceso "LOGOUT", CStr(Session("USERNAME")), Request.ServerVariables("REMOTE_ADDR"), "OK"
End If

CerrarSesionUsuario

Response.Redirect "login.asp?logout=1"
Response.End
%>
