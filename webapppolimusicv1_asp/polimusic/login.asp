<%
'==================================================================================
' PoliMusic - Pantalla de Login
' Archivo: login.asp
' Descripcion: Formulario de autenticacion. Valida credenciales contra TBL_USER y
'              redirige al dashboard segun el rol (Admin / Estandar).
'
' NOTA: no se usa 'Option Explicit'. Las paginas se ensamblan con #include y esa
' directiva solo puede figurar como PRIMERA instruccion del script compilado; al
' quedar detras de config.asp provocaba el error VBScript '800a0400'. Todas las
' variables se declaran explicitamente con Dim en cada procedimiento.
'==================================================================================
%>
<!--#include virtual="/polimusic/_includes/config.asp"-->
<!--#include virtual="/polimusic/_includes/conexion.asp"-->
<!--#include virtual="/polimusic/_includes/sesion.asp"-->
<%
EnviarCabecerasNoCache

' Si ya hay una sesion activa se redirige directamente al dashboard
If HaySesion() Then
    Response.Redirect "dashboard.asp"
    Response.End
End If

Dim errorMsg, infoMsg
errorMsg = ""
infoMsg  = ""

If Request.QueryString("logout") = "1" Then
    infoMsg = "Sesion finalizada correctamente. Hasta pronto."
ElseIf Request.QueryString("msg") <> "" Then
    infoMsg = Request.QueryString("msg")
End If

'----------------------------------------------------------------------------------
' Procesamiento del formulario de autenticacion
'----------------------------------------------------------------------------------
Dim accion
accion = Request.Form("accion")

If accion = "login" Then
    Dim usuario, clave, recordar
    usuario = Trim(Request.Form("usuario"))
    clave   = Trim(Request.Form("clave"))
    recordar = Request.Form("recordar")

    If usuario = "" Or clave = "" Then
        errorMsg = "Debe ingresar usuario y contrasena."
    Else
        Dim rs, connUser, ipOrigen
        Set rs = EjecutarConsulta("SELECT TOP 1 ID_USER, USERNAME, PASSWORD, EMAIL, USER_TYPE, USER_PHOTO FROM TBL_USER WHERE USERNAME = '" & Esc(usuario) & "'")

        ' RsValido() comprueba objeto + no Nothing + estado abierto. Evita el
        ' error 800a01b6 al leer .EOF sobre un Recordset cerrado.
        If RsValido(rs) Then
            If Not rs.EOF Then
                Dim claveBd, claveOk
                claveBd = Trim(CStr(rs("PASSWORD")))

                ' Soporte dual: texto plano (datos semilla) y SHA1 en mayusculas
                If StrComp(claveBd, clave, vbBinaryCompare) = 0 Then
                    claveOk = True
                Else
                    claveOk = (UCase(claveBd) = Sha1Hex(clave))
                End If

                If claveOk Then
                    Dim idUserOk, userOk, tipoOk, fotoOk, mailOk
                    idUserOk = rs("ID_USER")
                    userOk   = rs("USERNAME")
                    tipoOk   = rs("USER_TYPE")
                    fotoOk   = rs("USER_PHOTO")
                    mailOk   = rs("EMAIL")
                    rs.Close
                    Set rs = Nothing

                    IniciarSesionUsuario idUserOk, userOk, tipoOk, fotoOk, mailOk
                    RegistrarBitacoraAcceso "LOGIN", usuario, Request.ServerVariables("REMOTE_ADDR"), "OK"
                    Response.Redirect "dashboard.asp"
                    Response.End
                Else
                    errorMsg = "Credenciales invalidas. Verifique su contrasena."
                End If
            Else
                errorMsg = "Credenciales invalidas. El usuario no existe."
            End If
            rs.Close
            Set rs = Nothing
        Else
            errorMsg = "No fue posible conectar con la base de datos BDD_PoliMusic."
        End If
    End If
End If
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PoliMusic &mdash; Iniciar sesion</title>
<link rel="stylesheet" href="css/polimusic.css">
</head>
<body>

