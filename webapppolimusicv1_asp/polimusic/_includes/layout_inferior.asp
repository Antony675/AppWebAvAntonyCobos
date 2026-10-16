<%
'==================================================================================
' PoliMusic - Reproductor y Cierre de Documento
' Archivo: _includes/layout_inferior.asp
' Descripcion: Fragmento reutilizable que renderiza el reproductor de audio fijo,
'              el contenedor de notificaciones y cierra la estructura del
'              documento.
'              Requiere previamente: config.asp, conexion.asp, sesion.asp,
'              consultas.asp, iconos.asp.
'==================================================================================
%>
        </div><!-- /.pm-content -->
    </main>

    <!-- ===================== REPRODUCTOR ===================== -->
    <footer class="pm-player" id="pmPlayer">

        <!-- Pista en curso -->
        <div class="pm-now">
            <div class="pm-now__art">
                <img id="pmNowArt" src="<%=strBase%>resources/UserImages/default.jpg" alt="Sin reproduccion">
                <div class="pm-eq" aria-hidden="true">
                    <span class="pm-eq__bar"></span>
                    <span class="pm-eq__bar"></span>
                    <span class="pm-eq__bar"></span>
                    <span class="pm-eq__bar"></span>
                    <span class="pm-eq__bar"></span>
                </div>
            </div>
            <div class="pm-now__text">
                <div class="pm-now__title" id="pmNowTitle">Sin reproduccion</div>
                <div class="pm-now__artist" id="pmNowArtist">Seleccione una pista del catalogo</div>
            </div>
        </div>

        <!-- Controles y progreso -->
        <div class="pm-controls">
            <div class="pm-controls__row">
                <button class="pm-ctrl pm-ctrl--sm pm-ctrl--relative" id="pmBtnShuffle" type="button" title="Reproduccion aleatoria" aria-label="Reproduccion aleatoria">
                    <%=Ico("aleatorio")%>
                </button>
                <button class="pm-ctrl" id="pmBtnPrev" type="button" title="Pista anterior" aria-label="Pista anterior">
                    <%=Ico("anterior")%>
                </button>
                <button class="pm-ctrl pm-ctrl--play" id="pmBtnPlay" type="button" title="Reproducir / Pausar" aria-label="Reproducir o pausar">
                    <span class="pm-ico-play"><%=Ico("reproducir")%></span>
                    <span class="pm-ico-pause"><%=Ico("pausa")%></span>
                </button>
                <button class="pm-ctrl" id="pmBtnNext" type="button" title="Pista siguiente" aria-label="Pista siguiente">
                    <%=Ico("siguiente")%>
                </button>
                <button class="pm-ctrl pm-ctrl--sm pm-ctrl--relative" id="pmBtnRepeat" type="button" title="Activar repeticion" aria-label="Repeticion" aria-pressed="false">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <path d="m17 2 4 4-4 4"/><path d="M3 11v-1a4 4 0 0 1 4-4h14"/><path d="m7 22-4-4 4-4"/><path d="M21 13v1a4 4 0 0 1-4 4H3"/>
                    </svg>
                </button>
            </div>

            <div class="pm-progress">
                <span class="pm-time" id="pmTimeActual">0:00</span>
                <div class="pm-range" id="pmProgressRange" role="slider" tabindex="0" aria-label="Progreso de la pista" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" data-value="0">
                    <div class="pm-range__track">
                        <div class="pm-range__fill"></div>
                        <div class="pm-range__thumb"></div>
                    </div>
                </div>
                <span class="pm-time" id="pmTimeTotal">0:00</span>
            </div>
        </div>

        <!-- Volumen -->
        <div class="pm-extras">
            <button class="pm-ctrl" id="pmBtnMute" type="button" title="Silenciar" aria-label="Silenciar">
                <%=Ico("volumen")%>
            </button>
            <div class="pm-volume">
                <div class="pm-range" id="pmVolumeRange" role="slider" tabindex="0" aria-label="Volumen" aria-valuemin="0" aria-valuemax="100" aria-valuenow="80" data-value="0.8">
                    <div class="pm-range__track">
                        <div class="pm-range__fill"></div>
                        <div class="pm-range__thumb"></div>
                    </div>
                </div>
            </div>
        </div>

        <audio id="pmAudio" preload="metadata"></audio>
    </footer>

</div><!-- /.pm-app -->

<div class="pm-toast-host" id="pmToastHost" aria-live="polite" aria-atomic="false"></div>

<script src="<%=strBase%>js/polimusic.js"></script>
<% If strScriptExtra <> "" Then %>
<script src="<%=strBase%>js/<%=H(strScriptExtra)%>"></script>
<% End If %>
</body>
</html>
