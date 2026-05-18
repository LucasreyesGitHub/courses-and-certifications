# Módulo 4 — Modelo TCP/IP

## Contenido

- [¿Qué es el modelo TCP/IP?](#qué-es-el-modelo-tcpip)
- [Las 4 capas de TCP/IP](#las-4-capas-de-tcpip)
- [OSI vs TCP/IP](#osi-vs-tcpip)
- [Direccionamiento IP](#direccionamiento-ip)
- [Protocolos clave](#protocolos-clave)
- [Seguridad](#seguridad)
- [Troubleshooting](#troubleshooting)

---

## ¿Qué es el modelo TCP/IP?

El modelo **TCP/IP** (*Transmission Control Protocol / Internet Protocol*) es el conjunto de protocolos que realmente usa Internet. A diferencia del modelo OSI (que es un marco teórico), TCP/IP es el estándar **implementado en la práctica**.

Fue desarrollado por el Departamento de Defensa de EE.UU. en los años 70 y es la base de toda la comunicación en Internet moderna.

---

## Las 4 capas de TCP/IP

```
┌─────────────────────────────────────────────────────────┐
│  4 │ APLICACIÓN  │ HTTP, HTTPS, DNS, FTP, SSH, SMTP     │
├────┼─────────────┼─────────────────────────────────────┤
│  3 │ TRANSPORTE  │ TCP, UDP                              │
├────┼─────────────┼─────────────────────────────────────┤
│  2 │ INTERNET    │ IP (IPv4/IPv6), ICMP, ARP            │
├────┼─────────────┼─────────────────────────────────────┤
│  1 │ ACCESO RED  │ Ethernet, WiFi, drivers de NIC       │
└─────────────────────────────────────────────────────────┘
```

---

### Capa 1 — Acceso a la Red

Equivale a las capas Física + Enlace de Datos del modelo OSI.

Maneja:
- El hardware de red (NIC, cables, antenas WiFi).
- Los protocolos de capa 2: Ethernet (802.3), WiFi (802.11).
- Direccionamiento físico: **MAC address**.

```bash
# Ver interfaces y MACs
ip link show

# Ver estadísticas de la interfaz (errores, paquetes perdidos)
ip -s link show eth0
```

---

### Capa 2 — Internet

El corazón del modelo TCP/IP. Responsable del **enrutamiento de paquetes** entre redes.

**Protocolo principal: IP**

Cada dispositivo tiene una **dirección IP** que lo identifica en la red.

#### IPv4

- 32 bits: `192.168.1.100`
- Representación decimal en 4 octetos.
- Aproximadamente 4,300 millones de direcciones (ya agotadas → NAT como solución temporal).

**Clases de direcciones IPv4**:

| Clase | Rango                       | Uso                    |
|-------|-----------------------------|------------------------|
| A     | 1.0.0.0 – 126.255.255.255   | Redes grandes          |
| B     | 128.0.0.0 – 191.255.255.255 | Redes medianas         |
| C     | 192.0.0.0 – 223.255.255.255 | Redes pequeñas (LAN)   |

**Rangos privados (RFC 1918)**:

```
10.0.0.0/8       → Clase A privada
172.16.0.0/12    → Clase B privada
192.168.0.0/16   → Clase C privada (hogar/oficina)
```

#### Subnetting básico

La máscara de subred define qué parte de la IP identifica la red y qué parte identifica el host.

```
IP:      192.168.1.100
Máscara: 255.255.255.0  (/24)
         ──────────────
Red:     192.168.1.0
Hosts:   192.168.1.1 – 192.168.1.254
Broadcast: 192.168.1.255

Hosts disponibles en /24: 254
```

```bash
# Calcular subred desde terminal
ipcalc 192.168.1.100/24
# o con python:
python3 -c "import ipaddress; n=ipaddress.IPv4Network('192.168.1.0/24'); print(list(n.hosts())[:5])"
```

#### IPv6

- 128 bits: `2001:0db8:85a3:0000:0000:8a2e:0370:7334`
- Prácticamente direcciones ilimitadas: 3.4 × 10³⁸.
- No necesita NAT.

```bash
# Ver IPs (incluye IPv6)
ip addr show
# Las IPv6 empiezan con fe80:: (link-local) o 2xxx:: (global)
```

---

### Capa 3 — Transporte

Igual que en OSI. Gestiona la comunicación entre procesos/aplicaciones usando **TCP** o **UDP**.

**Diferencia clave en la práctica**:

```
TCP = Confiable pero más lento
  → Usar para: web (HTTP/S), SSH, transferencias de archivos

UDP = Rápido pero sin garantías
  → Usar para: DNS, streaming, videojuegos, VoIP
```

```bash
# Ver conexiones activas TCP y UDP
ss -tuln

# Ver qué proceso tiene abierto el puerto 80
ss -tulnp | grep :80
# o
lsof -i TCP:80
```

---

### Capa 4 — Aplicación

Agrupa las capas Sesión, Presentación y Aplicación del modelo OSI.

Los protocolos de aplicación definen cómo los programas se comunican entre sí.

**Flujo completo — ejemplo HTTP**:

```
Navegador (cliente)
  1. Resuelve "google.com" → DNS (UDP puerto 53)
  2. Conecta a 142.250.x.x:443 → TCP SYN handshake
  3. Negocia TLS → HTTPS
  4. Envía GET / HTTP/1.1
  5. Recibe respuesta HTML 200 OK
  6. Renderiza la página
```

```bash
# Seguir una petición HTTP paso a paso
curl -v https://google.com 2>&1 | head -40

# Ver la resolución DNS
dig google.com
nslookup google.com

# Simular conexión HTTP manualmente
nc -v google.com 80
# Luego escribir: GET / HTTP/1.0 [Enter][Enter]
```

---

## OSI vs TCP/IP

| Aspecto            | OSI (7 capas)                  | TCP/IP (4 capas)                |
|--------------------|--------------------------------|---------------------------------|
| Propósito          | Marco teórico de referencia    | Implementación real de Internet |
| Capas              | 7                              | 4                               |
| Uso                | Educación, troubleshooting     | Producción, desarrollo          |
| Sesión/Presentación| Capas separadas                | Fusionadas en Aplicación        |
| Origen             | ISO (1984)                     | DoD de EE.UU. (1970s)           |

```
OSI               TCP/IP
────────          ────────
Aplicación  ──┐
Presentación   ├──→ Aplicación
Sesión      ──┘
Transporte  ──────→ Transporte
Red         ──────→ Internet
Enlace      ──┐
Física      ──┘──→ Acceso a la Red
```

**Regla práctica**: usá OSI para **entender y diagnosticar**, usá TCP/IP para **implementar y programar**.

---

## Protocolos clave

### DNS — Domain Name System

Traduce nombres de dominio a IPs. Opera en UDP/TCP puerto 53.

```bash
# Resolver un nombre
dig A google.com           # Registro IPv4
dig AAAA google.com        # Registro IPv6
dig MX gmail.com           # Servidores de correo
dig NS google.com          # Name servers

# DNS inverso (IP → nombre)
dig -x 8.8.8.8

# Usar un servidor DNS específico
dig @1.1.1.1 cloudflare.com
```

### DHCP — Dynamic Host Configuration Protocol

Asigna automáticamente IPs, máscara, gateway y DNS a los dispositivos.

```bash
# Renovar IP asignada por DHCP (Linux)
sudo dhclient -r eth0   # Liberar
sudo dhclient eth0      # Renovar

# Windows
ipconfig /release
ipconfig /renew
```

### NAT — Network Address Translation

Permite que múltiples dispositivos con IPs privadas compartan una sola IP pública.

```
192.168.1.10 ──┐
192.168.1.11 ──┤── Router (NAT) ── IP pública: 200.x.x.x ── Internet
192.168.1.12 ──┘
```

---

## Seguridad

### Amenazas a nivel TCP/IP

| Capa TCP/IP | Ataque                     | Descripción                                             |
|-------------|----------------------------|---------------------------------------------------------|
| Acceso red  | ARP Spoofing               | Falsificación de MAC para interceptar tráfico           |
| Internet    | IP Spoofing                | Falsificación del IP origen en paquetes                 |
| Internet    | ICMP Redirect              | Redirigir tráfico hacia un router malicioso             |
| Transporte  | SYN Flood (DoS)            | Llenar la tabla de conexiones del servidor              |
| Transporte  | Port scanning              | Identificar servicios abiertos para atacar              |
| Aplicación  | DNS Poisoning              | Redirigir dominios legítimos a IPs maliciosas           |
| Aplicación  | Man-in-the-Middle (MITM)   | Interceptar y modificar tráfico entre dos partes        |

### Mitigaciones

```bash
# Verificar si el firewall está activo (Linux)
sudo ufw status
sudo iptables -L -n

# Ver reglas de firewall
sudo ufw status verbose

# Bloquear un IP específico
sudo ufw deny from 10.0.0.5

# Permitir solo SSH desde una subred
sudo ufw allow from 192.168.1.0/24 to any port 22
```

```bash
# Detectar port scan en tus logs (buscar múltiples conexiones rechazadas)
sudo grep "DPT=" /var/log/ufw.log | awk '{print $13}' | sort | uniq -c | sort -rn | head -20
```

---

## Troubleshooting

### Diagrama de decisión para problemas de red

```
¿Hay conectividad?
│
├─ NO → ¿La interfaz está up?
│         ├─ NO → Capa 1: revisar cable, driver, puerto switch
│         └─ SI → ¿Hay IP asignada?
│                   ├─ NO → DHCP no funciona → revisar servidor DHCP
│                   └─ SI → ¿El gateway responde al ping?
│                             ├─ NO → Capa 3: problema de enrutamiento
│                             └─ SI → ¿DNS resuelve?
│                                       ├─ NO → Problema DNS
│                                       └─ SI → Problema en capa aplicación
└─ SI → ¿Es lenta? → Ver módulo 5 para troubleshooting de rendimiento
```

### Comandos esenciales

```bash
# Diagnóstico completo rápido
echo "=== Interfaces ===" && ip link show
echo "=== IPs ===" && ip addr show
echo "=== Gateway ===" && ip route | grep default
echo "=== DNS ===" && cat /resolv.conf 2>/dev/null || cat /etc/resolv.conf
echo "=== Ping gateway ===" && ping -c 3 $(ip route | grep default | awk '{print $3}')
echo "=== Ping DNS ===" && ping -c 3 8.8.8.8
echo "=== Resolve ===" && nslookup google.com

# Trazar ruta con tiempos
traceroute -n google.com    # Linux
tracert google.com          # Windows

# Ver tabla de enrutamiento completa
ip route show table all
```

---

## Siguiente módulo

→ [Módulo 5 — Troubleshooting](modulo-5-troubleshooting.md)
