const db = require('./db');

async function ensureSchema() {
  try {
    // Create refresh_tokens table if not exists
    await db.query(`
      CREATE TABLE IF NOT EXISTS refresh_tokens (
        token TEXT PRIMARY KEY,
        user_id INT NOT NULL,
        expires_at TIMESTAMP WITHOUT TIME ZONE,
        revoked BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
      )
    `);
    console.log('DB init: ensured refresh_tokens table');
    // Create cart and order tables
    await db.query(`
      CREATE TABLE IF NOT EXISTS carrito (
        id SERIAL PRIMARY KEY,
        usuario_id INT NOT NULL,
        creado_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
      )
    `);
    await db.query(`
      CREATE TABLE IF NOT EXISTS cart_items (
        id SERIAL PRIMARY KEY,
        carrito_id INT NOT NULL,
        servicio_id INT NOT NULL,
        cantidad INT DEFAULT 1,
        precio_unitario DECIMAL(10,2) DEFAULT 0.00,
        FOREIGN KEY (carrito_id) REFERENCES carrito(id) ON DELETE CASCADE,
        FOREIGN KEY (servicio_id) REFERENCES servicios(id)
      )
    `);
    await db.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        usuario_id INT NOT NULL,
        total DECIMAL(10,2) NOT NULL,
        estado VARCHAR(50) DEFAULT 'pendiente',
        creado_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
      )
    `);
    await db.query(`
      CREATE TABLE IF NOT EXISTS order_items (
        id SERIAL PRIMARY KEY,
        order_id INT NOT NULL,
        servicio_id INT NOT NULL,
        cantidad INT DEFAULT 1,
        precio_unitario DECIMAL(10,2) DEFAULT 0.00,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (servicio_id) REFERENCES servicios(id)
      )
    `);
    console.log('DB init: ensured cart, cart_items, orders, order_items tables');
  } catch (err) {
    console.error('DB init error:', err);
  }
}

module.exports = { ensureSchema };
