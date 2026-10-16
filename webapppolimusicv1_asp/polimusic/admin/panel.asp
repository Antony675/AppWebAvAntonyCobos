<%
'==================================================================================
' PoliMusic - Panel de Administracion
' Archivo: admin/panel.asp
' Descripcion: Consola exclusiva del rol Administrador. Expone las operaciones de
'              Lectura, Actualizacion y Eliminacion (RUD) sobre Usuarios,
'              Canciones, Artistas, Albumes, Playlists y Catalogos.
'==================================================================================
%>
<!--#include virtual="/polimusic/_includes/config.asp"-->
<!--#include virtual="/polimusic/_includes/conexion.asp"-->
<!--#include virtual="/polimusic/_includes/sesion.asp"-->
<!--#include virtual="/polimusic/_includes/consultas.asp"-->
<!--#include virtual="/polimusic/_includes/iconos.asp"-->
<%
EnviarCabecerasNoCache
RequerirAdmin

Dim strTitulo, strSubtitulo, strVistaActiva, strScriptExtra
strTitulo = "Administracion"
strSubtitulo = "Gestion del catalogo PoliMusic"
strVistaActiva = ""
strScriptExtra = "admin.js"

Dim msgSistema, tipoMsg
msgSistema = ""
tipoMsg = "ok"
If Request.QueryString("msg") <> "" Then msgSistema = Request.QueryString("msg")
If Request.QueryString("tipo") <> "" Then tipoMsg = Request.QueryString("tipo")
%>
<!--#include virtual="/polimusic/_includes/layout_superior.asp"-->
<%
' NOTA: 'strBase' ya queda declarada (Dim) dentro de layout_superior.asp, que se
' acaba de incluir. Redeclararla aqui provocaria el error de compilacion
' VBScript "Name redefined" (HTTP 500).
If strBase = "" Then strBase = URL_BASE

