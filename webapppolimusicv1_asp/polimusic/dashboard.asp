<%
'==================================================================================
' PoliMusic - Pantalla Principal (Dashboard)
' Archivo: dashboard.asp
' Descripcion: Vista principal de consumo. Presenta el reproductor de audio y las
'              galerias de albumes, artistas, canciones y playlists. El catalogo
'              visible se adapta al rol del usuario autenticado.
'==================================================================================
%>
<!--#include virtual="/polimusic/_includes/config.asp"-->
<!--#include virtual="/polimusic/_includes/conexion.asp"-->
<!--#include virtual="/polimusic/_includes/sesion.asp"-->
<!--#include virtual="/polimusic/_includes/consultas.asp"-->
<!--#include virtual="/polimusic/_includes/iconos.asp"-->
<%
EnviarCabecerasNoCache
RequerirSesion

Dim strTitulo, strSubtitulo, strVistaActiva, strScriptExtra
strTitulo = "Inicio"
strSubtitulo = "Tu catalogo musical"
strVistaActiva = "catalogo"
strScriptExtra = ""

' Mensaje contextual recibido por cadena de consulta
Dim avisoSesion
avisoSesion = ""
If Request.QueryString("msg") <> "" Then avisoSesion = Request.QueryString("msg")
%>
<!--#include virtual="/polimusic/_includes/layout_superior.asp"-->
<%
' NOTA: 'strBase' ya queda declarada (Dim) dentro de layout_superior.asp, que se
' acaba de incluir. Volver a declararla aqui provocaria el error de compilacion
' VBScript "Name redefined" (HTTP 500). Solo se le asigna valor si esta vacia.
If strBase = "" Then strBase = URL_BASE

