# MEMORY.md — Proyecto WebAppPoliMusicV2

## Stack y convenciones
- ASP.NET WebForms (Web Application Project), `TargetFrameworkVersion` v2.0, namespace raiz `WebApplication1`.
- Capas: `Entities/` (POCOs con auto-properties), `DAL/` (SqlClient + parametros, recibe la cadena de conexion por constructor), `BLL/` (mismo patron, delega al DAL y valida), paginas en la raiz.
- Cadena de conexion: `BDD_PoliMusicConnectionString` en Web.config. SQL Server en Docker: `Server=localhost,14333`, usuario `usr_polimusic`. Sin `Encrypt` a proposito (CLR 2.0 + TLS 1.2 falla en el pre-login handshake). El nombre de la entrada debe ser exacto: si se le agrega algo (ej. `,14333`), `ConnectionStrings[...]` devuelve null y salta NullReferenceException.
- Nombres de tabla/columna en mayusculas: `TBL_SONG` (ID_SONG, SONG_NAME, SONG_PATH, PLAYS), `TBL_USER`, `TBL_ALBUM`, `TBL_TRACKLIST`, `TBL_PLAYLIST`, `TBL_PLAYER`, `TBL_ARTIST`.
- Las rutas de archivos se guardan con `~/` (ej. `~/songFiles/x.mp3`) y se resuelven con `ResolveUrl`.
- Contrasenas: SHA1 en hexadecimal mayuscula (`Util.Hash.GeneratePasswordHash`); el login compara el hash.
- Session del usuario autenticado: `Session[Util.Constants.USER]` (clave "USER") con un `Entities.User`.

## UI
- Tema del laboratorio: estilo Spotify con **morado satinado** (no verde). Variables CSS `--pm-*` en `css/song.css`.
- La pantalla `Song.aspx` es la referencia visual: sidebar + topbar + hero + lista + reproductor fijo abajo.
- El proyecto debe compilar: todo archivo `.cs` y cada `.aspx` tiene que estar listado en `WebAppPoliMusicV2.csproj` (es un WAP, no un sitio web).

## Entorno / IDE
- El proyecto se abre con **Visual Studio 2022** (solución `SlnAppPoliMusic.slnx`).
- Cuando aparece el aviso "Modificación de archivo detectada", elegir **Recargar todo**. Nunca "Omitir": VS conserva su modelo en memoria y al guardar borra los ítems agregados por fuera.
- Nunca editar el `.csproj` con el proyecto abierto en VS sin recargar después.

