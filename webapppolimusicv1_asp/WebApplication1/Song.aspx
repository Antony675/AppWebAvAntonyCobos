<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebApplication1.Song" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Canciones · PoliMusic</title>
    <link rel="stylesheet" href="css/song.css" />
</head>
<body>
    <form id="formSong" runat="server">
        <div class="pm-shell">

            <!-- ================= SIDEBAR ================= -->
            <aside class="pm-sidebar">
                <a class="pm-brand" href="Default.aspx">
                    <span class="pm-brand__mark">
                        <svg viewBox="0 0 24 24" aria-hidden="true">
                            <circle cx="12" cy="12" r="10"></circle>
                            <circle cx="12" cy="12" r="3.2"></circle>
                            <path d="M12 2a10 10 0 0 1 10 10"></path>
                        </svg>
                    </span>
                    <span class="pm-brand__text">Poli<strong>Music</strong></span>
                </a>

                <nav class="pm-nav">
                    <a class="pm-nav__item" href="Default.aspx">
                        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 10.5 12 3l9 7.5"></path><path d="M5 9.8V21h14V9.8"></path></svg>
                        <span>Inicio</span>
                    </a>
                    <a class="pm-nav__item is-active" href="Song.aspx">
                        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 18V5l10-2v13"></path><circle cx="6.5" cy="18" r="2.5"></circle><circle cx="16.5" cy="16" r="2.5"></circle></svg>
                        <span>Canciones</span>
                    </a>
                    <button type="button" class="pm-nav__item" id="btnFocusSearch">
                        <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle><path d="m20 20-4.2-4.2"></path></svg>
                        <span>Buscar</span>
                    </button>
                </nav>

                <div class="pm-side__section">
                    <div class="pm-side__title">Tu biblioteca</div>
                    <div class="pm-libcard">
                        <div class="pm-libcard__art">
                            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 18V5l10-2v13"></path><circle cx="6.5" cy="18" r="2.5"></circle><circle cx="16.5" cy="16" r="2.5"></circle></svg>
                        </div>
                        <div class="pm-libcard__body">
                            <div class="pm-libcard__title">Todas las canciones</div>
                            <div class="pm-libcard__meta">
                                <asp:Label ID="lblSideCount" runat="server"></asp:Label>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="pm-side__section pm-side__section--grow">
                    <div class="pm-side__title">Conexión</div>
                    <div class="pm-conn">
                        <span class="pm-conn__dot"></span>
                        <span>BDD_PoliMusic · SQL Server</span>
                    </div>
                    <div class="pm-conn pm-conn--muted">
                        <span>Tabla TBL_SONG</span>
                    </div>
                </div>

                <div class="pm-sideuser">
                    <div class="pm-avatar pm-avatar--sm">
                        <asp:Literal ID="litSideAvatar" runat="server" />
                    </div>
                    <div class="pm-sideuser__info">
                        <div class="pm-sideuser__name">
                            <asp:Label ID="lblSideUserName" runat="server"></asp:Label>
                        </div>
                        <div class="pm-sideuser__role">Sesión activa</div>
                    </div>
                    <a class="pm-sideuser__out" href="Logout.aspx" title="Cerrar sesión">
                        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3"></path><path d="M10 8l-4 4 4 4"></path><path d="M6 12h9"></path></svg>
                    </a>
                </div>
            </aside>

            <!-- ================= MAIN ================= -->
            <main class="pm-main">
                <header class="pm-topbar">
                    <div class="pm-topbar__history">
                        <span class="pm-roundbtn">
                            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M14 6l-6 6 6 6"></path></svg>
                        </span>
                        <span class="pm-roundbtn">
                            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M10 6l6 6-6 6"></path></svg>
                        </span>
                    </div>

                    <div class="pm-search">
                        <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle><path d="m20 20-4.2-4.2"></path></svg>
                        <asp:TextBox ID="txtSearch" runat="server" CssClass="pm-search__input"
                            placeholder="¿Qué quieres escuchar?" autocomplete="off"></asp:TextBox>
                    </div>

                    <div class="pm-userchip">
                        <div class="pm-avatar">
                            <asp:Literal ID="litUserAvatar" runat="server" />
                        </div>
                        <div class="pm-userchip__text">
                            <span class="pm-userchip__label">Autenticado como</span>
                            <asp:Label ID="lblUserName" runat="server" CssClass="pm-userchip__name"></asp:Label>
                        </div>
                        <a class="pm-userchip__out" href="Logout.aspx">Salir</a>
                    </div>
                </header>

                <div class="pm-scroll">
                    <!-- HERO -->
                    <section class="pm-hero">
                        <div class="pm-hero__art">
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M9 18V5l10-2v13"></path>
                                <circle cx="6.5" cy="18" r="2.5"></circle>
                                <circle cx="16.5" cy="16" r="2.5"></circle>
                            </svg>
                        </div>
                        <div class="pm-hero__text">
                            <div class="pm-hero__kind">Biblioteca</div>
                            <h1 class="pm-hero__title">Canciones</h1>
                            <div class="pm-hero__meta">
                                <asp:Label ID="lblHeroUser" runat="server" CssClass="pm-hero__owner"></asp:Label>
                                <span class="pm-hero__sep">·</span>
                                <asp:Label ID="lblSongCount" runat="server"></asp:Label>
                                <span class="pm-hero__sep">·</span>
                                <asp:Label ID="lblTotalPlays" runat="server"></asp:Label>
                            </div>
                        </div>
                    </section>

                    <!-- TOOLBAR -->
                    <div class="pm-toolbar">
                        <button type="button" class="pm-playall" id="btnPlayAll">
                            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 4.5 19.5 12 7 19.5z"></path></svg>
                        </button>
                        <div class="pm-toolbar__hint" id="pmHint">Reproduce cualquier pista de la lista</div>
                    </div>

                    <!-- TRACK LIST -->
                    <section class="pm-panel">
                        <div class="pm-listhead">
                            <span class="pm-col-idx">#</span>
                            <span class="pm-col-title">Título</span>
                            <span class="pm-col-plays">Reproducciones</span>
                            <span class="pm-col-time">Duración</span>
                            <span class="pm-col-eq"></span>
                        </div>

                        <asp:Repeater ID="rptSongs" runat="server">
                            <ItemTemplate>
                                <div class="pm-track"
                                    role="button"
                                    tabindex="0"
                                    data-id="<%# Eval("ID_SONG") %>"
                                    data-src="<%# ResolveUrl(Convert.ToString(Eval("SONG_PATH"))) %>"
                                    data-title="<%# Server.HtmlEncode(Convert.ToString(Eval("SONG_NAME"))) %>">
                                    <div class="pm-track__idx">
                                        <span class="pm-track__num"><%# Container.ItemIndex + 1 %></span>
                                        <span class="pm-track__play">
                                            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 4.5 19.5 12 7 19.5z"></path></svg>
                                        </span>
                                    </div>
                                    <div class="pm-track__main">
                                        <div class="pm-track__art">
                                            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 18V5l10-2v13"></path><circle cx="6.5" cy="18" r="2.5"></circle><circle cx="16.5" cy="16" r="2.5"></circle></svg>
                                        </div>
                                        <div class="pm-track__info">
                                            <div class="pm-track__title"><%# Server.HtmlEncode(Convert.ToString(Eval("SONG_NAME"))) %></div>
                                            <div class="pm-track__sub">PoliMusic · MP3</div>
                                        </div>
                                    </div>
                                    <div class="pm-track__plays">
                                        <span class="pm-plays" data-plays="<%# Eval("ID_SONG") %>"><%# Eval("PLAYS") %></span>
                                    </div>
                                    <div class="pm-track__time" data-time="<%# Eval("ID_SONG") %>">--:--</div>
                                    <div class="pm-track__eq">
                                        <span></span><span></span><span></span><span></span>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                        <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="pm-empty">
                            <div class="pm-empty__title">Todavía no hay canciones</div>
                            <div class="pm-empty__text">
                                <asp:Label ID="lblEmptyText" runat="server" Text="La tabla TBL_SONG no tiene registros para mostrar."></asp:Label>
                            </div>
                        </asp:Panel>

                        <div class="pm-noresults" id="pmNoResults" hidden>
                            <div class="pm-empty__title">Sin coincidencias</div>
                            <div class="pm-empty__text">Ninguna canción coincide con tu búsqueda.</div>
                        </div>
                    </section>
                </div>
            </main>
        </div>

        <!-- ================= PLAYER ================= -->
        <footer class="pm-player" id="pmPlayer">
            <div class="pm-player__now">
                <div class="pm-player__art" id="pmNowArt">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 18V5l10-2v13"></path><circle cx="6.5" cy="18" r="2.5"></circle><circle cx="16.5" cy="16" r="2.5"></circle></svg>
                </div>
                <div class="pm-player__meta">
                    <div class="pm-player__title" id="pmNowTitle">Selecciona una canción</div>
                    <div class="pm-player__sub" id="pmNowSub">PoliMusic</div>
                </div>
                <div class="pm-player__eq" id="pmNowEq"><span></span><span></span><span></span></div>
            </div>

            <div class="pm-player__center">
                <div class="pm-controls">
                    <button type="button" class="pm-ctrl" id="btnPrev" title="Anterior">
                        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M18 5v14L8 12z"></path><path d="M6 5v14"></path></svg>
                    </button>
                    <button type="button" class="pm-ctrl pm-ctrl--main" id="btnPlay" title="Reproducir">
                        <svg class="pm-ico-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M7 4.5 19.5 12 7 19.5z"></path></svg>
                        <svg class="pm-ico-pause" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5v14"></path><path d="M16 5v14"></path></svg>
                    </button>
                    <button type="button" class="pm-ctrl" id="btnNext" title="Siguiente">
                        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 5v14l10-7z"></path><path d="M18 5v14"></path></svg>
                    </button>
                </div>
                <div class="pm-progress">
                    <span class="pm-progress__time" id="pmTimeNow">0:00</span>
                    <div class="pm-progress__track" id="pmProgress">
                        <div class="pm-progress__fill" id="pmProgressFill"></div>
                        <div class="pm-progress__thumb" id="pmProgressThumb"></div>
                    </div>
                    <span class="pm-progress__time" id="pmTimeTotal">0:00</span>
                </div>
            </div>

            <div class="pm-player__right">
                <button type="button" class="pm-ctrl pm-ctrl--small" id="btnMute" title="Silenciar">
                    <svg class="pm-ico-vol" viewBox="0 0 24 24" aria-hidden="true"><path d="M4 9v6h4l5 4V5L8 9z"></path><path d="M17 9a4 4 0 0 1 0 6"></path><path d="M19.5 6.5a8 8 0 0 1 0 11"></path></svg>
                    <svg class="pm-ico-mute" viewBox="0 0 24 24" aria-hidden="true"><path d="M4 9v6h4l5 4V5L8 9z"></path><path d="m17 9 5 6"></path><path d="m22 9-5 6"></path></svg>
                </button>
                <div class="pm-volume" id="pmVolume">
                    <div class="pm-volume__fill" id="pmVolumeFill"></div>
                </div>
            </div>

            <audio id="pmAudio" preload="metadata"></audio>
        </footer>

        <div class="pm-toast" id="pmToast"></div>
    </form>

    <script src="js/song.js"></script>
</body>
</html>
