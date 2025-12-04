const express = require('express');
const db = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /users/me
router.get('/me', auth, async (req, res) => {
  try {
    const userId = req.user && req.user.userId;
    if (!userId) return res.status(401).json({ error: 'Usuario no autenticado' });
    const q = await db.query('SELECT id, nombre, apellido, email, rol_id, activo FROM usuarios WHERE id = $1', [userId]);
    if (q.rows.length === 0) return res.status(404).json({ error: 'Usuario no encontrado' });
    res.json({ user: q.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error obteniendo usuario', details: err.message });
  }
});

// PUT /users/:id
router.put('/:id', auth, async (req, res) => {
  const { id } = req.params;
  const { nombre, apellido, email, activo } = req.body || {};
  try {
    // Simple update (no password change here)
    const update = await db.query('UPDATE usuarios SET nombre = COALESCE($1, nombre), apellido = COALESCE($2, apellido), email = COALESCE($3, email), activo = COALESCE($4, activo) WHERE id = $5 RETURNING id, nombre, apellido, email, rol_id, activo', [nombre, apellido, email, activo, id]);
    if (update.rows.length === 0) return res.status(404).json({ error: 'Usuario no encontrado' });
    res.json({ user: update.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error actualizando usuario', details: err.message });
  }
});

module.exports = router;