<main class="pm-login">
    <div class="pm-login__bubbles" aria-hidden="true">
        <span class="pm-login__bubble pm-login__bubble--1"></span>
        <span class="pm-login__bubble pm-login__bubble--2"></span>
        <span class="pm-login__bubble pm-login__bubble--3"></span>
    </div>

    <div class="pm-login__shell">

        <!-- ============ Panel de marca ============ -->
        <section class="pm-login__brand">
            <div>
                <div class="pm-logo">
                    <span class="pm-logo__mark">
                        <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                            <path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm0 3.2a1.1 1.1 0 0 1 1.1 1.1v5.6l3.4 2a1.1 1.1 0 1 1-1.1 1.9l-4-2.35a1.1 1.1 0 0 1-.5-.93V6.3A1.1 1.1 0 0 1 12 5.2Z"/>
                        </svg>
                    </span>
                    <span class="pm-logo__text">Poli<span>Music</span></span>
                </div>

                <div class="pm-login__headline">
                    <h1>Tu musica.<br>Sin distracciones.</h1>
                    <p>Un catalogo minimalista para escuchar, explorar y organizar tu coleccion favorita.</p>
                </div>
            </div>

            <div class="pm-login__features">
                <div class="pm-login__feature">
                    <span class="pm-login__feature-ico">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>
                    </span>
                    <span><b>Reproductor integrado</b> con audio en streaming local</span>
                </div>
                <div class="pm-login__feature">
                    <span class="pm-login__feature-ico">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>
                    </span>
                    <span><b>Galeria visual</b> de albumes, artistas y playlists</span>
                </div>
                <div class="pm-login__feature">
                    <span class="pm-login__feature-ico">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 22s8-4.5 8-11V5l-8-3-8 3v6c0 6.5 8 11 8 11Z"/><path d="m9 12 2 2 4-4"/></svg>
                    </span>
                    <span><b>Control por roles</b> para administracion segura</span>
                </div>
            </div>

            <p class="pm-login__copy">Escuela Politecnica Nacional &middot; Aplicaciones Web Avanzadas</p>
        </section>

        <!-- ============ Panel de autenticacion ============ -->
        <section class="pm-login__panel">
            <h2>Iniciar sesion</h2>
            <p class="pm-login__panel-sub">Accede con tu cuenta de PoliMusic para continuar.</p>

            <% If errorMsg <> "" Then %>
            <div class="pm-alert pm-alert--error" role="alert">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16h.01"/></svg>
                <span><%=H(errorMsg)%></span>
            </div>
            <% End If %>

            <% If infoMsg <> "" Then %>
            <div class="pm-alert pm-alert--info" role="status">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 16v-5M12 8h.01"/></svg>
                <span><%=H(infoMsg)%></span>
            </div>
            <% End If %>

            <form method="post" action="login.asp" autocomplete="on" novalidate>
                <input type="hidden" name="accion" value="login">

                <div class="pm-field">
                    <label class="pm-field__label" for="usuario">Usuario</label>
                    <div class="pm-field__control">
                        <span class="pm-field__icon">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                        </span>
                        <input class="pm-input" type="text" id="usuario" name="usuario" placeholder="Nombre de usuario" maxlength="50" required autofocus value="<%=H(Request.Form("usuario"))%>">
                    </div>
                </div>

                <div class="pm-field">
                    <label class="pm-field__label" for="clave">Contrasena</label>
                    <div class="pm-field__control">
                        <span class="pm-field__icon">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>
                        </span>
                        <input class="pm-input" type="password" id="clave" name="clave" placeholder="Contrasena" maxlength="50" required>
                        <button class="pm-btn-toggle" type="button" id="btnToggleClave" title="Mostrar contrasena" aria-label="Mostrar contrasena">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                        </button>
                    </div>
                </div>

                <label class="pm-check">
                    <input type="checkbox" name="recordar" value="1">
                    <span class="pm-check__box"></span>
                    <span>Mantener la sesion iniciada</span>
                </label>

                <button class="pm-btn pm-btn--primary pm-btn--block" type="submit">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><path d="m10 17 5-5-5-5M15 12H3"/></svg>
                    Ingresar a PoliMusic
                </button>
            </form>

            <div class="pm-login__hint">
                <div class="pm-login__hint-title">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 16v-5M12 8h.01"/></svg>
                    Cuentas de prueba &mdash; clic para autocompletar
                </div>
                <div class="pm-login__hint-grid">
                    <button type="button" class="pm-cred pm-cred--admin" data-user="userAdmin" data-pass="12345678">
                        <span class="pm-cred__dot"></span>
                        <span class="pm-cred__meta">
                            <span class="pm-cred__role">Administrador</span>
                            <span class="pm-cred__user">userAdmin</span>
                        </span>
                    </button>
                    <button type="button" class="pm-cred pm-cred--std" data-user="AntonyCobos" data-pass="12345678">
                        <span class="pm-cred__dot"></span>
                        <span class="pm-cred__meta">
                            <span class="pm-cred__role">Estandar</span>
                            <span class="pm-cred__user">AntonyCobos</span>
                        </span>
                    </button>
                </div>
            </div>
        </section>
    </div>
</main>

<script>
(function () {
    'use strict';

    /* Alternar visibilidad de la contrasena */
    var btn = document.getElementById('btnToggleClave');
    var pwd = document.getElementById('clave');
    if (btn && pwd) {
        btn.addEventListener('click', function () {
            var visible = pwd.type === 'text';
            pwd.type = visible ? 'password' : 'text';
            btn.setAttribute('title', visible ? 'Mostrar contrasena' : 'Ocultar contrasena');
            pwd.focus();
        });
    }

    /* Autocompletado de credenciales de prueba.
       El nombre de usuario se normaliza al valor sembrado en la base de datos. */
    var botones = document.querySelectorAll('.pm-cred');
    for (var i = 0; i < botones.length; i++) {
        botones[i].addEventListener('click', function () {
            var u = document.getElementById('usuario');
            var c = document.getElementById('clave');
            if (u && c) {
                u.value = this.getAttribute('data-user');
                c.value = this.getAttribute('data-pass');
                c.focus();
            }
        });
    }
})();
</script>
</body>
</html>
