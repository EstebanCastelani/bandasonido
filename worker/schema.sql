-- Base D1 del servidor de archivos (ver README.md). Una sola copia de cada
-- archivo idéntico (blobs) y, por cuenta, los enlaces a los archivos que usa.

-- Un archivo guardado en R2 con la clave blob/{hash}.
CREATE TABLE IF NOT EXISTS blobs (
  hash   TEXT PRIMARY KEY,       -- SHA-256 en hexadecimal (calculado por el servidor)
  bytes  INTEGER NOT NULL,
  tipo   TEXT NOT NULL,          -- tipo de contenido (application/pdf, audio/mpeg...)
  creado INTEGER NOT NULL
);

-- Lo que cada cuenta tiene en su repertorio o sus secuencias. La cuota de una
-- cuenta es la suma de sus enlaces (aunque dos cuentas compartan la copia).
CREATE TABLE IF NOT EXISTS enlaces (
  uid    TEXT NOT NULL,
  clave  TEXT NOT NULL,          -- usuarios/{uid}/{carpeta}/{archivo}
  hash   TEXT NOT NULL REFERENCES blobs(hash),
  bytes  INTEGER NOT NULL,
  creado INTEGER NOT NULL,
  PRIMARY KEY (uid, clave)
);
CREATE INDEX IF NOT EXISTS enlaces_por_hash ON enlaces(hash);

-- Pruebas de que la app tiene el archivo antes de enlazarla a una copia que
-- ya existe (se usan una sola vez y vencen enseguida).
CREATE TABLE IF NOT EXISTS desafios (
  id     TEXT PRIMARY KEY,
  uid    TEXT NOT NULL,
  clave  TEXT NOT NULL,
  hash   TEXT NOT NULL,
  rangos TEXT NOT NULL,          -- JSON: [[desde, largo], ...]
  vence  INTEGER NOT NULL
);
