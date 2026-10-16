<%
'==================================================================================
' PoliMusic - Repositorio de Consultas
' Archivo: _includes/consultas.asp
' Descripcion: Centraliza las consultas SQL de lectura usadas por el dashboard
'              y por el panel de administracion. Todas las funciones devuelven
'              Recordset desconectados.
'              Debe incluirse DESPUES de conexion.asp.
'==================================================================================

'----------------------------------------------------------------------------------
' ListarAlbumes
' Devuelve los albumes con su numero de pistas y las reproducciones acumuladas.
'----------------------------------------------------------------------------------
Function ListarAlbumes()
    ListarAlbumes = EjecutarConsulta( _
        "SELECT A.ID_ALBUM, A.TITLE_ALBUM, A.RELEASE_YEAR, A.ALBUM_IMAGE_PATH, " & _
        "       (SELECT COUNT(*) FROM TBL_TRACKLIST T WHERE T.ID_ALBUM = A.ID_ALBUM) AS TOTAL_TRACKS, " & _
        "       (SELECT ISNULL(SUM(S.PLAYS),0) FROM TBL_TRACKLIST T " & _
        "         INNER JOIN TBL_SONG S ON S.ID_SONG = T.ID_SONG WHERE T.ID_ALBUM = A.ID_ALBUM) AS TOTAL_PLAYS, " & _
        "       (SELECT TOP 1 ART.ARTIST_NAME + ' ' + ISNULL(ART.ARTIST_LASTNAME,'') " & _
        "          FROM TBL_TRACKLIST T INNER JOIN TBL_PLAYER P ON P.ID_SONG = T.ID_SONG " & _
        "          INNER JOIN TBL_ARTIST ART ON ART.ID_ARTIST = P.ID_ARTIST " & _
        "         WHERE T.ID_ALBUM = A.ID_ALBUM) AS ARTISTA " & _
        "FROM TBL_ALBUM A ORDER BY A.TITLE_ALBUM")
End Function

'----------------------------------------------------------------------------------
' ObtenerAlbum
' Devuelve un album concreto por su identificador.
'----------------------------------------------------------------------------------
Function ObtenerAlbum(ByVal idAlbum)
    ObtenerAlbum = EjecutarConsulta( _
        "SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH " & _
        "FROM TBL_ALBUM WHERE ID_ALBUM = " & EscInt(idAlbum))
End Function

'----------------------------------------------------------------------------------
' ListarArtistas
' Devuelve los artistas con el numero de canciones asociadas.
'----------------------------------------------------------------------------------
Function ListarArtistas()
    ListarArtistas = EjecutarConsulta( _
        "SELECT AR.ID_ARTIST, AR.ARTIST_NAME, AR.ARTIST_LASTNAME, AR.ARTIST_IMAGE, " & _
        "       (SELECT COUNT(DISTINCT P.ID_SONG) FROM TBL_PLAYER P WHERE P.ID_ARTIST = AR.ID_ARTIST) AS TOTAL_SONGS " & _
        "FROM TBL_ARTIST AR " & _
        "ORDER BY (AR.ARTIST_NAME + ' ' + ISNULL(AR.ARTIST_LASTNAME,''))")
End Function

'----------------------------------------------------------------------------------
' ListarCanciones
' Devuelve el catalogo de canciones con su artista principal y album de origen.
'----------------------------------------------------------------------------------
Function ListarCanciones()
    ListarCanciones = EjecutarConsulta( _
        "SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
        "       ISNULL(AR.ARTIST_NAME,'Sin artista') + ' ' + ISNULL(AR.ARTIST_LASTNAME,'') AS ARTISTA, " & _
        "       ISNULL(AR.ID_ARTIST,0) AS ID_ARTIST, " & _
        "       ISNULL(AL.TITLE_ALBUM,'Sencillo') AS ALBUM, ISNULL(AL.ID_ALBUM,0) AS ID_ALBUM, " & _
        "       ISNULL(AL.ALBUM_IMAGE_PATH,'') AS ALBUM_IMAGE_PATH " & _
        "FROM TBL_SONG S " & _
        "LEFT JOIN TBL_PLAYER P ON P.ID_SONG = S.ID_SONG " & _
        "LEFT JOIN TBL_ARTIST AR ON AR.ID_ARTIST = P.ID_ARTIST " & _
        "LEFT JOIN TBL_TRACKLIST T ON T.ID_SONG = S.ID_SONG " & _
        "LEFT JOIN TBL_ALBUM AL ON AL.ID_ALBUM = T.ID_ALBUM " & _
        "ORDER BY S.SONG_NAME")
End Function