'----------------------------------------------------------------------------------
' Metricas del sistema para el encabezado del panel
'----------------------------------------------------------------------------------
Dim nUsuarios, nCanciones, nAlbumes, nArtistas, nPlaylists
nUsuarios  = ContarRegistros("tbl_user")
nCanciones = ContarRegistros("tbl_song")
nAlbumes   = ContarRegistros("tbl_album")
nArtistas  = ContarRegistros("tbl_artist")
nPlaylists = ContarRegistros("tbl_playlist")
%>
<div id="pmAdminRoot">

    <div class="pm-admin-head">
        <div>
            <div class="pm-hero__kind">Consola de administracion</div>
            <div class="pm-admin-head__title">Panel de control</div>
            <div class="pm-admin-head__sub">
                Operaciones de lectura, actualizacion y eliminacion sobre las entidades del sistema.
            </div>
        </div>
        <div style="display:flex;gap:10px;flex-wrap:wrap;">
            <%
            Dim metricas(4,1), i
            metricas(0,0) = "Usuarios"  : metricas(0,1) = nUsuarios
            metricas(1,0) = "Canciones" : metricas(1,1) = nCanciones
            metricas(2,0) = "Albumes"   : metricas(2,1) = nAlbumes
            metricas(3,0) = "Artistas"  : metricas(3,1) = nArtistas
            metricas(4,0) = "Playlists" : metricas(4,1) = nPlaylists
            For i = 0 To 4
            %>
            <div style="padding:12px 18px;background:var(--pm-bg-card);border:1px solid var(--pm-border);border-radius:var(--pm-radius-md);min-width:96px;">
                <div style="font-size:22px;font-weight:800;letter-spacing:-.02em;"><%=EscInt(metricas(i,1))%></div>
                <div style="font-size:10.5px;letter-spacing:.08em;text-transform:uppercase;color:var(--pm-text-muted);"><%=H(metricas(i,0))%></div>
            </div>
            <% Next %>
        </div>
    </div>

    <% If msgSistema <> "" Then %>
    <div style="padding:20px 24px 0;">
        <div class="pm-alert <%=IIf(tipoMsg = "error", "pm-alert--error", "pm-alert--success")%>" role="<%=IIf(tipoMsg = "error", "alert", "status")%>">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <% If tipoMsg = "error" Then %>
                <circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16h.01"/>
                <% Else %>
                <path d="M20 6 9 17l-5-5"/>
                <% End If %>
            </svg>
            <span><%=H(msgSistema)%></span>
        </div>
    </div>
    <% End If %>

    <!-- ===================== PESTANAS ===================== -->
    <nav class="pm-tabs">
        <button class="pm-tab is-active" type="button" data-panel="usuarios">Usuarios</button>
        <button class="pm-tab" type="button" data-panel="canciones">Canciones</button>
        <button class="pm-tab" type="button" data-panel="artistas">Artistas</button>
        <button class="pm-tab" type="button" data-panel="albumes">Albumes</button>
        <button class="pm-tab" type="button" data-panel="playlists">Playlists</button>
        <button class="pm-tab" type="button" data-panel="catalogos">Catalogos</button>
    </nav>

    <!-- =================================================================================
         PANEL: USUARIOS
         ================================================================================= -->
    <section class="pm-panel is-active" id="panel-usuarios">
        <div class="pm-toolbar">
            <div class="pm-toolbar__count">Lectura de los <%=EscInt(nUsuarios)%> usuarios registrados. La actualizacion permite cambiar rol y datos de contacto.</div>
            <div class="pm-toolbar__actions">
                <input class="pm-input--text" type="search" placeholder="Filtrar usuarios" data-filtro-tabla="tabla-usuarios" style="width:220px;">
            </div>
        </div>

        <div class="pm-table-wrap">
            <table class="pm-table" id="tabla-usuarios">
                <thead>
                    <tr>
                        <th style="width:60px;">ID</th>
                        <th>Usuario</th>
                        <th>Correo</th>
                        <th>Cumpleanos</th>
                        <th>Rol</th>
                        <th>Playlists</th>
                        <th style="width:120px;text-align:right;">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    Dim rsU
                    Set rsU = ListarUsuarios()
                    If RsValido(rsU) Then
                            Do While Not rsU.EOF
                                Dim uId, uNombre, uMail, uCumple, uRolTxt, uFoto, uTipoVal, uPl
                                uId = EscInt(rsU("ID_USER"))
                                uNombre = CStr(rsU("USERNAME"))
                                uMail = CStr(rsU("EMAIL"))
                                uCumple = ""
                                If Not IsNull(rsU("BIRTHDAY")) Then uCumple = Year(rsU("BIRTHDAY")) & "-" & Right("0" & Month(rsU("BIRTHDAY")), 2) & "-" & Right("0" & Day(rsU("BIRTHDAY")), 2)
                                uTipoVal = EscInt(rsU("USER_TYPE"))
                                If uTipoVal = USER_TYPE_ADMIN Then uRolTxt = "Administrador" Else uRolTxt = "Estandar"
                                uFoto = ImagenSegura(rsU("USER_PHOTO"), strBase, "UserImages", "default.jpg")
                                uPl = EscInt(rsU("TOTAL_PLAYLISTS"))
                    %>
                    <tr data-fila-tabla data-texto="<%=H(uNombre & " " & uMail & " " & uRolTxt)%>">
                        <td class="pm-table__id"><%=uId%></td>
                        <td>
                            <div style="display:flex;align-items:center;gap:11px;">
                                <img class="pm-table__mini" src="<%=H(uFoto)%>" alt="" loading="lazy">
                                <span class="pm-strong"><%=H(uNombre)%></span>
                            </div>
                        </td>
                        <td><%=H(uMail)%></td>
                        <td><%=H(uCumple)%></td>
                        <td>
                            <% If uTipoVal = USER_TYPE_ADMIN Then %>
                            <span class="pm-badge-admin"><%=Ico("escudo")%>Admin</span>
                            <% Else %>
                            <span class="pm-card__tag" style="margin:0;">Estandar</span>
                            <% End If %>
                        </td>
                        <td><%=uPl%></td>
                        <td>
                            <div class="pm-table__actions">
                                <button class="pm-ico-btn" type="button" title="Actualizar usuario"
                                        data-editar
                                        data-modal="modal-usuario"
                                        data-campos='{"id":"<%=uId%>","username":"<%=Js(uNombre)%>","email":"<%=Js(uMail)%>","birthday":"<%=uCumple%>","user_type":"<%=uTipoVal%>","password":""}'>
                                    <%=Ico("editar")%>
                                </button>
                                <form method="post" action="procesar.asp" style="display:inline;" data-confirmar-envio="Confirma la eliminacion del usuario &quot;<%=H(uNombre)%>&quot;? Esta accion no se puede deshacer.">
                                    <input type="hidden" name="accion" value="eliminar">
                                    <input type="hidden" name="entidad" value="tbl_user">
                                    <input type="hidden" name="id" value="<%=uId%>">
                                    <input type="hidden" name="tab" value="usuarios">
                                    <input type="hidden" name="token" value="<%=TokenActual()%>">
                                    <button class="pm-ico-btn pm-ico-btn--danger" type="submit" title="Eliminar usuario"><%=Ico("eliminar")%></button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <%
                                rsU.MoveNext
                            Loop
                            rsU.Close
                        Set rsU = Nothing
                    End If
                    %>
                </tbody>
            </table>
        </div>
    </section>

    <!-- =================================================================================
         PANEL: CANCIONES
         ================================================================================= -->
    <section class="pm-panel" id="panel-canciones">
        <div class="pm-toolbar">
            <div class="pm-toolbar__count">Catalogo de audio. La ruta debe apuntar a un archivo presente en <b>resources/SongFiles</b>.</div>
            <div class="pm-toolbar__actions">
                <input class="pm-input--text" type="search" placeholder="Filtrar canciones" data-filtro-tabla="tabla-canciones" style="width:220px;">
            </div>
        </div>

        <div class="pm-table-wrap">
            <table class="pm-table" id="tabla-canciones">
                <thead>
                    <tr>
                        <th style="width:60px;">ID</th>
                        <th>Nombre</th>
                        <th>Ruta del archivo</th>
                        <th>Artista</th>
                        <th>Album</th>
                        <th style="width:110px;">Reproducciones</th>
                        <th style="width:120px;text-align:right;">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    Dim rsCS
                    Set rsCS = ListarCanciones()
                    If RsValido(rsCS) Then
                            Do While Not rsCS.EOF
                                Dim cId, cNom, cRut, cArt, cAlb, cPly
                                cId = EscInt(rsCS("ID_SONG"))
                                cNom = CStr(rsCS("SONG_NAME"))
                                cRut = CStr(rsCS("SONG_PATH"))
                                cArt = CStr(rsCS("ARTISTA"))
                                cAlb = CStr(rsCS("ALBUM"))
                                cPly = EscInt(rsCS("PLAYS"))
                    %>
                    <tr data-fila-tabla data-texto="<%=H(cNom & " " & cArt & " " & cAlb)%>">
                        <td class="pm-table__id"><%=cId%></td>
                        <td><span class="pm-strong"><%=H(cNom)%></span></td>
                        <td style="font-family:Consolas,monospace;font-size:12px;"><%=H(cRut)%></td>
                        <td><%=H(cArt)%></td>
                        <td><%=H(cAlb)%></td>
                        <td><%=cPly%></td>
                        <td>
                            <div class="pm-table__actions">
                                <button class="pm-ico-btn" type="button" title="Previsualizar audio"
                                        onclick="PoliMusic.reproductor.cargarCola([{uid:'<%=cId%>',nombre:'<%=Js(cNom)%>',artista:'<%=Js(cArt)%>',album:'<%=Js(cAlb)%>',src:'<%=Js(ResolverRecurso(cRut, strBase))%>',img:'<%=Js(ImagenSegura("", strBase, "AlbumImages", "album1.png"))%>'}],'<%=cId%>','admin',true);">
                                    <%=Ico("reproducir")%>
                                </button>
                                <button class="pm-ico-btn" type="button" title="Actualizar cancion"
                                        data-editar
                                        data-modal="modal-cancion"
                                        data-campos='{"id":"<%=cId%>","song_name":"<%=Js(cNom)%>","song_path":"<%=Js(cRut)%>","plays":"<%=cPly%>"}'>
                                    <%=Ico("editar")%>
                                </button>
                                <form method="post" action="procesar.asp" style="display:inline;" data-confirmar-envio="Confirma la eliminacion de la cancion &quot;<%=H(cNom)%>&quot;? Se eliminaran tambien sus relaciones con albumes y playlists.">
                                    <input type="hidden" name="accion" value="eliminar">
                                    <input type="hidden" name="entidad" value="tbl_song">
                                    <input type="hidden" name="id" value="<%=cId%>">
                                    <input type="hidden" name="tab" value="canciones">
                                    <input type="hidden" name="token" value="<%=TokenActual()%>">
                                    <button class="pm-ico-btn pm-ico-btn--danger" type="submit" title="Eliminar cancion"><%=Ico("eliminar")%></button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <%
                                rsCS.MoveNext
                            Loop
                            rsCS.Close
                        Set rsCS = Nothing
                    End If
                    %>
                </tbody>
            </table>
        </div>
    </section>

    <!-- =================================================================================
         PANEL: ARTISTAS
         ================================================================================= -->
    <section class="pm-panel" id="panel-artistas">
        <div class="pm-toolbar">
            <div class="pm-toolbar__count">Interpretes del catalogo. La imagen debe existir en <b>resources/ArtistImages</b>.</div>
            <div class="pm-toolbar__actions">
                <input class="pm-input--text" type="search" placeholder="Filtrar artistas" data-filtro-tabla="tabla-artistas" style="width:220px;">
            </div>
        </div>

        <div class="pm-table-wrap">
            <table class="pm-table" id="tabla-artistas">
                <thead>
                    <tr>
                        <th style="width:60px;">ID</th>
                        <th>Artista</th>
                        <th>Imagen</th>
                        <th style="width:110px;">Canciones</th>
                        <th style="width:120px;text-align:right;">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    Dim rsAR
                    Set rsAR = ListarArtistas()
                    If RsValido(rsAR) Then
                            Do While Not rsAR.EOF
                                Dim rId, rNom, rApe, rImg, rImgFull, rTot
                                rId = EscInt(rsAR("ID_ARTIST"))
                                rNom = CStr(rsAR("ARTIST_NAME"))
                                rApe = ""
                                If Not IsNull(rsAR("ARTIST_LASTNAME")) Then rApe = CStr(rsAR("ARTIST_LASTNAME"))
                                rImg = ""
                                If Not IsNull(rsAR("ARTIST_IMAGE")) Then rImg = CStr(rsAR("ARTIST_IMAGE"))
                                rImgFull = ImagenSegura(rImg, strBase, "ArtistImages", "artist1.jpg")
                                rTot = EscInt(rsAR("TOTAL_SONGS"))
                    %>
                    <tr data-fila-tabla data-texto="<%=H(rNom & " " & rApe)%>">
                        <td class="pm-table__id"><%=rId%></td>
                        <td><span class="pm-strong"><%=H(Trim(rNom & " " & rApe))%></span></td>
                        <td>
                            <div style="display:flex;align-items:center;gap:11px;">
                                <img class="pm-table__mini" style="border-radius:50%;" src="<%=H(rImgFull)%>" alt="" loading="lazy">
                                <span style="font-family:Consolas,monospace;font-size:11.5px;"><%=H(rImg)%></span>
                            </div>
                        </td>
                        <td><%=rTot%></td>
                        <td>
                            <div class="pm-table__actions">
                                <button class="pm-ico-btn" type="button" title="Actualizar artista"
                                        data-editar
                                        data-modal="modal-artista"
                                        data-campos='{"id":"<%=rId%>","artist_name":"<%=Js(rNom)%>","artist_lastname":"<%=Js(rApe)%>","artist_image":"<%=Js(rImg)%>"}'>
                                    <%=Ico("editar")%>
                                </button>
                                <form method="post" action="procesar.asp" style="display:inline;" data-confirmar-envio="Confirma la eliminacion del artista &quot;<%=H(Trim(rNom & " " & rApe))%>&quot;? Se eliminaran sus asociaciones con canciones.">
                                    <input type="hidden" name="accion" value="eliminar">
                                    <input type="hidden" name="entidad" value="tbl_artist">
                                    <input type="hidden" name="id" value="<%=rId%>">
                                    <input type="hidden" name="tab" value="artistas">
                                    <input type="hidden" name="token" value="<%=TokenActual()%>">
                                    <button class="pm-ico-btn pm-ico-btn--danger" type="submit" title="Eliminar artista"><%=Ico("eliminar")%></button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <%
                                rsAR.MoveNext
                            Loop
                            rsAR.Close
                        Set rsAR = Nothing
                    End If
                    %>
                </tbody>
            </table>
        </div>
    </section>

    <!-- =================================================================================
         PANEL: ALBUMES
         ================================================================================= -->
    <section class="pm-panel" id="panel-albumes">
        <div class="pm-toolbar">
            <div class="pm-toolbar__count">Colecciones del catalogo. La caratula debe existir en <b>resources/AlbumImages</b>.</div>
            <div class="pm-toolbar__actions">
                <input class="pm-input--text" type="search" placeholder="Filtrar albumes" data-filtro-tabla="tabla-albumes" style="width:220px;">
            </div>
        </div>

        <div class="pm-table-wrap">
            <table class="pm-table" id="tabla-albumes">
                <thead>
                    <tr>
                        <th style="width:60px;">ID</th>
                        <th>Titulo</th>
                        <th>Caratula</th>
                        <th style="width:110px;">Anio</th>
                        <th style="width:110px;">Pistas</th>
                        <th style="width:120px;text-align:right;">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    Dim rsAL
                    Set rsAL = ListarAlbumes()
                    If RsValido(rsAL) Then
                            Do While Not rsAL.EOF
                                Dim lId, lTit, lAnio, lImg, lImgFull, lTrk
                                lId = EscInt(rsAL("ID_ALBUM"))
                                lTit = CStr(rsAL("TITLE_ALBUM"))
                                lAnio = ""
                                If Not IsNull(rsAL("RELEASE_YEAR")) Then lAnio = CStr(rsAL("RELEASE_YEAR"))
                                lImg = ""
                                If Not IsNull(rsAL("ALBUM_IMAGE_PATH")) Then lImg = CStr(rsAL("ALBUM_IMAGE_PATH"))
                                lImgFull = ImagenSegura(lImg, strBase, "AlbumImages", "album1.png")
                                lTrk = EscInt(rsAL("TOTAL_TRACKS"))
                    %>
                    <tr data-fila-tabla data-texto="<%=H(lTit & " " & lAnio)%>">
                        <td class="pm-table__id"><%=lId%></td>
                        <td><span class="pm-strong"><%=H(lTit)%></span></td>
                        <td>
                            <div style="display:flex;align-items:center;gap:11px;">
                                <img class="pm-table__mini" src="<%=H(lImgFull)%>" alt="" loading="lazy">
                                <span style="font-family:Consolas,monospace;font-size:11.5px;"><%=H(lImg)%></span>
                            </div>
                        </td>
                        <td><%=H(lAnio)%></td>
                        <td><%=lTrk%></td>
                        <td>
                            <div class="pm-table__actions">
                                <button class="pm-ico-btn" type="button" title="Actualizar album"
                                        data-editar
                                        data-modal="modal-album"
                                        data-campos='{"id":"<%=lId%>","title_album":"<%=Js(lTit)%>","release_year":"<%=H(lAnio)%>","album_image_path":"<%=Js(lImg)%>"}'>
                                    <%=Ico("editar")%>
                                </button>
                                <form method="post" action="procesar.asp" style="display:inline;" data-confirmar-envio="Confirma la eliminacion del album &quot;<%=H(lTit)%>&quot;? Se eliminara su lista de pistas.">
                                    <input type="hidden" name="accion" value="eliminar">
                                    <input type="hidden" name="entidad" value="tbl_album">
                                    <input type="hidden" name="id" value="<%=lId%>">
                                    <input type="hidden" name="tab" value="albumes">
                                    <input type="hidden" name="token" value="<%=TokenActual()%>">
                                    <button class="pm-ico-btn pm-ico-btn--danger" type="submit" title="Eliminar album"><%=Ico("eliminar")%></button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <%
                                rsAL.MoveNext
                            Loop
                            rsAL.Close
                        Set rsAL = Nothing
                    End If
                    %>
                </tbody>
            </table>
        </div>
    </section>

    <!-- =================================================================================
         PANEL: PLAYLISTS
         ================================================================================= -->
    <section class="pm-panel" id="panel-playlists">
        <div class="pm-toolbar">
            <div class="pm-toolbar__count">Vista completa del catalogo de playlists de todos los usuarios.</div>
            <div class="pm-toolbar__actions">
                <input class="pm-input--text" type="search" placeholder="Filtrar playlists" data-filtro-tabla="tabla-playlists" style="width:220px;">
            </div>
        </div>

        <div class="pm-table-wrap">
            <table class="pm-table" id="tabla-playlists">
                <thead>
                    <tr>
                        <th style="width:60px;">ID</th>
                        <th>Titulo</th>
                        <th>Propietario</th>
                        <th>Tipo</th>
                        <th>Creada</th>
                        <th style="width:110px;">Pistas</th>
                        <th style="width:120px;text-align:right;">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    Dim rsPLA
                    Set rsPLA = ListarTodasLasPlaylists()
                    If RsValido(rsPLA) Then
                            Do While Not rsPLA.EOF
                                Dim pId, pTit, pProp, pTipoVal, pTipoTxt, pFec, pFoto, pTot
                                pId = EscInt(rsPLA("ID_PLAYLIST"))
                                pTit = CStr(rsPLA("TITLE"))
                                pProp = CStr(rsPLA("PROPIETARIO"))
                                pTipoVal = EscInt(rsPLA("TYPE"))
                                If pTipoVal = PLAYLIST_TYPE_PRIVATE Then pTipoTxt = "Privada" Else pTipoTxt = "Publica"
                                pFec = ""
                                If Not IsNull(rsPLA("CREATION_DATE")) Then pFec = Year(rsPLA("CREATION_DATE")) & "-" & Right("0" & Month(rsPLA("CREATION_DATE")), 2) & "-" & Right("0" & Day(rsPLA("CREATION_DATE")), 2)
                                pFoto = ""
                                If Not IsNull(rsPLA("PHOTO")) Then pFoto = CStr(rsPLA("PHOTO"))
                                pTot = EscInt(rsPLA("TOTAL_SONGS"))
                    %>
                    <tr data-fila-tabla data-texto="<%=H(pTit & " " & pProp & " " & pTipoTxt)%>">
                        <td class="pm-table__id"><%=pId%></td>
                        <td>
                            <div style="display:flex;align-items:center;gap:11px;">
                                <img class="pm-table__mini" src="<%=H(ImagenSegura(pFoto, strBase, "PlaylistImages", "default.jpg"))%>" alt="" loading="lazy">
                                <span class="pm-strong"><%=H(pTit)%></span>
                            </div>
                        </td>
                        <td><%=H(pProp)%></td>
                        <td>
                            <span class="pm-card__tag" style="margin:0;<%=IIf(pTipoVal = PLAYLIST_TYPE_PRIVATE, "background:rgba(255,164,43,.16);color:#ffa42b;", "")%>">
                                <%=H(pTipoTxt)%>
                            </span>
                        </td>
                        <td><%=H(pFec)%></td>
                        <td><%=pTot%></td>
                        <td>
                            <div class="pm-table__actions">
                                <button class="pm-ico-btn" type="button" title="Actualizar playlist"
                                        data-editar
                                        data-modal="modal-playlist"
                                        data-campos='{"id":"<%=pId%>","title":"<%=Js(pTit)%>","id_user":"<%=EscInt(rsPLA("ID_USER"))%>","type":"<%=pTipoVal%>","photo":"<%=Js(pFoto)%>","creation_date":"<%=H(pFec)%>"}'>
                                    <%=Ico("editar")%>
                                </button>
                                <form method="post" action="procesar.asp" style="display:inline;" data-confirmar-envio="Confirma la eliminacion de la playlist &quot;<%=H(pTit)%>&quot;? Se eliminara su contenido asociado.">
                                    <input type="hidden" name="accion" value="eliminar">
                                    <input type="hidden" name="entidad" value="tbl_playlist">
                                    <input type="hidden" name="id" value="<%=pId%>">
                                    <input type="hidden" name="tab" value="playlists">
                                    <input type="hidden" name="token" value="<%=TokenActual()%>">
                                    <button class="pm-ico-btn pm-ico-btn--danger" type="submit" title="Eliminar playlist"><%=Ico("eliminar")%></button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <%
                                rsPLA.MoveNext
                            Loop
                            rsPLA.Close
                        Set rsPLA = Nothing
                    End If
                    %>
                </tbody>
            </table>
        </div>
    </section>

    <!-- =================================================================================
         PANEL: CATALOGOS
         ================================================================================= -->
    <section class="pm-panel" id="panel-catalogos">
        <div class="pm-toolbar">
            <div class="pm-toolbar__count">Tabla maestra de valores parametricos (tipos de usuario y de playlist).</div>
            <div class="pm-toolbar__actions">
                <input class="pm-input--text" type="search" placeholder="Filtrar catalogos" data-filtro-tabla="tabla-catalogos" style="width:220px;">
            </div>
        </div>

        <div class="pm-table-wrap">
            <table class="pm-table" id="tabla-catalogos">
                <thead>
                    <tr>
                        <th style="width:60px;">ID</th>
                        <th style="width:150px;">Codigo padre</th>
                        <th style="width:130px;">Codigo</th>
                        <th>Valor</th>
                        <th style="width:120px;text-align:right;">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    Dim rsCAT
                    Set rsCAT = ListarTodosLosCatalogos()
                    If RsValido(rsCAT) Then
                            Do While Not rsCAT.EOF
                                Dim kId, kPadre, kCod, kVal
                                kId = EscInt(rsCAT("ID_CATALOG"))
                                kPadre = "" : If Not IsNull(rsCAT("COD_CATALOG_PARENT")) Then kPadre = CStr(rsCAT("COD_CATALOG_PARENT"))
                                kCod = ""   : If Not IsNull(rsCAT("COD_CATALOG")) Then kCod = CStr(rsCAT("COD_CATALOG"))
                                kVal = CStr(rsCAT("VALUE"))
                    %>
                    <tr data-fila-tabla data-texto="<%=H(kPadre & " " & kCod & " " & kVal)%>">
                        <td class="pm-table__id"><%=kId%></td>
                        <td style="font-family:Consolas,monospace;"><%=H(kPadre)%></td>
                        <td style="font-family:Consolas,monospace;"><%=H(kCod)%></td>
                        <td><span class="pm-strong"><%=H(kVal)%></span></td>
                        <td>
                            <div class="pm-table__actions">
                                <button class="pm-ico-btn" type="button" title="Actualizar entrada"
                                        data-editar
                                        data-modal="modal-catalogo"
                                        data-campos='{"id":"<%=kId%>","cod_catalog_parent":"<%=Js(kPadre)%>","cod_catalog":"<%=Js(kCod)%>","value":"<%=Js(kVal)%>"}'>
                                    <%=Ico("editar")%>
                                </button>
                                <form method="post" action="procesar.asp" style="display:inline;" data-confirmar-envio="Confirma la eliminacion de la entrada &quot;<%=H(kVal)%>&quot;?">
                                    <input type="hidden" name="accion" value="eliminar">
                                    <input type="hidden" name="entidad" value="tbl_catalog">
                                    <input type="hidden" name="id" value="<%=kId%>">
                                    <input type="hidden" name="tab" value="catalogos">
                                    <input type="hidden" name="token" value="<%=TokenActual()%>">
                                    <button class="pm-ico-btn pm-ico-btn--danger" type="submit" title="Eliminar entrada"><%=Ico("eliminar")%></button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <%
                                rsCAT.MoveNext
                            Loop
                            rsCAT.Close
                        Set rsCAT = Nothing
                    End If
                    %>
                </tbody>
            </table>
        </div>
    </section>

