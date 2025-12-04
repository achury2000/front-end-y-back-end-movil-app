const express = require('express');
const db = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

// GET /reports/dashboard - stats basicas
router.get('/dashboard', auth, async (req, res) => {
  try {
    // basic stats: total orders sum, count orders, count reservas, count usuarios
    const totalSalesQ = await db.query('SELECT COALESCE(SUM(total),0) as total_sales FROM orders');
    const countOrdersQ = await db.query('SELECT COUNT(*) as orders_count FROM orders');
    const countReservasQ = await db.query('SELECT COUNT(*) as reservas_count FROM reservas');
    const countUsersQ = await db.query('SELECT COUNT(*) as users_count FROM usuarios');
    res.json({
      total_sales: totalSalesQ.rows[0].total_sales,
      orders_count: parseInt(countOrdersQ.rows[0].orders_count, 10),
      reservas_count: parseInt(countReservasQ.rows[0].reservas_count, 10),
      users_count: parseInt(countUsersQ.rows[0].users_count, 10)
    });
  } catch (err) {
    console.error('GET /reports/dashboard error', err);
    res.status(500).json({ error: 'Error generando reporte' });
  }
});

module.exports = router;