' =================================================================================
' BLOQUE 1: VISTA DE INICIO (CATALOGO)
' =================================================================================
%>
<section class="pm-vista" id="vista-catalogo" data-titulo="Inicio" data-subtitulo="Tu catalogo musical">

    <!-- Cabecera de bienvenida -->
    <div class="pm-hero" style="grid-template-columns:1fr;padding-bottom:10px;">
        <div>
            <div class="pm-hero__kind">
                <% If EsAdmin() Then %>Sesion de administrador<% Else %>Bienvenido de nuevo<% End If %>
            </div>
            <h1 class="pm-hero__title" style="font-size:clamp(28px,4vw,46px);">
                Hola, <%=H(Session("USERNAME"))%>
            </h1>
            <div class="pm-hero__meta">
                <span>Explora tu coleccion, reproduce tus pistas favoritas y descubre nuevo contenido.</span>
            </div>
        </div>
    </div>

    <div id="pmBusquedaBloque">

        <!-- ========== Albumes destacados ========== -->
        <%
        Dim rsAlb, nAlb
        Set rsAlb = ListarAlbumes()
        nAlb = 0
        ' RsValido: objeto + no Nothing + estado abierto.
        If RsValido(rsAlb) Then
        %>
        <section class="pm-section">
            <div class="pm-section__head">
                <div>
                    <div class="pm-section__title">Albumes destacados</div>
                    <div class="pm-section__sub">Colecciones listas para escuchar</div>
                </div>
                <button class="pm-section__link" type="button" data-vista="albumes">Ver todo</button>
            </div>

            <div class="pm-grid" data-filtrable>
                <%
                Do While Not rsAlb.EOF
                    nAlb = nAlb + 1
                    Dim sImgAlb, sTituloAlb, sAnioAlb, sArtistaAlb, sColaAlb
                    sImgAlb = ImagenSegura(rsAlb("ALBUM_IMAGE_PATH"), strBase, "AlbumImages", "album" & ((nAlb - 1) Mod 5 + 1) & ".png")
                    sTituloAlb = CStr(rsAlb("TITLE_ALBUM"))
                    sAnioAlb = ""
                    If Not IsNull(rsAlb("RELEASE_YEAR")) Then sAnioAlb = CStr(rsAlb("RELEASE_YEAR"))
                    sArtistaAlb = ""
                    If Not IsNull(rsAlb("ARTISTA")) Then sArtistaAlb = Trim(CStr(rsAlb("ARTISTA")))

                    sColaAlb = ColaJsonDeAlbum(EscInt(rsAlb("ID_ALBUM")), strBase)
                %>
                <article class="pm-card" data-texto="<%=H(sTituloAlb & " " & sArtistaAlb & " " & sAnioAlb)%>">
                    <div class="pm-card__art">
                        <img src="<%=H(sImgAlb)%>" alt="Portada de <%=H(sTituloAlb)%>" loading="lazy">
                        <button class="pm-card__play" type="button"
                                title="Reproducir <%=H(sTituloAlb)%>"
                                data-play-context="album"
                                data-play-json="<%=sColaAlb%>">
                            <span class="pm-ico-play"><%=Ico("reproducir")%></span>
                            <span class="pm-ico-pause"><%=Ico("pausa")%></span>
                        </button>
                    </div>
                    <div class="pm-card__title" title="<%=H(sTituloAlb)%>"><%=H(sTituloAlb)%></div>
                    <div class="pm-card__meta"><%=EscInt(rsAlb("TOTAL_TRACKS"))%> pistas<% If sAnioAlb <> "" Then %> &middot; <%=H(sAnioAlb)%><% End If %></div>
                    <span class="pm-card__tag">Album</span>
                </article>
                <%
                    rsAlb.MoveNext
                Loop
                %>
            </div>
        </section>
        <%
                rsAlb.Close
            Set rsAlb = Nothing
        End If
        %>

        <!-- ========== Artistas ========== -->
        <%
        Dim rsArt
        Set rsArt = ListarArtistas()
        ' RsValido: objeto + no Nothing + estado abierto.
        If RsValido(rsArt) Then
        %>
        <section class="pm-section">
            <div class="pm-section__head">
                <div>
                    <div class="pm-section__title">Artistas</div>
                    <div class="pm-section__sub">Voces y autores de tu biblioteca</div>
                </div>
                <button class="pm-section__link" type="button" data-vista="artistas">Ver todo</button>
            </div>

            <div class="pm-grid" data-filtrable>
                <%
                Dim nArt
                nArt = 0
                Do While Not rsArt.EOF
                    nArt = nArt + 1
                    Dim sImgArt, sNombreArt
                    sImgArt = ImagenSegura(rsArt("ARTIST_IMAGE"), strBase, "ArtistImages", "artist" & ((nArt - 1) Mod 5 + 1) & ".jpg")
                    sNombreArt = Trim(CStr(rsArt("ARTIST_NAME")) & " " & CStr(rsArt("ARTIST_LASTNAME")))
                %>
                <article class="pm-card" data-texto="<%=H(sNombreArt)%>">
                    <div class="pm-card__art pm-card__art--round">
                        <img src="<%=H(sImgArt)%>" alt="<%=H(sNombreArt)%>" loading="lazy">
                        <button class="pm-card__play" type="button"
                                title="Reproducir canciones de <%=H(sNombreArt)%>"
                                data-play-context="artista"
                                data-play-json="<%=ColaJsonDeArtista(EscInt(rsArt("ID_ARTIST")), strBase)%>">
                            <span class="pm-ico-play"><%=Ico("reproducir")%></span>
                            <span class="pm-ico-pause"><%=Ico("pausa")%></span>
                        </button>
                    </div>
                    <div class="pm-card__title" title="<%=H(sNombreArt)%>"><%=H(sNombreArt)%></div>
                    <div class="pm-card__meta"><%=EscInt(rsArt("TOTAL_SONGS"))%> canciones</div>
                    <span class="pm-card__tag">Artista</span>
                </article>
                <%
                    rsArt.MoveNext
                Loop
                %>
            </div>
        </section>
        <%
                rsArt.Close
            Set rsArt = Nothing
        End If
        %>

        <!-- ========== Canciones mas escuchadas ========== -->
        <%
        Dim rsTop
        Set rsTop = EjecutarConsulta( _
            "SELECT TOP 6 S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(S.PLAYS,0) AS PLAYS, " & _
            "       ISNULL(AR.ARTIST_NAME,'Sin artista') + ' ' + ISNULL(AR.ARTIST_LASTNAME,'') AS ARTISTA " & _
            "FROM TBL_SONG S LEFT JOIN TBL_PLAYER P ON P.ID_SONG = S.ID_SONG " & _
            "LEFT JOIN TBL_ARTIST AR ON AR.ID_ARTIST = P.ID_ARTIST " & _
            "ORDER BY ISNULL(S.PLAYS,0) DESC, S.SONG_NAME")
        ' RsValido: objeto + no Nothing + estado abierto.
        If RsValido(rsTop) Then
        %>
        <section class="pm-section">
            <div class="pm-section__head">
                <div>
                    <div class="pm-section__title">Lo mas escuchado</div>
                    <div class="pm-section__sub">Las pistas con mayor numero de reproducciones</div>
                </div>
                <button class="pm-section__link" type="button" data-vista="canciones">Ver todo</button>
            </div>

            <div class="pm-tracklist">
                <div class="pm-tracklist__head">
                    <span>#</span><span>Titulo</span><span>Artista</span><span>Album</span><span>Reproducciones</span><span></span>
                </div>
                <%
                Dim nTop
                nTop = 0
                Do While Not rsTop.EOF
                    nTop = nTop + 1
                %>
                <div class="pm-track" data-fila-busqueda data-texto="<%=H(CStr(rsTop("SONG_NAME")) & " " & CStr(rsTop("ARTISTA")))%>">
                    <div class="pm-track__idx">
                        <span class="pm-track__num"><%=nTop%></span>
                        <span class="pm-track__play-ico"><%=Ico("reproducir")%></span>
                    </div>
                    <div class="pm-track__main" data-play-uid="<%=EscInt(rsTop("ID_SONG"))%>" data-play-context="destacadas" data-play-json="<%=ColaJsonDestacadas(strBase)%>">
                        <img class="pm-track__art" src="<%=H(ImagenSegura("", strBase, "AlbumImages", "album" & ((nTop - 1) Mod 5 + 1) & ".png"))%>" alt="" loading="lazy">
                        <span class="pm-track__text">
                            <span class="pm-track__name"><%=H(rsTop("SONG_NAME"))%></span>
                            <span class="pm-track__artist"><%=H(rsTop("ARTISTA"))%></span>
                        </span>
                    </div>
                    <div class="pm-track__album">PoliMusic Records</div>
                    <div class="pm-track__album pm-hidden">PoliMusic Records</div>
                    <div class="pm-track__plays"><%=EscInt(rsTop("PLAYS"))%></div>
                    <div class="pm-track__actions">
                        <button class="pm-ico-btn" type="button" title="Agregar a favoritos" onclick="PoliMusic.notificar('Pista agregada a tus favoritos.','ok');">
                            <%=Ico("corazon")%>
                        </button>
                    </div>
                </div>
                <%
                    rsTop.MoveNext
                Loop
                %>
            </div>
        </section>
        <%
                rsTop.Close
            Set rsTop = Nothing
        End If
        %>

        <!-- ========== Playlists ========== -->
        <%
        Dim rsPL
        Set rsPL = ListarPlaylists(Session("ID_USER"), EsAdmin())
        ' RsValido: objeto + no Nothing + estado abierto.
        If RsValido(rsPL) Then
        %>
        <section class="pm-section">
            <div class="pm-section__head">
                <div>
                    <div class="pm-section__title">Playlists</div>
                    <div class="pm-section__sub">Selecciones curadas para cada momento</div>
                </div>
                <button class="pm-section__link" type="button" data-vista="playlists">Ver todo</button>
            </div>

            <div class="pm-grid" data-filtrable>
                <%
                Do While Not rsPL.EOF
                    Dim sImgPL, sTipoPL
                    sImgPL = ImagenSegura(rsPL("PHOTO"), strBase, "PlaylistImages", "default.jpg")
                    If EscInt(rsPL("TYPE")) = PLAYLIST_TYPE_PRIVATE Then sTipoPL = "Privada" Else sTipoPL = "Publica"
                %>
                <article class="pm-card" data-texto="<%=H(CStr(rsPL("TITLE")) & " " & sTipoPL)%>">
                    <div class="pm-card__art">
                        <img src="<%=H(sImgPL)%>" alt="Portada de <%=H(rsPL("TITLE"))%>" loading="lazy">
                        <button class="pm-card__play" type="button"
                                title="Reproducir <%=H(rsPL("TITLE"))%>"
                                data-play-context="playlist"
                                data-play-json="<%=ColaJsonDePlaylist(EscInt(rsPL("ID_PLAYLIST")), strBase)%>">
                            <span class="pm-ico-play"><%=Ico("reproducir")%></span>
                            <span class="pm-ico-pause"><%=Ico("pausa")%></span>
                        </button>
                    </div>
                    <div class="pm-card__title" title="<%=H(rsPL("TITLE"))%>"><%=H(rsPL("TITLE"))%></div>
                    <div class="pm-card__meta"><%=EscInt(rsPL("TOTAL_SONGS"))%> pistas &middot; <%=H(sTipoPL)%></div>
                    <span class="pm-card__tag">Playlist</span>
                </article>
                <%
                    rsPL.MoveNext
                Loop
                %>
            </div>
        </section>
        <%
                rsPL.Close
            Set rsPL = Nothing
        End If
        %>

        <p class="pm-empty-mini pm-hidden" id="pmSearchCount"></p>
    </div>