</div><!-- /#pmAdminRoot -->
<%
' =================================================================================
' MODALES DE ACTUALIZACION
' Cada modal se rellena dinamicamente desde los atributos data-campos de la fila.
' =================================================================================
%>

<!-- Modal: Usuario -->
<div class="pm-modal-backdrop" id="modal-usuario" role="dialog" aria-modal="true" aria-labelledby="titulo-modal-usuario">
    <div class="pm-modal">
        <div class="pm-modal__head">
            <div class="pm-modal__title" id="titulo-modal-usuario">Actualizar usuario</div>
            <button class="pm-ico-btn" type="button" data-cerrar-modal="modal-usuario" title="Cerrar"><%=Ico("cerrar")%></button>
        </div>
        <form method="post" action="procesar.asp">
            <div class="pm-modal__body">
                <input type="hidden" name="accion" value="actualizar">
                <input type="hidden" name="entidad" value="tbl_user">
                <input type="hidden" name="tab" value="usuarios">
                <input type="hidden" name="token" value="<%=TokenActual()%>">
                <input type="hidden" name="id" value="">

                <div class="pm-form-grid">
                    <div>
                        <label class="pm-field__label" for="u-username">Nombre de usuario</label>
                        <input class="pm-input--text" id="u-username" name="username" type="text" maxlength="50" required>
                    </div>
                    <div>
                        <label class="pm-field__label" for="u-email">Correo electronico</label>
                        <input class="pm-input--text" id="u-email" name="email" type="email" maxlength="50" required>
                    </div>
                    <div class="pm-form-grid pm-form-grid--2" style="gap:15px;">
                        <div>
                            <label class="pm-field__label" for="u-birthday">Fecha de nacimiento</label>
                            <input class="pm-input--text" id="u-birthday" name="birthday" type="date">
                        </div>
                        <div>
                            <label class="pm-field__label" for="u-rol">Rol</label>
                            <select class="pm-input--text" id="u-rol" name="user_type" required>
                                <option value="0">Estandar</option>
                                <option value="1">Administrador</option>
                            </select>
                        </div>
                    </div>
                    <div>
                        <label class="pm-field__label" for="u-password">Contrasena (dejar vacio para conservar la actual)</label>
                        <input class="pm-input--text" id="u-password" name="password" type="text" maxlength="50" placeholder="Sin cambios">
                    </div>
                </div>
            </div>
            <div class="pm-modal__foot">
                <button class="pm-btn pm-btn--ghost pm-btn--sm" type="button" data-cerrar-modal="modal-usuario">Cancelar</button>
                <button class="pm-btn pm-btn--primary pm-btn--sm" type="submit"><%=Ico("check")%>Guardar cambios</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: Cancion -->
