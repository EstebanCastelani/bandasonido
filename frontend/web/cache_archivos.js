// Guarda en el navegador (Cache Storage) los PDF del setlist y las pistas de
// audio de la sala para abrirlos sin red, igual que la versión Android
// (ver lib/main.dart: CachePdfs y ReproductorSecuencias, y lib/puente_web.dart).
//
//   - 'sc-pdfs'  : PDF del setlist.     Máximo 40 archivos de hasta 80 MB.
//   - 'sc-audio' : secuencias de audio. Máximo 12 archivos de hasta 120 MB.
//
// Las pistas de audio, además, se dejan listas como "blob URL" en
// window.__blobUrls: reproductor_secuencias.js las usa de forma sincrónica
// (los navegadores de celular solo dejan arrancar audio dentro de un toque,
// sin awaits de por medio).
(function () {
  const MAX_BYTES = { 'sc-pdfs': 80 * 1024 * 1024, 'sc-audio': 120 * 1024 * 1024 };
  const MAX_ARCHIVOS = { 'sc-pdfs': 40, 'sc-audio': 12 };
  const disponible = typeof caches !== 'undefined';
  const descargas = new Map();
  window.__blobUrls = window.__blobUrls || new Map();

  // Pide al navegador que no borre lo guardado cuando falta espacio.
  try {
    if (navigator.storage && navigator.storage.persist) navigator.storage.persist();
  } catch (_) {}

  async function guardar(nombre, url) {
    const clave = nombre + '|' + url;
    if (descargas.has(clave)) return descargas.get(clave);
    const tarea = (async () => {
      try {
        const cache = await caches.open(nombre);
        if (await cache.match(url)) return true;
        const respuesta = await fetch(url, { mode: 'cors' });
        if (!respuesta.ok) return false;
        const largo = Number(respuesta.headers.get('content-length') || 0);
        if (largo > MAX_BYTES[nombre]) return false;
        await cache.put(url, respuesta);
        return true;
      } catch (e) {
        console.warn('No se pudo guardar sin conexión:', url, e);
        return false;
      } finally {
        descargas.delete(clave);
      }
    })();
    descargas.set(clave, tarea);
    return tarea;
  }

  async function prepararBlob(url) {
    if (window.__blobUrls.has(url)) return;
    const cache = await caches.open('sc-audio');
    const respuesta = await cache.match(url);
    if (!respuesta) return;
    window.__blobUrls.set(url, URL.createObjectURL(await respuesta.blob()));
  }

  async function limpiar(nombre, actuales) {
    const cache = await caches.open(nombre);
    const llaves = await cache.keys();
    let sobran = llaves.length - MAX_ARCHIVOS[nombre];
    for (const pedido of llaves) {
      if (sobran <= 0) break;
      if (actuales.has(pedido.url)) continue;
      await cache.delete(pedido);
      const blob = window.__blobUrls.get(pedido.url);
      if (blob) {
        URL.revokeObjectURL(blob);
        window.__blobUrls.delete(pedido.url);
      }
      sobran--;
    }
  }

  window.cacheArchivos = {
    disponible,

    // Baja de a una las [urls] que falten y devuelve cuáles quedaron guardadas.
    async precargar(nombre, urls) {
      if (!disponible) return [];
      const listas = [];
      for (const url of urls) {
        if (await guardar(nombre, url)) {
          listas.push(url);
          if (nombre === 'sc-audio') await prepararBlob(url);
        }
      }
      try {
        await limpiar(nombre, new Set(urls));
      } catch (_) {}
      return listas;
    },

    async bytes(nombre, url) {
      if (!disponible) return null;
      const cache = await caches.open(nombre);
      const respuesta = await cache.match(url);
      return respuesta ? new Uint8Array(await respuesta.arrayBuffer()) : null;
    },

    async borrar(nombre, url) {
      if (!disponible) return;
      const cache = await caches.open(nombre);
      await cache.delete(url);
      const blob = window.__blobUrls.get(url);
      if (blob) {
        URL.revokeObjectURL(blob);
        window.__blobUrls.delete(url);
      }
    },
  };
})();