</section>

<!-- =================================================================================
     BLOQUE 2: VISTA DE ALBUMES
     ================================================================================= -->
<section class="pm-vista pm-hidden" id="vista-albumes" data-titulo="Albumes" data-subtitulo="Explora las colecciones completas">
    <div class="pm-section">
        <div class="pm-section__head">
            <div>
                <div class="pm-section__title">Todos los albumes</div>
                <div class="pm-section__sub"><%=EscInt(ContarRegistros("tbl_album"))%> albumes en el catalogo</div>
            </div>
        </div>
        <div class="pm-grid pm-grid--wide">
            <%
            Dim rsAlb2, nAlb2
            Set rsAlb2 = ListarAlbumes()
            If RsValido(rsAlb2) Then
                    nAlb2 = 0
                    Do While Not rsAlb2.EOF
                        nAlb2 = nAlb2 + 1
                        Dim iA, tA, yA, aA
                        iA = ImagenSegura(rsAlb2("ALBUM_IMAGE_PATH"), strBase, "AlbumImages", "album" & ((nAlb2 - 1) Mod 5 + 1) & ".png")
                        tA = CStr(rsAlb2("TITLE_ALBUM"))
                        yA = ""
                        If Not IsNull(rsAlb2("RELEASE_YEAR")) Then yA = CStr(rsAlb2("RELEASE_YEAR"))
                        aA = ""
                        If Not IsNull(rsAlb2("ARTISTA")) Then aA = Trim(CStr(rsAlb2("ARTISTA")))
            %>
            <article class="pm-card">
                <div class="pm-card__art">
                    <img src="<%=H(iA)%>" alt="<%=H(tA)%>" loading="lazy">
                    <button class="pm-card__play" type="button" title="Reproducir <%=H(tA)%>"
                            data-play-context="album"
                            data-play-json="<%=ColaJsonDeAlbum(EscInt(rsAlb2("ID_ALBUM")), strBase)%>">
                        <span class="pm-ico-play"><%=Ico("reproducir")%></span>
                        <span class="pm-ico-pause"><%=Ico("pausa")%></span>
                    </button>
                </div>
                <div class="pm-card__title" title="<%=H(tA)%>"><%=H(tA)%></div>
                <div class="pm-card__meta">
                    <%=EscInt(rsAlb2("TOTAL_TRACKS"))%> pistas<% If yA <> "" Then %> &middot; <%=H(yA)%><% End If %>
                    <% If aA <> "" Then %><br><%=H(aA)%><% End If %>
                </div>
            </article>
            <%
                    rsAlb2.MoveNext
                    Loop
                    rsAlb2.Close
                Set rsAlb2 = Nothing
            End If
            %>
        </div>
    </div>