<div class="pm-modal-backdrop" id="modal-cancion" role="dialog" aria-modal="true" aria-labelledby="titulo-modal-cancion">
    <div class="pm-modal">
        <div class="pm-modal__head">
            <div class="pm-modal__title" id="titulo-modal-cancion">Actualizar cancion</div>
            <button class="pm-ico-btn" type="button" data-cerrar-modal="modal-cancion" title="Cerrar"><%=Ico("cerrar")%></button>
        </div>
        <form method="post" action="procesar.asp">
            <div class="pm-modal__body">
                <input type="hidden" name="accion" value="actualizar">
                <input type="hidden" name="entidad" value="tbl_song">
                <input type="hidden" name="tab" value="canciones">
                <input type="hidden" name="token" value="<%=TokenActual()%>">
                <input type="hidden" name="id" value="">

                <div class="pm-form-grid">
                    <div>
                        <label class="pm-field__label" for="c-nombre">Nombre de la cancion</label>
                        <input class="pm-input--text" id="c-nombre" name="song_name" type="text" maxlength="50" required>
                    </div>
                    <div>
                        <label class="pm-field__label" for="c-ruta">Ruta del archivo de audio</label>
                        <input class="pm-input--text" id="c-ruta" name="song_path" type="text" maxlength="255" required placeholder="~/songFiles/archivo.mp3">
                        <div style="font-size:11.5px;color:var(--pm-text-muted);margin-top:6px;">
                            Archivos disponibles: bensound-adventure.mp3, bensound-dreams.mp3, bensound-energy.mp3, bensound-scifi.mp3, bensound-tomorrow.mp3
                        </div>
                    </div>
                    <div>
                        <label class="pm-field__label" for="c-plays">Reproducciones acumuladas</label>
                        <input class="pm-input--text" id="c-plays" name="plays" type="number" min="0" value="0">
                    </div>
                </div>
            </div>
            <div class="pm-modal__foot">
                <button class="pm-btn pm-btn--ghost pm-btn--sm" type="button" data-cerrar-modal="modal-cancion">Cancelar</button>
                <button class="pm-btn pm-btn--primary pm-btn--sm" type="submit"><%=Ico("check")%>Guardar cambios</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: Artista -->
