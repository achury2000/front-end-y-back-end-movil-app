const express = require('express');
const db = require('../db');
const router = express.Router();

// Intentamos soportar dos esquemas comunes:
// - tablas en español: `servicios (id,nombre,precio)`
// - tablas en inglés: `products (id,name,price)`
// GET /products -> lista (consulta `servicios` y en fallback `products`).
router.get('/', async (req, res) => {
  try {
    // intentar servicios (esquema en español)
    try {
      const r = await db.query('SELECT id, nombre AS name, precio AS price FROM servicios ORDER BY id LIMIT 200');
      return res.json(r.rows);
    } catch (err) {
      // si la tabla no existe, intentamos products
      if (String(err.message).includes('no existe la relación') || String(err.code) === '42P01') {
        const r2 = await db.query('SELECT id, name, price FROM products ORDER BY id LIMIT 200');
        return res.json(r2.rows);
      }
      throw err;
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error leyendo servicios/products', details: err.message });
  }
});

// GET /products/:id -> servicio/producto por id
router.get('/:id', async (req, res) => {
  const id = req.params.id;
  try {
    try {
      const r = await db.query('SELECT id, nombre AS name, precio AS price FROM servicios WHERE id = $1', [id]);
      if (r.rows.length === 0) return res.status(404).json({ error: 'No encontrado' });
      return res.json(r.rows[0]);
    } catch (err) {
      if (String(err.message).includes('no existe la relación') || String(err.code) === '42P01') {
        const r2 = await db.query('SELECT id, name, price FROM products WHERE id = $1', [id]);
        if (r2.rows.length === 0) return res.status(404).json({ error: 'No encontrado' });
        return res.json(r2.rows[0]);
      }
      throw err;
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error leyendo servicio/producto', details: err.message });
  }
});

module.exports = router;