</section>

<!-- =================================================================================
     BLOQUE 3: VISTA DE ARTISTAS
     ================================================================================= -->
<section class="pm-vista pm-hidden" id="vista-artistas" data-titulo="Artistas" data-subtitulo="Descubre a los interpretes">
    <div class="pm-section">
        <div class="pm-section__head">
            <div>
                <div class="pm-section__title">Todos los artistas</div>
                <div class="pm-section__sub"><%=EscInt(ContarRegistros("tbl_artist"))%> artistas registrados</div>
            </div>
        </div>
        <div class="pm-grid">
            <%
            Dim rsArt2, nArt2
            Set rsArt2 = ListarArtistas()
            If RsValido(rsArt2) Then
                    nArt2 = 0
                    Do While Not rsArt2.EOF
                        nArt2 = nArt2 + 1
                        Dim iR, nR
                        iR = ImagenSegura(rsArt2("ARTIST_IMAGE"), strBase, "ArtistImages", "artist" & ((nArt2 - 1) Mod 5 + 1) & ".jpg")
                        nR = Trim(CStr(rsArt2("ARTIST_NAME")) & " " & CStr(rsArt2("ARTIST_LASTNAME")))
            %>
            <article class="pm-card">
                <div class="pm-card__art pm-card__art--round">
                    <img src="<%=H(iR)%>" alt="<%=H(nR)%>" loading="lazy">
                    <button class="pm-card__play" type="button" title="Reproducir <%=H(nR)%>"
                            data-play-context="artista"
                            data-play-json="<%=ColaJsonDeArtista(EscInt(rsArt2("ID_ARTIST")), strBase)%>">
                        <span class="pm-ico-play"><%=Ico("reproducir")%></span>
                        <span class="pm-ico-pause"><%=Ico("pausa")%></span>
                    </button>
                </div>
                <div class="pm-card__title" title="<%=H(nR)%>"><%=H(nR)%></div>
                <div class="pm-card__meta"><%=EscInt(rsArt2("TOTAL_SONGS"))%> canciones</div>
            </article>
            <%
                    rsArt2.MoveNext
                    Loop
                    rsArt2.Close
                Set rsArt2 = Nothing
            End If
            %>
        </div>
    </div>
