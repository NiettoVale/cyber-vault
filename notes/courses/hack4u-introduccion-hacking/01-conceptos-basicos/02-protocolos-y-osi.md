# Protocolos de Red

Para que dos dispositivos puedan comunicarse a través de una red, no basta con que estén conectados físicamente: necesitan hablar el mismo "idioma" y respetar las mismas reglas a la hora de intercambiar información. Ese conjunto de reglas es lo que llamamos un protocolo. Un protocolo de red define, entre otras cosas, cómo se inicia una comunicación, qué formato deben tener los datos que se envían, cómo se confirma que un mensaje llegó correctamente y cómo se cierra la conversación una vez terminada. Sin protocolos, cada fabricante o cada aplicación tendría su propia forma de comunicarse y sería imposible que, por ejemplo, un navegador hecho por una empresa pudiera hablar con un servidor web hecho por otra completamente distinta.

Para quien se dedica a la ciberseguridad, entender los protocolos no es un simple requisito teórico: es la base para poder analizar tráfico de red, detectar anomalías, identificar servicios expuestos en un objetivo y, en definitiva, saber qué es "normal" y qué no lo es dentro de una comunicación. Un atacante que conoce a fondo cómo funciona un protocolo puede encontrar formas de abusar de él (por ejemplo, aprovechando una implementación mal configurada), y un defensor que conoce esos mismos protocolos puede reconocer qué secuencia de paquetes es sospechosa. Dos de los protocolos más importantes a este respecto, porque son la base del transporte de datos en Internet, son TCP y UDP.

## TCP vs UDP

El protocolo **TCP (Transmission Control Protocol)** es un protocolo orientado a conexión, lo que significa que antes de enviar cualquier dato, ambos extremos de la comunicación negocian y establecen una conexión formal, similar a descolgar un teléfono y confirmar que la otra persona está al otro lado antes de empezar a hablar. Una vez establecida esa conexión, TCP se encarga de garantizar que los datos lleguen completos, en el orden correcto y sin errores: si un paquete se pierde por el camino, TCP detecta esa pérdida y lo reenvía automáticamente. Esta fiabilidad tiene un coste en velocidad y en la cantidad de tráfico adicional que se genera solo para confirmar la entrega, pero es imprescindible cuando la integridad de los datos importa más que la velocidad. Por eso TCP es el protocolo que hay detrás de la navegación web, el correo electrónico o una conexión SSH: en todos estos casos nos interesa mucho más que la información llegue completa que llegar unos milisegundos antes.

El protocolo **UDP (User Datagram Protocol)**, en cambio, no está orientado a conexión: los datos se envían directamente, sin negociar nada previamente y sin que exista garantía de que vayan a llegar, de que lleguen en orden o de que no se dupliquen. Es como enviar postales por correo: cada una viaja de forma independiente y no hay ninguna confirmación de que el destinatario las reciba todas ni en el orden en que se enviaron. A cambio de esa falta de garantías, UDP es mucho más rápido y ligero que TCP, ya que no necesita establecer una conexión previa ni intercambiar confirmaciones constantes. Por eso se utiliza en escenarios donde la velocidad es más importante que la fiabilidad absoluta, como las consultas DNS, las videollamadas o el streaming de vídeo, donde es preferible perder algún paquete puntual (por ejemplo, un pequeño corte de imagen) antes que sufrir retrasos esperando su reenvío.

## El Three-Way Handshake de TCP

Como TCP necesita establecer una conexión formal antes de transmitir datos, define un procedimiento concreto para ello llamado **Three-Way Handshake** (saludo de tres vías), que consiste en el intercambio de tres paquetes entre el cliente y el servidor. Este procedimiento sirve para que ambas partes se pongan de acuerdo en los números de secuencia que van a usar para numerar los datos que se envíen a partir de ese momento, lo cual es precisamente lo que le permite a TCP más adelante detectar paquetes perdidos, duplicados o fuera de orden.

El proceso funciona de la siguiente manera:

1. **SYN**: el cliente que quiere iniciar la conexión envía un paquete con el flag `SYN` (synchronize) activado al servidor, junto con un número de secuencia inicial elegido de forma aleatoria. Es, en esencia, decir "quiero hablar contigo, y voy a numerar mis mensajes empezando por aquí".
2. **SYN-ACK**: si el servidor acepta la conexión, responde con un paquete que tiene activados a la vez los flags `SYN` y `ACK`. El `ACK` confirma que ha recibido el número de secuencia del cliente (respondiendo con ese número + 1), y el `SYN` indica su propio número de secuencia inicial, con el que empezará a numerar sus propios mensajes.
3. **ACK**: finalmente, el cliente responde con un paquete `ACK` confirmando que ha recibido el número de secuencia del servidor. En este punto, ambas partes han confirmado mutuamente sus números de secuencia y la conexión queda establecida, lista para empezar a transmitir datos reales.

