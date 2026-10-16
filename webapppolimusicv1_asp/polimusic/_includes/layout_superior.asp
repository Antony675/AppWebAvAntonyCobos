<%
'==================================================================================
' PoliMusic - Cabecera, Barra Lateral y Barra Superior
' Archivo: _includes/layout_superior.asp
' Descripcion: Fragmento reutilizable que abre el documento HTML, construye la
'              navegacion lateral con el catalogo accesible y pinta la barra
'              superior con el buscador y la identidad del usuario.
'              Requiere previamente: config.asp, conexion.asp, sesion.asp,
'              consultas.asp, iconos.asp.
' Entradas esperadas:
'       strTitulo       Titulo de la pestana del navegador
'       strVistaActiva  Identificador de la vista inicial (catalogo|albumes|...)
'==================================================================================

Dim strBase, strTituloDoc, strAvatar, strInicialesUsuario
strBase = URL_BASE
If strTitulo = "" Then strTitulo = "PoliMusic"

strInicialesUsuario = Iniciales(Session("USERNAME"))
strAvatar = ResolverRecurso(Session("USER_PHOTO"), strBase)
If strAvatar = "" Then strAvatar = strBase & "resources/UserImages/default.jpg"
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><%=H(strTitulo)%> &mdash; PoliMusic</title>
<link rel="stylesheet" href="<%=strBase%>css/polimusic.css">
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><circle cx='12' cy='12' r='11' fill='%23a855f7'/></svg>">
</head>
<body>

