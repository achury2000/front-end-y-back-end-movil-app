const express = require('express');
const db = require('../db');
const router = express.Router();

// POST /reservations
// Body: { cliente_id, programacion_id, finca_id, venta_id, fecha, numero_personas, precio_total }
// Inserta en la tabla `reservas` del esquema proporcionado.
router.post('/', async (req, res) => {
  const { cliente_id, programacion_id, finca_id, venta_id, fecha, numero_personas, precio_total, servicios } = req.body || {};
  if (!fecha) return res.status(400).json({ error: 'fecha es requerida' });
  const clientServices = Array.isArray(servicios) ? servicios : [];
  const clientNumero = numero_personas || 1;
  const clientPrecio = precio_total || 0.0;
  let clientId = cliente_id || null;

  try {
    // Validaciones: cada servicio debe tener servicio_id y existir en la tabla
    for (const s of clientServices) {
      if (!s || !s.servicio_id) return res.status(400).json({ error: 'servicio_id requerido en cada servicio' });
      const exist = await db.query('SELECT id FROM servicios WHERE id = $1', [s.servicio_id]);
      if (exist.rows.length === 0) return res.status(400).json({ error: `Servicio no encontrado: ${s.servicio_id}` });
    }

    await db.query('BEGIN');

    // Si se proporcionó cliente_id pero no existe, creamos un cliente genérico y usamos su id
    if (clientId) {
      const c = await db.query('SELECT id FROM clientes WHERE id = $1', [clientId]);
      if (c.rows.length === 0) {
        const created = await db.query('INSERT INTO clientes (nombre) VALUES ($1) RETURNING id', ['Cliente auto']);
        clientId = created.rows[0].id;
      }
    } else {
      // Si no se proporcionó cliente_id, crear un cliente genérico
      const created = await db.query('INSERT INTO clientes (nombre) VALUES ($1) RETURNING id', ['Cliente auto']);
      clientId = created.rows[0].id;
    }

    const insertReserva = await db.query(
      `INSERT INTO reservas (cliente_id, programacion_id, finca_id, venta_id, fecha, numero_personas, precio_total)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
      [clientId, programacion_id || null, finca_id || null, venta_id || null, fecha, clientNumero, clientPrecio]
    );
    const reservaId = insertReserva.rows[0].id;

    for (const s of clientServices) {
      const sid = s.servicio_id;
      const cant = s.cantidad || 1;
      const precio_unit = s.precio_unitario != null ? s.precio_unitario : 0.0;
      await db.query('INSERT INTO reserva_servicio (reserva_id, servicio_id, cantidad, precio_unitario) VALUES ($1,$2,$3,$4)', [reservaId, sid, cant, precio_unit]);
    }

    await db.query('COMMIT');
    res.json({ ok: true, reserva_id: reservaId });
  } catch (err) {
    try { await db.query('ROLLBACK'); } catch (e) {}
    console.error('Error creando reserva:', err);
    const message = err && err.message ? err.message : String(err);
    res.status(500).json({ error: 'Error creando reserva', details: message });
  }
});

module.exports = router;
