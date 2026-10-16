<%
'==================================================================================
' PoliMusic - Procesador de Operaciones de Administracion (RUD)
' Archivo: admin/procesar.asp
' Descripcion: Punto unico de entrada para las operaciones de Lectura, Actualizacion
'              y Eliminacion sobre las entidades del sistema. Solo accesible para
'              el rol Administrador. Cada operacion valida el token de sesion y
'              redirige de vuelta al panel con un mensaje de resultado.
'              Nota: el alta (Create) de entidades esta fuera del alcance
'              solicitado; el sistema expone RUD.
'==================================================================================
%>
<!--#include virtual="/polimusic/_includes/config.asp"-->
<!--#include virtual="/polimusic/_includes/conexion.asp"-->
<!--#include virtual="/polimusic/_includes/sesion.asp"-->
<!--#include virtual="/polimusic/_includes/consultas.asp"-->
<%
EnviarCabecerasNoCache
RequerirAdmin

Dim accion, entidad, idReg, ok, mensaje, tabDestino, sql

accion  = LCase(Trim(CStr(Request.Form("accion"))))
entidad = LCase(Trim(CStr(Request.Form("entidad"))))
idReg   = EscInt(Request.Form("id"))
tabDestino = Trim(CStr(Request.Form("tab")))
ok = False
mensaje = ""

If tabDestino = "" Then tabDestino = entidad

'----------------------------------------------------------------------------------
' Verificacion del token de sesion (proteccion contra peticiones cruzadas)
'----------------------------------------------------------------------------------
If Not ValidarToken(Request.Form("token")) Then
    Response.Redirect "panel.asp?msg=" & Server.URLEncode("Token de seguridad invalido. Vuelva a intentarlo.") & "&tipo=error#" & tabDestino
    Response.End
End If

