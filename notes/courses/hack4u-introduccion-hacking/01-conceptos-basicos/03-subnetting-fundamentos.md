# ¿Qué es el Subnetting?

Cuando una organización recibe un bloque de direcciones IP, rara vez le conviene usarlo todo como una única red gigante: sería ineficiente (se desperdiciarían muchísimas direcciones), poco práctico de administrar y, sobre todo, poco seguro, ya que todos los dispositivos compartirían el mismo dominio de broadcast y no habría ninguna barrera lógica entre, por ejemplo, la red de invitados, la red de servidores y la red del departamento de contabilidad. El subnetting (segmentación de subredes) es la técnica que resuelve esto: consiste en tomar una red IP y dividirla en subredes más pequeñas y manejables, cada una con su propio rango de direcciones, su propia dirección de red y su propia dirección de broadcast.

Esta división se logra jugando con la máscara de red, que es la que determina qué parte de una dirección IP identifica a la red (y por tanto es común a todos los dispositivos de esa subred) y qué parte identifica al host individual dentro de esa red. Cuantos más bits "movamos" de la parte de host hacia la parte de red, más subredes pequeñas podremos crear a partir de un mismo bloque original, a costa de que cada una de esas subredes tenga menos direcciones disponibles para hosts. Este equilibrio entre "cuántas subredes necesito" y "cuántos hosts necesito en cada una" es, en esencia, todo el arte del subnetting.

Más allá de la eficiencia, dominar el subnetting importa mucho en ciberseguridad: te permite reconocer al instante, a partir de una IP con su prefijo (por ejemplo `192.168.1.130/26`), a qué subred pertenece exactamente un host, cuál es el rango completo de esa subred y cuántos otros dispositivos podrían estar en el mismo segmento. Esto es clave a la hora de mapear una red objetivo, decidir el rango que hay que escanear con herramientas como `nmap`, o entender por qué, tras comprometer una máquina, solo se puede ver a ciertos hosts y no a toda la red interna de la empresa (porque están en subredes distintas, separadas por routers o firewalls).

## Cómo interpretar una máscara de red

Una máscara de red es, igual que una IP, un número de 32 bits, pero en lugar de identificar a un dispositivo, su función es "marcar" qué bits de la IP son parte de la red y cuáles son parte del host. Los bits en "1" indican la porción de red, y los bits en "0" indican la porción de host. Por ejemplo, la máscara `255.255.255.0` en binario es:

```
11111111.11111111.11111111.00000000
```

Los primeros 24 bits están en 1 (los primeros tres octetos), lo que significa que esos 24 bits de cualquier IP que use esta máscara identifican la red, mientras que los últimos 8 bits (el último octeto) quedan libres para identificar hosts individuales dentro de esa red. Así, con esta máscara, todas las IPs que compartan los mismos tres primeros octetos pertenecen a la misma subred, y solo el último octeto puede variar de un dispositivo a otro.

## Notación CIDR

Escribir la máscara completa (`255.255.255.0`) cada vez que queremos referirnos a una red es poco práctico, así que se usa una notación abreviada llamada **CIDR (Classless Inter-Domain Routing)**. En lugar de escribir la máscara entera, se escribe la IP seguida de una barra y el número de bits que están en "1" en la máscara, es decir, el número de bits que corresponden a la red. Así, una IP `192.168.1.1` con máscara `255.255.255.0` se escribe simplemente como `192.168.1.1/24`, ya que esa máscara tiene 24 bits en "1".

CIDR surgió como reemplazo del sistema de "clases" de red (que veremos en la siguiente sección) precisamente porque permite definir el límite entre red y host en cualquier bit, no solo en los límites fijos de cada octeto. Esto permite ajustar el tamaño de una red exactamente a lo que se necesita, sin desperdiciar direcciones IP asignando bloques enormes a organizaciones que solo necesitan unos pocos hosts (de ahí el nombre "classless": ya no dependemos de clases fijas). Para pasar de un prefijo CIDR a la máscara en decimal, basta con escribir tantos "1" como indique el prefijo, rellenar el resto con "0" hasta completar los 32 bits, y convertir cada octeto de 8 bits a decimal. Por ejemplo, un prefijo `/24` se traduce en binario como `11111111.11111111.11111111.00000000`, que convertido octeto a octeto da como resultado `255.255.255.0`.

