const express = require('express');
const db = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /cart - obtiene el carrito del usuario
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const q = await db.query('SELECT id FROM carrito WHERE usuario_id = $1', [userId]);
    if (q.rows.length === 0) return res.json({ items: [] });
    const cartId = q.rows[0].id;
    const items = await db.query('SELECT ci.id, ci.servicio_id, s.nombre, ci.cantidad, ci.precio_unitario FROM cart_items ci LEFT JOIN servicios s ON s.id = ci.servicio_id WHERE ci.carrito_id = $1', [cartId]);
    res.json({ items: items.rows });
  } catch (err) {
    console.error('GET /cart error', err);
    res.status(500).json({ error: 'Error leyendo carrito' });
  }
});

// POST /cart/items - añade un item al carrito
router.post('/items', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { servicio_id, cantidad, precio_unitario } = req.body || {};
    if (!servicio_id) return res.status(400).json({ error: 'servicio_id requerido' });
    // ensure cart exists
    let cart = await db.query('SELECT id FROM carrito WHERE usuario_id = $1', [userId]);
    let cartId;
    if (cart.rows.length === 0) {
      const c = await db.query('INSERT INTO carrito (usuario_id) VALUES ($1) RETURNING id', [userId]);
      cartId = c.rows[0].id;
    } else cartId = cart.rows[0].id;
    // Insert item (if exists, update cantidad)
    const exist = await db.query('SELECT id, cantidad FROM cart_items WHERE carrito_id = $1 AND servicio_id = $2', [cartId, servicio_id]);
    if (exist.rows.length > 0) {
      const newQty = (exist.rows[0].cantidad || 0) + (cantidad || 1);
      await db.query('UPDATE cart_items SET cantidad = $1, precio_unitario = COALESCE($2, precio_unitario) WHERE id = $3', [newQty, precio_unitario, exist.rows[0].id]);
      return res.json({ ok: true });
    }
    await db.query('INSERT INTO cart_items (carrito_id, servicio_id, cantidad, precio_unitario) VALUES ($1,$2,$3,$4)', [cartId, servicio_id, cantidad || 1, precio_unitario || 0.0]);
    res.json({ ok: true });
  } catch (err) {
    console.error('POST /cart/items error', err);
    res.status(500).json({ error: 'Error añadiendo item' });
  }
});

// PUT /cart/items/:id - actualizar cantidad o precio
router.put('/items/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { cantidad, precio_unitario } = req.body || {};
    const update = await db.query('UPDATE cart_items SET cantidad = COALESCE($1, cantidad), precio_unitario = COALESCE($2, precio_unitario) WHERE id = $3 RETURNING *', [cantidad, precio_unitario, id]);
    if (update.rows.length === 0) return res.status(404).json({ error: 'Item no encontrado' });
    res.json({ item: update.rows[0] });
  } catch (err) {
    console.error('PUT /cart/items/:id error', err);
    res.status(500).json({ error: 'Error actualizando item' });
  }
});

// DELETE /cart/items/:id
router.delete('/items/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    await db.query('DELETE FROM cart_items WHERE id = $1', [id]);
    res.json({ ok: true });
  } catch (err) {
    console.error('DELETE /cart/items/:id error', err);
    res.status(500).json({ error: 'Error eliminando item' });
  }
});

module.exports = router;
