import { Sequelize } from 'sequelize';
import { getSecret } from '../secrets';
import item from '../models/item';

const db = new Sequelize(
  getSecret('PGDB'),
  getSecret('PGUSER'),
  getSecret('PGPASSWORD'),
  {
    dialect: 'postgres',
    host: process.env.PGHOST
  });

const modelDefiners = [
  item
];

for (const modelDefiner of modelDefiners) {
  modelDefiner(db);
}

export default db;
