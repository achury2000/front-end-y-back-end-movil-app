const express = require('express');
const cors = require('cors');
require('dotenv').config({ path: '../.env' });

const productsRouter = require('./routes/products');
const authRouter = require('./routes/auth');
const reservationsRouter = require('./routes/reservations');
const usersRouter = require('./routes/users');
const dbInit = require('./db_init');
const cartRouter = require('./routes/cart');
const ordersRouter = require('./routes/orders');
const reportsRouter = require('./routes/reports');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/products', productsRouter);
app.use('/auth', authRouter);
app.use('/reservations', reservationsRouter);
app.use('/users', usersRouter);
app.use('/cart', cartRouter);
app.use('/orders', ordersRouter);
app.use('/reports', reportsRouter);

// Ensure DB helper objects exist (refresh_tokens table) ONLY when explicitly enabled
const enableDbInit = (process.env.ENABLE_DB_INIT || 'false').toLowerCase() === 'true';

(async () => {
	if (enableDbInit) {
		console.log('DB init enabled: ensuring auxiliary tables...');
		await dbInit.ensureSchema();
	} else {
		console.log('DB init disabled (ENABLE_DB_INIT!=true). Skipping runtime schema changes.');
	}
	const port = process.env.BACKEND_PORT || 3000;
	app.listen(port, () => console.log(`Backend listening on ${port}`));
})();
