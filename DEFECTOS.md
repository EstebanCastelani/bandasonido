# Defectos conocidos

Registro vivo de defectos (parte de la Etapa 7 del plan de testing, adelantado para respaldar las pruebas marcadas `skip`). Formato por defecto: **ID · severidad · estado · cómo reproducir · esperado · obtenido · prueba · decisión relacionada**.

Estados: **Abierto** · **Esperando decisión** · **En curso** · **Corregido** (con commit).

## Abiertos

### DF-01 · Alta · Esperando decisión (D-04)
Un rol que contiene la palabra "de som" entra al panel del sonidista aunque no lo sea.
- **Reproducir:** crear o unirse a una sala con rol `Vocalista de Somos Mil`.
- **Esperado:** pantalla de pedidos (es un cantante).
- **Obtenido:** panel del sonidista (`esRolSonidista` devuelve `true`).
- **Prueba:** `logica_pura_test.dart` · `"Vocalista de Somos Mil" NO debe entrar al panel` (skip).

### DF-02 · Media · Esperando decisión (D-04)
Roles de sonido reales no activan la entrada al panel.
- **Reproducir:** rol `Ingeniero de audio`, `Operador de audio`, `FOH` o `Monitorista`.
- **Esperado (propuesto):** panel del sonidista.
- **Obtenido:** pantalla de pedidos.
- **Prueba:** `logica_pura_test.dart` · 4 casos (skip).

### DF-03 · Alta · Esperando decisión (D-05)
La transposición no hace nada con notación latina y no avisa.
- **Reproducir:** cifrado `[Do]a [Re]b [Mi]c`, transponer +2.
- **Esperado:** `[Re]a [Mi]b [Fa#]c`.
- **Obtenido:** el texto queda igual.
- **Prueba:** `logica_pura_test.dart` · `notación latina [Do] [Re] [Mi] +2` (skip).

### DF-04 · Media · Esperando decisión (D-03)
Unirse con un código de 8 caracteres inexistente entra a una sala vacía sin aviso.
- **Reproducir:** Unirme a sala → código `ZZZZZZZZ` + nombre + rol.
- **Esperado (propuesto):** aviso "Esa sala no existe. Revisá el código." y no entrar.
- **Obtenido:** entra a la sala vacía.
- **Prueba:** pendiente (Etapa 3, requiere servicios simulados).

### DF-05 · Media · Esperando decisión (D-07)
"Deshacer" restaura la copia vieja del pedido y puede revertir cambios hechos por otro sonidista; actuar sobre un pedido ya borrado lanza una excepción sin mensaje. (Riesgo identificado por inspección de código; **no reproducido**.)
- **Pasos para reproducir (a confirmar en Etapa 5):** con dos sonidistas en la misma sala, B marca atendido el pedido justo antes de que A lo borre; A toca Deshacer.
- **Esperado (propuesto):** el pedido vuelve con el estado más reciente.
- **Obtenido (por código):** vuelve con `atendido` anterior.
- **Prueba:** pendiente (Etapa 5, dos clientes con emulador).

### DF-06 · Baja · Abierto
La transposición escribe sostenidos aunque el texto original no tenga alteraciones: `C G Am F` +3 → `D# A# Cm G#` (un músico espera `Eb Bb Cm Ab`).
- **Prueba:** pendiente (depende de la lógica de tonalidad).

### DF-07 · Baja · Abierto
La lista de pedidos rápidos repite "Volumen retorno" (primera y tercera fila de `AppConstants.pedidosRapidos`).
- **Prueba:** pendiente (basta una prueba que verifique que no hay frases repetidas).

### DF-08 · Media · Abierto
Las consultas en tiempo real de la sala (`snapshots()`) no tienen límite: 12 `snapshots()` y 2 `limit()` en `main.dart`; la lista de pedidos crece sin tope en cada dispositivo.
- **Decisión relacionada:** D-08.
- **Prueba:** pendiente (Etapa 6, medir lecturas).

## Corregidos
(ninguno todavía)
