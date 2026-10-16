"""
Validador estatico de sintaxis VBScript para PoliMusic (ASP Clasico).

Detecta errores de compilacion comunes SIN necesidad de IIS:
  1. Option Explicit fuera del primer bloque de script (error 800a0400).
  2. Bloques <script> en global.asa con contenido no autorizado.
  3. Delimitadores <% %> desbalanceados.
  4. Estructuras de control sin cerrar (If/End If, For/Next, Do/Loop,
     Select/End Select, Function/End Function, Sub/End Sub, With/End With).
  5. Comillas dobles impares en una linea de codigo.
  6. global.asa con '<%' o '%>' en cualquier parte.

Uso:  python validar_asp.py <carpeta_polimusic>
"""

import os
import re
import sys


def quitar_comentarios_y_cadenas(linea: str) -> str:
    """Elimina comentarios (') y el contenido de cadenas para analizar estructura."""
    resultado = []
    en_cadena = False
    i = 0
    while i < len(linea):
        c = linea[i]
        if en_cadena:
            if c == '"':
                if i + 1 < len(linea) and linea[i + 1] == '"':
                    i += 2
                    continue
                en_cadena = False
            i += 1
            continue
        if c == '"':
            en_cadena = True
            i += 1
            continue
        if c == "'":
            break
        resultado.append(c)
        i += 1
    return "".join(resultado)


def extraer_codigo_vb(contenido: str):
    """Extrae solo las regiones de codigo VBScript: bloques <% %> y <script runat=Server>."""
    regiones = []

    # Bloques <% ... %>  (con detectores de posicion para el analisis de Option Explicit)
    for m in re.finditer(r"<%(.*?)%>", contenido, re.DOTALL):
        regiones.append(("asp", m.start(), m.group(1)))

    # Bloques <script language="VBScript" runat="Server"> ... </script>
    for m in re.finditer(
        r'<script[^>]*runat\s*=\s*["\']?Server["\']?[^>]*>(.*?)</script>',
        contenido,
        re.DOTALL | re.IGNORECASE,
    ):
        regiones.append(("script", m.start(), m.group(1)))

    return regiones


def codigo_vb_plano(contenido: str) -> str:
    """
    Devuelve SOLO el codigo VBScript ejecutable, con los marcadores ASP
    (<% , %> , <%=) sustituidos por espacios para que las instrucciones queden
    al principio de linea y los analisis con regex anclados (^for, ^next, ^if)
    funcionen aunque la instruccion comparta linea con HTML.

    Ademas ELIMINA los bloques <script> de CLIENTE (JavaScript) y los bloques
    <style>, que no son VBScript y no deben analizarse.
    """
    texto = contenido

    # 1. Quitar bloques <script> de cliente (sin runat="Server")
    texto = re.sub(
        r"<script(?![^>]*runat\s*=\s*[\"']?Server)[^>]*>.*?</script\s*>",
        lambda m: "\n" * m.group(0).count("\n"),
        texto,
        flags=re.DOTALL | re.IGNORECASE,
    )
    # 1b. Quitar bloques <style>
    texto = re.sub(
        r"<style[^>]*>.*?</style\s*>",
        lambda m: "\n" * m.group(0).count("\n"),
        texto,
        flags=re.DOTALL | re.IGNORECASE,
    )

    # 2. Fuera de los bloques <% %>, el HTML no debe generar falsos positivos.
    #    Estrategia: conservar el contenido de cada bloque <% %> en su posicion
    #    de linea original, y neutralizar todo lo que este fuera.
    salida = []
    pos = 0
    for m in re.finditer(r"<%(.*?)%>", texto, re.DOTALL):
        fuera = texto[pos:m.start()]
        # Neutralizar HTML: conservar solo los saltos de linea
        salida.append("\n" * fuera.count("\n"))
        cuerpo = m.group(1)
        # Quitar el '=' inicial de <%= ... %> para que la expresion no rompa nada
        if cuerpo.startswith("="):
            cuerpo = " " + cuerpo[1:]
        salida.append(cuerpo)
        pos = m.end()
    salida.append("\n" * texto[pos:].count("\n"))
    return "".join(salida)


def solo_codigo_real(cuerpo: str) -> str:
    """Elimina comentarios y cadenas de un bloque de codigo VBScript."""
    salida = []
    for linea in cuerpo.splitlines():
        salida.append(quitar_comentarios_y_cadenas(linea))
    return "\n".join(salida)