# Clases de Red (Direccionamiento Classful)

Antes de que existiera CIDR, las direcciones IPv4 se repartían en bloques fijos llamados "clases", donde el propio valor del primer octeto determinaba automáticamente el tamaño de la red y su máscara por defecto. Aunque hoy en día prácticamente nadie usa este sistema tal cual (se ha sustituido casi por completo por CIDR), sigue siendo útil conocerlo porque ayuda a entender de dónde vienen ciertas convenciones (como que `192.168.x.x` "suene" a red pequeña y `10.x.x.x` a red grande) y porque los exámenes y documentación clásica de redes lo siguen mencionando constantemente.

| Clase | Primer octeto | Máscara por defecto | Prefijo | Ejemplo |
|-------|----------------|----------------------|---------|---------|
| A     | 1 – 126        | 255.0.0.0            | /8      | `10.52.36.11` |
| B     | 128 – 191      | 255.255.0.0          | /16     | `172.16.52.63` |
| C     | 192 – 223      | 255.255.255.0        | /24     | `192.168.123.132` |
| D     | 224 – 239      | (reservada, multicast) | —     | `224.0.0.1` |
| E     | 240 – 255      | (reservada, experimental) | —  | — |

Las redes de Clase A destinan un solo octeto a identificar la red y los tres restantes a hosts, por lo que cada red de Clase A puede tener millones de hosts: están pensadas para organizaciones enormes (históricamente, grandes corporaciones o gobiernos). Las de Clase B reparten la mitad y la mitad, pensadas para organizaciones medianas-grandes, y las de Clase C, las más comunes en redes domésticas y de oficinas pequeñas, destinan tres octetos a la red y dejan solo el último octeto (256 direcciones, 254 utilizables) para hosts. Las clases D y E no se usan para direccionar hosts normales: la D se reserva para tráfico multicast y la E quedó reservada para uso experimental.

El problema de este sistema es que era muy rígido: si una empresa necesitaba 300 hosts, no le servía una red de Clase C (máximo 254 hosts utilizables) y tenía que recibir una red de Clase B completa, desperdiciando decenas de miles de direcciones que nunca llegaría a usar. Este desperdicio masivo fue una de las razones que aceleró la adopción de CIDR, que permite crear un bloque a medida (por ejemplo, un `/23`, que junta dos bloques de Clase C y da justo 510 hosts utilizables) en lugar de saltar directamente a la siguiente clase completa.

# Fórmulas Fundamentales (el machetito)

Todo el cálculo de subnetting se apoya en un puñado de fórmulas muy simples que conviene memorizar de memoria, porque son las que se repiten en cualquier ejercicio. La idea clave es que el número de bits que le "quitamos" a la parte de host determina cuántas direcciones quedan disponibles dentro de esa subred, y ese número siempre se calcula como una potencia de 2.

```
n = número de bits de red (el prefijo, ej: /26 → n = 26)
h = número de bits de host = 32 - n

Direcciones totales en la subred      = 2^h
Hosts utilizables en la subred        = 2^h - 2   (se restan Network ID y Broadcast)
Número de subredes al pedir s bits    = 2^s
Bloque de tamaño / "número mágico"    = 256 - (valor de la máscara en el octeto interesante)
```

El motivo de restar 2 en los hosts utilizables es que, dentro de cada subred, la primera dirección (todos los bits de host en 0) se reserva como **Network ID** (identifica a la subred en sí, no a un host) y la última dirección (todos los bits de host en 1) se reserva como **dirección de Broadcast** (para enviar un paquete a todos los hosts de esa subred a la vez); ninguna de las dos puede asignarse a un dispositivo. Hay dos excepciones que vale la pena conocer: una subred `/31` (solo 2 direcciones, 0 bits libres para restar) se usa en la práctica para enlaces punto a punto entre dos routers, donde ambas direcciones se usan como hosts sin reservar broadcast; y una `/32` representa una única dirección IP exacta (por ejemplo, para identificar una sola máquina en una ruta estática), sin ningún host que repartir.

