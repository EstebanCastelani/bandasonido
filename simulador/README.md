# Simulador de carga (varios celulares en una sala)

Simula N "celulares" en la misma sala contra el **Firebase real** del proyecto `appbandasonido` (misma configuración pública que la app). No simula las pantallas, sino el tráfico de datos que produce la app:

- Cada dispositivo entra como **invitado** (Auth anónimo), escucha en vivo los pedidos (`orderBy createdAt desc`, `limit 200`) y el setlist, y manda pedidos con los mismos campos que la app.
- El dispositivo 0 hace de **sonidista**: marca los pedidos como vistos y atiende la mitad.
- Los dispositivos 1 a 3 cambian el tono (`transposicion`) del setlist cada ~5 s.
- Al final hay una **ráfaga**: todos mandan varios pedidos a la vez.
- Mide: tiempo de conexión, de escritura y de **llegada a los demás** (p50, p95, p99, máximo), entregas perdidas y errores. El informe queda en `informe.json`.
- Al terminar **borra** los pedidos y el setlist de la sala de prueba (`SIMxxxxx`) y las cuentas de invitado.

## Cómo correrlo
```bash
cd simulador
npm install
npm start                                   # 10 dispositivos, 60 s, un pedido cada 4 s
DISPOSITIVOS=10 SEGUNDOS=60 INTERVALO_MS=1000 RAFAGA=10 npm start   # presión
```
Variables: `DISPOSITIVOS`, `SEGUNDOS`, `INTERVALO_MS`, `RAFAGA`.

**Cuida la cuota gratuita de Firebase** (50.000 lecturas y 20.000 escrituras por día): cada pedido se lee en todos los dispositivos. El script estima las lecturas y **se niega a correr** si pasan de 20.000. Una corrida de presión (10 dispositivos, 1 s) usa ~7.000 lecturas.

## Resultados (13-nov-2026, desde una PC en Argentina, red doméstica)
| | Normal (1 pedido / 4 s / dispositivo) | Presión (1 pedido / s / dispositivo, ráfaga de 10) |
|---|---|---|
| Pedidos enviados | 203 | 698 |
| Entregas (a los otros 9 dispositivos) | 1.827 de 1.827 (100 %) | 6.282 de 6.282 (100 %) |
| Errores | 0 | 0 |
| Escritura de un pedido (p50 / p95) | 113 / 330 ms | 107 / 482 ms |
| **Llegada a los demás** (p50 / p95 / máx) | 128 / 362 / 767 ms | 118 / 716 / 735 ms |
| Llegada de un cambio de tono (p50 / p95) | 123 / 504 ms | 115 / 181 ms |
| Conexión de los 10 dispositivos | 788 ms | 826 ms |

Lectura: con 10 dispositivos y ~10 pedidos por segundo, ninguno se perdió y el p95 de llegada quedó bajo 0,75 s. (Los máximos de llegada del setlist de esa corrida, 13 s y 87 s, eran un error de medición del script —contaba el aviso de borrado de la limpieza—, ya corregido.)

## Lo que NO cubre
- La carga de **dibujar** pantallas en celulares reales (memoria, batería, GPU).
- Archivos (PDF y audio) ni el servidor de Cloudflare.
- Reglas de seguridad y App Check (no hay límite por minuto ni validación de pedidos todavía: B-02).
- Redes malas (4G inestable, cortes): los dispositivos usan la misma red de la PC.
- Más de unas decenas de dispositivos: la cuota gratuita lo impide.
