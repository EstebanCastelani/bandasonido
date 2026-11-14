// Limpieza de salas abandonadas. Una sala no es un documento: es un código con
// subcolecciones (pedidos, setlist, secuencias, miembros). Se considera
// abandonada si ninguna de ellas tuvo actividad en DIAS_INACTIVA_SALA días, y
// entonces se borra entera. Corre desde el cron del Worker (ver wrangler.toml),
// el día 1 de cada mes; con BORRAR_SALAS distinto de "true" solo lista.
//
// Cuesta lecturas de Firestore: unas pocas por sala (una consulta por
// subcolección), no un recorrido de todos los documentos.

export const DIAS_SALA_INACTIVA = 180;
const DIA_MS = 24 * 60 * 60 * 1000;
const SUBCOLECCIONES = [
  { id: 'pedidos', campo: 'createdAt' },
  { id: 'setlist', campo: 'createdAt' },
  { id: 'secuencias', campo: 'createdAt' },
  { id: 'miembros', campo: 'ultimaConexion' },
];

const base = (proyecto) => `https://firestore.googleapis.com/v1/projects/${proyecto}/databases/(default)/documents`;

async function pedir(buscar, token, url, cuerpo) {
  const r = await buscar(url, {
    method: cuerpo ? 'POST' : 'GET',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    ...(cuerpo ? { body: JSON.stringify(cuerpo) } : {}),
  });
  if (!r.ok) throw new Error(`firestore ${r.status}`);
  return r.json();
}

/** Códigos de todas las salas (los "documentos que faltan" que tienen subcolecciones). */
export async function listarSalas(proyecto, token, buscar = fetch) {
  const codigos = [];
  let pagina = '';
  do {
    const j = await pedir(
      buscar,
      token,
      `${base(proyecto)}/salas?pageSize=300&showMissing=true&mask.fieldPaths=x${pagina ? `&pageToken=${encodeURIComponent(pagina)}` : ''}`,
    );
    for (const d of j.documents ?? []) codigos.push(d.name.split('/').pop());
    pagina = j.nextPageToken ?? '';
  } while (pagina);
  return codigos;
}

const aMs = (iso) => (iso ? Date.parse(iso) : NaN);

/**
 * Última actividad de una sala (ms), o null si no se puede saber (en ese caso
 * NO se borra). Mira lo más nuevo de cada subcolección; los documentos viejos
 * sin fecha propia cuentan por su fecha de modificación.
 */
export async function ultimaActividad(proyecto, token, sala, buscar = fetch) {
  let mejor = 0;
  let vioDocumentos = false;
  for (const { id, campo } of SUBCOLECCIONES) {
    const url = `${base(proyecto)}/salas/${encodeURIComponent(sala)}:runQuery`;
    const ordenada = await pedir(buscar, token, url, {
      structuredQuery: {
        from: [{ collectionId: id }],
        orderBy: [{ field: { fieldPath: campo }, direction: 'DESCENDING' }],
        limit: 1,
      },
    });
    const doc = ordenada.find((x) => x.document)?.document;
    if (doc) {
      vioDocumentos = true;
      const f = aMs(doc.fields?.[campo]?.timestampValue) || aMs(doc.updateTime);
      if (f > mejor) mejor = f;
      continue;
    }
    const sinFecha = await pedir(buscar, token, url, {
      structuredQuery: { from: [{ collectionId: id }], limit: 20 },
    });
    for (const x of sinFecha) {
      if (!x.document) continue;
      vioDocumentos = true;
      const f = aMs(x.document.updateTime);
      if (f > mejor) mejor = f;
    }
  }
  return vioDocumentos && mejor > 0 ? mejor : null;
}

/** Salas con [dias] días o más sin actividad (las que no se pueden medir quedan fuera). */
export async function salasAbandonadas(proyecto, token, ahoraMs, dias = DIAS_SALA_INACTIVA, buscar = fetch) {
  const limite = ahoraMs - dias * DIA_MS;
  const fuera = [];
  for (const sala of await listarSalas(proyecto, token, buscar)) {
    const ultima = await ultimaActividad(proyecto, token, sala, buscar);
    if (ultima !== null && ultima < limite) fuera.push(sala);
  }
  return fuera;
}

/** Borra todos los documentos de las subcolecciones de una sala. Devuelve cuántos. */
export async function borrarSala(proyecto, token, sala, buscar = fetch) {
  let borrados = 0;
  for (const { id } of SUBCOLECCIONES) {
    for (;;) {
      const j = await pedir(
        buscar,
        token,
        `${base(proyecto)}/salas/${encodeURIComponent(sala)}/${id}?pageSize=300&mask.fieldPaths=x`,
      );
      const docs = j.documents ?? [];
      if (docs.length === 0) break;
      await pedir(buscar, token, `${base(proyecto)}:batchWrite`, {
        writes: docs.map((d) => ({ delete: d.name })),
      });
      borrados += docs.length;
    }
  }
  return borrados;
}
