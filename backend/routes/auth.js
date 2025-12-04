const express = require('express');
const db = require('../db');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
require('dotenv').config({ path: '../.env' });

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'devsecret';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';
const REFRESH_EXPIRES_DAYS = parseInt(process.env.REFRESH_EXPIRES_DAYS || '30');

function signAccessToken(user) {
  const payload = { userId: user.id, email: user.email, rol_id: user.rol_id };
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

function calcRefreshExpiry() {
  const d = new Date();
  d.setDate(d.getDate() + REFRESH_EXPIRES_DAYS);
  return d;
}

async function ensureRefreshTable() {
  try {
    await db.query(`CREATE TABLE IF NOT EXISTS refresh_tokens (
      token TEXT PRIMARY KEY,
      user_id INT NOT NULL,
      expires_at TIMESTAMP WITHOUT TIME ZONE,
      revoked BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
    )`);
  } catch (e) {
    console.error('Error ensuring refresh_tokens table', e);
  }
}

// POST /auth/register
router.post('/register', async (req, res) => {
  const { nombre, apellido, email, cedula, password } = req.body || {};
  if (!email || !password || !nombre || !apellido) return res.status(400).json({ error: 'nombre, apellido, email y password requeridos' });
  const cedulaSafe = cedula || `sin${Date.now().toString().slice(-8)}`;
  try {
    const exists = await db.query('SELECT id FROM usuarios WHERE email = $1', [email]);
    if (exists.rows.length > 0) return res.status(400).json({ error: 'Email ya registrado' });
    const hash = await bcrypt.hash(password, 10);
    // Ensure at least one role exists; default to first role or create 'user'
    let roleId;
    const roleQ = await db.query('SELECT id FROM roles LIMIT 1');
    if (roleQ.rows.length > 0) roleId = roleQ.rows[0].id;
    else {
      const r = await db.query('INSERT INTO roles (nombre) VALUES ($1) RETURNING id', ['user']);
      roleId = r.rows[0].id;
    }
    const insert = await db.query(
      'INSERT INTO usuarios (nombre, apellido, cedula, email, password_hash, rol_id, activo) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id, nombre, apellido, email, rol_id, activo',
      [nombre, apellido, cedulaSafe, email, hash, roleId, true]
    );
    const user = insert.rows[0];
    const access_token = signAccessToken(user);
    res.json({ access_token, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error en registro', details: err.message });
  }
});

// POST /auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) return res.status(400).json({ error: 'email y password requeridos' });
  try {
    const result = await db.query('SELECT id, nombre, apellido, email, rol_id, activo, password_hash FROM usuarios WHERE email = $1', [email]);
    if (result.rows.length === 0) return res.status(401).json({ error: 'Credenciales inválidas' });
    const user = result.rows[0];
    const match = await bcrypt.compare(password, user.password_hash || '');
    if (!match) return res.status(401).json({ error: 'Credenciales inválidas' });
    const safeUser = { id: user.id, nombre: user.nombre, apellido: user.apellido, email: user.email, rol_id: user.rol_id, activo: user.activo };
    const access_token = signAccessToken(user);
    res.json({ access_token, user: safeUser });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error en login', details: err.message });
  }
});

// POST /auth/refresh - not implemented (refresh tokens not stored in this MVP)
router.post('/refresh', async (req, res) => {
  res.status(501).json({ error: 'refresh no implementado en este entorno' });
});

module.exports = router;
