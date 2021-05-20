import Router from 'express-promise-router';
import db from '../db/db';

const items = Router();

items.get('/', async (req, res) => {
  const rows = await db.models['item'].findAll();
  res.json(rows);
});

export default items;
