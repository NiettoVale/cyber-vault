# 🗄️ CyberVault

**Laboratorio personal de ciberseguridad ofensiva.** Documentación de técnicas, resolución de máquinas en HackTheBox e informes profesionales de pentesting, con foco en un enfoque práctico, técnico y estructurado.

---

## 📖 Sobre este repositorio

CyberVault es mi bitácora de aprendizaje en seguridad ofensiva. Cada máquina resuelta se documenta como un **informe de pentesting profesional** — no como un writeup rápido — siguiendo una estructura estandarizada: resumen ejecutivo, cadena de ataque, análisis técnico detallado por vulnerabilidad (con CWE, CVSS e impacto) y remediaciones a corto, mediano y largo plazo.

El objetivo es doble: consolidar mi propio aprendizaje y demostrar cómo comunico un hallazgo técnico de la forma en que se espera en un entorno profesional.

---

## 📂 Estructura del repositorio

| Carpeta                       | Contenido                                                                                                            | Estado                                                 |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| [`/machines`](./machines)     | Informes completos de máquinas comprometidas (HackTheBox), desde reconocimiento hasta escalada de privilegios.       | 🟢 Activo — [Cap](./machines/hack-the-box) documentada |
| [`/notes`](./notes)           | Apuntes técnicos sobre metodologías, vectores de ataque, escalada de privilegios, reverse shells y conceptos de red. | 🟡 En construcción                                     |
| [`/sherlocks`](./sherlocks)   | Investigaciones forenses y de análisis de incidentes (DFIR).                                                         | 🟡 En construcción                                     |
| [`/challenges`](./challenges) | Resolución de retos puntuales de distintas categorías (web, cripto, forense, etc.).                                  | 🟡 En construcción                                     |
| [`/templates`](./templates)   | Plantillas propias (optimizadas para Obsidian) usadas para estandarizar cada informe y reporte de vulnerabilidad.    | 🟢 Activo                                              |

> 📌 Repositorio en crecimiento activo: subo contenido nuevo a medida que resuelvo máquinas, retos y avanzo en cursos de formación ofensiva.

---

## 🎯 Informe destacado

### [Cap (HackTheBox — Linux, Fácil)](./machines/hack-the-box/linux//01-cap/report.md)

Compromiso completo del sistema obteniendo `root`. Cadena de ataque:

**IDOR en panel web** → captura `.pcap` con credenciales FTP en texto plano → **reutilización de credenciales en SSH** → acceso como usuario `nathan` → **abuso de Linux Capability `cap_setuid`** en `python3.8` → shell como `root`.

Incluye 4 hallazgos documentados con CWE, CVSS y remediación (IDOR / CWE-639, transmisión en texto plano / CWE-319, reutilización de credenciales / CWE-522, capability mal asignada / CWE-250).

---

## 🛠️ Stack y metodología

- **Reconocimiento y enumeración:** Nmap
- **Análisis y explotación web:** Burp Suite
- **Explotación y post-explotación:** Metasploit, binarios nativos de Linux/Windows (LOLBins/GTFOBins)
- **Análisis de tráfico:** Wireshark
- **Documentación:** Markdown, flujos de trabajo basados en Obsidian, plantillas propias de reporting

---

## 👨‍💻 Autor

**Valentín Francisco Nieto** — Junior Penetration Tester & Backend Developer

[LinkedIn](https://linkedin.com/in/niettovale) · [GitHub](https://github.com/NiettoVale) · [HackTheBox](https://app.hackthebox.com/users/3366501) · [Portfolio](https://www.ntech.studio/)