</section>

<!-- =================================================================================
     BLOQUE 4: VISTA DE CANCIONES
     ================================================================================= -->
<section class="pm-vista pm-hidden" id="vista-canciones" data-titulo="Canciones" data-subtitulo="Todo el catalogo de audio">
    <div class="pm-section">
        <div class="pm-section__head">
            <div>
                <div class="pm-section__title">Catalogo de canciones</div>
                <div class="pm-section__sub"><%=EscInt(ContarRegistros("tbl_song"))%> pistas disponibles</div>
            </div>
            <button class="pm-btn pm-btn--primary pm-btn--sm" type="button"
                    data-play-context="catalogo"
                    data-play-json="<%=ColaJsonCatalogo(strBase)%>">
                <%=Ico("reproducir")%>
                Reproducir todo
            </button>
        </div>

        <div class="pm-tracklist">
            <div class="pm-tracklist__head">
                <span>#</span><span>Titulo</span><span>Artista</span><span>Album</span><span>Reproducciones</span><span></span>
            </div>
            <%
            Dim rsCan, nCan
            Set rsCan = ListarCanciones()
            nCan = 0
            If RsValido(rsCan) Then
                    Do While Not rsCan.EOF
                        nCan = nCan + 1
                        Dim imgCan
                        imgCan = ImagenSegura(rsCan("ALBUM_IMAGE_PATH"), strBase, "AlbumImages", "album" & ((nCan - 1) Mod 5 + 1) & ".png")
            %>
            <div class="pm-track" data-fila-busqueda data-texto="<%=H(CStr(rsCan("SONG_NAME")) & " " & CStr(rsCan("ARTISTA")) & " " & CStr(rsCan("ALBUM")))%>">
                <div class="pm-track__idx">
                    <span class="pm-track__num"><%=nCan%></span>
                    <span class="pm-track__play-ico"><%=Ico("reproducir")%></span>
                </div>
                <div class="pm-track__main" data-play-uid="<%=EscInt(rsCan("ID_SONG"))%>" data-play-context="catalogo" data-play-json="<%=ColaJsonCatalogo(strBase)%>">
                    <img class="pm-track__art" src="<%=H(imgCan)%>" alt="" loading="lazy">
                    <span class="pm-track__text">
                        <span class="pm-track__name"><%=H(rsCan("SONG_NAME"))%></span>
                        <span class="pm-track__artist"><%=H(rsCan("ARTISTA"))%></span>
                    </span>
                </div>
                <div class="pm-track__album"><%=H(rsCan("ALBUM"))%></div>
                <div class="pm-track__album pm-hidden"><%=H(rsCan("ALBUM"))%></div>
                <div class="pm-track__plays"><%=EscInt(rsCan("PLAYS"))%></div>
                <div class="pm-track__actions">
                    <button class="pm-ico-btn" type="button" title="Agregar a favoritos" onclick="PoliMusic.notificar('Pista agregada a tus favoritos.','ok');">
                        <%=Ico("corazon")%>
                    </button>
                    <% If EsAdmin() Then %>
                    <a class="pm-ico-btn" href="<%=strBase%>admin/panel.asp#canciones" title="Administrar cancion" style="text-decoration:none;">
                        <%=Ico("editar")%>
                    </a>
                    <% End If %>
                </div>
            </div>
            <%
                        rsCan.MoveNext
                    Loop
                    rsCan.Close
                Set rsCan = Nothing
            End If
            %>
        </div>
    </div>
