/* ==========================================================================
   PoliMusic · Song.aspx
   Reproductor de audio: play/pause, anterior/siguiente, barra de progreso,
   volumen, busqueda en la lista y registro de reproducciones en TBL_SONG.
   ========================================================================== */
(function () {
    'use strict';

    var audio = document.getElementById('pmAudio');
    var player = document.getElementById('pmPlayer');
    var tracks = Array.prototype.slice.call(document.querySelectorAll('.pm-track'));

    var nowTitle = document.getElementById('pmNowTitle');
    var nowSub = document.getElementById('pmNowSub');
    var nowArt = document.getElementById('pmNowArt');

    var btnPlay = document.getElementById('btnPlay');
    var btnPrev = document.getElementById('btnPrev');
    var btnNext = document.getElementById('btnNext');
    var btnPlayAll = document.getElementById('btnPlayAll');
    var btnMute = document.getElementById('btnMute');
    var btnFocusSearch = document.getElementById('btnFocusSearch');

    var progress = document.getElementById('pmProgress');
    var progressFill = document.getElementById('pmProgressFill');
    var progressThumb = document.getElementById('pmProgressThumb');
    var timeNow = document.getElementById('pmTimeNow');
    var timeTotal = document.getElementById('pmTimeTotal');

    var volumeBar = document.getElementById('pmVolume');
    var volumeFill = document.getElementById('pmVolumeFill');
    var search = document.getElementById('txtSearch');
    var noResults = document.getElementById('pmNoResults');
    var toast = document.getElementById('pmToast');

    var currentTrack = null;
    var lastCountedId = null;
    var toastTimer = null;
    var DEFAULT_VOLUME = 0.8;
    var DEFAULT_ART = nowArt.innerHTML;

    /* ---------------------------------------------------------------- utils */
    function visibleTracks() {
        var list = [];
        for (var i = 0; i < tracks.length; i++) {
            if (!tracks[i].classList.contains('is-hidden')) {
                list.push(tracks[i]);
            }
        }
        return list;
    }

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds < 0) {
            return '0:00';
        }
        var total = Math.floor(seconds);
        var min = Math.floor(total / 60);
        var sec = total % 60;
        return min + ':' + (sec < 10 ? '0' + sec : sec);
    }

    function showToast(message) {
        if (!toast) {
            return;
        }
        toast.textContent = message;
        toast.classList.add('is-visible');
        window.clearTimeout(toastTimer);
        toastTimer = window.setTimeout(function () {
            toast.classList.remove('is-visible');
        }, 4200);
    }

    function clearPlayingState() {
        for (var i = 0; i < tracks.length; i++) {
            tracks[i].classList.remove('is-playing');
        }
    }

    /* ------------------------------------------------------- play counter */
    function registerPlay(track) {
        var id = track.getAttribute('data-id');
        if (!id || id === lastCountedId) {
            return;
        }
        lastCountedId = id;

        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'Handlers/SongPlay.ashx?id=' + encodeURIComponent(id), true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== 4 || xhr.status !== 200) {
                return;
            }
            try {
                var data = JSON.parse(xhr.responseText);
                if (typeof data.plays === 'number') {
                    var cells = document.querySelectorAll('[data-plays="' + id + '"]');
                    for (var i = 0; i < cells.length; i++) {
                        cells[i].textContent = data.plays;
                    }
                }
            } catch (e) {
                /* el contador no es critico para la reproduccion */
            }
        };
        xhr.send();
    }

    /* ------------------------------------------------------------- player */
    function playTrack(track) {
        if (!track) {
            return;
        }
        var src = track.getAttribute('data-src');
        var title = track.getAttribute('data-title') || 'Pista sin nombre';
        var id = track.getAttribute('data-id');

        if (!src) {
            showToast('La cancion "' + title + '" no tiene una ruta de archivo registrada.');
            return;
        }

        if (currentTrack === track && audio.src) {
            if (audio.paused) {
                audio.play();
            } else {
                audio.pause();
            }
            return;
        }

        currentTrack = track;
        clearPlayingState();
        track.classList.add('is-playing');

        nowTitle.textContent = title;
        nowSub.textContent = 'PoliMusic · MP3';

        audio.src = src;
        audio.load();

        var promise = audio.play();
        if (promise && typeof promise.catch === 'function') {
            promise.catch(function () {
                showToast('No se pudo reproducir "' + title + '". Verifica que el archivo exista en ' + src);
            });
        }

        registerPlay(track);
        var row = track.querySelector('[data-time="' + id + '"]');
        if (row) {
            row.textContent = '0:00';
        }
    }

    function step(offset) {
        var list = visibleTracks();
        if (list.length === 0) {
            return;
        }
        var index = currentTrack ? list.indexOf(currentTrack) : -1;
        if (index === -1) {
            playTrack(list[0]);
            return;
        }
        var next = index + offset;
        if (next < 0) {
            next = list.length - 1;
        }
        if (next >= list.length) {
            next = 0;
        }
        playTrack(list[next]);
    }

    function togglePlay() {
        if (!currentTrack) {
            var list = visibleTracks();
            if (list.length > 0) {
                playTrack(list[0]);
            }
            return;
        }
        if (audio.paused) {
            audio.play();
        } else {
            audio.pause();
        }
    }

    /* -------------------------------------------------------------- events */
    for (var i = 0; i < tracks.length; i++) {
        (function (track) {
            track.addEventListener('click', function () {
                playTrack(track);
            });
            track.addEventListener('keydown', function (event) {
                if (event.key === 'Enter' || event.key === ' ' || event.keyCode === 13 || event.keyCode === 32) {
                    event.preventDefault();
                    playTrack(track);
                }
            });
        })(tracks[i]);
    }

    btnPlay.addEventListener('click', togglePlay);
    btnPrev.addEventListener('click', function () { step(-1); });
    btnNext.addEventListener('click', function () { step(1); });

    if (btnPlayAll) {
        btnPlayAll.addEventListener('click', function () {
            var list = visibleTracks();
            if (list.length > 0) {
                playTrack(list[0]);
            }
        });
    }

    audio.addEventListener('play', function () {
        player.classList.add('is-playing');
        btnPlay.setAttribute('title', 'Pausar');
    });

    audio.addEventListener('pause', function () {
        player.classList.remove('is-playing');
        btnPlay.setAttribute('title', 'Reproducir');
    });

    audio.addEventListener('ended', function () {
        step(1);
    });

    audio.addEventListener('loadedmetadata', function () {
        timeTotal.textContent = formatTime(audio.duration);
        if (currentTrack) {
            var id = currentTrack.getAttribute('data-id');
            var cell = currentTrack.querySelector('[data-time="' + id + '"]');
            if (cell) {
                cell.textContent = formatTime(audio.duration);
            }
        }
    });

    audio.addEventListener('timeupdate', function () {
        var duration = audio.duration;
        var ratio = (isFinite(duration) && duration > 0) ? (audio.currentTime / duration) : 0;
        var percent = Math.min(100, Math.max(0, ratio * 100));
        progressFill.style.width = percent + '%';
        progressThumb.style.left = percent + '%';
        timeNow.textContent = formatTime(audio.currentTime);
    });

    audio.addEventListener('error', function () {
        var title = currentTrack ? currentTrack.getAttribute('data-title') : 'la pista';
        var src = currentTrack ? currentTrack.getAttribute('data-src') : '';
        showToast('No se encontro el archivo de "' + title + '". Copia el MP3 en la carpeta indicada: ' + src);
        if (currentTrack) {
            currentTrack.classList.add('is-unavailable');
        }
        player.classList.remove('is-playing');
        nowArt.innerHTML = DEFAULT_ART;
    });

    /* progress seek */
    function seekFromEvent(event) {
        if (!isFinite(audio.duration) || audio.duration <= 0) {
            return;
        }
        var rect = progress.getBoundingClientRect();
        var ratio = (event.clientX - rect.left) / rect.width;
        ratio = Math.min(1, Math.max(0, ratio));
        audio.currentTime = ratio * audio.duration;
    }

    progress.addEventListener('click', seekFromEvent);

    /* volume */
    function setVolumeFromEvent(event) {
        var rect = volumeBar.getBoundingClientRect();
        var ratio = (event.clientX - rect.left) / rect.width;
        ratio = Math.min(1, Math.max(0, ratio));
        audio.volume = ratio;
        audio.muted = false;
        volumeFill.style.width = (ratio * 100) + '%';
        player.classList.remove('is-muted');
    }

    volumeBar.addEventListener('click', setVolumeFromEvent);

    btnMute.addEventListener('click', function () {
        audio.muted = !audio.muted;
        if (audio.muted) {
            player.classList.add('is-muted');
            volumeFill.style.width = '0%';
        } else {
            player.classList.remove('is-muted');
            volumeFill.style.width = (audio.volume * 100) + '%';
        }
    });

    /* search filter */
    function filterTracks() {
        var term = (search.value || '').toLowerCase().trim();
        var shown = 0;

        for (var i = 0; i < tracks.length; i++) {
            var title = (tracks[i].getAttribute('data-title') || '').toLowerCase();
            var match = term === '' || title.indexOf(term) !== -1;
            tracks[i].classList.toggle('is-hidden', !match);
            if (match) {
                shown++;
            }
        }

        if (noResults) {
            noResults.hidden = !(shown === 0 && tracks.length > 0);
        }
    }

    if (search) {
        search.addEventListener('input', filterTracks);
        search.addEventListener('keydown', function (event) {
            if (event.key === 'Escape' || event.keyCode === 27) {
                search.value = '';
                filterTracks();
            }
        });
    }

    if (btnFocusSearch) {
        btnFocusSearch.addEventListener('click', function () {
            search.focus();
            search.select();
        });
    }

    /* keyboard shortcuts */
    document.addEventListener('keydown', function (event) {
        var tag = (event.target && event.target.tagName ? event.target.tagName.toLowerCase() : '');
        if (tag === 'input' || tag === 'textarea' || tag === 'select') {
            return;
        }
        if (event.key === ' ' || event.keyCode === 32) {
            event.preventDefault();
            togglePlay();
        } else if (event.key === 'ArrowRight' || event.keyCode === 39) {
            if (isFinite(audio.duration)) {
                audio.currentTime = Math.min(audio.duration, audio.currentTime + 5);
            }
        } else if (event.key === 'ArrowLeft' || event.keyCode === 37) {
            audio.currentTime = Math.max(0, audio.currentTime - 5);
        }
    });

    /* initial state */
    audio.volume = DEFAULT_VOLUME;
    volumeFill.style.width = (DEFAULT_VOLUME * 100) + '%';

    if (tracks.length === 0 && noResults) {
        noResults.hidden = true;
    }
})();