<div class="pm-modal-backdrop" id="modal-artista" role="dialog" aria-modal="true" aria-labelledby="titulo-modal-artista">
    <div class="pm-modal">
        <div class="pm-modal__head">
            <div class="pm-modal__title" id="titulo-modal-artista">Actualizar artista</div>
            <button class="pm-ico-btn" type="button" data-cerrar-modal="modal-artista" title="Cerrar"><%=Ico("cerrar")%></button>
        </div>
        <form method="post" action="procesar.asp">
            <div class="pm-modal__body">
                <input type="hidden" name="accion" value="actualizar">
                <input type="hidden" name="entidad" value="tbl_artist">
                <input type="hidden" name="tab" value="artistas">
                <input type="hidden" name="token" value="<%=TokenActual()%>">
                <input type="hidden" name="id" value="">

                <div class="pm-form-grid">
                    <div class="pm-form-grid pm-form-grid--2" style="gap:15px;">
                        <div>
                            <label class="pm-field__label" for="a-nombre">Nombre</label>
                            <input class="pm-input--text" id="a-nombre" name="artist_name" type="text" maxlength="100" required>
                        </div>
                        <div>
                            <label class="pm-field__label" for="a-apellido">Apellido</label>
                            <input class="pm-input--text" id="a-apellido" name="artist_lastname" type="text" maxlength="100">
                        </div>
                    </div>
                    <div>
                        <label class="pm-field__label" for="a-imagen">Ruta de la imagen</label>
                        <input class="pm-input--text" id="a-imagen" name="artist_image" type="text" maxlength="255" placeholder="~/ArtistImages/artist1.jpg">
                    </div>
                </div>
            </div>
            <div class="pm-modal__foot">
                <button class="pm-btn pm-btn--ghost pm-btn--sm" type="button" data-cerrar-modal="modal-artista">Cancelar</button>
                <button class="pm-btn pm-btn--primary pm-btn--sm" type="submit"><%=Ico("check")%>Guardar cambios</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: Album -->
