# Estados de un puerto

Cuando Nmap escanea un puerto, no se limita a devolver un simple "sí" o "no": clasifica cada puerto en uno de varios estados posibles, y entender bien la diferencia entre ellos es fundamental para interpretar correctamente los resultados de un escaneo (y para no descartar por error un puerto que en realidad podría ser interesante). Los tres estados que nos vamos a encontrar con más frecuencia son:

| Estado | Significado |
|--------|-------------|
| **open** (abierto) | Hay una aplicación aceptando activamente conexiones TCP o paquetes UDP en ese puerto. Es el estado que más nos interesa como atacantes o auditores, porque indica un servicio real con el que podemos interactuar. |
| **closed** (cerrado) | El puerto es accesible (responde a los paquetes de Nmap) pero no hay ninguna aplicación escuchando en él. Es útil saber que un host está detrás de esa IP, aunque ese puerto en concreto no sirva de mucho. |
| **filtered** (filtrado) | Nmap no puede determinar si el puerto está abierto o cerrado, porque un firewall, filtro de paquetes u otro obstáculo de red está bloqueando la sonda y no llega ninguna respuesta (o llega una respuesta de error inutilizable). |

La diferencia entre "cerrado" y "filtrado" es más importante de lo que parece a primera vista: un puerto cerrado significa que nuestros paquetes llegan sin problema al host y el sistema operativo simplemente responde que ahí no hay nada (normalmente con un paquete `RST`), mientras que un puerto filtrado significa que algo intermedio (típicamente un firewall) está descartando los paquetes en silencio, sin que sepamos si detrás hay o no un servicio real. Además de estos tres, Nmap puede reportar otros estados menos frecuentes, como `unfiltered` (el puerto es accesible pero Nmap no logra determinar si está abierto o cerrado, algo que ocurre solo con ciertos tipos de escaneo como el ACK scan), `open|filtered` y `closed|filtered`, estados "ambiguos" que aparecen cuando la técnica de escaneo utilizada no permite distinguir con certeza entre las dos opciones (algo habitual, por ejemplo, en escaneos UDP).

# Escaneo TCP vs escaneo UDP

Por defecto, cuando se ejecuta con privilegios de administrador (root), Nmap realiza un **SYN scan** (`-sS`) sobre los puertos TCP más comunes: como ya vimos al hablar del three-way handshake, esta técnica envía un paquete `SYN` a cada puerto y, en lugar de completar la conexión, la corta a medias en cuanto obtiene respuesta, lo que la hace más rápida y más difícil de registrar en los logs de aplicación del objetivo que una conexión completa. Si Nmap se ejecuta sin privilegios suficientes para construir paquetes en bruto (raw sockets), recurre automáticamente a un **TCP connect scan** (`-sT`), que sí completa el handshake por completo usando las llamadas normales del sistema operativo; funciona en cualquier circunstancia, pero es más lento y deja un rastro mucho más visible en el objetivo, ya que cada conexión llega a establecerse del todo.

Junto al mundo TCP, Nmap también permite escanear puertos **UDP** con la flag `-sU`. Al no existir en UDP un equivalente al three-way handshake, el mecanismo es distinto: Nmap envía un paquete UDP vacío (o con datos específicos del protocolo, según el puerto) y espera respuesta. Si recibe una respuesta UDP, el puerto está abierto; si recibe un mensaje ICMP de "puerto inalcanzable" (`ICMP port unreachable`), el puerto está cerrado; y si no recibe nada en absoluto, Nmap lo marca como `open|filtered`, porque no hay forma de distinguir un puerto abierto que simplemente no responde (muchos servicios UDP se comportan así con paquetes vacíos) de un firewall que está descartando el tráfico en silencio. Esta ambigüedad, sumada a que hay que esperar un tiempo prudencial por cada puerto antes de darlo por perdido, hace que los escaneos UDP sean notablemente más lentos que los TCP:

```bash
❯ nmap -sU --top-ports 500 --open -v -n 192.168.1.1
```

# Acotando el alcance del escaneo: `--top-ports`, `--open` y `-v`

Cuantos más puertos se escaneen, más tiempo tarda el escaneo, sobre todo si se aplican técnicas poco intrusivas (temporizaciones lentas) porque, como ya se mencionó, Nmap genera bastante tráfico de red por cada puerto que comprueba. Por eso, en la práctica, casi nunca se escanean directamente los 65535 puertos posibles como primer paso: es mucho más habitual empezar por un subconjunto reducido de los puertos más comunes, usando `--top-ports`, para hacerse una idea rápida del objetivo antes de decidir si merece la pena profundizar:

```bash
❯ nmap --top-ports 500 192.168.1.1
```

Con esto se escanean los 500 puertos más frecuentes según la base de datos interna de Nmap (una lista basada en estadísticas reales de qué puertos suelen estar abiertos en Internet), en lugar de los 1000 que se escanean por defecto sin especificar nada.

Como durante una auditoría lo que de verdad interesa son los puertos abiertos (los cerrados y filtrados aportan poca información accionable), se puede añadir la flag `--open` para que Nmap solo muestre en el resultado final los puertos que están efectivamente abiertos, omitiendo el resto. Y para no esperar en silencio hasta que el escaneo completo termine, `-v` (verbose) hace que Nmap vaya mostrando información adicional a medida que va descubriendo cosas, en lugar de mostrar todo de golpe al final:

```bash
❯ nmap --top-ports 500 --open -v 192.168.1.1
```

# Resolución DNS: `-n`

Por defecto, Nmap intenta resolver el nombre de dominio inverso (reverse DNS) de cada IP que escanea, una consulta adicional que puede alargar innecesariamente el tiempo total del escaneo, sobre todo contra rangos grandes de direcciones. Si esa información no es relevante para la auditoría (o si el objetivo no tiene ningún registro DNS inverso configurado, algo muy habitual en redes internas), se puede desactivar esta resolución con `-n`, acelerando el escaneo:

```bash
❯ nmap --top-ports 500 --open -v -n 192.168.1.1
```

# Plantillas de temporización: `-T<n>`

Nmap agrupa un conjunto de parámetros relacionados con la velocidad del escaneo (tiempos de espera entre sondas, número de sondas en paralelo, tiempo máximo de espera por respuesta, etc.) en seis plantillas predefinidas, numeradas de `-T0` a `-T5`, para no tener que ajustar cada parámetro por separado:

| Plantilla | Nombre | Comportamiento |
|-----------|--------|----------------|
| `-T0` | Paranoid | El más lento y sigiloso de todos; espacia mucho las sondas para evadir sistemas de detección de intrusiones (IDS/IPS). Puede tardar horas. |
| `-T1` | Sneaky | Similar al anterior, algo más rápido, pensado también para evadir detección. |
| `-T2` | Polite | Reduce el uso de ancho de banda y CPU para no sobrecargar el objetivo, a costa de velocidad. |
| `-T3` | Normal | Comportamiento por defecto de Nmap si no se especifica ninguna plantilla; un equilibrio razonable entre velocidad y discreción. |
| `-T4` | Aggressive | Acelera notablemente el escaneo asumiendo una red fiable y rápida; es la opción más usada en laboratorios y máquinas de práctica, donde no preocupa ser detectado. |
| `-T5` | Insane | El más agresivo y rápido de todos, a costa de sacrificar precisión (puede pasar por alto puertos abiertos si el objetivo tarda en responder). |

En una auditoría real contra un cliente, donde puede haber un IDS/IPS vigilando el tráfico, conviene inclinarse hacia plantillas más lentas y discretas (`-T0`, `-T1` o `-T2`); en un entorno de práctica sin esas restricciones, `-T4` suele ser la opción por defecto para no perder tiempo esperando innecesariamente.

# Descubrimiento de hosts: `-Pn` y `-sn`

Antes de escanear puertos, Nmap suele realizar primero una fase de descubrimiento para comprobar si el host (u hosts) indicado está realmente activo, evitando así perder tiempo escaneando puertos de una máquina que ni siquiera existe o está apagada. El método que utiliza para esta comprobación depende de si el objetivo está en la misma red local o no: contra hosts de la red local, Nmap envía peticiones ARP (mucho más fiables en ese contexto, porque ARP es imprescindible para que cualquier comunicación funcione y prácticamente ningún firewall de host lo bloquea); contra hosts remotos, combina otras técnicas como el envío de paquetes ICMP echo request, un TCP SYN al puerto 443, un TCP ACK al puerto 80 y una petición ICMP timestamp, dando por activo al host si responde a cualquiera de ellas.

Si ya sabemos con certeza que el host objetivo está activo (por ejemplo, porque acabamos de hacer ping o porque ya interactuamos antes con él), esta fase de descubrimiento es un paso innecesario que solo añade tiempo al escaneo; en ese caso se puede omitir con `-Pn`, indicándole a Nmap que dé por hecho que el host está vivo y pase directamente a escanear los puertos:

```bash
❯ nmap --top-ports 500 --open -v -n -Pn 192.168.1.1
```

La flag `-Pn` es especialmente útil, además, contra objetivos que bloquean explícitamente ICMP o las sondas de descubrimiento por defecto: sin `-Pn`, Nmap podría dar por muerto (y por tanto no escanear en absoluto) un host que en realidad sí está activo, simplemente porque no respondió a la fase de descubrimiento.

Si en cambio lo que se quiere es justo lo contrario (averiguar qué hosts de un rango completo están activos, sin llegar a escanear ningún puerto todavía), se usa `-sn` ("no port scan"), que realiza únicamente esa fase de descubrimiento y reporta qué máquinas respondieron, un paso muy habitual al empezar a auditar una red entera antes de decidir contra qué hosts concretos merece la pena lanzar un escaneo de puertos completo:

```bash
❯ nmap -sn 192.168.1.0/24
```

# Detección de sistema operativo: `-O`

La flag `-O` le indica a Nmap que intente determinar el sistema operativo del objetivo, analizando particularidades sutiles en cómo responde su pila TCP/IP a distintos tipos de paquetes (valores del TTL inicial, tamaño de ventana TCP, opciones específicas, comportamiento ante paquetes malformados, etc.) y comparando esas respuestas contra una base de datos de miles de huellas digitales conocidas. Aunque es una funcionalidad útil, conviene usarla con moderación: requiere enviar bastantes sondas adicionales para obtener suficientes datos con los que comparar, lo que genera notablemente más tráfico que un escaneo de puertos normal y la hace más fácil de detectar por un IDS/IPS, además de no ser siempre fiable al 100% (sobre todo contra hosts detrás de un firewall que altera o descarta parte de esas sondas).
