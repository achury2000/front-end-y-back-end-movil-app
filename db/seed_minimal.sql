-- Seed mínimo para desarrollo
-- Inserta roles y algunos servicios de ejemplo

-- Roles (no duplicar si ya existen)
INSERT INTO roles (nombre)
SELECT 'user'
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE nombre = 'user');

INSERT INTO roles (nombre)
SELECT 'admin'
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE nombre = 'admin');

-- Servicios de ejemplo
INSERT INTO servicios (nombre, precio)
SELECT 'Visita guiada básica', 25.00
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Visita guiada básica');

INSERT INTO servicios (nombre, precio)
SELECT 'Degustación local', 15.00
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Degustación local');

INSERT INTO servicios (nombre, precio)
SELECT 'Recorrido por la finca', 40.00
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Recorrido por la finca');

-- Nota: para crear un usuario admin usa el endpoint /auth/register o inserta manualmente añadiendo un password_hash válido.