Un ejemplo práctico y muy habitual en pentesting donde se ve claramente el handshake (o, mejor dicho, una versión incompleta de él) es el escaneo de puertos con `nmap` en modo SYN scan (`nmap -sS`). En un escaneo de puertos normal contra un objetivo, `nmap` envía un paquete `SYN` a un puerto y observa la respuesta: si recibe un `SYN-ACK`, sabe que el puerto está abierto (y, en lugar de completar el handshake enviando el `ACK` final, envía un `RST` para cerrar la conexión sin completarla, algo mucho más rápido y menos "ruidoso" que abrir conexiones completas contra cientos de puertos). Si en cambio recibe un `RST` directamente, el puerto está cerrado. Esta técnica se conoce como "escaneo sigiloso" precisamente porque nunca llega a completar el tercer paso del handshake:

```bash
❯ sudo nmap -sS 192.168.1.10

PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http
443/tcp closed https
```

## Puertos comunes en TCP y UDP

Además de saber cómo se establece una conexión, es fundamental reconocer qué servicio suele estar detrás de cada puerto, ya que esto es lo primero que se identifica al auditar una máquina. Cada puerto es simplemente un número que identifica, dentro de una misma IP, a qué servicio o aplicación va dirigido el tráfico; así, una misma máquina puede tener un servidor web escuchando en el puerto 80 y, al mismo tiempo, un servidor SSH escuchando en el puerto 22, sin que ambos tráficos se mezclen.

| Puerto | Protocolo | Servicio | Descripción |
|--------|-----------|----------|-------------|
| 21     | TCP       | FTP      | Transferencia de archivos entre sistemas. |
| 22     | TCP       | SSH      | Conexión remota segura y administración de sistemas. |
| 23     | TCP       | Telnet   | Conexión remota a dispositivos de red, sin cifrado. |
| 80     | TCP       | HTTP     | Transferencia de datos en la Web, sin cifrar. |
| 443    | TCP       | HTTPS    | Versión de HTTP cifrada mediante SSL/TLS. |
| 53     | UDP       | DNS      | Traducción de nombres de dominio a direcciones IP. |
| 67/68  | UDP       | DHCP     | Asignación automática de IP y parámetros de red. |
| 69     | UDP       | TFTP     | Transferencia simple de archivos, sin autenticación. |
| 123    | UDP       | NTP      | Sincronización de relojes entre dispositivos. |
| 161    | UDP       | SNMP     | Administración y monitorización de dispositivos de red. |

Estos son solo algunos de los puertos más habituales; en la práctica existen 65535 puertos posibles tanto en TCP como en UDP, y muchos servicios pueden reconfigurarse para escuchar en un puerto distinto al estándar, algo que también conviene tener en cuenta durante un escaneo (no asumir que un puerto no estándar implica ausencia de un servicio conocido).

# Modelos de capas: OSI vs TCP/IP

Toda esta comunicación (protocolos, puertos, handshakes) no ocurre en un único bloque monolítico, sino que se organiza en capas, donde cada capa se encarga de una responsabilidad concreta y se apoya en la capa inferior sin necesidad de saber cómo funciona internamente. Esta separación por capas es una decisión de diseño deliberada: permite que, por ejemplo, un mismo protocolo de aplicación como HTTP funcione exactamente igual sin importar si por debajo viaja sobre una red cableada, WiFi o fibra óptica, porque esos detalles quedan resueltos en capas inferiores. Para entender y enseñar esta organización existen principalmente dos modelos de referencia: el modelo OSI y el modelo TCP/IP.

El **modelo OSI (Open Systems Interconnection)** fue desarrollado por la ISO como un modelo teórico y de referencia, pensado para describir de forma muy detallada y didáctica todas las funciones que intervienen en una comunicación de red, dividiéndolas en 7 capas independientes. El **modelo TCP/IP**, en cambio, es el modelo que se implementó realmente y que es el que efectivamente usa Internet hoy en día; es más antiguo en la práctica, más simple, con solo 4 capas, y nació directamente de la necesidad de hacer funcionar los protocolos TCP e IP, en lugar de partir de un diseño puramente teórico. En la actualidad, cuando hablamos de "la capa de red" o "la capa de transporte" de una comunicación real en Internet, nos estamos refiriendo de facto al modelo TCP/IP, mientras que el modelo OSI se sigue utilizando sobre todo como herramienta pedagógica y como marco de referencia común para explicar y ubicar conceptos, ya que su granularidad de 7 capas resulta más clara a la hora de estudiar dónde encaja cada protocolo o cada tipo de ataque.

## Las 7 capas del modelo OSI