## El truco del "número mágico" (subnetting rápido sin pelearte con binario)

Convertir todo a binario cada vez que queremos calcular una subred es lento y propenso a errores. Existe un atajo mental, muy usado en certificaciones de redes, que evita el binario casi por completo:

1. **Localiza el octeto "interesante"**: es el único octeto de la máscara que no es ni `255` ni `0` (por ejemplo, en `255.255.255.192`, el octeto interesante es el último, con valor `192`).
2. **Calcula el número mágico (tamaño de bloque)**: réstale ese valor a 256. En el ejemplo, `256 - 192 = 64`. Ese número (64) es el "salto" entre el inicio de una subred y el inicio de la siguiente.
3. **Lista los múltiplos del número mágico** dentro de ese octeto, empezando en 0: en el ejemplo, `0, 64, 128, 192`. Cada uno de esos valores es el inicio (Network ID) de una subred distinta.
4. **Ubica en qué rango cae tu IP** y ya tienes la subred completa: el Network ID es el múltiplo igual o inmediatamente inferior a tu IP en ese octeto, y el Broadcast es el número justo antes del siguiente múltiplo (es decir, `siguiente múltiplo - 1`).

# Ejemplos Prácticos Resueltos

## Ejemplo 1: red alineada, `192.168.1.0/26`

Partimos de la IP `192.168.1.0` con prefijo `/26`. Como `26` no es múltiplo de 8, el octeto interesante es el último (los primeros tres octetos completos, 24 bits, ya están en la parte de red; nos faltan 2 bits más de los 26 totales, que se toman del cuarto octeto).

**Máscara de red**: colocamos 26 bits en "1" y el resto en "0":

```
11111111.11111111.11111111.11000000
```

Los primeros tres octetos son `255.255.255`, y el último octeto (`11000000` en binario) equivale a `192` en decimal. Máscara resultante: **255.255.255.192**.

**Bits de host y hosts utilizables**: `h = 32 - 26 = 6` bits de host, así que hay `2^6 = 64` direcciones totales en la subred, de las cuales `2^6 - 2 = 62` son utilizables para hosts.

**Número mágico**: el octeto interesante vale `192`, así que el bloque es `256 - 192 = 64`. Los múltiplos de 64 en ese octeto son `0, 64, 128, 192`.

**Network ID y Broadcast**: como nuestra IP es `192.168.1.0`, cae justo en el primer bloque (`0` a `63`). El Network ID es `192.168.1.0` y el Broadcast es el número justo antes del siguiente múltiplo (`64 - 1 = 63`), es decir, `192.168.1.63`.

**Verificación por el método binario (AND lógico)**, para quien prefiera confirmarlo bit a bit: convertimos la IP y la máscara a binario y aplicamos un AND entre ambas. El AND lógico compara bit a bit y solo da "1" si ambos bits son "1"; esto "apaga" automáticamente todos los bits de host, dejando solo la parte de red intacta:

```
      IP:      11000000.10101000.00000001.00000000
  Máscara:      11111111.11111111.11111111.11000000
  --------------------------------------------------
  AND (Network ID): 11000000.10101000.00000001.00000000 → 192.168.1.0
```

Y para el Broadcast, en vez de un AND, ponemos a "1" todos los bits de host (los últimos 6 bits) manteniendo intacta la parte de red:

```
IP con bits de host en "1": 11000000.10101000.00000001.00111111 → 192.168.1.63
```

**Resumen de la subred `192.168.1.0/26`:**

| Campo | Valor |
|-------|-------|
| Máscara | 255.255.255.192 |
| Network ID | 192.168.1.0 |
| Primer host utilizable | 192.168.1.1 |
| Último host utilizable | 192.168.1.62 |
| Broadcast | 192.168.1.63 |
| Hosts utilizables | 62 |