def analizar_archivo(ruta: str):
    """Devuelve una lista de problemas encontrados en el archivo."""
    problemas = []
    with open(ruta, "r", encoding="utf-8", errors="replace") as f:
        contenido = f.read()

    nombre = os.path.basename(ruta)
    es_global_asa = nombre.lower() == "global.asa"

    # --- 1. Delimitadores desbalanceados ---------------------------------------
    abre = len(re.findall(r"<%", contenido))
    cierra = len(re.findall(r"%>", contenido))
    if abre != cierra:
        problemas.append(
            f"Delimitadores ASP desbalanceados: {abre} '<%' vs {cierra} '%>'"
        )

    # --- 2. global.asa: no puede contener <% ni %> en ningun sitio -------------
    if es_global_asa:
        if re.search(r"<%|%>", contenido):
            problemas.append(
                "global.asa contiene '<%' o '%>' -> provocara ASP 0137. "
                "Debe tener SOLO bloques <script runat=Server>"
            )
        lineas_script = re.findall(
            r'<script[^>]*language\s*=\s*["\']?VBScript["\']?[^>]*runat\s*=\s*["\']?Server["\']?[^>]*>',
            contenido,
            re.IGNORECASE,
        )
        if not lineas_script:
            problemas.append(
                'global.asa no contiene <script language="VBScript" runat="Server">'
            )
        if "</script>" not in contenido.lower():
            problemas.append("global.asa no cierra con </script>")

        # Subrutinas autorizadas
        subs = re.findall(r"^\s*Sub\s+(\w+)", contenido, re.MULTILINE | re.IGNORECASE)
        autorizadas = {
            "application_onstart",
            "application_onend",
            "session_onstart",
            "session_onend",
        }
        for s in subs:
            if s.lower() not in autorizadas:
                problemas.append(
                    f"Sub '{s}' no esta entre las autorizadas en global.asa "
                    f"(Application_OnStart/OnEnd, Session_OnStart/OnEnd) -> ASP 0137"
                )

        primera = next((l for l in contenido.splitlines() if l.strip()), "")
        if not primera.strip().lower().startswith("<script"):
            problemas.append(
                f"global.asa no empieza con <script> (empieza con: {primera[:40]!r})"
            )

    # --- 3. Option Explicit fuera de posicion valida ---------------------------
    regiones = extraer_codigo_vb(contenido)
    for tipo, pos, cuerpo in regiones:
        # Analizar SOLO codigo real (sin comentarios ni cadenas)
        codigo = solo_codigo_real(cuerpo)
        if re.search(r"\bOption\s+Explicit\b", codigo, re.IGNORECASE):
            # Valido solo si es la primera region de codigo Y es la primera
            # instruccion no comentada de esa region
            primera_region = regiones[0] if regiones else None
            es_primera = primera_region is not None and pos == primera_region[1]
            instrucciones = [
                l.strip() for l in codigo.splitlines() if l.strip()
            ]
            es_primera_instr = (
                bool(instrucciones)
                and instrucciones[0].lower().startswith("option explicit")
            )
            # Ademas, solo es valido si es la PRIMERA region de todo el archivo
            if not es_primera:
                problemas.append(
                    "Option Explicit aparece en un include posterior o fuera del "
                    "primer bloque -> error 800a0400 'Se esperaba una instruccion'"
                )
            elif not es_primera_instr:
                problemas.append(
                    "Option Explicit no es la PRIMERA instruccion del script -> "
                    "error 800a0400 'Se esperaba una instruccion'"
                )

    # --- 4. Analisis de bloques por profundidad --------------------------------
    # Se analiza SOLO el codigo VBScript (sin HTML ni JavaScript de cliente).
    profundidad = {
        "If/End If": 0,
        "For/Next": 0,
        "Do/Loop": 0,
        "Select/End Select": 0,
        "Sub|Function/End": 0,
        "With/End With": 0,
    }

    for linea in codigo_vb_plano(contenido).splitlines():
        limpia = quitar_comentarios_y_cadenas(linea)
        L = limpia.strip().lower()
        if not L:
            continue

        # --- If ... Then ---
        # Es un If multilinea SOLO si termina en 'then' y no hay nada despues.
        # Un 'If x Then instruccion' de una sola linea NO abre bloque.
        m_if = re.match(r"^if\b.*", L)
        if m_if:
            if L.rstrip().endswith("then"):
                profundidad["If/End If"] += 1
            # Si no termina en 'then', es un If de una sola linea -> no abre bloque
        if re.match(r"^end\s+if\b", L):
            profundidad["If/End If"] -= 1

        # --- For ... Next ---
        # 'For ... : Next' en la misma linea no abre bloque.
        if re.match(r"^for\b", L):
            if re.search(r"\bnext\b", L):
                pass  # bucle de una linea
            else:
                profundidad["For/Next"] += 1
        if re.match(r"^next\b", L):
            profundidad["For/Next"] -= 1

        # --- Do ... Loop ---
        if re.match(r"^do\b", L):
            if re.search(r"\bloop\b", L):
                pass
            else:
                profundidad["Do/Loop"] += 1
        if re.match(r"^loop\b", L):
            profundidad["Do/Loop"] -= 1

        # --- Select Case ... End Select ---
        if re.match(r"^select\s+case\b", L):
            profundidad["Select/End Select"] += 1
        if re.match(r"^end\s+select\b", L):
            profundidad["Select/End Select"] -= 1

        # --- Sub / Function ... End Sub/Function ---
        # Una linea 'Sub X(): ... : End Sub' no abre bloque
        if re.match(r"^(sub|function)\s+\w+", L):
            if re.search(r"\bend\s+(sub|function)\b", L):
                pass
            else:
                profundidad["Sub|Function/End"] += 1
        if re.match(r"^end\s+(sub|function)\b", L):
            profundidad["Sub|Function/End"] -= 1

        # --- With ... End With ---
        if re.match(r"^with\b", L):
            profundidad["With/End With"] += 1
        if re.match(r"^end\s+with\b", L):
            profundidad["With/End With"] -= 1

    for etiqueta, valor in profundidad.items():
        if valor != 0:
            problemas.append(
                f"Bloque '{etiqueta}' desbalanceado (diferencia: {valor:+d})"
            )

    return problemas