<div class="pm-modal-backdrop" id="modal-album" role="dialog" aria-modal="true" aria-labelledby="titulo-modal-album">
    <div class="pm-modal">
        <div class="pm-modal__head">
            <div class="pm-modal__title" id="titulo-modal-album">Actualizar album</div>
            <button class="pm-ico-btn" type="button" data-cerrar-modal="modal-album" title="Cerrar"><%=Ico("cerrar")%></button>
        </div>
        <form method="post" action="procesar.asp">
            <div class="pm-modal__body">
                <input type="hidden" name="accion" value="actualizar">
                <input type="hidden" name="entidad" value="tbl_album">
                <input type="hidden" name="tab" value="albumes">
                <input type="hidden" name="token" value="<%=TokenActual()%>">
                <input type="hidden" name="id" value="">

                <div class="pm-form-grid">
                    <div class="pm-form-grid pm-form-grid--2" style="gap:15px;">
                        <div>
                            <label class="pm-field__label" for="l-titulo">Titulo del album</label>
                            <input class="pm-input--text" id="l-titulo" name="title_album" type="text" maxlength="50" required>
                        </div>
                        <div>
                            <label class="pm-field__label" for="l-anio">Anio de publicacion</label>
                            <input class="pm-input--text" id="l-anio" name="release_year" type="number" min="1900" max="2100">
                        </div>
                    </div>
                    <div>
                        <label class="pm-field__label" for="l-imagen">Ruta de la caratula</label>
                        <input class="pm-input--text" id="l-imagen" name="album_image_path" type="text" maxlength="255" placeholder="~/albumImages/album1.png">
                    </div>
                </div>
            </div>
            <div class="pm-modal__foot">
                <button class="pm-btn pm-btn--ghost pm-btn--sm" type="button" data-cerrar-modal="modal-album">Cancelar</button>
                <button class="pm-btn pm-btn--primary pm-btn--sm" type="submit"><%=Ico("check")%>Guardar cambios</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: Playlist -->
