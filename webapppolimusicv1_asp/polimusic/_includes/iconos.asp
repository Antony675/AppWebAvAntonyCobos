<%
'==================================================================================
' PoliMusic - Biblioteca de Iconos SVG
' Archivo: _includes/iconos.asp
' Descripcion: Funcion centralizada de iconografia en linea para mantener la
'              interfaz libre de dependencias externas (sin CDN).
'==================================================================================

Function Icono(ByVal nombre)
    Dim s
    s = LCase(Trim(CStr(nombre)))

    Select Case s

        Case "inicio"
            Icono = "<path d=""M3 10.5 12 3l9 7.5""/><path d=""M5 9.5V21h5v-6h4v6h5V9.5""/>"

        Case "buscar"
            Icono = "<circle cx=""11"" cy=""11"" r=""7""/><path d=""m20 20-3.5-3.5""/>"

        Case "biblioteca"
            Icono = "<path d=""M4 4v16M9 4v16""/><path d=""m14 5 5 15""/>"

        Case "album"
            Icono = "<circle cx=""12"" cy=""12"" r=""9""/><circle cx=""12"" cy=""12"" r=""2.6""/>"

        Case "artista"
            Icono = "<path d=""M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2""/><circle cx=""12"" cy=""7"" r=""4""/>"

        Case "cancion"
            Icono = "<path d=""M9 18V5l12-2v13""/><circle cx=""6"" cy=""18"" r=""3""/><circle cx=""18"" cy=""16"" r=""3""/>"

        Case "playlist"
            Icono = "<path d=""M3 6h13M3 12h13M3 18h9""/><circle cx=""18"" cy=""16"" r=""3""/><path d=""M21 16V6l-6 1.6""/>"

        Case "reproducir"
            Icono = "<path d=""M7 4.5v15l13-7.5-13-7.5Z"" fill=""currentColor"" stroke=""none""/>"

        Case "pausa"
            Icono = "<path d=""M8 5h3v14H8zM13 5h3v14h-3z"" fill=""currentColor"" stroke=""none""/>"

        Case "anterior"
            Icono = "<path d=""M19 5v14L8 12l11-7Z"" fill=""currentColor"" stroke=""none""/><path d=""M5 5v14""/>"

        Case "siguiente"
            Icono = "<path d=""M5 5v14l11-7L5 5Z"" fill=""currentColor"" stroke=""none""/><path d=""M19 5v14""/>"

        Case "aleatorio"
            Icono = "<path d=""M16 3h5v5""/><path d=""M4 20 21 3""/><path d=""M21 16v5h-5""/><path d=""m15 15 6 6""/><path d=""M4 4l5 5""/>"

        Case "repetir"
            Icono = "<path d=""m17 2 4 4-4 4""/><path d=""M3 11v-1a4 4 0 0 1 4-4h14""/><path d=""m7 22-4-4 4-4""/><path d=""M21 13v1a4 4 0 0 1-4 4H3""/>"

        Case "repetir-uno"
            Icono = "<path d=""m17 2 4 4-4 4""/><path d=""M3 11v-1a4 4 0 0 1 4-4h14""/><path d=""m7 22-4-4 4-4""/><path d=""M21 13v1a4 4 0 0 1-4 4H3""/><path d=""M11 10h1v4""/>"

        Case "volumen"
            Icono = "<path d=""M11 5 6 9H2v6h4l5 4V5Z""/><path d=""M15.5 8.5a5 5 0 0 1 0 7""/><path d=""M18.5 5.5a9 9 0 0 1 0 13""/>"

        Case "volumen-bajo"
            Icono = "<path d=""M11 5 6 9H2v6h4l5 4V5Z""/><path d=""M15.5 8.5a5 5 0 0 1 0 7""/>"

        Case "volumen-mudo"
            Icono = "<path d=""M11 5 6 9H2v6h4l5 4V5Z""/><path d=""m16 9 5 6M21 9l-5 6""/>"

        Case "corazon"
            Icono = "<path d=""M12 20.5 4.6 13A4 4 0 0 1 12 7.4 4 4 0 0 1 19.4 13L12 20.5Z""/>"

        Case "mas"
            Icono = "<path d=""M12 5v14M5 12h14""/>"

        Case "cerrar"
            Icono = "<path d=""M18 6 6 18M6 6l12 12""/>"

        Case "editar"
            Icono = "<path d=""M12 20h9""/><path d=""M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5Z""/>"

        Case "eliminar"
            Icono = "<path d=""M3 6h18""/><path d=""M8 6V4h8v2""/><path d=""M19 6l-1 14H6L5 6""/><path d=""M10 11v6M14 11v6""/>"

        Case "agregar"
            Icono = "<circle cx=""12"" cy=""12"" r=""9""/><path d=""M12 8v8M8 12h8""/>"

        Case "escudo"
            Icono = "<path d=""M12 22s8-4.5 8-11V5l-8-3-8 3v6c0 6.5 8 11 8 11Z""/><path d=""m9 12 2 2 4-4""/>"

        Case "admin"
            Icono = "<path d=""M12 3 4 6.5v5c0 5 3.4 8.6 8 9.5 4.6-.9 8-4.5 8-9.5v-5L12 3Z""/><path d=""m9.5 12 1.8 1.8 3.4-3.4""/>"

        Case "salir"
            Icono = "<path d=""M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4""/><path d=""m16 17 5-5-5-5M21 12H9""/>"

        Case "usuario"
            Icono = "<path d=""M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2""/><circle cx=""12"" cy=""7"" r=""4""/>"

        Case "calendario"
            Icono = "<rect x=""3"" y=""5"" width=""18"" height=""16"" rx=""2""/><path d=""M3 10h18M8 3v4M16 3v4""/>"

        Case "correo"
            Icono = "<rect x=""2"" y=""5"" width=""20"" height=""14"" rx=""2""/><path d=""m3 7 9 6 9-6""/>"

        Case "etiqueta"
            Icono = "<path d=""M3 11V4h7l11 11-7 7L3 11Z""/><circle cx=""8"" cy=""8"" r=""1.4""/>"

        Case "imagen"
            Icono = "<rect x=""3"" y=""4"" width=""18"" height=""16"" rx=""2""/><circle cx=""9"" cy=""10"" r=""1.6""/><path d=""m21 16-5-5-9 9""/>"

        Case "ruta"
            Icono = "<path d=""M4 4h6v6H4zM14 14h6v6h-6z""/><path d=""M10 7h5a3 3 0 0 1 3 3v4""/>"

        Case "grafico"
            Icono = "<path d=""M4 20V10M10 20V4M16 20v-7M22 20H2""/>"

        Case "reloj"
            Icono = "<circle cx=""12"" cy=""12"" r=""9""/><path d=""M12 7v5l3.5 2""/>"

        Case "info"
            Icono = "<circle cx=""12"" cy=""12"" r=""9""/><path d=""M12 16v-5M12 8h.01""/>"

        Case "alerta"
            Icono = "<path d=""M12 3 2 20h20L12 3Z""/><path d=""M12 10v4M12 17h.01""/>"

        Case "check"
            Icono = "<path d=""M20 6 9 17l-5-5""/>"

        Case "error"
            Icono = "<circle cx=""12"" cy=""12"" r=""9""/><path d=""M12 8v5M12 16h.01""/>"

        Case "actualizar"
            Icono = "<path d=""M21 12a9 9 0 1 1-3-6.7""/><path d=""M21 4v5h-5""/>"

        Case "menu"
            Icono = "<path d=""M3 6h18M3 12h18M3 18h18""/>"

        Case "spotify"
            Icono = "<path d=""M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm4.6 14.4a.75.75 0 0 1-1 .25c-2.8-1.7-6.3-2.1-10.4-1.1a.75.75 0 1 1-.35-1.45c4.5-1.05 8.3-.6 11.4 1.3.35.2.45.65.35 1Zm1.2-2.9a.94.94 0 0 1-1.3.3c-3.2-1.95-8-2.5-11.75-1.35a.94.94 0 0 1-.55-1.8c4.25-1.3 9.5-.7 13.2 1.55.45.25.6.85.4 1.3Zm.1-3a1.12 1.12 0 0 1-1.5.4C12.6 8.55 6.9 8.3 3.9 9.2a1.12 1.12 0 1 1-.65-2.15C6.75 6.1 13 6.4 17.2 9c.55.3.7 1 .5 1.5Z"" fill=""currentColor"" stroke=""none""/>"

        Case Else
            Icono = "<circle cx=""12"" cy=""12"" r=""9""/>"

    End Select

    ' Iconos con relleno propio no requieren los atributos de trazo
    If s = "reproducir" Or s = "pausa" Or s = "anterior" Or s = "siguiente" Or s = "spotify" Then
        '<svg>' con fill heredado, sin stroke global
        Icono = "<svg viewBox=""0 0 24 24"" fill=""currentColor"" aria-hidden=""true"">" & Icono & "</svg>"
    Else
        Icono = "<svg viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""1.9"" stroke-linecap=""round"" stroke-linejoin=""round"" aria-hidden=""true"">" & Icono & "</svg>"
    End If
End Function

'----------------------------------------------------------------------------------
' Ico
' Abreviacion de Icono para uso directo dentro de las plantillas HTML.
'----------------------------------------------------------------------------------
Function Ico(ByVal nombre)
    Ico = Icono(nombre)
End Function
%>
