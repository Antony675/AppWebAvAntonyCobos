<%@ Page Title="Canciones" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV3.Song" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <style>
        /* ============================================================
           PoliMusic - Song.aspx
           Tema: morado satinado + estética de programación
           ============================================================ */
        :root {
            --pm-ink: #f6efff;
            --pm-muted: #b9a8d6;
            --pm-line: rgba(196, 148, 255, .14);
            --pm-purple: #7c3aed;
            --pm-purple-2: #a855f7;
            --pm-lilac: #d8b4fe;
        }

        body {
            background:
                radial-gradient(1100px 620px at 10% -12%, #3a1a63 0%, rgba(58, 26, 99, 0) 60%),
                radial-gradient(900px 520px at 96% -4%, #2b1150 0%, rgba(43, 17, 80, 0) 55%),
                linear-gradient(180deg, #150a26 0%, #0e0719 100%) fixed;
            background-color: #0e0719;
            color: var(--pm-ink);
            font-family: "Segoe UI", "Helvetica Neue", Arial, sans-serif;
            padding-bottom: 132px;
        }

        /* --- Barra de navegación heredada del Site.Master --- */
        .navbar.navbar-dark.bg-dark {
            background: linear-gradient(90deg, #2a1146 0%, #4c1d95 52%, #2a1146 100%) !important;
            border-bottom: 1px solid rgba(216, 180, 254, .16);
            box-shadow: 0 10px 30px -22px rgba(0, 0, 0, .9);
        }

        .navbar .navbar-brand,
        .navbar .nav-link {
            font-family: Consolas, "Courier New", monospace;
            color: #e9d5ff !important;
            letter-spacing: .02em;
        }

        .navbar .nav-link:hover,
        .navbar .navbar-brand:hover {
            color: #ffffff !important;
            text-shadow: 0 0 14px rgba(168, 85, 247, .85);
        }

        .body-content { padding-bottom: 10px; }

        footer p { color: #8b7fa8; font-size: .85rem; }

        hr { border-color: rgba(196, 148, 255, .18); opacity: 1; }

        /* --- Encabezado tipo "hero" --- */
        .pm-hero {
            position: relative;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 28px;
            margin-top: 18px;
            padding: 34px 36px;
            border-radius: 24px;
            overflow: hidden;
            border: 1px solid rgba(216, 180, 254, .18);
            background: linear-gradient(135deg, #4c1d95 0%, #6d28d9 40%, #3b1266 100%);
            box-shadow: 0 28px 60px -34px rgba(124, 58, 237, .85), inset 0 1px 0 rgba(255, 255, 255, .16);
        }

        /* Brillo satinado */
        .pm-hero::after {
            content: "";
            position: absolute;
            inset: -60% -12%;
            background: linear-gradient(100deg, rgba(255, 255, 255, 0) 34%, rgba(255, 255, 255, .18) 47%, rgba(255, 255, 255, .04) 54%, rgba(255, 255, 255, 0) 66%);
            transform: rotate(-9deg);
            pointer-events: none;
        }

        .pm-hero > * { position: relative; z-index: 1; }

        .pm-eyebrow {
            display: inline-block;
            margin-bottom: 10px;
            font-family: Consolas, "Courier New", monospace;
            font-size: .78rem;
            letter-spacing: .06em;
            color: rgba(233, 213, 255, .82);
        }

        .pm-hello {
            margin: 0 0 10px;
            font-size: clamp(1.7rem, 3.6vw, 2.6rem);
            font-weight: 700;
            letter-spacing: -.5px;
            line-height: 1.15;
        }

        .pm-user {
            display: inline-block;
            padding: 2px 12px;
            border-radius: 10px;
            font-family: Consolas, "Courier New", monospace;
            font-size: .82em;
            color: #f4e6ff;
            background: rgba(12, 5, 24, .35);
            border: 1px solid rgba(216, 180, 254, .38);
            box-shadow: inset 0 1px 0 rgba(255, 255, 255, .12);
        }

        .pm-tagline {
            margin: 0 0 20px;
            color: rgba(240, 230, 255, .84);
            font-size: .98rem;
            max-width: 46ch;
        }

        .pm-caret {
            display: inline-block;
            animation: pm-blink 1.1s steps(1, end) infinite;
            color: var(--pm-lilac);
        }

        @keyframes pm-blink { 0%, 49% { opacity: 1; } 50%, 100% { opacity: 0; } }

        .pm-stats { display: flex; flex-wrap: wrap; gap: 10px; }

        .pm-stat {
            display: flex;
            flex-direction: column;
            gap: 2px;
            min-width: 92px;
            padding: 9px 16px;
            border-radius: 14px;
            background: rgba(12, 5, 24, .28);
            border: 1px solid rgba(255, 255, 255, .12);
        }

        .pm-stat-num {
            font-family: Consolas, "Courier New", monospace;
            font-size: 1.2rem;
            font-weight: 700;
            line-height: 1.2;
        }

        .pm-stat-lbl {
            font-size: .64rem;
            letter-spacing: .16em;
            text-transform: uppercase;
            color: rgba(233, 213, 255, .68);
        }

        .pm-hero-card { position: relative; text-align: center; flex-shrink: 0; padding: 0 44px; }

        .pm-watermark {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -54%);
            font-family: Consolas, "Courier New", monospace;
            font-size: 7rem;
            font-weight: 700;
            letter-spacing: -.1em;
            color: rgba(255, 255, 255, .085);
            pointer-events: none;
            user-select: none;
            z-index: 0;
        }

        .pm-avatar {
            position: relative;
            z-index: 1;
            width: 104px;
            height: 104px;
            object-fit: cover;
            border-radius: 50%;
            border: 3px solid rgba(255, 255, 255, .55);
            box-shadow: 0 0 0 6px rgba(216, 180, 254, .16), 0 16px 32px -16px rgba(0, 0, 0, .9);
        }

        .pm-hero-card-label {
            position: relative;
            z-index: 1;
            display: block;
            margin-top: 10px;
            font-family: Consolas, "Courier New", monospace;
            font-size: .7rem;
            letter-spacing: .08em;
            color: rgba(233, 213, 255, .72);
        }

        /* --- Barra de herramientas --- */
        .pm-toolbar {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 14px;
            margin: 26px 0 14px;
        }

        .pm-term {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 8px 16px;
            border-radius: 999px;
            background: rgba(255, 255, 255, .04);
            border: 1px solid var(--pm-line);
            font-family: Consolas, "Courier New", monospace;
            font-size: .78rem;
            color: #cbb8e8;
        }

        .pm-term-dot { width: 9px; height: 9px; border-radius: 50%; display: inline-block; }
        .pm-term-dot:nth-child(1) { background: #f87171; }
        .pm-term-dot:nth-child(2) { background: #fbbf24; }
        .pm-term-dot:nth-child(3) { background: #34d399; }
        .pm-term-text { margin-left: 6px; }

        .pm-search { position: relative; }

        .pm-search-ico {
            position: absolute;
            left: 13px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 1rem;
            color: var(--pm-muted);
            pointer-events: none;
        }

        .pm-search-input {
            width: 268px;
            max-width: 100%;
            padding: 9px 16px 9px 34px;
            border-radius: 999px;
            border: 1px solid var(--pm-line);
            background: rgba(255, 255, 255, .05);
            color: var(--pm-ink);
            font-size: .88rem;
            outline: none;
            transition: border-color .18s, box-shadow .18s, background .18s;
        }

        .pm-search-input::placeholder { color: #8d7fac; }

        .pm-search-input:focus {
            border-color: var(--pm-purple-2);
            background: rgba(255, 255, 255, .08);
            box-shadow: 0 0 0 3px rgba(168, 85, 247, .22);
        }

        /* --- Lista de canciones --- */
        .pm-list {
            border: 1px solid var(--pm-line);
            border-radius: 20px;
            overflow: hidden;
            background: linear-gradient(180deg, rgba(124, 58, 237, .10) 0%, rgba(20, 10, 35, .55) 45%);
            box-shadow: 0 22px 50px -40px rgba(0, 0, 0, 1);
        }

        .pm-list-head,
        .pm-row {
            display: grid;
            grid-template-columns: 44px minmax(0, 1fr) 122px 92px 84px;
            align-items: center;
            gap: 14px;
            padding: 12px 20px;
        }

        .pm-list-head {
            font-size: .68rem;
            letter-spacing: .14em;
            text-transform: uppercase;
            color: var(--pm-muted);
            background: rgba(255, 255, 255, .025);
            border-bottom: 1px solid var(--pm-line);
        }

        .pm-list-head > span:nth-child(3),
        .pm-list-head > span:nth-child(4),
        .pm-list-head > span:nth-child(5) { text-align: right; }

        .pm-row {
            border-bottom: 1px solid rgba(196, 148, 255, .07);
            transition: background .18s ease;
        }

        .pm-row:last-child { border-bottom: 0; }
        .pm-row:hover { background: rgba(168, 85, 247, .10); }

        .pm-row.is-current {
            background: rgba(168, 85, 247, .16);
            box-shadow: inset 3px 0 0 var(--pm-purple-2);
        }

        .pm-num {
            font-family: Consolas, "Courier New", monospace;
            font-size: .85rem;
            color: var(--pm-muted);
        }

        .pm-track { display: flex; align-items: center; gap: 12px; min-width: 0; }

        .pm-cover {
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            width: 46px;
            height: 46px;
            border-radius: 11px;
            font-family: Consolas, "Courier New", monospace;
            font-size: .78rem;
            font-weight: 700;
            color: rgba(255, 255, 255, .95);
            text-shadow: 0 1px 6px rgba(0, 0, 0, .45);
            box-shadow: inset 0 1px 0 rgba(255, 255, 255, .28), 0 8px 18px -12px rgba(0, 0, 0, .9);
        }

        .pm-cover-0 { background: linear-gradient(135deg, #7c3aed, #c026d3); }
        .pm-cover-1 { background: linear-gradient(135deg, #4f46e5, #a855f7); }
        .pm-cover-2 { background: linear-gradient(135deg, #9333ea, #ec4899); }
        .pm-cover-3 { background: linear-gradient(135deg, #6d28d9, #2563eb); }
        .pm-cover-4 { background: linear-gradient(135deg, #a21caf, #7c3aed); }

        .pm-track-txt { display: flex; flex-direction: column; min-width: 0; }

        .pm-track-name {
            font-weight: 600;
            font-size: .96rem;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .pm-track-meta {
            display: flex;
            align-items: center;
            gap: 8px;
            min-width: 0;
            font-family: Consolas, "Courier New", monospace;
            font-size: .7rem;
            color: var(--pm-muted);
        }

        .pm-path {
            display: inline-block;
            max-width: 100%;
            font-family: Consolas, "Courier New", monospace;
            font-size: .7rem;
            color: #b39ddb;
            padding: 2px 8px;
            border-radius: 7px;
            background: rgba(0, 0, 0, .3);
            border: 1px solid rgba(196, 148, 255, .12);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .pm-plays {
            font-family: Consolas, "Courier New", monospace;
            font-size: .82rem;
            color: #d9c9f2;
            text-align: right;
        }

        .pm-dur {
            font-family: Consolas, "Courier New", monospace;
            font-size: .78rem;
            color: var(--pm-muted);
            text-align: right;
        }

        .pm-play {
            justify-self: end;
            width: 40px;
            height: 40px;
            border: 0;
            border-radius: 50%;
            cursor: pointer;
            color: #fff;
            font-size: .82rem;
            line-height: 1;
            background: linear-gradient(145deg, var(--pm-purple-2), #6d28d9);
            box-shadow: 0 10px 20px -12px rgba(168, 85, 247, .95), inset 0 1px 0 rgba(255, 255, 255, .35);
            transition: transform .15s ease, box-shadow .15s ease, filter .15s ease;
        }

        .pm-play:hover { transform: scale(1.08); filter: brightness(1.12); }
        .pm-play:active { transform: scale(.96); }

        .pm-play.is-off {
            background: rgba(255, 255, 255, .07);
            color: rgba(255, 255, 255, .32);
            box-shadow: none;
            cursor: not-allowed;
            transform: none;
            filter: none;
        }

        .pm-flag {
            margin-left: 8px;
            padding: 1px 7px;
            border-radius: 999px;
            font-size: .62rem;
            font-family: Consolas, "Courier New", monospace;
            color: #fca5a5;
            background: rgba(248, 113, 113, .12);
            border: 1px solid rgba(248, 113, 113, .28);
        }

        .pm-empty {
            padding: 46px 20px;
            text-align: center;
            color: var(--pm-muted);
            font-family: Consolas, "Courier New", monospace;
            font-size: .85rem;
        }

        .pm-empty code { color: var(--pm-lilac); }

        .pm-alert {
            display: block;
            margin-top: 14px;
            padding: 12px 16px;
            border-radius: 12px;
            background: rgba(248, 113, 113, .12);
            border: 1px solid rgba(248, 113, 113, .3);
            color: #fecaca;
            font-family: Consolas, "Courier New", monospace;
            font-size: .78rem;
        }

        /* --- Reproductor inferior --- */
        .pm-player {
            position: fixed;
            left: 0;
            right: 0;
            bottom: 0;
            z-index: 1030;
            display: grid;
            grid-template-columns: 1fr 1.5fr 1fr;
            align-items: center;
            gap: 20px;
            padding: 12px 28px;
            background: linear-gradient(180deg, rgba(46, 20, 74, .94) 0%, rgba(16, 8, 28, .99) 100%);
            border-top: 1px solid rgba(196, 148, 255, .22);
            backdrop-filter: blur(14px);
            box-shadow: 0 -20px 44px -26px rgba(0, 0, 0, .95);
        }

        .pm-player-track { display: flex; align-items: center; gap: 12px; min-width: 0; }

        .pm-player .pm-cover { width: 44px; height: 44px; border-radius: 10px; }

        .pm-player-txt { display: flex; flex-direction: column; min-width: 0; }

        .pm-player-name {
            font-size: .9rem;
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .pm-player-sub {
            font-family: Consolas, "Courier New", monospace;
            font-size: .7rem;
            color: var(--pm-muted);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .pm-player-controls { display: flex; align-items: center; gap: 16px; }

        .pm-big {
            width: 46px;
            height: 46px;
            flex-shrink: 0;
            border: 0;
            border-radius: 50%;
            cursor: pointer;
            color: #fff;
            font-size: .9rem;
            line-height: 1;
            background: linear-gradient(145deg, var(--pm-purple-2), #6d28d9);
            box-shadow: 0 12px 24px -12px rgba(168, 85, 247, 1), inset 0 1px 0 rgba(255, 255, 255, .4);
            transition: transform .15s ease, filter .15s ease;
        }

        .pm-big:hover { transform: scale(1.06); filter: brightness(1.12); }

        .pm-bar-wrap { display: flex; align-items: center; gap: 10px; flex: 1; }

        .pm-time {
            font-family: Consolas, "Courier New", monospace;
            font-size: .7rem;
            color: var(--pm-muted);
            min-width: 32px;
            text-align: center;
        }

        .pm-bar {
            flex: 1;
            height: 5px;
            border-radius: 999px;
            background: rgba(255, 255, 255, .13);
            cursor: pointer;
            overflow: hidden;
        }

        .pm-bar-fill {
            width: 0;
            height: 100%;
            border-radius: 999px;
            background: linear-gradient(90deg, #a855f7, #e879f9);
            box-shadow: 0 0 12px rgba(232, 121, 249, .8);
        }

        .pm-player-tag { text-align: right; }

        .pm-chip {
            padding: 3px 10px;
            border-radius: 999px;
            font-family: Consolas, "Courier New", monospace;
            font-size: .68rem;
            color: var(--pm-lilac);
            background: rgba(168, 85, 247, .14);
            border: 1px solid rgba(196, 148, 255, .26);
        }

        /* --- Responsive --- */
        @media (max-width: 900px) {
            .pm-hero { flex-direction: column; align-items: flex-start; padding: 26px; }
            .pm-hero-card { align-self: center; }
            .pm-list-head, .pm-row { grid-template-columns: 30px minmax(0, 1fr) 60px 60px; }
            .pm-dur, .pm-list-head > span:nth-child(4) { display: none; }
            .pm-player { grid-template-columns: 1fr auto; padding: 10px 16px; gap: 12px; }
            .pm-player-tag { display: none; }
            .pm-search-input { width: 100%; }
        }
    </style>

    <div class="pm-page">

        <!-- ================= Encabezado ================= -->
        <header class="pm-hero">
            <div class="pm-hero-copy">
                <span class="pm-eyebrow">// biblioteca.songs &middot; polimusic v3</span>
                <h1 class="pm-hello">Hola, <span class="pm-user">"<asp:Label ID="lblUserName" runat="server"></asp:Label>"</span></h1>
                <p class="pm-tagline">
                    Tu banda sonora para compilar sin miedo y depurar con estilo.
                    <span class="pm-caret">_</span>
                </p>
                <div class="pm-stats">
                    <div class="pm-stat">
                        <span class="pm-stat-num"><asp:Label ID="lblTotalSongs" runat="server"></asp:Label></span>
                        <span class="pm-stat-lbl">tracks</span>
                    </div>
                    <div class="pm-stat">
                        <span class="pm-stat-num"><asp:Label ID="lblTotalPlays" runat="server"></asp:Label></span>
                        <span class="pm-stat-lbl">plays</span>
                    </div>
                    <div class="pm-stat">
                        <span class="pm-stat-num">mp3</span>
                        <span class="pm-stat-lbl">formato</span>
                    </div>
                </div>
            </div>
            <div class="pm-hero-card">
                <span class="pm-watermark">&lt;/&gt;</span>
                <asp:Image ID="imgUserPhoto" runat="server" CssClass="pm-avatar" AlternateText="Foto del usuario" />
                <span class="pm-hero-card-label">session.user</span>
            </div>
        </header>

        <!-- ================= Barra de herramientas ================= -->
        <div class="pm-toolbar">
            <div class="pm-term">
                <span class="pm-term-dot"></span>
                <span class="pm-term-dot"></span>
                <span class="pm-term-dot"></span>
                <span class="pm-term-text">~/polimusic $ ls -l songs</span>
            </div>
            <div class="pm-search">
                <span class="pm-search-ico">&#9906;</span>
                <input type="text" id="pmSearch" class="pm-search-input" placeholder="filtrar por título..." autocomplete="off" />
            </div>
        </div>

        <!-- ================= Lista de canciones ================= -->
        <section class="pm-list" aria-label="Lista de canciones">
            <div class="pm-list-head">
                <span>#</span>
                <span>Título</span>
                <span>Reproducciones</span>
                <span>Duración</span>
                <span>Play</span>
            </div>

            <asp:Repeater ID="rptSongs" runat="server">
                <ItemTemplate>
                    <div class="pm-row" data-title='<%#: Eval("SongName") %>'>
                        <span class="pm-num"><%# Container.ItemIndex + 1 %></span>

                        <div class="pm-track">
                            <div class='pm-cover pm-cover-<%# (Container.ItemIndex % 5) %>'>
                                <span><%# GetGlyph(Container.ItemIndex) %></span>
                            </div>
                            <div class="pm-track-txt">
                                <span class="pm-track-name"><%#: Eval("SongName") %></span>
                                <span class="pm-track-meta">
                                    <code class="pm-path"><%#: Eval("SongPath") %></code>
                                    <span class='pm-flag <%# IsAvailable((string)Eval("SongPath")) ? "d-none" : "" %>'>archivo no disponible</span>
                                </span>
                            </div>
                        </div>

                        <span class="pm-plays"><%# Eval("Plays") %></span>

                        <span class="pm-dur" data-dur='<%# Eval("ID") %>'><%# IsAvailable((string)Eval("SongPath")) ? "--:--" : "&mdash;" %></span>

                        <button type="button"
                                class='pm-play <%# IsAvailable((string)Eval("SongPath")) ? "" : "is-off" %>'
                                data-src='<%# ResolveUrl((string)Eval("SongPath")) %>'
                                data-title='<%#: Eval("SongName") %>'
                                data-id='<%# Eval("ID") %>'
                                aria-label="Reproducir canción">&#9654;</button>
                    </div>
                </ItemTemplate>
            </asp:Repeater>

            <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
                <div class="pm-empty">
                    // 0 resultados &rarr; la tabla <code>TBL_SONG</code> no tiene registros.
                </div>
            </asp:PlaceHolder>

            <div class="pm-empty" id="pmNoResults" style="display: none;">
                // 0 coincidencias para el filtro aplicado.
            </div>
        </section>

        <asp:Label ID="lblMessage" runat="server" CssClass="pm-alert" Visible="false"></asp:Label>

    </div>

    <!-- ================= Reproductor ================= -->
    <div class="pm-player">
        <div class="pm-player-track">
            <div class="pm-cover pm-cover-0" id="pmCover"><span>{ }</span></div>
            <div class="pm-player-txt">
                <span class="pm-player-name" id="pmNowName">Nada en reproducción</span>
                <span class="pm-player-sub" id="pmNowSub">Elige una canción de la lista</span>
            </div>
        </div>

        <div class="pm-player-controls">
            <button type="button" class="pm-big" id="pmToggle" aria-label="Reproducir o pausar">&#9654;</button>
            <div class="pm-bar-wrap">
                <span class="pm-time" id="pmCur">0:00</span>
                <div class="pm-bar" id="pmBar"><div class="pm-bar-fill" id="pmFill"></div></div>
                <span class="pm-time" id="pmDur">0:00</span>
            </div>
        </div>

        <div class="pm-player-tag">
            <span class="pm-chip">.mp3 &middot; stream</span>
        </div>
    </div>

    <audio id="pmAudio" preload="none"></audio>

    <script type="text/javascript">
        (function () {
            var audio = document.getElementById('pmAudio');
            if (!audio) { return; }

            var btnToggle = document.getElementById('pmToggle'),
                bar = document.getElementById('pmBar'),
                fill = document.getElementById('pmFill'),
                cur = document.getElementById('pmCur'),
                dur = document.getElementById('pmDur'),
                nowName = document.getElementById('pmNowName'),
                nowSub = document.getElementById('pmNowSub'),
                cover = document.getElementById('pmCover'),
                search = document.getElementById('pmSearch');

            var currentBtn = null;

            function formatTime(seconds) {
                if (!isFinite(seconds) || seconds < 0) { seconds = 0; }
                var m = Math.floor(seconds / 60),
                    s = Math.floor(seconds % 60);
                return m + ':' + (s < 10 ? '0' : '') + s;
            }

            function setIcon(playing) {
                btnToggle.innerHTML = playing ? '&#10074;&#10074;' : '&#9654;';
                btnToggle.setAttribute('aria-label', playing ? 'Pausar' : 'Reproducir');
            }

            function tryPlay() {
                var promise = audio.play();
                if (promise && typeof promise.catch === 'function') {
                    promise.catch(function () { /* el navegador puede bloquear el autoplay */ });
                }
            }

            function clearCurrent() {
                var rows = document.querySelectorAll('.pm-row.is-current');
                for (var i = 0; i < rows.length; i++) {
                    rows[i].classList.remove('is-current');
                }
            }

            function registerPlay(id) {
                if (!id || typeof PageMethods === 'undefined') { return; }
                try {
                    PageMethods.RegisterPlay(id, function () { }, function () { });
                } catch (e) { /* el conteo es opcional, nunca bloquea la reproducción */ }
            }

            function playFrom(btn) {
                if (!btn || btn.classList.contains('is-off')) { return; }

                if (currentBtn === btn && audio.src) {
                    if (audio.paused) { tryPlay(); } else { audio.pause(); }
                    return;
                }

                currentBtn = btn;
                audio.src = btn.getAttribute('data-src');
                fill.style.width = '0%';
                cur.textContent = '0:00';
                tryPlay();

                nowName.textContent = btn.getAttribute('data-title');
                nowSub.textContent = 'Reproduciendo ahora';

                var row = btn.closest('.pm-row');
                clearCurrent();
                if (row) {
                    row.classList.add('is-current');
                    var rowCover = row.querySelector('.pm-cover');
                    if (rowCover) {
                        cover.className = rowCover.className;
                        cover.innerHTML = rowCover.innerHTML;
                    }
                    var plays = row.querySelector('.pm-plays');
                    if (plays) {
                        plays.textContent = (parseInt(plays.textContent, 10) || 0) + 1;
                    }
                }

                registerPlay(parseInt(btn.getAttribute('data-id'), 10));
            }

            // Botones de reproducción de cada fila
            var playButtons = document.querySelectorAll('.pm-play');

            // Lee la duración real del mp3 (metadatos) y la pinta en la columna Duración
            function bindDuration(btn) {
                if (btn.classList.contains('is-off')) { return; }
                var probe = new Audio();
                probe.preload = 'metadata';
                probe.addEventListener('loadedmetadata', function () {
                    var cell = document.querySelector('[data-dur="' + btn.getAttribute('data-id') + '"]');
                    if (cell) { cell.textContent = formatTime(probe.duration); }
                });
                probe.src = btn.getAttribute('data-src');
            }

            function bindPlay(btn) {
                btn.addEventListener('click', function () { playFrom(btn); });
                bindDuration(btn);
            }

            for (var i = 0; i < playButtons.length; i++) {
                bindPlay(playButtons[i]);
            }

            // Botón principal del reproductor
            btnToggle.addEventListener('click', function () {
                if (!audio.src) {
                    var first = document.querySelector('.pm-play:not(.is-off)');
                    playFrom(first);
                    return;
                }
                if (audio.paused) { tryPlay(); } else { audio.pause(); }
            });

            audio.addEventListener('play', function () { setIcon(true); });
            audio.addEventListener('pause', function () { setIcon(false); });

            audio.addEventListener('loadedmetadata', function () {
                dur.textContent = formatTime(audio.duration);
            });

            audio.addEventListener('timeupdate', function () {
                if (audio.duration) {
                    fill.style.width = ((audio.currentTime / audio.duration) * 100) + '%';
                }
                cur.textContent = formatTime(audio.currentTime);
            });

            audio.addEventListener('ended', function () {
                fill.style.width = '0%';
                cur.textContent = '0:00';
                setIcon(false);
                nowSub.textContent = 'Finalizó la reproducción';
            });

            audio.addEventListener('error', function () {
                setIcon(false);
                nowSub.textContent = 'No se pudo cargar el archivo';
            });

            // Buscar dentro de la posición de la barra
            bar.addEventListener('click', function (e) {
                if (!audio.duration) { return; }
                var rect = bar.getBoundingClientRect();
                audio.currentTime = ((e.clientX - rect.left) / rect.width) * audio.duration;
            });

            // Filtro en vivo por título (sin postback, no corta la música)
            if (search) {
                search.addEventListener('input', function () {
                    var q = this.value.toLowerCase().trim(),
                        rows = document.querySelectorAll('.pm-row'),
                        visible = 0;
                    for (var j = 0; j < rows.length; j++) {
                        var title = (rows[j].getAttribute('data-title') || '').toLowerCase(),
                            show = title.indexOf(q) !== -1;
                        rows[j].style.display = show ? '' : 'none';
                        if (show) { visible++; }
                    }
                    var empty = document.getElementById('pmNoResults');
                    if (empty) { empty.style.display = visible === 0 ? '' : 'none'; }
                });
            }
        })();
    </script>

</asp:Content>
