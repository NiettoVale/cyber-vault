# Nmap

Nmap (Network Mapper) es una herramienta de escaneo de red gratuita y de código abierto, creada en 1997 por Gordon Lyon (conocido en la comunidad como "Fyodor"), que se utiliza en pruebas de penetración (pentesting) para explorar y auditar redes y sistemas informáticos. Es, con diferencia, la herramienta de reconocimiento más extendida en el mundo del hacking ético, hasta el punto de que aparece incluso en escenas de películas y series (Matrix Reloaded, The Girl with the Dragon Tattoo, Mr. Robot...) como sinónimo visual de "estoy hackeando algo". Detrás de esa fama está el hecho de que Nmap resuelve, mejor que casi cualquier otra herramienta, la pregunta más básica y más importante de toda auditoría: ¿qué hay ahí fuera, y qué está escuchando?

Con Nmap, los profesionales de seguridad pueden identificar los hosts conectados a una red, los servicios que se están ejecutando en ellos y las posibles vulnerabilidades que podrían ser explotadas por un atacante. La herramienta es capaz de detectar una amplia gama de dispositivos, incluyendo enrutadores, servidores web, impresoras, cámaras IP, sistemas operativos y otros dispositivos conectados a una red. En la práctica, Nmap responde a tres preguntas encadenadas que forman el esqueleto de la fase de reconocimiento de cualquier pentest: ¿qué máquinas están vivas dentro de un rango de IPs?, ¿qué puertos tienen abiertos esas máquinas? y ¿qué servicio (y qué versión concreta de ese servicio) hay detrás de cada puerto abierto? A partir de esas tres respuestas, un atacante o auditor ya puede empezar a construir un mapa de la superficie de ataque de un objetivo y decidir por dónde merece la pena seguir investigando.

## ¿Por qué es tan utilizado en hacking y pentesting?

Nmap se ha convertido en una herramienta prácticamente universal en el sector por varios motivos que se refuerzan entre sí. El primero es que es gratuito y de código abierto: cualquiera puede descargarlo, auditar su código y ejecutarlo sin coste, lo cual ha permitido que se convierta en un estándar de facto tanto en entornos formativos como en empresas de seguridad profesionales. El segundo es su madurez: lleva más de 25 años de desarrollo activo, lo que se traduce en un soporte enorme de protocolos, técnicas de escaneo y bases de datos de huellas digitales (fingerprints) de sistemas operativos y servicios, constantemente actualizadas por la comunidad.

El tercer motivo, y quizás el más importante desde el punto de vista de un pentester, es que Nmap se sitúa justo al principio de la metodología de cualquier auditoría: antes de poder explotar una vulnerabilidad concreta, hace falta saber qué hay expuesto, y Nmap es la herramienta que responde a esa pregunta de forma rápida y fiable. Esto lo convierte en el punto de partida obligado de casi cualquier pentest, tanto en cajas de práctica (como las de HackTheBox o TryHackMe) como en auditorías reales contra clientes. No es casualidad que en el apunte anterior, al hablar de direcciones IP, ya mencionáramos que "al identificar la IP de una máquina objetivo, se pueden lanzar escaneos de puertos y servicios (por ejemplo, con herramientas como `nmap`) para descubrir qué servicios están expuestos": ese es, precisamente, el papel que cumple esta herramienta dentro del flujo de trabajo completo.

## Ventajas de Nmap

Además de su popularidad, Nmap acumula una serie de ventajas técnicas concretas que explican por qué sigue siendo la referencia del sector frente a alternativas más modernas:

- **Multiplataforma**: funciona igual de bien en Linux, Windows y macOS, e incluso dispone de una interfaz gráfica oficial (Zenmap) para quien prefiera no usar la línea de comandos.
- **Múltiples técnicas de escaneo**: no se limita a un único método para determinar si un puerto está abierto; soporta escaneos TCP connect, SYN (sigiloso), UDP, ACK, FIN, entre otros, cada uno pensado para adaptarse a distintos escenarios (por ejemplo, evadir ciertos firewalls o reducir el ruido generado durante el escaneo).
- **Detección de servicios y versiones**: no solo indica si un puerto está abierto, sino que puede identificar qué software concreto está escuchando en él y en qué versión, información clave para buscar después vulnerabilidades conocidas asociadas a esa versión específica.
- **Detección de sistema operativo**: mediante el análisis de particularidades en las respuestas de red (fingerprinting de la pila TCP/IP), Nmap puede inferir con bastante precisión qué sistema operativo corre la máquina objetivo.
- **Nmap Scripting Engine (NSE)**: un motor de scripts en Lua que permite automatizar tareas de reconocimiento avanzadas (detección de vulnerabilidades concretas, fuerza bruta de credenciales, recolección de información adicional de un servicio, etc.), ampliando enormemente lo que la herramienta puede hacer más allá de un simple escaneo de puertos.
- **Control fino de la velocidad y el sigilo**: mediante plantillas de temporización (de `-T0`, extremadamente lento y silencioso, a `-T5`, agresivo y rápido) se puede adaptar el escaneo tanto a la necesidad de pasar desapercibido ante un IDS/IPS como a la de escanear rápidamente un rango muy amplio de direcciones.
- **Salida flexible**: los resultados se pueden exportar en distintos formatos (normal, XML, "grepable"), lo que facilita integrarlos con otras herramientas o scripts propios dentro de un flujo de trabajo más amplio de auditoría.

Como contrapartida, conviene tener presente que Nmap genera tráfico de red que puede ser detectado y registrado por firewalls, IDS o IPS, especialmente si se usa con configuraciones agresivas; y que ciertas técnicas de escaneo (como el propio SYN scan) requieren permisos de administrador o root en el sistema desde el que se ejecuta, precisamente porque necesitan construir paquetes en bruto (raw sockets) en lugar de usar las llamadas normales del sistema operativo.

## Ejemplos básicos de uso

El uso más simple de Nmap consiste en indicarle una IP o un nombre de host para que realice un escaneo de puertos TCP por defecto (los 1000 puertos más comunes):

```bash
❯ nmap 192.168.1.10

PORT    STATE SERVICE
22/tcp  open  ssh
80/tcp  open  http
443/tcp open  https
```

Si en lugar de un único host lo que queremos es saber qué máquinas están activas dentro de un rango completo, sin llegar todavía a escanear puertos, se utiliza un escaneo de descubrimiento de hosts (`-sn`, de "no port scan"), útil como primer paso antes de lanzar un escaneo más pesado contra toda una red:

```bash
❯ nmap -sn 192.168.1.0/24

Nmap scan report for 192.168.1.1
Host is up (0.0021s latency).
Nmap scan report for 192.168.1.10
Host is up (0.0034s latency).
```

Para obtener información más detallada de los servicios detectados (incluyendo, siempre que sea posible, su versión exacta), se añade la opción `-sV`:

```bash
❯ nmap -sV 192.168.1.10

PORT    STATE SERVICE VERSION
22/tcp  open  ssh     OpenSSH 8.9p1 Ubuntu
80/tcp  open  http    Apache httpd 2.4.52
443/tcp open  https   Apache httpd 2.4.52
```

Por defecto, Nmap solo escanea los 1000 puertos más habituales; si el objetivo tiene un servicio corriendo en un puerto no estándar (algo bastante habitual cuando un administrador intenta ocultar un servicio "por seguridad a través de la oscuridad"), conviene forzar un escaneo de todos los puertos posibles con `-p-`:

```bash
❯ nmap -p- 192.168.1.10
```

Finalmente, la opción `-A` combina de una sola vez detección de versión de servicios, detección de sistema operativo, ejecución de scripts básicos de NSE y traceroute, lo que la convierte en una forma rápida y muy habitual de obtener una foto general bastante completa de un objetivo, aunque a costa de generar bastante más tráfico y ser mucho más fácil de detectar que un escaneo discreto:

```bash
❯ sudo nmap -A 192.168.1.10
```

Todas estas opciones se pueden combinar entre sí (por ejemplo, `nmap -sV -p- -T4 192.168.1.10` para una detección de versiones exhaustiva en todos los puertos con una temporización rápida), lo cual es precisamente lo que hace de Nmap una herramienta tan versátil: permite empezar con un escaneo ligero y rápido para hacerse una idea general de un objetivo, e ir progresivamente afinando y profundizando el escaneo a medida que la auditoría avanza.