def _dims_globales(ruta: str):
    """Variables declaradas con Dim en el ambito global (fuera de Sub/Function)."""
    with open(ruta, "r", encoding="utf-8", errors="replace") as f:
        src = f.read()
    code = "\n".join(m.group(1) for m in re.finditer(r"<%(.*?)%>", src, re.DOTALL))
    lineas = []
    prof = 0
    for line in code.splitlines():
        L = line.strip()
        if re.match(r"^(Sub|Function)\s+\w+", L, re.IGNORECASE):
            prof += 1
            lineas.append("")
            continue
        if re.match(r"^End\s+(Sub|Function)", L, re.IGNORECASE):
            prof = max(0, prof - 1)
            lineas.append("")
            continue
        lineas.append("" if prof > 0 else line)
    body = "\n".join(lineas)
    nombres = []
    for m in re.finditer(r"^\s*Dim\s+(.+)$", body, re.MULTILINE | re.IGNORECASE):
        for v in m.group(1).split(","):
            v = v.strip().split("(")[0].strip()
            if re.fullmatch(r"\w+", v):
                nombres.append(v.lower())
    return nombres


# Composicion real de #include de cada pagina (orden de ensamblado)
COMPOSICION_PAGINAS = {
    "login.asp": [
        "_includes/config.asp", "_includes/conexion.asp",
        "_includes/sesion.asp", "login.asp",
    ],
    "logout.asp": [
        "_includes/config.asp", "_includes/conexion.asp",
        "_includes/sesion.asp", "logout.asp",
    ],
    "dashboard.asp": [
        "_includes/config.asp", "_includes/conexion.asp", "_includes/sesion.asp",
        "_includes/consultas.asp", "_includes/iconos.asp",
        "_includes/layout_superior.asp", "dashboard.asp",
        "_includes/layout_inferior.asp",
    ],
    "admin/panel.asp": [
        "_includes/config.asp", "_includes/conexion.asp", "_includes/sesion.asp",
        "_includes/consultas.asp", "_includes/iconos.asp",
        "_includes/layout_superior.asp", "admin/panel.asp",
        "_includes/layout_inferior.asp",
    ],
    "admin/procesar.asp": [
        "_includes/config.asp", "_includes/conexion.asp", "_includes/sesion.asp",
        "_includes/consultas.asp", "admin/procesar.asp",
    ],
}


