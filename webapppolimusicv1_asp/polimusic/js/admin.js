/* ==================================================================================
   PoliMusic - Soporte del Panel de Administracion
   Responsabilidades:
     1. Filtro instantaneo sobre las tablas de cada entidad.
     2. Sincronizacion del campo oculto "id" y del selector de propietario al abrir
        un modal de actualizacion.
   Depende de: js/polimusic.js (API global PoliMusic)
   ================================================================================== */
(function (window, document) {
    'use strict';

    /* ------------------------------------------------------------------------------
       1. FILTRO INSTANTANEO POR TABLA
       Cada cuadro de busqueda declara la tabla objetivo en data-filtro-tabla.
       ------------------------------------------------------------------------------ */
    function iniciarFiltros() {
        var cajas = document.querySelectorAll('[data-filtro-tabla]');

        Array.prototype.forEach.call(cajas, function (caja) {
            var idTabla = caja.getAttribute('data-filtro-tabla');
            var tabla = document.getElementById(idTabla);
            if (!tabla) return;

            var tbody = tabla.querySelector('tbody');
            if (!tbody) return;

            caja.addEventListener('input', function () {
                var q = caja.value.trim().toLowerCase();
                var filas = tbody.querySelectorAll('[data-fila-tabla]');
                var visibles = 0;

                Array.prototype.forEach.call(filas, function (fila) {
                    var texto = (fila.getAttribute('data-texto') || '').toLowerCase();
                    var coincide = (q === '' || texto.indexOf(q) !== -1);
                    fila.classList.toggle('pm-hidden', !coincide);
                    if (coincide) visibles++;
                });

                /* Mensaje cuando el filtro no arroja resultados */
                var vacio = tabla.parentNode.querySelector('.pm-empty-filtro');
                if (visibles === 0 && filas.length > 0) {
                    if (!vacio) {
                        vacio = document.createElement('div');
                        vacio.className = 'pm-empty pm-empty-filtro';
                        vacio.innerHTML = '<p>Sin resultados para la busqueda aplicada.</p>';
                        tabla.parentNode.appendChild(vacio);
                    }
                    vacio.style.display = '';
                } else if (vacio) {
                    vacio.style.display = 'none';
                }
            });
        });
    }

    /* ------------------------------------------------------------------------------
       2. SINCRONIZACION DE MODALES
       Copia los valores de la fila seleccionada a los campos del modal. Los
       <select> requieren asignacion por indice para reflejar el valor recibido.
       ------------------------------------------------------------------------------ */
    function iniciarSincronizacion() {
        document.addEventListener('click', function (e) {
            var btn = e.target.closest ? e.target.closest('[data-editar]') : null;
            if (!btn) return;

            var modalId = btn.getAttribute('data-modal');
            var camposRaw = btn.getAttribute('data-campos');
            if (!modalId || !camposRaw) return;

            var datos;
            try { datos = JSON.parse(camposRaw); }
            catch (err) { return; }

            var modal = document.getElementById(modalId);
            if (!modal) return;

            /* Diferido: el motor principal ya escribio los campos en este mismo clic. */
            window.setTimeout(function () {
                var idOculto = modal.querySelector('input[name="id"]');
                if (idOculto && datos.id !== undefined) idOculto.value = datos.id;

                Object.keys(datos).forEach(function (nombre) {
                    var campo = modal.querySelector('[name="' + nombre + '"]');
                    if (!campo) return;

                    if (campo.tagName === 'SELECT') {
                        for (var i = 0; i < campo.options.length; i++) {
                            if (String(campo.options[i].value) === String(datos[nombre])) {
                                campo.selectedIndex = i;
                                break;
                            }
                        }
                    } else {
                        campo.value = (datos[nombre] === null || datos[nombre] === undefined) ? '' : datos[nombre];
                    }
                });
            }, 10);
        });
    }

    /* ------------------------------------------------------------------------------
       3. NAVEGACION DIRECTA A UNA PESTANA DESDE EL HASH
       Permite que los enlaces del dashboard abran una entidad especifica.
       ------------------------------------------------------------------------------ */
    function abrirPanelDesdeHash() {
        var hash = (window.location.hash || '').substring(1);
        if (!hash) return;

        var tab = document.querySelector('.pm-tab[data-panel="' + hash + '"]');
        if (tab) {
            tab.click();
            var main = document.getElementById('pmMain');
            if (main) main.scrollTop = 0;
        }
    }

    /* ------------------------------------------------------------------------------
       4. INICIALIZACION
       ------------------------------------------------------------------------------ */
    function iniciar() {
        iniciarFiltros();
        iniciarSincronizacion();
        abrirPanelDesdeHash();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', iniciar);
    } else {
        iniciar();
    }

})(window, document);