'----------------------------------------------------------------------------------
' Despacho de la operacion segun la accion y la entidad
'----------------------------------------------------------------------------------
Select Case accion & ":" & entidad

    ' ================= USUARIOS =================
    Case "actualizar:tbl_user"
        Dim uUsername, uEmail, uBirthday, uRol, uClave
        uUsername = Left(Trim(CStr(Request.Form("username"))), 50)
        uEmail    = Left(Trim(CStr(Request.Form("email"))), 50)
        uBirthday = Trim(CStr(Request.Form("birthday")))
        uRol      = EscInt(Request.Form("user_type"))
        uClave    = Trim(CStr(Request.Form("password")))

        If uUsername = "" Or uEmail = "" Then
            mensaje = "El nombre de usuario y el correo son obligatorios."
        ElseIf uRol <> USER_TYPE_STANDARD And uRol <> USER_TYPE_ADMIN Then
            mensaje = "El rol seleccionado no es valido."
        Else
            Dim sFecha
            If uBirthday = "" Then
                sFecha = "NULL"
            ElseIf IsDate(uBirthday) Then
                sFecha = "'" & Year(CDate(uBirthday)) & "-" & Right("0" & Month(CDate(uBirthday)), 2) & "-" & Right("0" & Day(CDate(uBirthday)), 2) & "'"
            Else
                sFecha = "NULL"
            End If

            sql = "UPDATE TBL_USER SET USERNAME = '" & Esc(uUsername) & "', " & _
                  "EMAIL = '" & Esc(uEmail) & "', BIRTHDAY = " & sFecha & ", " & _
                  "USER_TYPE = " & uRol
            If uClave <> "" Then
                sql = sql & ", PASSWORD = '" & Esc(uClave) & "'"
            End If
            sql = sql & " WHERE ID_USER = " & idReg

            ok = EjecutarComando(sql)
            If ok Then mensaje = "Usuario actualizado correctamente." Else mensaje = "No fue posible actualizar el usuario."
        End If

    Case "eliminar:tbl_user"
        ' Proteccion: un administrador no puede eliminar su propia cuenta en sesion
        If idReg = EscInt(Session("ID_USER")) Then
            mensaje = "Operacion bloqueada: no puede eliminar la cuenta con la que esta conectado."
        ElseIf EscInt(EjecutarEscalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = " & idReg)) > 0 Then
            mensaje = "El usuario tiene playlists asociadas. Elimine primero sus playlists."
        Else
            ok = EjecutarComando("DELETE FROM TBL_USER WHERE ID_USER = " & idReg)
            If ok Then mensaje = "Usuario eliminado correctamente." Else mensaje = "No fue posible eliminar el usuario."
        End If

    ' ================= CANCIONES =================
    Case "actualizar:tbl_song"
        Dim sNombre, sRuta, sPlays
        sNombre = Left(Trim(CStr(Request.Form("song_name"))), 50)
        sRuta   = Left(Trim(CStr(Request.Form("song_path"))), 255)
        sPlays  = EscInt(Request.Form("plays"))

        If sNombre = "" Or sRuta = "" Then
            mensaje = "El nombre y la ruta del archivo son obligatorios."
        Else
            ok = EjecutarComando( _
                "UPDATE TBL_SONG SET SONG_NAME = '" & Esc(sNombre) & "', " & _
                "SONG_PATH = '" & Esc(sRuta) & "', PLAYS = " & sPlays & _
                " WHERE ID_SONG = " & idReg)
            If ok Then mensaje = "Cancion actualizada correctamente." Else mensaje = "No fue posible actualizar la cancion."
        End If

    Case "eliminar:tbl_song"
        ok = EjecutarComando( _
            "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = " & idReg & ";" & _
            "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = " & idReg & ";" & _
            "DELETE FROM TBL_PLAYER WHERE ID_SONG = " & idReg & ";" & _
            "DELETE FROM TBL_SONG WHERE ID_SONG = " & idReg)
        If ok Then mensaje = "Cancion eliminada junto con sus relaciones." Else mensaje = "No fue posible eliminar la cancion."

    ' ================= ARTISTAS =================
    Case "actualizar:tbl_artist"
        Dim aNombre, aApellido, aImagen
        aNombre   = Left(Trim(CStr(Request.Form("artist_name"))), 100)
        aApellido = Left(Trim(CStr(Request.Form("artist_lastname"))), 100)
        aImagen   = Left(Trim(CStr(Request.Form("artist_image"))), 255)

        If aNombre = "" Then
            mensaje = "El nombre del artista es obligatorio."
        Else
            ok = EjecutarComando( _
                "UPDATE TBL_ARTIST SET ARTIST_NAME = '" & Esc(aNombre) & "', " & _
                "ARTIST_LASTNAME = '" & Esc(aApellido) & "', " & _
                "ARTIST_IMAGE = '" & Esc(aImagen) & "' WHERE ID_ARTIST = " & idReg)
            If ok Then mensaje = "Artista actualizado correctamente." Else mensaje = "No fue posible actualizar el artista."
        End If

    Case "eliminar:tbl_artist"
        ok = EjecutarComando( _
            "DELETE FROM TBL_PLAYER WHERE ID_ARTIST = " & idReg & ";" & _
            "DELETE FROM TBL_ARTIST WHERE ID_ARTIST = " & idReg)
        If ok Then mensaje = "Artista eliminado junto con sus asociaciones." Else mensaje = "No fue posible eliminar el artista."

    ' ================= ALBUMES =================
    Case "actualizar:tbl_album"
        Dim bTitulo, bAnio, bImagen
        bTitulo = Left(Trim(CStr(Request.Form("title_album"))), 50)
        bAnio   = EscInt(Request.Form("release_year"))
        bImagen = Left(Trim(CStr(Request.Form("album_image_path"))), 255)

        If bTitulo = "" Then
            mensaje = "El titulo del album es obligatorio."
        Else
            Dim sAnio
            If IsNull(Request.Form("release_year")) Or Trim(CStr(Request.Form("release_year"))) = "" Then
                sAnio = "NULL"
            Else
                sAnio = CStr(bAnio)
            End If

            ok = EjecutarComando( _
                "UPDATE TBL_ALBUM SET TITLE_ALBUM = '" & Esc(bTitulo) & "', " & _
                "RELEASE_YEAR = " & sAnio & ", " & _
                "ALBUM_IMAGE_PATH = '" & Esc(bImagen) & "' WHERE ID_ALBUM = " & idReg)
            If ok Then mensaje = "Album actualizado correctamente." Else mensaje = "No fue posible actualizar el album."
        End If

    Case "eliminar:tbl_album"
        ok = EjecutarComando( _
            "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = " & idReg & ";" & _
            "DELETE FROM TBL_ALBUM WHERE ID_ALBUM = " & idReg)
        If ok Then mensaje = "Album eliminado junto con su lista de pistas." Else mensaje = "No fue posible eliminar el album."

    ' ================= PLAYLISTS =================
    Case "actualizar:tbl_playlist"
        Dim pTitulo, pTipo, pFoto, pPropietario, pFecha
        pTitulo      = Left(Trim(CStr(Request.Form("title"))), 50)
        pTipo        = EscInt(Request.Form("type"))
        pFoto        = Left(Trim(CStr(Request.Form("photo"))), 255)
        pPropietario = EscInt(Request.Form("id_user"))
        pFecha       = Trim(CStr(Request.Form("creation_date")))

        If pTitulo = "" Then
            mensaje = "El titulo de la playlist es obligatorio."
        ElseIf pPropietario <= 0 Then
            mensaje = "Debe seleccionar un propietario valido."
        Else
            Dim sFechaPL
            If pFecha <> "" And IsDate(pFecha) Then
                sFechaPL = "'" & Year(CDate(pFecha)) & "-" & Right("0" & Month(CDate(pFecha)), 2) & "-" & Right("0" & Day(CDate(pFecha)), 2) & "'"
            Else
                sFechaPL = "GETDATE()"
            End If

            ok = EjecutarComando( _
                "UPDATE TBL_PLAYLIST SET TITLE = '" & Esc(pTitulo) & "', " & _
                "TYPE = " & pTipo & ", PHOTO = '" & Esc(pFoto) & "', " & _
                "ID_USER = " & pPropietario & ", CREATION_DATE = " & sFechaPL & _
                " WHERE ID_PLAYLIST = " & idReg)
            If ok Then mensaje = "Playlist actualizada correctamente." Else mensaje = "No fue posible actualizar la playlist."
        End If

    Case "eliminar:tbl_playlist"
        ok = EjecutarComando( _
            "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = " & idReg & ";" & _
            "DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = " & idReg)
        If ok Then mensaje = "Playlist eliminada junto con su contenido." Else mensaje = "No fue posible eliminar la playlist."

    ' ================= CATALOGOS =================
    Case "actualizar:tbl_catalog"
        Dim cValor, cCodigo, cPadre
        cValor  = Left(Trim(CStr(Request.Form("value"))), 255)
        cCodigo = Left(Trim(CStr(Request.Form("cod_catalog"))), 8)
        cPadre  = Left(Trim(CStr(Request.Form("cod_catalog_parent"))), 8)

        If cValor = "" Then
            mensaje = "El valor del catalogo es obligatorio."
        Else
            ok = EjecutarComando( _
                "UPDATE TBL_CATALOG SET VALUE = '" & Esc(cValor) & "', " & _
                "COD_CATALOG = '" & Esc(cCodigo) & "', " & _
                "COD_CATALOG_PARENT = '" & Esc(cPadre) & "' WHERE ID_CATALOG = " & idReg)
            If ok Then mensaje = "Entrada de catalogo actualizada." Else mensaje = "No fue posible actualizar el catalogo."
        End If

    Case "eliminar:tbl_catalog"
        ok = EjecutarComando("DELETE FROM TBL_CATALOG WHERE ID_CATALOG = " & idReg)
        If ok Then mensaje = "Entrada de catalogo eliminada." Else mensaje = "No fue posible eliminar la entrada."

    Case Else
        mensaje = "Operacion no reconocida: " & H(accion & " / " & entidad)

End Select

'----------------------------------------------------------------------------------
' Registro de auditoria de la operacion
'----------------------------------------------------------------------------------
If ok Then
    RegistrarBitacoraAcceso "ADMIN", CStr(Session("USERNAME")), accion & ":" & entidad & ":" & idReg, "OK"
Else
    RegistrarBitacoraAcceso "ADMIN", CStr(Session("USERNAME")), accion & ":" & entidad & ":" & idReg, "FALLO"
End If

'----------------------------------------------------------------------------------
' Redireccion de retorno al panel con el resultado
'----------------------------------------------------------------------------------
Dim tipoMsg
If ok Then tipoMsg = "ok" Else tipoMsg = "error"

Response.Redirect "panel.asp?msg=" & Server.URLEncode(mensaje) & "&tipo=" & tipoMsg & "#" & tabDestino
Response.End
%>