<div class="pm-modal-backdrop" id="modal-playlist" role="dialog" aria-modal="true" aria-labelledby="titulo-modal-playlist">
    <div class="pm-modal">
        <div class="pm-modal__head">
            <div class="pm-modal__title" id="titulo-modal-playlist">Actualizar playlist</div>
            <button class="pm-ico-btn" type="button" data-cerrar-modal="modal-playlist" title="Cerrar"><%=Ico("cerrar")%></button>
        </div>
        <form method="post" action="procesar.asp">
            <div class="pm-modal__body">
                <input type="hidden" name="accion" value="actualizar">
                <input type="hidden" name="entidad" value="tbl_playlist">
                <input type="hidden" name="tab" value="playlists">
                <input type="hidden" name="token" value="<%=TokenActual()%>">
                <input type="hidden" name="id" value="">

                <div class="pm-form-grid">
                    <div>
                        <label class="pm-field__label" for="p-titulo">Titulo</label>
                        <input class="pm-input--text" id="p-titulo" name="title" type="text" maxlength="50" required>
                    </div>
                    <div class="pm-form-grid pm-form-grid--2" style="gap:15px;">
                        <div>
                            <label class="pm-field__label" for="p-propietario">Propietario</label>
                            <select class="pm-input--text" id="p-propietario" name="id_user" required>
                                <%
                                Dim rsSelU
                                Set rsSelU = ListarUsuarios()
                                If RsValido(rsSelU) Then
                                        Do While Not rsSelU.EOF
                                %>
                                <option value="<%=EscInt(rsSelU("ID_USER"))%>"><%=H(rsSelU("USERNAME"))%></option>
                                <%
                                            rsSelU.MoveNext
                                        Loop
                                        rsSelU.Close
                                    Set rsSelU = Nothing
                                End If
                                %>
                            </select>
                        </div>
                        <div>
                            <label class="pm-field__label" for="p-tipo">Visibilidad</label>
                            <select class="pm-input--text" id="p-tipo" name="type" required>
                                <option value="0">Publica</option>
                                <option value="1">Privada</option>
                            </select>
                        </div>
                    </div>
                    <div class="pm-form-grid pm-form-grid--2" style="gap:15px;">
                        <div>
                            <label class="pm-field__label" for="p-fecha">Fecha de creacion</label>
                            <input class="pm-input--text" id="p-fecha" name="creation_date" type="date">
                        </div>
                        <div>
                            <label class="pm-field__label" for="p-foto">Ruta de la portada</label>
                            <input class="pm-input--text" id="p-foto" name="photo" type="text" maxlength="255" placeholder="~/playlistImages/playlist1.png">
                        </div>
                    </div>
                </div>
            </div>
            <div class="pm-modal__foot">
                <button class="pm-btn pm-btn--ghost pm-btn--sm" type="button" data-cerrar-modal="modal-playlist">Cancelar</button>
                <button class="pm-btn pm-btn--primary pm-btn--sm" type="submit"><%=Ico("check")%>Guardar cambios</button>
            </div>
        </form>
    </div>