def validar_dim_duplicado(base: str):
    """
    Detecta un 'Dim' duplicado en el ambito global de una pagina ensamblada.
    En VBScript eso es error FATAL de compilacion ('Name redefined') -> HTTP 500.
    """
    problemas = []
    for pagina, archivos in COMPOSICION_PAGINAS.items():
        vistos = {}
        for rel in archivos:
            ruta = os.path.join(base, rel.replace("/", os.sep))
            if not os.path.exists(ruta):
                problemas.append(f"{pagina}: no se encontro '{rel}'")
                continue
            for nombre in _dims_globales(ruta):
                if nombre in vistos:
                    problemas.append(
                        f"{pagina}: 'Dim {nombre}' duplicado en ambito global "
                        f"({vistos[nombre]} + {rel}) -> 'Name redefined' (HTTP 500)"
                    )
                else:
                    vistos[nombre] = rel
    return problemas


def validar_guardas_recordset(base: str):
    """
    Detecta accesos a .EOF / .Fields sobre una variable de Recordset que NO este
    protegida por RsValido(). Leer .EOF sobre un Recordset cerrado lanza el error
    de tiempo de ejecucion 800a01b6 ("El objeto no acepta esta propiedad o metodo").

    Heuristica: para cada variable X usada como 'X.EOF' o 'X("campo")', debe existir
    al menos una aparicion de 'RsValido(X)' en el mismo archivo.
    """
    problemas = []
    archivos = []
    for raiz, _, ficheros in os.walk(base):
        for fn in ficheros:
            if fn.lower().endswith(".asp"):
                archivos.append(os.path.join(raiz, fn))

    for ruta in sorted(archivos):
        rel = os.path.relpath(ruta, base)
        with open(ruta, "r", encoding="utf-8", errors="replace") as f:
            src = f.read()
        # Variables usadas como recordset
        usadas = set(re.findall(r"\b(\w+)\.EOF\b", src, re.IGNORECASE))
        usadas |= set(re.findall(r"\b(rs\w*)\s*\(", src))  # rsX("campo")
        protegidas = set(re.findall(r"RsValido\(\s*(\w+)\s*\)", src, re.IGNORECASE))
        for v in sorted(usadas):
            if v.lower() not in {p.lower() for p in protegidas}:
                # 'rs' puede venir de otra fuente; solo se avisa si parece un Recordset
                problemas.append(
                    f"{rel}: '{v}' se usa con .EOF/.Fields pero nunca se comprueba "
                    f"con RsValido({v}) -> posible 800a01b6"
                )
    return problemas


# Funciones, objetos y constantes incorporados de VBScript. Declarar una variable
# con uno de estos nombres la ENSOMBRECE y provoca el error de tiempo de ejecucion
# 800a000d "No coinciden los tipos: 'xxx'" al intentar invocar la funcion real.
# Ejemplo real: 'Dim rnd' rompe 'Int(Rnd() * n)'; 'Dim hex' rompe 'Hex(...)'.
RESERVADAS_VBSCRIPT = {
    "rnd", "timer", "time", "date", "now", "len", "mid", "left", "right",
    "trim", "ltrim", "rtrim", "ucase", "lcase", "instr", "instrrev", "replace",
    "split", "join", "ubound", "lbound", "array", "isnull", "isempty",
    "isnumeric", "isarray", "isobject", "isdate", "cstr", "cint", "clng",
    "cdbl", "csng", "cbool", "cdate", "asc", "ascb", "chr", "chrb", "hex",
    "oct", "abs", "int", "fix", "round", "sgn", "sqr", "exp", "log", "sin",
    "cos", "tan", "atn", "formatnumber", "formatcurrency", "formatdatetime",
    "space", "string", "strreverse", "strcomp", "filter", "msgbox", "inputbox",
    "eval", "execute", "getobject", "createobject", "randomize", "dateadd",
    "datediff", "datepart", "dateserial", "datevalue", "day", "month", "year",
    "hour", "minute", "second", "weekday", "err", "vbcrlf", "vbcr", "vblf",
    "vbtab", "vbnewline", "true", "false", "nothing", "null", "empty",
}


