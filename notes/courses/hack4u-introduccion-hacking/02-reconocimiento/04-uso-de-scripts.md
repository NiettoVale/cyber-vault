# El Nmap Scripting Engine (NSE)

Una de las características más poderosas de Nmap es el **Nmap Scripting Engine (NSE)**, un motor de scripting basado en el lenguaje Lua que permite extender el comportamiento de la herramienta mucho más allá de un simple escaneo de puertos. Hasta ahora, todo lo visto en los apuntes anteriores (estados de puertos, técnicas de evasión, detección de versiones) responde a la pregunta de "qué hay abierto y qué corre ahí"; el NSE va un paso más allá y permite automatizar tareas de reconocimiento y descubrimiento mucho más específicas: enumerar usuarios de un servicio SMB, comprobar si un servidor FTP permite acceso anónimo, detectar si un servicio es vulnerable a un CVE conocido, extraer el título de una página web, o incluso lanzar ataques de fuerza bruta contra un servicio de autenticación, todo ello sin salir de Nmap ni necesitar herramientas adicionales.

Estos scripts son, en esencia, pequeños programas escritos en Lua que Nmap ejecuta contra un objetivo cuando se le indica con el parámetro `--script`, y que pueden interactuar con los resultados del propio escaneo (por ejemplo, ejecutarse solo si detectan un puerto SMB abierto) para decidir qué comprobaciones tiene sentido realizar. En un sistema con Nmap instalado, todos estos scripts (con extensión `.nse`) se encuentran habitualmente en `/usr/share/nmap/scripts/`, y se puede localizar su ubicación exacta con:

```bash
❯ locate .nse
```

## Categorías de scripts

Nmap organiza los cientos de scripts disponibles en categorías, cada una pensada para un propósito distinto, lo que permite ejecutar de golpe un grupo entero de scripts relacionados (por ejemplo, "todos los que comprueban vulnerabilidades") en lugar de tener que indicar uno por uno. Las categorías más relevantes son:

| Categoría | Propósito |
|-----------|-----------|
| `default` | Conjunto de scripts básicos y de uso general que Nmap considera seguros y útiles en la mayoría de los escaneos; se activa de forma abreviada con `-sC`. |
| `discovery` | Scripts orientados a obtener más información sobre la red y los servicios del objetivo, como enumerar recursos compartidos, usuarios o nombres de dominio. |
| `safe` | Scripts diseñados para no causar ningún efecto adverso en el objetivo (no modifican nada, no intentan explotar nada); pensados para poder ejecutarse sin apenas riesgo. |
| `intrusive` | Scripts que pueden ser más agresivos o generar más ruido y son más fácilmente detectables por un IDS/IPS, o que corren el riesgo de afectar al funcionamiento del servicio objetivo. |
| `vuln` | Scripts centrados específicamente en comprobar si un servicio es vulnerable a fallos de seguridad conocidos (CVEs concretos, malas configuraciones típicas, etc.). |
| `auth` | Scripts relacionados con mecanismos de autenticación, como comprobar credenciales por defecto o bypasses de autenticación conocidos. |
| `brute` | Scripts que realizan ataques de fuerza bruta contra servicios de autenticación (SSH, FTP, HTTP básico, bases de datos...); pueden bloquear cuentas o generar mucho tráfico. |
| `exploit` | Scripts que van un paso más allá de detectar una vulnerabilidad e intentan explotarla activamente. |
| `dos` | Scripts que pueden llegar a provocar una denegación de servicio en el objetivo; deben usarse con muchísima precaución y solo dentro de un alcance autorizado. |
| `version` | Scripts auxiliares que ayudan a la detección de versión (`-sV`) a identificar con más precisión el software que corre detrás de un puerto. |
| `broadcast` | Scripts que envían peticiones broadcast a toda la red local para descubrir dispositivos que normalmente no responderían a un escaneo dirigido. |

Categorías como `intrusive`, `brute`, `exploit` o `dos` no son adecuadas para ejecutarse a la ligera: pueden bloquear cuentas de usuario, saturar un servicio o directamente tumbarlo, así que su uso debe quedar siempre dentro del alcance explícitamente autorizado por el cliente en una auditoría, igual que ya se comentó al hablar de las técnicas de evasión.

## Sintaxis del parámetro `--script`

El parámetro `--script` admite varias formas de indicar qué scripts ejecutar. Se puede especificar una categoría completa:

```bash
❯ nmap --script vuln 192.168.1.10
```

Uno o varios scripts concretos por su nombre, separados por comas:

```bash
❯ nmap --script ftp-anon,smb-os-discovery 192.168.1.10
```

O usar comodines para ejecutar todos los scripts cuyo nombre empiece por un mismo prefijo, útil cuando se quiere apuntar a un protocolo concreto (por ejemplo, todos los scripts relacionados con SMB):

```bash
❯ nmap --script "smb-*" 192.168.1.10
```

Además, muchos scripts aceptan parámetros propios que modifican su comportamiento (por ejemplo, indicar una lista de usuarios y contraseñas a un script de fuerza bruta), los cuales se pasan mediante `--script-args`:

```bash
❯ nmap --script ftp-brute --script-args userdb=usuarios.txt,passdb=passwords.txt 192.168.1.10
```

## Actualizando la base de datos de scripts

Los scripts de Nmap se registran en una base de datos interna (`scripts.db`) que indica a qué categorías pertenece cada uno; si se añade o modifica manualmente algún script (por ejemplo, uno descargado de un repositorio externo), es necesario regenerar esa base de datos para que Nmap lo reconozca correctamente:

```bash
❯ sudo nmap --script-updatedb
```

## Combinando escaneo, versión y scripts por defecto: `-sSVC`

Es muy habitual, sobre todo como paso inicial de reconocimiento, combinar en un mismo comando varias de las flags ya vistas en apuntes anteriores junto con la categoría `default` de NSE. La combinación `-sSVC` no es más que la unión de tres flags independientes: `-sS` (SYN scan), `-sV` (detección de versión) y `-sC` (que es, precisamente, la forma abreviada de `--script=default`). Junto con `-n` (sin resolución DNS) y `-Pn` (sin fase de descubrimiento de hosts), da como resultado un escaneo bastante completo y muy usado en la práctica:

```bash
❯ sudo nmap -sSVC -n -Pn 192.168.1.10

PORT    STATE SERVICE VERSION
22/tcp  open  ssh     OpenSSH 8.9p1 Ubuntu
80/tcp  open  http    Apache httpd 2.4.52
| http-title: Apache2 Ubuntu Default Page
|_Requested resource was http://192.168.1.10/index.html
443/tcp open  https   Apache httpd 2.4.52
```

En el resultado se puede ver cómo, además del puerto, el estado y la versión del servicio (aportados por `-sV`), aparecen líneas adicionales precedidas por `|` o `|_`: esa es precisamente la salida de los scripts de la categoría `default` que se ejecutaron automáticamente gracias a `-sC` (en este caso, `http-title`, que extrajo el título de la página web servida en el puerto 80).

# Sintaxis básica de Lua

Todos los scripts del NSE están escritos en **Lua**, un lenguaje de scripting ligero, interpretado y pensado originalmente para ser embebido dentro de otras aplicaciones (de hecho, así lo usa Nmap: como un pequeño intérprete integrado en la propia herramienta). Antes de escribir un script propio, conviene conocer un puñado de reglas básicas de sintaxis que se repiten en prácticamente cualquier script de NSE:

- **Comentarios**: se escriben con `--` para una línea, o `--[[ ... ]]` para varias líneas.
- **Variables**: no requieren declarar un tipo; por convención casi siempre se declaran como `local` (con ámbito limitado al bloque donde se definen) en lugar de globales, para evitar interferencias entre scripts distintos que Nmap pueda ejecutar en la misma sesión: `local puerto = 80`.
- **Tablas**: son la única estructura de datos compuesta de Lua, y sirven tanto de array como de diccionario (clave-valor) según cómo se rellenen: `local lista = {"ssh", "http", "https"}` o `local datos = {puerto = 80, servicio = "http"}`.
- **Cadenas de texto**: se concatenan con el operador `..` en lugar de `+`: `"Puerto " .. 80 .. " abierto"`.
- **Condicionales**: `if condicion then ... elseif otra_condicion then ... else ... end`, sin llaves ni paréntesis obligatorios alrededor de la condición.
- **Bucles**: `for i = 1, 10 do ... end` para un rango numérico, o `for clave, valor in pairs(tabla) do ... end` para recorrer una tabla.
- **Funciones**: se definen con `function nombre(parametros) ... return valor end`; en Lua las funciones son "ciudadanos de primera clase", es decir, se pueden asignar a una variable y pasar como argumento igual que cualquier otro valor, algo que el NSE aprovecha constantemente (como se ve a continuación).
- **Módulos**: se importan con `require`, de forma similar a `import` en Python: `local shortport = require "shortport"` carga el módulo `shortport`, una de las librerías auxiliares que trae Nmap para tareas comunes de los scripts (como comprobar si un puerto coincide con cierto servicio).

## Estructura de un script NSE

Todo script de NSE, más allá de la lógica concreta que implemente, sigue siempre el mismo esqueleto: un bloque de metadatos (descripción, autor, licencia, categorías), una regla que determina contra qué decide ejecutarse (`portrule` si depende de un puerto concreto, o `hostrule` si depende del host en general), y una función `action` con la lógica real, que Nmap invoca solo cuando la regla anterior se cumple:

```lua
-- prueba.nse
-- Script de prueba: saluda al detectar un puerto HTTP abierto.

local shortport = require "shortport"

description = [[
Script de prueba que comprueba si el objetivo tiene un puerto HTTP abierto
y, en ese caso, muestra un mensaje indicando la IP y el puerto detectados.
]]

author = "Nombre del autor"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe"}

-- Esta regla determina si el script debe ejecutarse: solo si el puerto
-- coincide con el 80 o con el servicio "http" detectado por -sV.
portrule = shortport.port_or_service(80, "http")

-- Esta es la función que se ejecuta cuando la regla anterior se cumple.
action = function(host, port)
  return "Puerto HTTP detectado en " .. host.ip .. ":" .. port.number
end
```

Guardando este contenido como `prueba.nse` dentro de la carpeta de scripts de Nmap (o indicando su ruta completa), se puede probar directamente con `--script`:

```bash
❯ sudo nmap --script prueba.nse -p 80 192.168.1.10

PORT   STATE SERVICE
80/tcp open  http
|_prueba: Puerto HTTP detectado en 192.168.1.10:80
```

Este ejemplo es deliberadamente sencillo (solo construye una cadena de texto), pero sigue exactamente la misma estructura que cualquier script real de la categoría `vuln` o `discovery`: la diferencia está únicamente en la complejidad de la lógica dentro de `action`, que en un script real típicamente se conecta al servicio, envía una petición concreta y analiza la respuesta para decidir si existe o no la condición que el script busca detectar.
