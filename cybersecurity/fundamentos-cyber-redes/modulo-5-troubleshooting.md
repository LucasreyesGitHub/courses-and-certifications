# Módulo 5 — Troubleshooting de Redes

## Contenido

- [Metodología de diagnóstico](#metodología-de-diagnóstico)
- [Problemas comunes y soluciones](#problemas-comunes-y-soluciones)
- [Comandos de diagnóstico por OS](#comandos-de-diagnóstico-por-os)
- [Casos prácticos](#casos-prácticos)
- [Seguridad en el proceso de troubleshooting](#seguridad-en-el-proceso-de-troubleshooting)
- [Herramientas recomendadas](#herramientas-recomendadas)

---

## Metodología de diagnóstico

No existe un único método correcto, pero hay dos enfoques principales:

### Bottom-Up (de capa 1 hacia arriba)

Ideal cuando hay **pérdida total de conectividad**.

```
Capa 1 → Capa 2 → Capa 3 → Capa 4 → Capa 7
Física → Enlace → Red   → Transport → App
```

### Top-Down (de capa 7 hacia abajo)

Ideal cuando **algunas aplicaciones funcionan y otras no**.

```
Capa 7 → Capa 4 → Capa 3 → Capa 2 → Capa 1
App → Transport → Red → Enlace → Física
```

### Proceso general de diagnóstico

```
1. DEFINIR el problema claramente
   "No puedo acceder a google.com" ≠ "No tengo internet"

2. RECOPILAR información
   - ¿Qué funciona y qué no?
   - ¿Cuándo empezó?
   - ¿Cambió algo recientemente?

3. HIPÓTESIS más probable
   - Si nadie tiene internet → problema en el gateway/ISP
   - Si solo mi PC no tiene → problema local

4. PROBAR la hipótesis
   - Comandos específicos por capa

5. IMPLEMENTAR solución
   - Si funciona → documentar
   - Si no → volver al paso 3

6. DOCUMENTAR la causa y la solución
```

---

## Problemas comunes y soluciones

### Sin conectividad total

**Síntomas**: ningún sitio web carga, ping a IPs externas falla.

```bash
# Paso 1: verificar interfaz
ip link show
# Buscar: state UP / state DOWN

# Si está DOWN:
sudo ip link set eth0 up

# Paso 2: verificar IP
ip addr show
# Si no hay IP: problema DHCP

# Obtener IP por DHCP manualmente
sudo dhclient eth0        # Linux
ipconfig /renew           # Windows

# Paso 3: probar gateway
ping -c 3 $(ip route | grep default | awk '{print $3}')

# Paso 4: probar internet por IP (sin DNS)
ping -c 3 8.8.8.8
# Si esto funciona pero los dominios no → problema DNS

# Paso 5: probar DNS
nslookup google.com
nslookup google.com 8.8.8.8   # Probar con DNS de Google
```

---

### Solo DNS no funciona

**Síntoma**: `ping 8.8.8.8` funciona pero `ping google.com` falla.

```bash
# Ver el servidor DNS configurado
cat /etc/resolv.conf

# Cambiar DNS temporalmente (Linux)
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'

# Windows — cambiar DNS por PowerShell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "8.8.8.8","1.1.1.1"

# Limpiar caché DNS
sudo systemd-resolve --flush-caches   # Linux (systemd)
sudo killall -HUP mDNSResponder       # macOS
ipconfig /flushdns                    # Windows

# Diagnosticar con dig
dig google.com              # Qué servidor responde
dig +trace google.com       # Seguir la resolución completa paso a paso
```

---

### Lentitud de red

**Síntoma**: la red funciona pero es muy lenta.

```bash
# 1. Medir latencia
ping -c 20 8.8.8.8
# Revisar: pérdida de paquetes y variación en tiempos (jitter)

# 2. Identificar el cuello de botella
traceroute google.com
# El salto con mayor latencia o pérdida es el problema

# 3. Medir throughput real
iperf3 -s                        # En el servidor
iperf3 -c IP_SERVIDOR -t 30      # En el cliente

# 4. Revisar errores en la interfaz
ip -s link show eth0
# Buscar: errors, dropped, overruns

# 5. Ver uso de ancho de banda en tiempo real
sudo apt install nload
nload eth0                        # Gráfico en tiempo real

# o con iftop
sudo iftop -i eth0
```

---

### Un puerto específico no responde

**Síntoma**: la red está bien pero una aplicación/servicio no conecta.

```bash
# Verificar si el puerto está abierto en el destino
nc -zv 192.168.1.100 80
nc -zv 192.168.1.100 443
# z = solo verificar, v = verbose

# Escanear puertos abiertos (en tu propia red)
nmap -sV 192.168.1.100

# Verificar si el servicio está escuchando localmente
ss -tulnp | grep :80
lsof -i TCP:80

# Ver si el firewall bloquea el puerto
sudo ufw status
sudo iptables -L -n | grep 80
```

---

### Conflicto de IP (IP duplicada)

**Síntoma**: conexión intermitente, mensajes de "IP ya en uso".

```bash
# Detectar quién tiene una IP específica en la red
arping -c 3 192.168.1.50
# Si ves dos MACs diferentes respondiendo → conflicto

# Escanear la red para ver qué IPs están en uso
nmap -sn 192.168.1.0/24

# Windows: detectar conflicto
arp -a | findstr "192.168.1.50"
```

**Solución**: cambiar la IP del dispositivo conflictivo o configurar el servidor DHCP para asignar IPs fijas por MAC (reservas DHCP).

---

## Comandos de diagnóstico por OS

### Linux

```bash
# Interfaz y estado
ip link show
ip addr show
ip -s link show eth0          # Estadísticas

# Enrutamiento
ip route show
ip route get 8.8.8.8          # ¿Por qué ruta va a este destino?

# Conectividad
ping -c 4 -W 1 8.8.8.8       # 4 paquetes, timeout 1s
traceroute -n 8.8.8.8        # -n evita resolución DNS (más rápido)
mtr 8.8.8.8                  # Combinación de ping + traceroute

# Puertos y conexiones
ss -tuln                      # Puertos en escucha
ss -tun                       # Conexiones activas
ss -s                         # Resumen de estadísticas

# DNS
dig google.com
dig +short google.com
resolvectl status             # Estado del resolver (systemd)

# Captura de paquetes
sudo tcpdump -i eth0 -n
sudo tcpdump -i eth0 port 80
sudo tcpdump -i eth0 -w captura.pcap    # Guardar para analizar con Wireshark
```

### macOS

```bash
# Equivalentes macOS
ifconfig                      # En lugar de ip addr
netstat -rn                   # Tabla de rutas
route -n get 8.8.8.8          # Ruta a destino
lsof -i                       # Conexiones activas
networksetup -listallhardwareports
dns-sd -q google.com          # Consulta DNS con Bonjour
```

### Windows (PowerShell / CMD)

```powershell
# Estado de red
ipconfig /all
Get-NetIPAddress
Get-NetAdapter

# Enrutamiento
route print
Get-NetRoute

# Conectividad
ping -n 4 8.8.8.8
tracert 8.8.8.8
Test-NetConnection google.com -Port 443   # PowerShell

# DNS
nslookup google.com
Resolve-DnsName google.com    # PowerShell

# Puertos
netstat -an
Get-NetTCPConnection          # PowerShell

# Limpiar
ipconfig /flushdns
ipconfig /release
ipconfig /renew
```

---

## Casos prácticos

### Caso 1: "No puedo entrar a ningún sitio web"

```
Síntoma: El navegador muestra ERR_NAME_NOT_RESOLVED

Diagnóstico:
  ping 8.8.8.8      → OK (hay conexión IP)
  ping google.com   → FAIL (falla DNS)
  nslookup google.com 8.8.8.8 → OK

Causa: El servidor DNS configurado (del ISP o router) no responde.

Solución:
  sudo bash -c 'echo "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf'
  # o cambiar DNS en la config del router para todos los dispositivos
```

---

### Caso 2: "Internet lento solo a la noche"

```
Síntoma: Latencia alta (100-300ms) en horario nocturno, normal de día.

Diagnóstico:
  traceroute google.com (de noche)
  # Resultado: primer salto (gateway) = 1ms, segundo salto = 180ms

Causa: Congestión en el enlace del ISP (oversubscription).

Solución:
  - Documentar y reportar al ISP con evidencia (capturas de traceroute).
  - Como workaround: QoS en el router para priorizar tráfico crítico.
```

---

### Caso 3: "Mi PC no se conecta pero los demás sí"

```
Síntoma: Todos en la oficina tienen internet, solo un equipo no.

Diagnóstico:
  ip addr show     → 169.254.x.x (IP de autoconfiguración = DHCP falló)
  ping gateway     → FAIL

Causa: El servidor DHCP no asignó IP (MAC bloqueada, pool agotado, o problema físico).

Solución:
  # Verificar cable / switch port
  ip link show     → state DOWN → problema físico

  # Si el cable está bien:
  sudo dhclient -v eth0    # Ver el proceso DHCP con detalle

  # Si DHCP falla, asignar IP estática temporalmente:
  sudo ip addr add 192.168.1.200/24 dev eth0
  sudo ip route add default via 192.168.1.1
```

---

### Caso 4: "El servidor web no responde en el puerto 443"

```
Síntoma: curl https://miserver.com → Connection refused

Diagnóstico:
  nc -zv miserver.com 443  → Connection refused
  ss -tulnp | grep :443    → No aparece nada

Causa: El servidor web (nginx/apache) no está corriendo o no escucha en 443.

Solución:
  # Verificar el servicio
  sudo systemctl status nginx

  # Si está caído:
  sudo systemctl start nginx
  sudo journalctl -u nginx --no-pager -n 50   # Ver errores en los logs

  # Verificar que el firewall permite 443
  sudo ufw allow 443/tcp
```

---

## Seguridad en el proceso de troubleshooting

### Precauciones al diagnosticar

```
⚠️  Nunca usar herramientas de diagnóstico (nmap, tcpdump) en redes ajenas
    sin autorización escrita. Es ilegal en la mayoría de jurisdicciones.

⚠️  Las capturas de tráfico (tcpdump, Wireshark) pueden contener credenciales
    en texto plano. Tratar los archivos .pcap como información sensible.

⚠️  El acceso a logs del sistema puede revelar información de usuarios.
    Restringir quién puede ejecutar estos comandos (sudo).
```

### Hardening básico post-diagnóstico

```bash
# Después de resolver un problema, verificar que no quedaron puertos
# innecesarios abiertos
ss -tulnp

# Revisar el firewall
sudo ufw status verbose

# Verificar que no hay procesos escuchando en puertos inesperados
ss -tulnp | grep -v "127.0.0.1\|::1"   # Puertos expuestos a la red

# Revisar conexiones salientes activas (detectar malware)
ss -tun state established
```

### Checklist de seguridad post-incidente

```
☐ ¿Se identificó la causa raíz?
☐ ¿Se aplicó el fix y se verificó que funciona?
☐ ¿El fix no dejó puertos/servicios innecesarios expuestos?
☐ ¿Se actualizaron las reglas de firewall si correspondía?
☐ ¿Se documentó el incidente? (fecha, causa, solución, tiempo de resolución)
☐ ¿Se notificó a los afectados?
```

---

## Herramientas recomendadas

| Herramienta  | Plataforma       | Función                                      | Instalación                    |
|--------------|------------------|----------------------------------------------|--------------------------------|
| `ping`       | Todas            | Latencia básica                              | Nativa                         |
| `traceroute` | Linux/macOS      | Ruta de paquetes                             | Nativa                         |
| `mtr`        | Linux/macOS      | ping + traceroute combinado                  | `apt install mtr`              |
| `nmap`       | Todas            | Escaneo de puertos y servicios               | `apt install nmap`             |
| `tcpdump`    | Linux/macOS      | Captura de paquetes en terminal              | Nativa                         |
| `Wireshark`  | Todas (GUI)      | Análisis visual de capturas                  | wireshark.org                  |
| `iperf3`     | Todas            | Medición de throughput                       | `apt install iperf3`           |
| `nload`      | Linux            | Monitoreo de ancho de banda en tiempo real   | `apt install nload`            |
| `iftop`      | Linux/macOS      | Ver conexiones por consumo de BW             | `apt install iftop`            |
| `dig`        | Linux/macOS      | Diagnóstico DNS avanzado                     | `apt install dnsutils`         |
| `netstat`/`ss`| Todas           | Conexiones y puertos activos                 | Nativa (`ss` reemplaza netstat)|
| `curl`       | Todas            | Probar HTTP/HTTPS desde terminal             | Nativa                         |
| `nc`         | Linux/macOS      | Probar conectividad a puerto específico      | Nativa                         |

### Instalación rápida de herramientas esenciales

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y \
  net-tools nmap mtr iperf3 nload iftop \
  dnsutils tcpdump wireshark-cli curl

# macOS (con Homebrew)
brew install nmap mtr iperf3 nload iftop bind

# Windows (con Chocolatey)
choco install nmap wireshark curl
```

---

## Conclusión del curso

Al completar este módulo, deberías poder:

✅ Aplicar metodología de troubleshooting por capas (OSI/TCP-IP)  
✅ Diagnosticar problemas de conectividad, DNS, lentitud y puertos  
✅ Usar los comandos esenciales en Linux, macOS y Windows  
✅ Identificar problemas de seguridad durante el diagnóstico  
✅ Documentar incidentes de red correctamente  

---

## Recursos adicionales

- [RFC 1918 — Direcciones IP privadas](https://tools.ietf.org/html/rfc1918)
- [RFC 793 — TCP](https://tools.ietf.org/html/rfc793)
- [RFC 768 — UDP](https://tools.ietf.org/html/rfc768)
- [Wireshark Documentation](https://www.wireshark.org/docs/)
- [nmap Reference Guide](https://nmap.org/book/man.html)

---

← [Módulo 4 — Modelo TCP/IP](modulo-4-modelo-tcp-ip.md) | [Volver al inicio](README.md)