<div class="pm-app">

    <!-- ===================== BARRA LATERAL ===================== -->
    <aside class="pm-sidebar">

        <nav class="pm-sidebar__block pm-sidebar__block--nav">
            <a class="pm-logo" href="<%=strBase%>dashboard.asp" style="padding:10px 14px 16px;">
                <span class="pm-logo__mark" style="width:34px;height:34px;">
                    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" style="width:19px;height:19px;">
                        <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm0 3.2a1.1 1.1 0 0 1 1.1 1.1v5.6l3.4 2a1.1 1.1 0 1 1-1.1 1.9l-4-2.35a1.1 1.1 0 0 1-.5-.93V6.3A1.1 1.1 0 0 1 12 5.2Z"/>
                    </svg>
                </span>
                <span class="pm-logo__text" style="font-size:19px;">Poli<span>Music</span></span>
            </a>

            <button class="pm-nav-link" data-vista="catalogo" type="button">
                <%=Ico("inicio")%>
                Inicio
            </button>
            <button class="pm-nav-link" data-vista="albumes" type="button">
                <%=Ico("album")%>
                Albumes
            </button>
            <button class="pm-nav-link" data-vista="artistas" type="button">
                <%=Ico("artista")%>
                Artistas
            </button>
            <button class="pm-nav-link" data-vista="canciones" type="button">
                <%=Ico("cancion")%>
                Canciones
            </button>
            <button class="pm-nav-link" data-vista="playlists" type="button">
                <%=Ico("playlist")%>
                Playlists
            </button>

            <% If EsAdmin() Then %>
            <a class="pm-nav-link" href="<%=strBase%>admin/panel.asp">
                <%=Ico("admin")%>
                Panel de administracion
            </a>
            <% End If %>
        </nav>

        <div class="pm-sidebar__block pm-sidebar__block--list">
            <div class="pm-sidebar__title">
                <span>Tu biblioteca</span>
                <%=Ico("biblioteca")%>
            </div>
            <div class="pm-sidebar__scroll">
                <%
                Dim rsSidePL, strSideImg, nSide
                nSide = 0
                Set rsSidePL = ListarPlaylists(Session("ID_USER"), EsAdmin())
                ' RsValido() comprueba objeto + no Nothing + estado abierto.
                ' Es imprescindible: leer .EOF sobre un Recordset cerrado lanza 800a01b6.
                If RsValido(rsSidePL) Then
                    Do While Not rsSidePL.EOF
                        nSide = nSide + 1
                        strSideImg = ImagenSegura(rsSidePL("PHOTO"), strBase, "PlaylistImages", "default.jpg")
                %>
                <button class="pm-pl-item" type="button" data-vista="playlists">
                    <img class="pm-pl-item__img" src="<%=H(strSideImg)%>" alt="" loading="lazy">
                    <span class="pm-pl-item__meta">
                        <span class="pm-pl-item__name pm-truncate" style="display:block;"><%=H(rsSidePL("TITLE"))%></span>
                        <span class="pm-pl-item__type">
                            <% If EscInt(rsSidePL("TYPE")) = PLAYLIST_TYPE_PRIVATE Then %>Privada<% Else %>Publica<% End If %>
                            &middot; <%=EscInt(rsSidePL("TOTAL_SONGS"))%> pistas
                        </span>
                    </span>
                </button>
                <%
                        rsSidePL.MoveNext
                    Loop
                    rsSidePL.Close
                    Set rsSidePL = Nothing
                End If

                If nSide = 0 Then
                %>
                <p class="pm-empty-mini">Aun no tienes playlists disponibles.</p>
                <% End If %>
            </div>
        </div>
    </aside>

    <!-- ===================== CONTENIDO PRINCIPAL ===================== -->
    <main class="pm-main" id="pmMain">
        <header class="pm-topbar" id="pmTopbar">
            <div class="pm-topbar__left">
                <div>
                    <div class="pm-topbar__title" id="pmTopbarTitle"><%=H(strTitulo)%></div>
                    <div class="pm-topbar__crumb" id="pmTopbarCrumb"><%=H(strSubtitulo)%></div>
                </div>
            </div>

            <div class="pm-search">
                <%=Ico("buscar")%>
                <input type="search" id="pmSearchInput" placeholder="Buscar canciones, albumes o artistas" autocomplete="off" aria-label="Buscar en el catalogo">
            </div>

            <button class="pm-user-chip" id="pmUserChip" type="button" aria-haspopup="menu" aria-expanded="false">
                <span class="pm-avatar">
                    <% If strAvatar <> "" Then %>
                    <img src="<%=H(strAvatar)%>" alt="Foto de perfil" onerror="this.style.display='none'">
                    <% Else %>
                    <%=H(strInicialesUsuario)%>
                    <% End If %>
                </span>
                <span style="text-align:left;">
                    <span class="pm-user-chip__name pm-truncate" style="display:block;"><%=H(Session("USERNAME"))%></span>
                    <% If EsAdmin() Then %>
                    <span class="pm-badge-admin"><%=Ico("escudo")%>Admin</span>
                    <% Else %>
                    <span class="pm-user-chip__role">Usuario estandar</span>
                    <% End If %>
                </span>
            </button>

            <div class="pm-menu pm-hidden" id="pmUserMenu" role="menu">
                <div style="padding:12px 13px 10px;border-bottom:1px solid var(--pm-border);">
                    <div style="display:flex;align-items:center;gap:11px;">
                        <span class="pm-avatar"><%=H(strInicialesUsuario)%></span>
                        <span style="min-width:0;">
                            <span class="pm-strong" style="display:block;font-size:13.5px;font-weight:700;"><%=H(Session("USERNAME"))%></span>
                            <span style="display:block;font-size:11.5px;color:var(--pm-text-muted);" class="pm-truncate"><%=H(Session("USER_EMAIL"))%></span>
                        </span>
                    </div>
                </div>
                <% If EsAdmin() Then %>
                <a class="pm-menu__item" href="<%=strBase%>admin/panel.asp" role="menuitem">
                    <%=Ico("admin")%>
                    Panel de administracion
                </a>
                <% End If %>
                <button class="pm-menu__item" type="button" data-vista="catalogo" role="menuitem">
                    <%=Ico("inicio")%>
                    Ir al catalogo
                </button>
                <div class="pm-menu__sep"></div>
                <a class="pm-menu__item" href="<%=strBase%>logout.asp" role="menuitem" style="color:var(--pm-danger);">
                    <%=Ico("salir")%>
                    Cerrar sesion
                </a>
            </div>
        </header>

        <div class="pm-content" id="pmAdminRootMarker">
