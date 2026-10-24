## Qué cambia y por qué
<!-- Una o dos frases. Si corrige un defecto, indicá su ID (DF-xx); si implementa un requisito, su RQ-xx. -->

## Definición de "hecho" (ver REQUISITOS.md §3)
- [ ] `dart format` aplicado y `flutter analyze --no-fatal-infos` sin errores ni warnings
- [ ] `flutter test` en verde (las pruebas `skip` siguen siendo defectos abiertos en `DEFECTOS.md`)
- [ ] Si cambia una regla de negocio: hay una prueba nueva o un caso en `AUDITORIA_TESTING.md`
- [ ] Textos nuevos en los 5 idiomas (`lib/l10n/app_XX.arb`)
- [ ] Probado a mano el flujo afectado (navegador/celular) y anotado abajo
- [ ] `CONTEXTO_PARA_IA.md` y `CHANGELOG.md` actualizados si corresponde
- [ ] Si toca reglas de Firestore/Storage, claves o servicios externos: está avisado y es reversible

## Cómo lo probé
<!-- Pasos y resultado. Indicá también lo que NO pudiste probar. -->

## Riesgos / cómo volver atrás
<!-- ¿Se puede volver a la versión anterior publicando su tag? ¿Hay datos que migrar? -->
