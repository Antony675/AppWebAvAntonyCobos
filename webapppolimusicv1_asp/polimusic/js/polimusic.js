/* ==================================================================================
   PoliMusic - Motor de la aplicacion cliente
   Responsabilidades:
     1. Reproductor de audio (play/pause/next/prev, progreso, volumen, aleatorio,
        repeticion) con retroalimentacion visual y persistencia ligera.
     2. Navegacion entre vistas del catalogo sin recarga completa de pagina.
     3. Filtro instantaneo del catalogo y gestion de modales / toasts.
   Sin dependencias externas.
   ================================================================================== */
(function (window, document) {
    'use strict';

    /* ==============================================================================
       1. ESTADO GLOBAL
       ============================================================================== */
    var PM = {
        lista: [],          // Cola de reproduccion activa
        indice: -1,         // Indice de la pista actual
        aleatorio: false,
        repetir: 0,         // 0 = off, 1 = repetir todo, 2 = repetir una
        audio: null,
        arrastrando: false,
        volumen: 0.8,
        volumenPrevio: 0.8,
        origen: 'catalogo'  // Contexto de la cola: catalogo | album | playlist | artista
    };

    /* ==============================================================================
       2. UTILIDADES
       ============================================================================== */
    function $(sel)  { return document.querySelector(sel); }
    function $$(sel) { return Array.prototype.slice.call(document.querySelectorAll(sel)); }

    function crear(tag, cls, txt) {
        var el = document.createElement(tag);
        if (cls) el.className = cls;
        if (txt !== undefined && txt !== null) el.textContent = txt;
        return el;
    }

    function segundosATexto(seg) {
        if (!isFinite(seg) || seg < 0) seg = 0;
        var m = Math.floor(seg / 60);
        var s = Math.floor(seg % 60);
        return m + ':' + (s < 10 ? '0' : '') + s;
    }

    function leerClave(clave, def) {
        try {
            var v = window.localStorage.getItem(clave);
            return v === null ? def : v;
        } catch (e) { return def; }
    }

    function guardarClave(clave, valor) {
        try { window.localStorage.setItem(clave, valor); } catch (e) { /* modo privado */ }
    }

    /* ==============================================================================
       3. NOTIFICACIONES (TOASTS)
       ============================================================================== */
    var ICONO_TOAST = {
        ok:    '<path d="M20 6 9 17l-5-5"/>',
        error: '<circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16h.01"/>',
        info:  '<circle cx="12" cy="12" r="9"/><path d="M12 16v-5M12 8h.01"/>'
    };

    function notificar(mensaje, tipo) {
        var host = $('#pmToastHost');
        if (!host) return;

        tipo = tipo || 'ok';
        var toast = crear('div', 'pm-toast pm-toast--' + (tipo === 'ok' ? 'ok' : tipo));
        toast.setAttribute('role', tipo === 'error' ? 'alert' : 'status');

        var icono = crear('span');
        icono.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
                          'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
                          (ICONO_TOAST[tipo] || ICONO_TOAST.info) + '</svg>';

        var texto = crear('span', null, mensaje);
        toast.appendChild(icono);
        toast.appendChild(texto);
        host.appendChild(toast);

        window.setTimeout(function () {
            toast.classList.add('is-leaving');
            window.setTimeout(function () {
                if (toast.parentNode) toast.parentNode.removeChild(toast);
            }, 280);
        }, 3400);
    }

    /* ==============================================================================
       4. REPRODUCTOR DE AUDIO
       ============================================================================== */
    var Reproductor = {

        init: function () {
            var audio = $('#pmAudio');
            if (!audio) return;
            PM.audio = audio;

            PM.volumen = parseFloat(leerClave('pm_volumen', '0.8'));
            if (isNaN(PM.volumen)) PM.volumen = 0.8;
            audio.volume = PM.volumen;

            PM.aleatorio = leerClave('pm_aleatorio', '0') === '1';
            PM.repetir   = parseInt(leerClave('pm_repetir', '0'), 10) || 0;

            this.actualizarBotonesEstado();
            this.actualizarVolumenUI();
            this.enlazarEventos();
        },

        enlazarEventos: function () {
            var self = this, audio = PM.audio;

            audio.addEventListener('timeupdate', function () { self.pintarProgreso(); });
            audio.addEventListener('loadedmetadata', function () { self.pintarProgreso(); });
            audio.addEventListener('play',  function () { self.cambiarEstadoVisual(true); });
            audio.addEventListener('pause', function () { self.cambiarEstadoVisual(false); });
            audio.addEventListener('waiting', function () { self.marcarBuffering(true); });
            audio.addEventListener('playing', function () { self.marcarBuffering(false); });
            audio.addEventListener('ended', function () { self.alTerminar(); });

            audio.addEventListener('error', function () {
                self.marcarBuffering(false);
                notificar('No fue posible reproducir el archivo de audio.', 'error');
                self.cambiarEstadoVisual(false);
            });

            /* --- Controles principales --- */
            var btnPlay = $('#pmBtnPlay');
            if (btnPlay) btnPlay.addEventListener('click', function () { self.alternar(); });

            var btnPrev = $('#pmBtnPrev');
            if (btnPrev) btnPrev.addEventListener('click', function () { self.anterior(); });

            var btnNext = $('#pmBtnNext');
            if (btnNext) btnNext.addEventListener('click', function () { self.siguiente(); });

            var btnShuffle = $('#pmBtnShuffle');
            if (btnShuffle) btnShuffle.addEventListener('click', function () { self.alternarAleatorio(); });

            var btnRepeat = $('#pmBtnRepeat');
            if (btnRepeat) btnRepeat.addEventListener('click', function () { self.ciclarRepeticion(); });

            /* --- Volumen --- */
            var volWrap = $('#pmVolumeRange');
            if (volWrap) {
                this.enlazarRange(volWrap, function (ratio) {
                    PM.volumen = ratio;
                    PM.audio.volume = ratio;
                    if (ratio > 0) PM.volumenPrevio = ratio;
                    guardarClave('pm_volumen', String(ratio));
                    self.actualizarVolumenUI();
                });
            }

            var btnMute = $('#pmBtnMute');
            if (btnMute) {
                btnMute.addEventListener('click', function () {
                    if (PM.audio.volume > 0) {
                        PM.volumenPrevio = PM.audio.volume;
                        PM.audio.volume = 0;
                        PM.volumen = 0;
                    } else {
                        PM.audio.volume = PM.volumenPrevio || 0.8;
                        PM.volumen = PM.audio.volume;
                    }
                    self.actualizarVolumenUI();
                    self.sincronizarRange('#pmVolumeRange', PM.volumen);
                });
            }

            /* --- Barra de progreso --- */
            var progWrap = $('#pmProgressRange');
            if (progWrap) {
                this.enlazarRange(progWrap, function (ratio) {
                    if (isFinite(PM.audio.duration) && PM.audio.duration > 0) {
                        PM.audio.currentTime = ratio * PM.audio.duration;
                        self.pintarProgreso();
                    }
                });
            }

            /* --- Atajos de teclado --- */
            document.addEventListener('keydown', function (e) {
                var activo = document.activeElement;
                var escribiendo = activo && (activo.tagName === 'INPUT' || activo.tagName === 'TEXTAREA' || activo.tagName === 'SELECT');
                if (escribiendo) return;

                if (e.code === 'Space') { e.preventDefault(); self.alternar(); }
                else if (e.code === 'ArrowRight') { self.saltar(5); }
                else if (e.code === 'ArrowLeft')  { self.saltar(-5); }
                else if (e.code === 'ArrowUp')    { e.preventDefault(); self.ajustarVolumen(0.05); }
                else if (e.code === 'ArrowDown')  { e.preventDefault(); self.ajustarVolumen(-0.05); }
            });

            /* --- Reproducir desde cualquier elemento del catalogo --- */
            document.addEventListener('click', function (e) {
                var disparador = e.target.closest ? e.target.closest('[data-play-json]') : null;
                if (!disparador) return;
                e.preventDefault();
                e.stopPropagation();

                var payload = disparador.getAttribute('data-play-json');
                if (!payload) return;

                var datos;
                try { datos = JSON.parse(payload); }
                catch (err) { return; }

                if (!datos || !datos.length) return;

                var uid = disparador.getAttribute('data-play-uid');
                var ctx = disparador.getAttribute('data-play-context') || 'catalogo';

                if (uid && ctx === PM.origen && Reproductor.esPistaActual(uid) && PM.audio && !PM.audio.paused) {
                    self.pausar();
                } else if (uid && ctx === PM.origen && Reproductor.esPistaActual(uid) && PM.audio && PM.audio.paused) {
                    self.reanudar();
                } else {
                    self.cargarCola(datos, uid, ctx, true);
                }
            });
        },

        /* --- Control de rangos arrastrables reutilizable --- */
        enlazarRange: function (wrap, callback) {
            var self = this;

            function ratioDesdeEvento(clienteX) {
                var rect = wrap.getBoundingClientRect();
                var r = (clienteX - rect.left) / rect.width;
                return Math.max(0, Math.min(1, r));
            }

            function aplicar(clienteX) {
                var r = ratioDesdeEvento(clienteX);
                self.sincronizarRangeWrap(wrap, r);
                callback(r);
            }

            wrap.addEventListener('mousedown', function (e) {
                e.preventDefault();
                PM.arrastrando = true;
                wrap.classList.add('is-dragging');
                aplicar(e.clientX);

                function mover(ev) { aplicar(ev.clientX); }
                function soltar() {
                    PM.arrastrando = false;
                    wrap.classList.remove('is-dragging');
                    document.removeEventListener('mousemove', mover);
                    document.removeEventListener('mouseup', soltar);
                }
                document.addEventListener('mousemove', mover);
                document.addEventListener('mouseup', soltar);
            });

            wrap.addEventListener('click', function (e) {
                if (!PM.arrastrando) aplicar(e.clientX);
            });

            wrap.setAttribute('role', 'slider');
            wrap.setAttribute('tabindex', '0');
            wrap.addEventListener('keydown', function (e) {
                var actual = parseFloat(wrap.getAttribute('data-value') || '0');
                if (e.key === 'ArrowRight' || e.key === 'ArrowUp') {
                    e.preventDefault();
                    aplicar2(Math.min(1, actual + 0.05));
                } else if (e.key === 'ArrowLeft' || e.key === 'ArrowDown') {
                    e.preventDefault();
                    aplicar2(Math.max(0, actual - 0.05));
                }
            });

            function aplicar2(r) {
                self.sincronizarRangeWrap(wrap, r);
                callback(r);
            }
        },

        sincronizarRangeWrap: function (wrap, ratio) {
            var fill = wrap.querySelector('.pm-range__fill');
            var thumb = wrap.querySelector('.pm-range__thumb');
            var pct = (ratio * 100).toFixed(3) + '%';
            if (fill)  fill.style.width = pct;
            if (thumb) thumb.style.left = pct;
            wrap.setAttribute('data-value', ratio);
            wrap.setAttribute('aria-valuenow', Math.round(ratio * 100));
        },

        sincronizarRange: function (sel, ratio) {
            var wrap = $(sel);
            if (wrap) this.sincronizarRangeWrap(wrap, ratio);
        },

        /* --- Carga de una cola de reproduccion --- */
        cargarCola: function (pistas, uid, contexto, iniciarAuto) {
            PM.lista = pistas.slice();
            PM.origen = contexto || 'catalogo';

            var idx = 0;
            if (uid) {
                for (var i = 0; i < PM.lista.length; i++) {
                    if (String(PM.lista[i].uid) === String(uid)) { idx = i; break; }
                }
            } else {
                idx = 0;
            }

            this.cargarPista(idx, iniciarAuto !== false);
        },

        cargarPista: function (indice, reproducirAuto) {
            if (indice < 0 || indice >= PM.lista.length) return;
            var pista = PM.lista[indice];
            PM.indice = indice;

            PM.audio.src = pista.src;
            PM.audio.load();

            this.actualizarPanelPista(pista);
            this.marcarPistaActiva(pista);
            this.sincronizarRange('#pmProgressRange', 0);
            var tAct = $('#pmTimeActual'); if (tAct) tAct.textContent = '0:00';
            var tDur = $('#pmTimeTotal');  if (tDur) tDur.textContent = '0:00';

            if (reproducirAuto !== false) this.reproducir();
        },

        reproducir: function () {
            var p = PM.audio.play();
            if (p && typeof p.catch === 'function') {
                p.catch(function () {
                    notificar('El navegador bloqueo la reproduccion automatica. Pulse Play.', 'info');
                });
            }
        },

        pausar: function () { PM.audio.pause(); },
        reanudar: function () { this.reproducir(); },

        alternar: function () {
            if (PM.indice < 0) {
                if (PM.lista.length === 0) {
                    notificar('No hay pistas disponibles para reproducir.', 'info');
                    return;
                }
                this.cargarPista(0, true);
                return;
            }
            if (PM.audio.paused) this.reproducir();
            else this.pausar();
        },

        siguiente: function () {
            if (PM.lista.length === 0) return;

            if (PM.aleatorio && PM.lista.length > 1) {
                var nuevo = PM.indice;
                while (nuevo === PM.indice) {
                    nuevo = Math.floor(Math.random() * PM.lista.length);
                }
                this.cargarPista(nuevo, true);
                return;
            }

            var sig = PM.indice + 1;
            if (sig >= PM.lista.length) {
                if (PM.repetir === 1) sig = 0;
                else { this.detener(); return; }
            }
            this.cargarPista(sig, true);
        },

        anterior: function () {
            if (PM.lista.length === 0) return;

            /* Si la pista ya avanzo mas de 3 segundos, reinicia la actual */
            if (PM.audio.currentTime > 3) {
                PM.audio.currentTime = 0;
                return;
            }

            if (PM.aleatorio && PM.lista.length > 1) {
                var nuevo = PM.indice;
                while (nuevo === PM.indice) {
                    nuevo = Math.floor(Math.random() * PM.lista.length);
                }
                this.cargarPista(nuevo, true);
                return;
            }

            var ant = PM.indice - 1;
            if (ant < 0) ant = PM.lista.length - 1;
            this.cargarPista(ant, true);
        },

        detener: function () {
            PM.audio.pause();
            PM.audio.currentTime = 0;
            this.cambiarEstadoVisual(false);
        },

        saltar: function (segundos) {
            if (!isFinite(PM.audio.duration)) return;
            var t = PM.audio.currentTime + segundos;
            PM.audio.currentTime = Math.max(0, Math.min(PM.audio.duration, t));
        },

        ajustarVolumen: function (delta) {
            PM.volumen = Math.max(0, Math.min(1, PM.audio.volume + delta));
            PM.audio.volume = PM.volumen;
            guardarClave('pm_volumen', String(PM.volumen));
            this.actualizarVolumenUI();
            this.sincronizarRange('#pmVolumeRange', PM.volumen);
        },

        alTerminar: function () {
            if (PM.repetir === 2) {
                PM.audio.currentTime = 0;
                this.reproducir();
                return;
            }
            this.siguiente();
        },

        alternarAleatorio: function () {
            PM.aleatorio = !PM.aleatorio;
            guardarClave('pm_aleatorio', PM.aleatorio ? '1' : '0');
            this.actualizarBotonesEstado();
            notificar(PM.aleatorio ? 'Reproduccion aleatoria activada.' : 'Reproduccion aleatoria desactivada.', 'info');
        },

        ciclarRepeticion: function () {
            PM.repetir = (PM.repetir + 1) % 3;
            guardarClave('pm_repetir', String(PM.repetir));
            this.actualizarBotonesEstado();

            var msg = PM.repetir === 0 ? 'Repeticion desactivada.'
                    : PM.repetir === 1 ? 'Repetir toda la cola.'
                    : 'Repetir la pista actual.';
            notificar(msg, 'info');
        },

        actualizarBotonesEstado: function () {
            var btnShuffle = $('#pmBtnShuffle');
            if (btnShuffle) {
                btnShuffle.classList.toggle('is-on', PM.aleatorio);
                btnShuffle.setAttribute('aria-pressed', PM.aleatorio ? 'true' : 'false');
            }

            var btnRepeat = $('#pmBtnRepeat');
            if (btnRepeat) {
                btnRepeat.classList.toggle('is-on', PM.repetir > 0);
                btnRepeat.setAttribute('aria-pressed', PM.repetir > 0 ? 'true' : 'false');
                btnRepeat.setAttribute('title',
                    PM.repetir === 0 ? 'Activar repeticion' :
                    PM.repetir === 1 ? 'Repetir toda la cola' : 'Repetir una pista');

                var svg = btnRepeat.querySelector('svg');
                if (svg) {
                    svg.innerHTML = PM.repetir === 2
                        ? '<path d="m17 2 4 4-4 4"/><path d="M3 11v-1a4 4 0 0 1 4-4h14"/><path d="m7 22-4-4 4-4"/><path d="M21 13v1a4 4 0 0 1-4 4H3"/><path d="M11 10h1.5v4"/>'
                        : '<path d="m17 2 4 4-4 4"/><path d="M3 11v-1a4 4 0 0 1 4-4h14"/><path d="m7 22-4-4 4-4"/><path d="M21 13v1a4 4 0 0 1-4 4H3"/>';
                }
            }
        },

        actualizarVolumenUI: function () {
            var actual = PM.audio ? PM.audio.volume : PM.volumen;
            var wrap = $('#pmVolumeRange');
            if (wrap) this.sincronizarRangeWrap(wrap, actual);

            var btn = $('#pmBtnMute');
            if (btn) {
                var svg = btn.querySelector('svg');
                var icono;
                if (actual === 0) {
                    icono = '<path d="M11 5 6 9H2v6h4l5 4V5Z"/><path d="m16 9 5 6M21 9l-5 6"/>';
                } else if (actual < 0.5) {
                    icono = '<path d="M11 5 6 9H2v6h4l5 4V5Z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/>';
                } else {
                    icono = '<path d="M11 5 6 9H2v6h4l5 4V5Z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.5 5.5a9 9 0 0 1 0 13"/>';
                }
                if (svg) svg.innerHTML = icono;
                btn.setAttribute('title', actual === 0 ? 'Activar sonido' : 'Silenciar');
            }
        },

        pintarProgreso: function () {
            if (PM.arrastrando) return;
            var audio = PM.audio;
            var dur = audio.duration;
            var ratio = (isFinite(dur) && dur > 0) ? (audio.currentTime / dur) : 0;

            this.sincronizarRange('#pmProgressRange', ratio);

            var tAct = $('#pmTimeActual');
            if (tAct) tAct.textContent = segundosATexto(audio.currentTime);

            var tDur = $('#pmTimeTotal');
            if (tDur) {
                tDur.textContent = (isFinite(dur) && dur > 0) ? segundosATexto(dur) : '0:00';
                if (isFinite(dur) && dur > 0) tDur.setAttribute('data-dur', String(dur));
            }
        },

        marcarBuffering: function (activo) {
            var wrap = $('#pmProgressRange');
            if (wrap) wrap.classList.toggle('is-buffering', !!activo);
        },

        actualizarPanelPista: function (pista) {
            var img = $('#pmNowArt');
            if (img) {
                img.src = pista.img;
                img.alt = 'Caratula de ' + pista.nombre;
            }
            var t = $('#pmNowTitle');
            if (t) t.textContent = pista.nombre;
            var a = $('#pmNowArtist');
            if (a) a.textContent = pista.artista || 'Artista desconocido';

            document.title = pista.nombre + ' \u00b7 ' + (pista.artista || 'PoliMusic');
        },

        cambiarEstadoVisual: function (reproduciendo) {
            var player = $('#pmPlayer');
            if (player) player.classList.toggle('is-playing', reproduciendo);
        },

        esPistaActual: function (uid) {
            if (PM.indice < 0 || PM.indice >= PM.lista.length) return false;
            return String(PM.lista[PM.indice].uid) === String(uid);
        },

        marcarPistaActiva: function (pista) {
            $$('[data-play-uid]').forEach(function (el) {
                var coincide = String(el.getAttribute('data-play-uid')) === String(pista.uid);
                var ctx = el.getAttribute('data-play-context');
                el.classList.toggle('is-playing', coincide && ctx === PM.origen);
            });
        }
    };

    /* ==============================================================================
       5. NAVEGACION ENTRE VISTAS
       ============================================================================== */
    var Vistas = {

        init: function () {
            var self = this;

            /* Enlaces del menu lateral y de las tarjetas de acceso rapido */
            document.addEventListener('click', function (e) {
                var link = e.target.closest ? e.target.closest('[data-vista]') : null;
                if (!link) return;
                e.preventDefault();
                self.irA(link.getAttribute('data-vista'));
            });

            /* Soporte de navegacion por hash para enlaces directos */
            window.addEventListener('hashchange', function () {
                self.irA((window.location.hash || '#catalogo').substring(1), true);
            });

            var inicial = (window.location.hash || '#catalogo').substring(1);
            if ($('#vista-' + inicial)) this.irA(inicial, true);
        },

        irA: function (nombre, omitirHash) {
            if (!nombre) return;
            var destino = $('#vista-' + nombre);
            if (!destino) return;

            $$('.pm-vista').forEach(function (v) { v.classList.add('pm-hidden'); });
            destino.classList.remove('pm-hidden');
            /* Reinicia la animacion de entrada */
            destino.style.animation = 'none';
            void destino.offsetWidth;
            destino.style.animation = '';

            $$('[data-vista]').forEach(function (l) {
                l.classList.toggle('is-active', l.getAttribute('data-vista') === nombre && l.classList.contains('pm-nav-link'));
            });

            var titulo = destino.getAttribute('data-titulo');
            var elTitulo = $('#pmTopbarTitle');
            if (elTitulo && titulo) elTitulo.textContent = titulo;

            var elCrumb = $('#pmTopbarCrumb');
            if (elCrumb) elCrumb.textContent = destino.getAttribute('data-subtitulo') || '';

            if (!omitirHash) {
                try { history.replaceState(null, '', '#' + nombre); }
                catch (err) { window.location.hash = nombre; }
            }

            var main = $('#pmMain');
            if (main) main.scrollTop = 0;

            Reproductor.marcarPistaActivaSoloSiExiste();
        }
    };

    /* Metodo auxiliar para re-sincronizar el resaltado tras cambiar de vista */
    Reproductor.marcarPistaActivaSoloSiExiste = function () {
        if (PM.indice < 0 || PM.indice >= PM.lista.length) return;
        this.marcarPistaActiva(PM.lista[PM.indice]);
    };

    /* ==============================================================================
       6. FILTRO INSTANTANEO DEL CATALOGO
       ============================================================================== */
    var Filtro = {
        init: function () {
            var input = $('#pmSearchInput');
            if (!input) return;

            var contador = $('#pmSearchCount');

            input.addEventListener('input', function () {
                var q = input.value.trim().toLowerCase();

                $$('#pmBusquedaBloque [data-filtrable]').forEach(function (grupo) {
                    var hijos = grupo.children;
                    var visibles = 0;

                    for (var i = 0; i < hijos.length; i++) {
                        var hijo = hijos[i];
                        var texto = (hijo.getAttribute('data-texto') || hijo.textContent || '').toLowerCase();
                        var coincide = (q === '' || texto.indexOf(q) !== -1);
                        hijo.classList.toggle('pm-hidden', !coincide);
                        if (coincide) visibles++;
                    }

                    var seccion = grupo.closest ? grupo.closest('.pm-section') : null;
                    if (seccion) seccion.classList.toggle('pm-hidden', visibles === 0);
                });

                /* Tambien filtra filas de la tabla de pistas */
                $$('[data-fila-busqueda]').forEach(function (fila) {
                    var texto = (fila.getAttribute('data-texto') || '').toLowerCase();
                    fila.classList.toggle('pm-hidden', q !== '' && texto.indexOf(q) === -1);
                });

                if (contador) {
                    if (q === '') {
                        contador.textContent = '';
                    } else {
                        var total = $$('#pmBusquedaBloque [data-filtrable] > *:not(.pm-hidden)').length;
                        contador.textContent = total + ' resultado' + (total === 1 ? '' : 's') + ' para "' + input.value.trim() + '"';
                    }
                }
            });

            /* Atajo: "/" enfoca el buscador */
            document.addEventListener('keydown', function (e) {
                var activo = document.activeElement;
                var escribiendo = activo && (activo.tagName === 'INPUT' || activo.tagName === 'TEXTAREA');
                if (e.key === '/' && !escribiendo) {
                    e.preventDefault();
                    input.focus();
                    input.select();
                }
            });
        }
    };

    /* ==============================================================================
       7. MODALES Y MENUS
       ============================================================================== */
    var UI = {
        init: function () {
            var self = this;

            /* Cierre generico por atributo data-cerrar-modal */
            document.addEventListener('click', function (e) {
                var cerrar = e.target.closest ? e.target.closest('[data-cerrar-modal]') : null;
                if (cerrar) {
                    e.preventDefault();
                    self.cerrarModal(cerrar.getAttribute('data-cerrar-modal'));
                }
            });

            /* Clic fuera del modal */
            $$('.pm-modal-backdrop').forEach(function (bd) {
                bd.addEventListener('mousedown', function (e) {
                    if (e.target === bd) self.cerrarModal(bd.id);
                });
            });

            document.addEventListener('keydown', function (e) {
                if (e.key === 'Escape') {
                    $$('.pm-modal-backdrop.is-open').forEach(function (bd) { self.cerrarModal(bd.id); });
                    self.cerrarMenus();
                }
            });

            /* Menu desplegable de usuario */
            var chip = $('#pmUserChip');
            var menu = $('#pmUserMenu');
            if (chip && menu) {
                chip.addEventListener('click', function (e) {
                    e.stopPropagation();
                    menu.classList.toggle('pm-hidden');
                });
                document.addEventListener('click', function (e) {
                    if (menu.classList.contains('pm-hidden')) return;
                    if (!menu.contains(e.target) && !chip.contains(e.target)) {
                        menu.classList.add('pm-hidden');
                    }
                });
            }

            /* Barra superior con fondo al hacer scroll */
            var main = $('#pmMain');
            var topbar = $('#pmTopbar');
            if (main && topbar) {
                main.addEventListener('scroll', function () {
                    topbar.classList.toggle('is-stuck', main.scrollTop > 24);
                });
            }
        },

        abrirModal: function (id) {
            var m = document.getElementById(id);
            if (!m) return;
            m.classList.add('is-open');
            var primerCampo = m.querySelector('input, select, textarea, button');
            if (primerCampo) window.setTimeout(function () { primerCampo.focus(); }, 60);
        },

        cerrarModal: function (id) {
            var m = document.getElementById(id);
            if (m) m.classList.remove('is-open');
        },

        cerrarMenus: function () {
            var menu = $('#pmUserMenu');
            if (menu) menu.classList.add('pm-hidden');
        }
    };

    /* ==============================================================================
       8. SOPORTE PARA FORMULARIOS DE ADMINISTRACION
       ============================================================================== */
    var Admin = {

        init: function () {
            var self = this;

            /* Rellenar formularios de edicion desde los atributos data-* de la fila */
            document.addEventListener('click', function (e) {
                var btn = e.target.closest ? e.target.closest('[data-editar]') : null;
                if (!btn) return;
                e.preventDefault();

                var modalId = btn.getAttribute('data-modal');
                var campos = btn.getAttribute('data-campos');
                if (!modalId || !campos) return;

                var datos;
                try { datos = JSON.parse(campos); }
                catch (err) { return; }

                var modal = document.getElementById(modalId);
                if (!modal) return;

                Object.keys(datos).forEach(function (nombre) {
                    var campo = modal.querySelector('[name="' + nombre + '"]');
                    if (campo) campo.value = datos[nombre] === null ? '' : datos[nombre];

                    /* Refleja el valor en el resto de la interfaz del modal */
                    var eco = modal.querySelector('[data-eco="' + nombre + '"]');
                    if (eco) eco.textContent = datos[nombre];
                });

                self.abrir(modalId);
            });

            /* Confirmacion para operaciones destructivas */
            document.addEventListener('click', function (e) {
                var btn = e.target.closest ? e.target.closest('[data-confirmar]') : null;
                if (!btn) return;

                var mensaje = btn.getAttribute('data-confirmar');
                if (mensaje && !window.confirm(mensaje)) {
                    e.preventDefault();
                    e.stopPropagation();
                }
            });

            /* Confirmacion desde un formulario de eliminacion */
            $$('form[data-confirmar-envio]').forEach(function (f) {
                f.addEventListener('submit', function (e) {
                    if (!window.confirm(f.getAttribute('data-confirmar-envio'))) e.preventDefault();
                });
            });

            /* Pestañas del panel */
            var tabs = $$('.pm-tab');
            tabs.forEach(function (tab) {
                tab.addEventListener('click', function () {
                    var destino = tab.getAttribute('data-panel');
                    tabs.forEach(function (t) { t.classList.remove('is-active'); });
                    tab.classList.add('is-active');
                    $$('.pm-panel').forEach(function (p) {
                        p.classList.toggle('is-active', p.id === 'panel-' + destino);
                    });
                    try { history.replaceState(null, '', '#' + destino); } catch (err) { /* noop */ }
                });
            });

            /* Restaura la pestaña indicada en la URL */
            var hash = (window.location.hash || '').substring(1);
            if (hash) {
                var activa = document.querySelector('.pm-tab[data-panel="' + hash + '"]');
                if (activa) activa.click();
            }
        },

        abrir: function (id) { UI.abrirModal(id); },
        cerrar: function (id) { UI.cerrarModal(id); }
    };

    /* ==============================================================================
       9. INICIALIZACION
       ============================================================================== */
    function iniciar() {
        Reproductor.init();
        Vistas.init();
        Filtro.init();
        UI.init();

        if ($('#pmAdminRoot')) Admin.init();

        /* Precarga las colas declaradas en el marcado para que el primer clic
           sobre Play funcione sin esperar una peticion adicional. */
        var primeraPista = $('[data-play-json]');
        if (primeraPista) {
            var payload = primeraPista.getAttribute('data-play-json');
            try {
                var lista = JSON.parse(payload || '[]');
                if (lista.length) {
                    PM.lista = lista.slice();
                    PM.origen = primeraPista.getAttribute('data-play-context') || 'catalogo';
                }
            } catch (err) { /* cola vacia */ }
        }
    }

    /* Expone la API publica para uso desde las paginas ASP */
    window.PoliMusic = {
        reproductor: Reproductor,
        vistas: Vistas,
        notificar: notificar,
        ui: UI,
        estado: PM
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', iniciar);
    } else {
        iniciar();
    }

})(window, document);