</section>

<!-- =================================================================================
     BLOQUE 5: VISTA DE PLAYLISTS
     ================================================================================= -->
<section class="pm-vista pm-hidden" id="vista-playlists" data-titulo="Playlists" data-subtitulo="Tus selecciones personales">
    <div class="pm-section">
        <div class="pm-section__head">
            <div>
                <div class="pm-section__title">Playlists disponibles</div>
                <div class="pm-section__sub">
                    <% If EsAdmin() Then %>
                    Vista completa del catalogo de playlists
                    <% Else %>
                    Playlists publicas y las creadas por ti
                    <% End If %>
                </div>
            </div>
        </div>
        <div class="pm-grid pm-grid--wide">
            <%
            Dim rsPL2
            Set rsPL2 = ListarPlaylists(Session("ID_USER"), EsAdmin())
            If RsValido(rsPL2) Then
                    Do While Not rsPL2.EOF
                        Dim iP, tP, tipoP, fechaP
                        iP = ImagenSegura(rsPL2("PHOTO"), strBase, "PlaylistImages", "default.jpg")
                        tP = CStr(rsPL2("TITLE"))
                        If EscInt(rsPL2("TYPE")) = PLAYLIST_TYPE_PRIVATE Then tipoP = "Privada" Else tipoP = "Publica"
            %>
            <article class="pm-card">
                <div class="pm-card__art">
                    <img src="<%=H(iP)%>" alt="<%=H(tP)%>" loading="lazy">
                    <button class="pm-card__play" type="button" title="Reproducir <%=H(tP)%>"
                            data-play-context="playlist"
                            data-play-json="<%=ColaJsonDePlaylist(EscInt(rsPL2("ID_PLAYLIST")), strBase)%>">
                        <span class="pm-ico-play"><%=Ico("reproducir")%></span>
                        <span class="pm-ico-pause"><%=Ico("pausa")%></span>
                    </button>
                </div>
                <div class="pm-card__title" title="<%=H(tP)%>"><%=H(tP)%></div>
                <div class="pm-card__meta">
                    <%=EscInt(rsPL2("TOTAL_SONGS"))%> pistas &middot; <%=H(tipoP)%><br>
                    Creada el <%=FechaCorta(rsPL2("CREATION_DATE"))%>
                    <% If EsAdmin() And Not IsNull(rsPL2("PROPIETARIO")) Then %><br>De: <%=H(rsPL2("PROPIETARIO"))%><% End If %>
                </div>
            </article>
            <%
                    rsPL2.MoveNext
                    Loop
                    rsPL2.Close
                Set rsPL2 = Nothing
            End If
            %>
        </div>
    </div>