def validar_sombreado_funciones(base: str):
    """
    Detecta variables, parametros o contadores que ensombrecen funciones
    incorporadas de VBScript -> error de tiempo de ejecucion 800a000d
    ("No coinciden los tipos: 'xxx'").
    """
    problemas = []
    archivos = []
    for raiz, _, ficheros in os.walk(base):
        for fn in ficheros:
            if fn.lower().endswith(".asp") or fn.lower() == "global.asa":
                archivos.append(os.path.join(raiz, fn))

    for ruta in sorted(archivos):
        rel = os.path.relpath(ruta, base)
        with open(ruta, "r", encoding="utf-8", errors="replace") as f:
            src = f.read()

        bloques = [m.group(1) for m in re.finditer(r"<%(.*?)%>", src, re.DOTALL)]
        bloques += [
            m.group(1)
            for m in re.finditer(
                r'<script[^>]*runat\s*=\s*["\']?Server["\']?[^>]*>(.*?)</script>',
                src,
                re.DOTALL | re.IGNORECASE,
            )
        ]
        codigo = "\n".join(bloques)

        # 1. Dim
        for m in re.finditer(r"^\s*Dim\s+(.+)$", codigo, re.MULTILINE | re.IGNORECASE):
            for v in m.group(1).split(","):
                nombre = v.strip().split("(")[0].strip()
                if nombre.lower() in RESERVADAS_VBSCRIPT:
                    problemas.append(
                        f"{rel}: 'Dim {nombre}' ensombrece la funcion {nombre}() "
                        f"-> posible 800a000d 'No coinciden los tipos: {nombre}'"
                    )

        # 2. Parametros de Sub/Function
        for m in re.finditer(
            r"^\s*(?:Function|Sub)\s+(\w+)\s*\(([^)]*)\)", codigo, re.MULTILINE | re.IGNORECASE
        ):
            fnombre, params = m.group(1), m.group(2)
            for p in params.split(","):
                p = re.sub(r"^(ByVal|ByRef)\s+", "", p.strip(), flags=re.IGNORECASE).strip()
                if p.lower() in RESERVADAS_VBSCRIPT:
                    problemas.append(
                        f"{rel}: parametro '{p}' de {fnombre}() ensombrece {p}() "
                        f"-> posible 800a000d"
                    )

        # 3. Contadores de bucle For
        for m in re.finditer(r"^\s*For\s+(\w+)\s*=", codigo, re.MULTILINE | re.IGNORECASE):
            if m.group(1).lower() in RESERVADAS_VBSCRIPT:
                problemas.append(
                    f"{rel}: contador 'For {m.group(1)} = ...' ensombrece {m.group(1)}() "
                    f"-> posible 800a000d"
                )

    return problemas


def main():
    base = sys.argv[1] if len(sys.argv) > 1 else "."
    archivos = []
    for raiz, _, ficheros in os.walk(base):
        for fn in ficheros:
            if fn.lower().endswith(".asp") or fn.lower() == "global.asa":
                archivos.append(os.path.join(raiz, fn))

    archivos.sort()
    total_problemas = 0
    for ruta in archivos:
        rel = os.path.relpath(ruta, base)
        problemas = analizar_archivo(ruta)
        if problemas:
            total_problemas += len(problemas)
            print(f"[X] {rel}")
            for p in problemas:
                print(f"      - {p}")
        else:
            print(f"[OK] {rel}")

    # --- Analisis transversal: Dim duplicado en paginas ensambladas -------------
    problemas_dim = validar_dim_duplicado(base)
    if problemas_dim:
        total_problemas += len(problemas_dim)
        print()
        print("[X] Dim duplicado en ambito global (error fatal 'Name redefined')")
        for p in problemas_dim:
            print(f"      - {p}")
    else:
        print()
        print("[OK] Sin 'Dim' duplicados en el ambito global de las paginas ensambladas.")

    # --- Analisis transversal: guardas RsValido() sobre Recordset ---------------
    problemas_rs = validar_guardas_recordset(base)
    if problemas_rs:
        total_problemas += len(problemas_rs)
        print()
        print("[X] Recordset sin guarda RsValido() (posible 800a01b6)")
        for p in problemas_rs:
            print(f"      - {p}")
    else:
        print()
        print("[OK] Todos los Recordset estan protegidos con RsValido().")

    # --- Analisis transversal: sombreado de funciones incorporadas --------------
    problemas_sombra = validar_sombreado_funciones(base)
    if problemas_sombra:
        total_problemas += len(problemas_sombra)
        print()
        print("[X] Nombres que ensombrecen funciones de VBScript (800a000d)")
        for p in problemas_sombra:
            print(f"      - {p}")
    else:
        print()
        print("[OK] Ningun identificador ensombrece funciones incorporadas de VBScript.")

    print()
    if total_problemas == 0:
        print(f"Resultado: {len(archivos)} archivos analizados, SIN problemas detectados.")
    else:
        print(
            f"Resultado: {len(archivos)} archivos analizados, "
            f"{total_problemas} problema(s) detectado(s)."
        )
    return 0 if total_problemas == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