## Ejemplo 2: ubicar un host cualquiera dentro de una subred `/28`

En la práctica, no siempre nos dan el Network ID de entrada; muchas veces tenemos la IP de un host cualquiera (por ejemplo, la de una máquina detectada en un escaneo) y necesitamos deducir a qué subred pertenece. Supongamos que encontramos el host `192.168.1.100/28` durante una auditoría.

Con prefijo `/28`, el octeto interesante vuelve a ser el último. La máscara es `11111111.11111111.11111111.11110000`, es decir, **255.255.255.240**. El número mágico es `256 - 240 = 16`, así que los múltiplos de 16 en el último octeto son: `0, 16, 32, 48, 64, 80, 96, 112, 128, ...`

Nuestra IP termina en `.100`, que cae entre `96` y `112` (el siguiente múltiplo). Por tanto:

- **Network ID**: `192.168.1.96` (el múltiplo igual o inferior a 100).
- **Broadcast**: `192.168.1.111` (`112 - 1`).
- **Rango de hosts utilizables**: de `192.168.1.97` a `192.168.1.110` → `2^4 - 2 = 14` hosts utilizables.

Es decir, aunque la IP que vimos era `.100`, en realidad pertenece a la subred `192.168.1.96/28`, junto con otros 13 hosts posibles más, y nunca podrá comunicarse directamente (sin pasar por un router) con un host de la subred vecina `192.168.1.112/28`.

# Tabla de Referencia Rápida (prefijos más comunes)

Esta tabla es el "machetito" definitivo para tener a mano: relaciona el prefijo CIDR, la máscara equivalente, el tamaño de bloque (número mágico) y la cantidad de hosts utilizables, para los prefijos que más se repiten en la práctica.

| Prefijo | Máscara | Bits de host | Tamaño de bloque | Hosts utilizables |
|---------|---------|--------------|-------------------|--------------------|
| /24 | 255.255.255.0   | 8 | 256 | 254 |
| /25 | 255.255.255.128 | 7 | 128 | 126 |
| /26 | 255.255.255.192 | 6 | 64  | 62  |
| /27 | 255.255.255.224 | 5 | 32  | 30  |
| /28 | 255.255.255.240 | 4 | 16  | 14  |
| /29 | 255.255.255.248 | 3 | 8   | 6   |
| /30 | 255.255.255.252 | 2 | 4   | 2   |
| /31 | 255.255.255.254 | 1 | 2   | 2 (uso especial: enlaces punto a punto) |
| /32 | 255.255.255.255 | 0 | 1   | 1 (un único host, sin red/broadcast) |

# Subnetting en el día a día del pentesting

Más allá del cálculo en sí, entender subnetting tiene aplicaciones muy concretas en seguridad ofensiva. Al reconocer un objetivo, es habitual recibir (o descubrir) un rango en notación CIDR, por ejemplo `192.168.1.0/24`, y poder lanzar directamente un escaneo contra toda la subred sin tener que enumerar las 254 IPs a mano:

```bash
❯ nmap -sn 192.168.1.0/24
```

Saber calcular Network ID y Broadcast también evita perder tiempo escaneando direcciones que nunca van a responder por ser inválidas como host (la propia dirección de red o la de broadcast), y permite reconocer inmediatamente, al ver la máscara de una interfaz comprometida, qué tan grande es el segmento en el que estamos y qué otros hosts podrían estar alcanzables directamente por capa 2, sin necesidad de atravesar un router. Por último, en redes corporativas reales es muy común encontrarse con **VLSM (Variable Length Subnet Masking)**, que no es más que aplicar subnetting de forma recursiva: tomar una subred ya creada y volver a dividirla en subredes aún más pequeñas con prefijos distintos entre sí, para ajustar cada segmento (servidores, oficinas, invitados, IoT) exactamente al número de hosts que necesita, sin desperdiciar direcciones en ningún tramo.