</section>
<%
' =================================================================================
' FUNCIONES AUXILIARES DE CONSTRUCCION DE COLAS JSON
' Generan los arreglos de pistas que consume el reproductor en el cliente.
' =================================================================================

Function ColaJsonDeAlbum(ByVal idAlbum, ByVal base)
    ColaJsonDeAlbum = ConstruirColaJson( _
        "SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, ISNULL(AR.ARTIST_NAME,'Sin artista') + ' ' + ISNULL(AR.ARTIST_LASTNAME,'') AS ARTISTA, " & _
        "(SELECT TOP 1 A.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS IMG, " & _
        "(SELECT TOP 1 A.TITLE_ALBUM FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS ALBUM " & _
        "FROM TBL_TRACKLIST T INNER JOIN TBL_SONG S ON S.ID_SONG = T.ID_SONG " & _
        "LEFT JOIN TBL_PLAYER P ON P.ID_SONG = S.ID_SONG LEFT JOIN TBL_ARTIST AR ON AR.ID_ARTIST = P.ID_ARTIST " & _
        "WHERE T.ID_ALBUM = " & EscInt(idAlbum) & " ORDER BY S.SONG_NAME", base)
End Function

Function ColaJsonDeArtista(ByVal idArtist, ByVal base)
    ColaJsonDeArtista = ConstruirColaJson( _
        "SELECT DISTINCT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, " & _
        "ISNULL(AR.ARTIST_NAME,'Sin artista') + ' ' + ISNULL(AR.ARTIST_LASTNAME,'') AS ARTISTA, " & _
        "(SELECT TOP 1 A.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS IMG, " & _
        "(SELECT TOP 1 A.TITLE_ALBUM FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS ALBUM " & _
        "FROM TBL_PLAYER P INNER JOIN TBL_SONG S ON S.ID_SONG = P.ID_SONG " & _
        "LEFT JOIN TBL_ARTIST AR ON AR.ID_ARTIST = P.ID_ARTIST " & _
        "WHERE P.ID_ARTIST = " & EscInt(idArtist) & " ORDER BY S.SONG_NAME", base)
End Function

Function ColaJsonDePlaylist(ByVal idPlaylist, ByVal base)
    ColaJsonDePlaylist = ConstruirColaJson( _
        "SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, " & _
        "ISNULL(AR.ARTIST_NAME,'Sin artista') + ' ' + ISNULL(AR.ARTIST_LASTNAME,'') AS ARTISTA, " & _
        "(SELECT TOP 1 A.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS IMG, " & _
        "(SELECT TOP 1 A.TITLE_ALBUM FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS ALBUM " & _
        "FROM TBL_PLAYLIST_SONG PS INNER JOIN TBL_SONG S ON S.ID_SONG = PS.ID_SONG " & _
        "LEFT JOIN TBL_PLAYER P ON P.ID_SONG = S.ID_SONG LEFT JOIN TBL_ARTIST AR ON AR.ID_ARTIST = P.ID_ARTIST " & _
        "WHERE PS.ID_PLAYLIST = " & EscInt(idPlaylist) & " ORDER BY S.SONG_NAME", base)