1. **Capa Física**: es la capa más baja y se encarga de la transmisión de los bits en bruto (unos y ceros) a través de un medio físico, ya sea un cable de cobre, fibra óptica u ondas de radio en una red WiFi. Aquí no existe el concepto de "dato con significado", solo señales eléctricas, ópticas o electromagnéticas. Un ejemplo cotidiano es el propio cable Ethernet o la antena WiFi de un router, que son los que transportan literalmente la señal.

2. **Capa de Enlace de Datos**: organiza esos bits en tramas (frames) y se encarga de la comunicación entre dispositivos que están dentro del mismo segmento de red física, utilizando las direcciones MAC para identificar a los equipos. Aquí operan tecnologías como Ethernet o WiFi (802.11), y también switches, que reenvían tramas basándose en la MAC de destino. Un ejemplo práctico es cuando un switch de una oficina decide a qué puerto físico reenviar una trama según la tabla de direcciones MAC que ha ido aprendiendo.

3. **Capa de Red**: introduce el direccionamiento lógico (las direcciones IP de las que hablamos en el apunte anterior) y se encarga de encontrar el camino óptimo para que un paquete llegue de una red a otra, tarea conocida como enrutamiento. El protocolo IP y los routers viven en esta capa. Un ejemplo claro es cuando enviamos un paquete desde nuestra red doméstica hasta un servidor en otro país: varios routers intermedios van decidiendo, salto a salto, por dónde reenviar ese paquete según su IP de destino.

4. **Capa de Transporte**: es la capa donde viven TCP y UDP, los protocolos que ya explicamos antes. Se encarga de gestionar la comunicación extremo a extremo entre las aplicaciones de origen y destino, ya sea garantizando la entrega fiable (TCP) o priorizando la velocidad (UDP), además de introducir el concepto de puerto para poder distinguir distintos servicios en una misma máquina.

5. **Capa de Sesión**: se encarga de abrir, mantener y cerrar la "sesión" de comunicación entre dos aplicaciones, coordinando quién habla y cuándo. Un ejemplo típico es una sesión NetBIOS o RPC, donde se necesita mantener un diálogo continuo y coordinado entre cliente y servidor a lo largo de varias operaciones, más allá de una simple conexión TCP puntual.

6. **Capa de Presentación**: se encarga de que los datos tengan un formato entendible para la aplicación receptora, independientemente de cómo los generó la aplicación emisora; aquí entran en juego tareas como el cifrado, la compresión o la codificación de caracteres. El cifrado TLS que hace posible HTTPS es un ejemplo habitual de funcionalidad que se suele ubicar en esta capa (aunque en la práctica TLS también tiene aspectos de la capa de sesión).

7. **Capa de Aplicación**: es la capa más cercana al usuario y la que usan directamente los programas para comunicarse en red. Aquí viven los protocolos que ya usamos a diario sin pensarlo: HTTP/HTTPS para navegar por la web, SSH para conectarnos remotamente a un servidor, DNS para resolver nombres de dominio o SMTP para el correo electrónico. Cuando abrimos un navegador y escribimos una URL, la petición que se genera es, precisamente, tráfico de esta capa.

## Las 4 capas del modelo TCP/IP

El modelo TCP/IP condensa esas mismas responsabilidades en 4 capas, agrupando varias capas del modelo OSI en una sola:

1. **Capa de Acceso a la Red (o Enlace)**: agrupa lo que en OSI serían la capa Física y la capa de Enlace de Datos. Se encarga de todo lo relacionado con la transmisión física de datos y el direccionamiento MAC dentro de la misma red local.

2. **Capa de Internet**: equivale a la capa de Red de OSI. Aquí vive el protocolo IP, encargado del direccionamiento lógico y el enrutamiento de paquetes entre redes distintas.

3. **Capa de Transporte**: es prácticamente idéntica a la capa de Transporte de OSI, con TCP y UDP como protagonistas, gestionando la entrega extremo a extremo y los puertos.

4. **Capa de Aplicación**: agrupa lo que en OSI serían las capas de Sesión, Presentación y Aplicación en una sola capa, ya que en la práctica muchos protocolos de aplicación reales (como HTTP o SSH) resuelven internamente aspectos de sesión y presentación sin necesidad de separarlos en capas independientes.

Un ejemplo que ayuda a fijar la comparación entre ambos modelos es seguir el recorrido de una simple petición web: cuando escribimos una URL en el navegador, en la capa de Aplicación se genera una petición HTTP; esa petición baja a la capa de Transporte, donde TCP la divide en segmentos y les asigna números de secuencia (y de paso, establece antes el Three-Way Handshake); después baja a la capa de Internet, donde IP le añade la dirección de origen y destino para poder enrutarla; y finalmente baja a la capa de Acceso a la Red, donde se convierte en una trama con direcciones MAC y se transmite físicamente como señales eléctricas u ópticas. En el equipo receptor, este mismo proceso ocurre exactamente al revés, capa por capa, hasta reconstruir la petición HTTP original.
