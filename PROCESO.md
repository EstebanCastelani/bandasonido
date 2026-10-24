# Cómo se trabaja en el proyecto

Proceso mínimo para sostener la calidad (ver `AUDITORIA_CALIDAD_ESTANDARES.md`, etapa 7). Está pensado para un equipo muy chico (ISO/IEC 29110, perfil básico: *gestión del proyecto* + *implementación del software*) y para consolidar el **nivel 2 de CMMI** antes de pensar en niveles superiores.

## 1. Flujo de un cambio

1. **Elegir un ítem** del `BACKLOG.md` (el de mayor prioridad que no esté bloqueado por una decisión).
2. **Crear una rama** corta: `git switch -c tipo/descripcion` (`fix/`, `feat/`, `docs/`, `deps/`).
3. **Trabajar con pruebas:** primero el caso que falla (o el requisito RQ-xx), después el código. Formatear con `dart format lib/main.dart lib/puente_web.dart test`.
4. **Abrir un pull request** hacia `main` con la plantilla (`.github/pull_request_template.md`): la CI corre formato, análisis y pruebas. **No se une con la CI en rojo.**
5. **Revisión:** otra persona (o, si trabajás solo, una relectura propia al día siguiente con la plantilla en la mano) confirma la definición de "hecho".
6. **Unir a `main`** (la web se publica sola si la CI pasó) y, si es una versión nueva, seguir `OPERACION.md` §1 (versión, `CHANGELOG.md`, tag).

> Hoy el 100 % del historial (43+ commits) está en `main` y sin revisión. Hasta que se active la protección de rama (§4) el flujo anterior es una regla del equipo, no una restricción técnica.

## 2. Cadencia (Agile / Scrum liviano)

| Elemento | En Scrum | Cómo se hace acá |
|---|---|---|
| Backlog del producto | Lista priorizada | `BACKLOG.md` (única fuente de pendientes) |
| Sprint | Iteración corta | **1 semana**; se eligen 3–5 ítems del backlog y se anotan en la sección "En curso" |
| Daily | Seguimiento diario | Solo si hay más de una persona; si no, anotar en el ítem "qué hice / qué sigue / qué me traba" |
| Review | Mostrar lo hecho | Al cerrar el sprint, **probar con alguien de la banda o el sonidista** lo que cambió (no alcanza con que compile) y anotar sus comentarios |
| Retrospectiva | Mejora continua | 15 minutos al cerrar el sprint con la plantilla de §3; **una** acción concreta para la semana siguiente |
| Roles | PO / Scrum Master / equipo | Dueño del producto = quien decide las decisiones D-xx de `REQUISITOS.md`; el resto del equipo implementa |

## 3. Plantilla de retrospectiva
Copiar al final de `BACKLOG.md` (sección "Retrospectivas") o a un issue:

```
Sprint: AAAA-MM-DD → AAAA-MM-DD
Qué salió bien:
Qué no salió bien / qué nos frenó:
Qué aprendimos de las pruebas con usuarios:
UNA acción para el próximo sprint (con responsable):
Defectos abiertos / cerrados:  /
```

## 4. Protección de la rama `main` 🔑
Requiere permisos de administración del repositorio (no se puede hacer desde el código). En GitHub → *Settings* → *Branches* → *Add branch ruleset* para `main`:
- Exigir *pull request* antes de unir.
- Exigir que pase la comprobación de estado **`test`** (el trabajo de `.github/workflows/deploy.yml`).
- Impedir *force push* y borrado de la rama.
- Si trabajás solo, permitir que el administrador pueda saltearse la regla en emergencias (quedará registrado).

## 5. Autoevaluación de madurez (informal, no es una evaluación CMMI)
Áreas típicas del nivel 2 de CMMI ("gestionado"). Revisar cada tres meses y guardar la fecha:

| Área | Pregunta | Estado al 24-oct-2026 |
|---|---|---|
| Gestión de requisitos | ¿Hay requisitos escritos, con criterio de aceptación y trazabilidad a pruebas? | 🟡 `REQUISITOS.md` (RQ-01…RQ-26) y casos CP-xx; falta cubrir todos con pruebas |
| Planificación y seguimiento | ¿Hay un plan priorizado y se compara con lo hecho? | 🟡 `BACKLOG.md` nuevo; falta cadencia sostenida |
| Aseguramiento de calidad del proceso | ¿Se controla que se siga el proceso? | 🟡 CI con control previo; falta protección de rama y revisión |
| Gestión de la configuración | ¿Versiones, tags, cambios trazables? | 🟡 Git y versión `1.1.0` con `CHANGELOG.md`; falta publicar el primer tag |
| Medición y análisis | ¿Se miden tiempos, errores, uso? | 🔴 Línea base de carga local (`OPERACION.md` §7); sin métricas de uso ni de latencia |
| Gestión de proveedores | ¿Se conocen y vigilan los servicios externos? | 🟡 Inventario en `OPERACION.md` §4; faltan planes y cuotas 🔑 |

Lectura: el proyecto está en el **nivel 1 → 2 en transición**. El objetivo útil es cerrar los 🟡 y el 🔴 antes de buscar niveles superiores (lección de la clase: no invertir en el nivel 5 con procesos sin documentar).

## 6. Definición de "hecho"
Ver `REQUISITOS.md` §3 y la plantilla de pull request. En resumen: formato, análisis y pruebas en verde; prueba nueva si cambia una regla de negocio; textos en 5 idiomas; flujo probado a mano; documentos al día.
