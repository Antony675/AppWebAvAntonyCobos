<%
'==================================================================================
' PoliMusic - Configuracion Global
' Archivo: _includes/config.asp
' Descripcion: Define la URL base de la aplicacion y utilidades de cabecera
'              comunes. Debe incluirse como PRIMER archivo en cada pagina.
'==================================================================================

' URL base relativa calculada a partir de la ubicacion del script actual.
' Permite que la aplicacion funcione tanto en la raiz del sitio como en un
' directorio virtual o subcarpeta (por ejemplo /polimusic/).
Dim URL_BASE
URL_BASE = CalcularUrlBase()

Function CalcularUrlBase()
    Dim p, i, segs, res
    p = Replace(Request.ServerVariables("URL"), "\", "/")
    If InStr(p, ".asp") > 0 Then
        p = Left(p, InStrRev(p, "/"))
    ElseIf Right(p, 1) <> "/" Then
        p = p & "/"
    End If

    ' Eliminar el segmento /admin/ para que todas las paginas compartan la misma base
    If LCase(Right(p, 7)) = "/admin/" Then
        p = Left(p, Len(p) - 6)
    End If

    CalcularUrlBase = p
End Function

'----------------------------------------------------------------------------------
' EnviarCabecerasNoCache
' Evita el almacenamiento en cache de paginas protegidas.
'----------------------------------------------------------------------------------
Sub EnviarCabecerasNoCache()
    Response.AddHeader "Cache-Control", "no-store, no-cache, must-revalidate, private"
    Response.AddHeader "Pragma", "no-cache"
    Response.Expires = -1
End Sub

'----------------------------------------------------------------------------------
' AvanzarContadorReproducciones
' Incrementa el contador de reproducciones de una cancion.
'----------------------------------------------------------------------------------
Sub RegistrarReproduccion(ByVal idSong)
    Dim n
    n = EscInt(idSong)
    If n > 0 Then
        EjecutarComando "UPDATE TBL_SONG SET PLAYS = ISNULL(PLAYS,0) + 1 WHERE ID_SONG = " & n
    End If
End Sub
%>
