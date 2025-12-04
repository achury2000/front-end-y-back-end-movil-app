const express = require('express');
const db = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

// POST /orders - crear orden a partir de carrito o payload
router.post('/', auth, async (req, res) => {
  const client = await db.pool.connect();
  try {
    const usuario_id = req.user.userId;
    const { from_cart } = req.body || {};
    await client.query('BEGIN');
    let items = [];
    if (from_cart) {
      const cartQ = await client.query('SELECT id FROM carrito WHERE usuario_id = $1', [usuario_id]);
      if (cartQ.rows.length === 0) return res.status(400).json({ error: 'Carrito vacío' });
      const cartId = cartQ.rows[0].id;
      const itemsQ = await client.query('SELECT servicio_id, cantidad, precio_unitario FROM cart_items WHERE carrito_id = $1', [cartId]);
      items = itemsQ.rows;
    } else {
      items = Array.isArray(req.body.items) ? req.body.items : [];
    }
    if (items.length === 0) return res.status(400).json({ error: 'No hay items para crear la orden' });
    const total = items.reduce((acc, it) => acc + (parseFloat(it.precio_unitario || 0) * (it.cantidad || 1)), 0);
    const ins = await client.query('INSERT INTO orders (usuario_id, total, estado) VALUES ($1,$2,$3) RETURNING id', [usuario_id, total, 'pendiente']);
    const orderId = ins.rows[0].id;
    for (const it of items) {
      await client.query('INSERT INTO order_items (order_id, servicio_id, cantidad, precio_unitario) VALUES ($1,$2,$3,$4)', [orderId, it.servicio_id, it.cantidad || 1, it.precio_unitario || 0.0]);
    }
    if (from_cart) {
      // clear cart
      const cartQ = await client.query('SELECT id FROM carrito WHERE usuario_id = $1', [usuario_id]);
      if (cartQ.rows.length > 0) {
        await client.query('DELETE FROM cart_items WHERE carrito_id = $1', [cartQ.rows[0].id]);
      }
    }
    await client.query('COMMIT');
    res.json({ ok: true, order_id: orderId });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('POST /orders error', err);
    res.status(500).json({ error: 'Error creando orden' });
  } finally {
    client.release();
  }
});

// GET /orders - historial del usuario
router.get('/', auth, async (req, res) => {
  try {
    const usuario_id = req.user.userId;
    const orders = await db.query('SELECT id, total, estado, creado_at FROM orders WHERE usuario_id = $1 ORDER BY creado_at DESC', [usuario_id]);
    const results = [];
    for (const o of orders.rows) {
      const itemsQ = await db.query('SELECT oi.id, oi.servicio_id, s.nombre, oi.cantidad, oi.precio_unitario FROM order_items oi LEFT JOIN servicios s ON s.id = oi.servicio_id WHERE oi.order_id = $1', [o.id]);
      results.push({ order: o, items: itemsQ.rows });
    }
    res.json({ orders: results });
  } catch (err) {
    console.error('GET /orders error', err);
    res.status(500).json({ error: 'Error obteniendo órdenes' });
  }
});

module.exports = router;