'----------------------------------------------------------------------------------
' ListarCancionesDeAlbum
' Devuelve las pistas asociadas a un album, con datos del artista principal.
'----------------------------------------------------------------------------------
Function ListarCancionesDeAlbum(ByVal idAlbum)
    ListarCancionesDeAlbum = EjecutarConsulta( _
        "SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
        "       ISNULL(AR.ARTIST_NAME,'Sin artista') + ' ' + ISNULL(AR.ARTIST_LASTNAME,'') AS ARTISTA " & _
        "FROM TBL_TRACKLIST T " & _
        "INNER JOIN TBL_SONG S ON S.ID_SONG = T.ID_SONG " & _
        "LEFT JOIN TBL_PLAYER P ON P.ID_SONG = S.ID_SONG " & _
        "LEFT JOIN TBL_ARTIST AR ON AR.ID_ARTIST = P.ID_ARTIST " & _
        "WHERE T.ID_ALBUM = " & EscInt(idAlbum) & " ORDER BY S.SONG_NAME")
End Function

'----------------------------------------------------------------------------------
' ListarCancionesDeArtista
' Devuelve las canciones interpretadas por un artista.
'----------------------------------------------------------------------------------
Function ListarCancionesDeArtista(ByVal idArtist)
    ListarCancionesDeArtista = EjecutarConsulta( _
        "SELECT DISTINCT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
        "       ISNULL(AL.TITLE_ALBUM,'Sencillo') AS ALBUM " & _
        "FROM TBL_PLAYER P " & _
        "INNER JOIN TBL_SONG S ON S.ID_SONG = P.ID_SONG " & _
        "LEFT JOIN TBL_TRACKLIST T ON T.ID_SONG = S.ID_SONG " & _
        "LEFT JOIN TBL_ALBUM AL ON AL.ID_ALBUM = T.ID_ALBUM " & _
        "WHERE P.ID_ARTIST = " & EscInt(idArtist) & " ORDER BY S.SONG_NAME")
End Function

'----------------------------------------------------------------------------------
' ListarPlaylists
' Playlists visibles para el usuario: las publicas mas las propias cuando es
' un usuario Estandar. El Administrador ve la totalidad del catalogo.
'----------------------------------------------------------------------------------
Function ListarPlaylists(ByVal idUser, ByVal esAdmin)
    Dim filtro, sql
    If esAdmin Then
        filtro = ""
    Else
        filtro = " WHERE PL.TYPE = " & PLAYLIST_TYPE_PUBLIC & " OR PL.ID_USER = " & EscInt(idUser)
    End If

    sql = "SELECT PL.ID_PLAYLIST, PL.ID_USER, PL.TITLE, PL.CREATION_DATE, PL.TYPE, PL.PHOTO, " & _
          "       U.USERNAME AS PROPIETARIO, " & _
          "       (SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS TOTAL_SONGS " & _
          "FROM TBL_PLAYLIST PL " & _
          "LEFT JOIN TBL_USER U ON U.ID_USER = PL.ID_USER " & filtro & " " & _
          "ORDER BY PL.CREATION_DATE DESC"

    ListarPlaylists = EjecutarConsulta(sql)
End Function

'----------------------------------------------------------------------------------
' ListarTodasLasPlaylists
' Catalogo completo de playlists (uso exclusivo del panel de administracion).
'----------------------------------------------------------------------------------
Function ListarTodasLasPlaylists()
    ListarTodasLasPlaylists = EjecutarConsulta( _
        "SELECT PL.ID_PLAYLIST, PL.ID_USER, PL.TITLE, PL.CREATION_DATE, PL.TYPE, PL.PHOTO, " & _
        "       ISNULL(U.USERNAME,'(sin propietario)') AS PROPIETARIO, " & _
        "       (SELECT COUNT(*) FROM TBL_PLAYLIST_SONG PS WHERE PS.ID_PLAYLIST = PL.ID_PLAYLIST) AS TOTAL_SONGS " & _
        "FROM TBL_PLAYLIST PL LEFT JOIN TBL_USER U ON U.ID_USER = PL.ID_USER " & _
        "ORDER BY PL.CREATION_DATE DESC")
End Function

