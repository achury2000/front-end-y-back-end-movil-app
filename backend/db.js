const { Pool } = require('pg');
require('dotenv').config({ path: '../.env' });

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 5432,
  user: process.env.DB_USER || 'occi_user',
  password: process.env.DB_PASSWORD || 'secretpassword',
  database: process.env.DB_NAME || 'occitours_dev'
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool
};