End Function

Function ColaJsonCatalogo(ByVal base)
    ColaJsonCatalogo = ConstruirColaJson( _
        "SELECT S.ID_SONG, S.SONG_NAME, S.SONG_PATH, " & _
        "ISNULL(AR.ARTIST_NAME,'Sin artista') + ' ' + ISNULL(AR.ARTIST_LASTNAME,'') AS ARTISTA, " & _
        "(SELECT TOP 1 A.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS IMG, " & _
        "(SELECT TOP 1 A.TITLE_ALBUM FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS ALBUM " & _
        "FROM TBL_SONG S LEFT JOIN TBL_PLAYER P ON P.ID_SONG = S.ID_SONG " & _
        "LEFT JOIN TBL_ARTIST AR ON AR.ID_ARTIST = P.ID_ARTIST ORDER BY S.SONG_NAME", base)
End Function

Function ColaJsonDestacadas(ByVal base)
    ColaJsonDestacadas = ConstruirColaJson( _
        "SELECT TOP 6 S.ID_SONG, S.SONG_NAME, S.SONG_PATH, " & _
        "ISNULL(AR.ARTIST_NAME,'Sin artista') + ' ' + ISNULL(AR.ARTIST_LASTNAME,'') AS ARTISTA, " & _
        "(SELECT TOP 1 A.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS IMG, " & _
        "(SELECT TOP 1 A.TITLE_ALBUM FROM TBL_TRACKLIST T2 INNER JOIN TBL_ALBUM A ON A.ID_ALBUM = T2.ID_ALBUM WHERE T2.ID_SONG = S.ID_SONG) AS ALBUM " & _
        "FROM TBL_SONG S LEFT JOIN TBL_PLAYER P ON P.ID_SONG = S.ID_SONG " & _
        "LEFT JOIN TBL_ARTIST AR ON AR.ID_ARTIST = P.ID_ARTIST " & _
        "ORDER BY ISNULL(S.PLAYS,0) DESC, S.SONG_NAME", base)
End Function

'----------------------------------------------------------------------------------
' ConstruirColaJson
' Ejecuta la consulta indicada y serializa el resultado como arreglo JSON de
' pistas listo para el reproductor: { uid, nombre, artista, album, src, img }.
'----------------------------------------------------------------------------------
Function ConstruirColaJson(ByVal sql, ByVal base)
    Dim rs, sb, primero, imgDef, src, img
    sb = "["
    primero = True
    imgDef = base & "resources/AlbumImages/album1.png"

    Set rs = EjecutarConsulta(sql)
    If RsValido(rs) Then
        Do While Not rs.EOF
            src = ResolverRecurso(rs("SONG_PATH"), base)
            img = ResolverRecurso(rs("IMG"), base)
            If img = "" Then img = imgDef

            If Not primero Then sb = sb & ","
            primero = False

            sb = sb & "{""uid"":""" & EscInt(rs("ID_SONG")) & """," & _
                      """nombre"":""" & Js(rs("SONG_NAME")) & """," & _
                      """artista"":""" & Js(rs("ARTISTA")) & """," & _
                      """album"":""" & Js(rs("ALBUM")) & """," & _
                      """src"":""" & Js(src) & """," & _
                      """img"":""" & Js(img) & """}"

            rs.MoveNext
        Loop
        rs.Close
        Set rs = Nothing
    End If

    sb = sb & "]"
    ConstruirColaJson = sb
End Function
%>
<%
strScriptExtra = ""
%>
<!--#include virtual="/polimusic/_includes/layout_inferior.asp"-->