'----------------------------------------------------------------------------------
' ListarCancionesDePlaylist
' Detalle de pistas que componen una playlist.
'----------------------------------------------------------------------------------
Function ListarCancionesDePlaylist(ByVal idPlaylist)
    ListarCancionesDePlaylist = EjecutarConsulta( _
        "SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
        "       ISNULL(AR.ARTIST_NAME,'Sin artista') + ' ' + ISNULL(AR.ARTIST_LASTNAME,'') AS ARTISTA, " & _
        "       ISNULL(AL.TITLE_ALBUM,'Sencillo') AS ALBUM " & _
        "FROM TBL_PLAYLIST_SONG PS " & _
        "INNER JOIN TBL_SONG S ON S.ID_SONG = PS.ID_SONG " & _
        "LEFT JOIN TBL_PLAYER P ON P.ID_SONG = S.ID_SONG " & _
        "LEFT JOIN TBL_ARTIST AR ON AR.ID_ARTIST = P.ID_ARTIST " & _
        "LEFT JOIN TBL_TRACKLIST T ON T.ID_SONG = S.ID_SONG " & _
        "LEFT JOIN TBL_ALBUM AL ON AL.ID_ALBUM = T.ID_ALBUM " & _
        "WHERE PS.ID_PLAYLIST = " & EscInt(idPlaylist) & " ORDER BY S.SONG_NAME")
End Function

'----------------------------------------------------------------------------------
' ObtenerPlaylist
' Recupera una playlist puntual con su propietario.
'----------------------------------------------------------------------------------
Function ObtenerPlaylist(ByVal idPlaylist)
    ObtenerPlaylist = EjecutarConsulta( _
        "SELECT PL.ID_PLAYLIST, PL.ID_USER, PL.TITLE, PL.CREATION_DATE, PL.TYPE, PL.PHOTO, " & _
        "       ISNULL(U.USERNAME,'') AS PROPIETARIO " & _
        "FROM TBL_PLAYLIST PL LEFT JOIN TBL_USER U ON U.ID_USER = PL.ID_USER " & _
        "WHERE PL.ID_PLAYLIST = " & EscInt(idPlaylist))
End Function

'----------------------------------------------------------------------------------
' ListarUsuarios
' Catalogo de usuarios registrados con la etiqueta de su rol.
'----------------------------------------------------------------------------------
Function ListarUsuarios()
    ListarUsuarios = EjecutarConsulta( _
        "SELECT U.ID_USER, U.USERNAME, U.EMAIL, U.BIRTHDAY, U.USER_PHOTO, U.USER_TYPE, " & _
        "       CASE U.USER_TYPE WHEN 1 THEN 'Administrador' ELSE 'Estandar' END AS ROL, " & _
        "       (SELECT COUNT(*) FROM TBL_PLAYLIST P WHERE P.ID_USER = U.ID_USER) AS TOTAL_PLAYLISTS " & _
        "FROM TBL_USER U ORDER BY U.USERNAME")
End Function

'----------------------------------------------------------------------------------
' ObtenerUsuario
' Recupera un usuario por identificador.
'----------------------------------------------------------------------------------
Function ObtenerUsuario(ByVal idUser)
    ObtenerUsuario = EjecutarConsulta( _
        "SELECT ID_USER, USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE " & _
        "FROM TBL_USER WHERE ID_USER = " & EscInt(idUser))
End Function

'----------------------------------------------------------------------------------
' ContarRegistros
' Cuenta filas de una tabla permitida. Se usa para mostrar metricas del panel.
'----------------------------------------------------------------------------------
Function ContarRegistros(ByVal tabla)
    Dim t
    t = LCase(Trim(CStr(tabla)))
    Select Case t
        Case "tbl_user", "tbl_song", "tbl_album", "tbl_artist", "tbl_playlist"
            ContarRegistros = EscInt(EjecutarEscalar("SELECT COUNT(*) FROM " & t))
        Case Else
            ContarRegistros = 0
    End Select
End Function

'----------------------------------------------------------------------------------
' ListarCatalogoPorPadre
' Devuelve los valores de catalogo hijos de un codigo padre (tipos de usuario,
' tipos de playlist, etc.).
'----------------------------------------------------------------------------------
Function ListarCatalogoPorPadre(ByVal codPadre)
    ListarCatalogoPorPadre = EjecutarConsulta( _
        "SELECT ID_CATALOG, COD_CATALOG_PARENT, COD_CATALOG, VALUE FROM TBL_CATALOG " & _
        "WHERE COD_CATALOG_PARENT = '" & Esc(codPadre) & "' ORDER BY ID_CATALOG")
End Function

'----------------------------------------------------------------------------------
' ListarTodosLosCatalogos
' Volcado completo de la tabla de catalogos para el panel administrador.
'----------------------------------------------------------------------------------
Function ListarTodosLosCatalogos()
    ListarTodosLosCatalogos = EjecutarConsulta( _
        "SELECT ID_CATALOG, COD_CATALOG_PARENT, COD_CATALOG, VALUE FROM TBL_CATALOG ORDER BY ID_CATALOG")
End Function
%>
