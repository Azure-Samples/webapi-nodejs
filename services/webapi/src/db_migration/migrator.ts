import Umzug from 'umzug';
import * as path from 'path';
import db from '../db/db';
import { checkDBConnection } from '../dbConnect';

const umzug = new Umzug({
    storage: 'sequelize',
    storageOptions: {
        sequelize: db
    },
    logging: (...args) => console.log.apply(null, args),
    migrations: {
        path: path.join(__dirname, './migrations'),
        pattern: /\.js$/,
        params: [
            db.getQueryInterface()
        ]
    }
});

export async function migrate() {
    console.log("Running migrations.");
    await checkDBConnection(10);
    await umzug.up();
}

export async function rollback() {
    console.log("Rollback migrations.");
    await checkDBConnection(10);
    await umzug.down();
}