</div>

<!-- Modal: Catalogo -->
<div class="pm-modal-backdrop" id="modal-catalogo" role="dialog" aria-modal="true" aria-labelledby="titulo-modal-catalogo">
    <div class="pm-modal pm-modal--sm">
        <div class="pm-modal__head">
            <div class="pm-modal__title" id="titulo-modal-catalogo">Actualizar entrada de catalogo</div>
            <button class="pm-ico-btn" type="button" data-cerrar-modal="modal-catalogo" title="Cerrar"><%=Ico("cerrar")%></button>
        </div>
        <form method="post" action="procesar.asp">
            <div class="pm-modal__body">
                <input type="hidden" name="accion" value="actualizar">
                <input type="hidden" name="entidad" value="tbl_catalog">
                <input type="hidden" name="tab" value="catalogos">
                <input type="hidden" name="token" value="<%=TokenActual()%>">
                <input type="hidden" name="id" value="">

                <div class="pm-form-grid">
                    <div class="pm-form-grid pm-form-grid--2" style="gap:15px;">
                        <div>
                            <label class="pm-field__label" for="k-padre">Codigo padre</label>
                            <input class="pm-input--text" id="k-padre" name="cod_catalog_parent" type="text" maxlength="8">
                        </div>
                        <div>
                            <label class="pm-field__label" for="k-codigo">Codigo</label>
                            <input class="pm-input--text" id="k-codigo" name="cod_catalog" type="text" maxlength="8">
                        </div>
                    </div>
                    <div>
                        <label class="pm-field__label" for="k-valor">Valor</label>
                        <input class="pm-input--text" id="k-valor" name="value" type="text" maxlength="255" required>
                    </div>
                </div>
            </div>
            <div class="pm-modal__foot">
                <button class="pm-btn pm-btn--ghost pm-btn--sm" type="button" data-cerrar-modal="modal-catalogo">Cancelar</button>
                <button class="pm-btn pm-btn--primary pm-btn--sm" type="submit"><%=Ico("check")%>Guardar cambios</button>
            </div>
        </form>
    </div>
</div>
<%
strScriptExtra = "admin.js"
%>
<!--#include virtual="/polimusic/_includes/layout_inferior.asp"-->
