import db from './db/db';

export async function checkDBConnection(retries: number) {
    for (let index = 0; index < retries; index++) {
        try {
            console.log(`Trying to connect to: ${process.env.PGHOST}`);
            await db.authenticate();
            console.log(`Database connection OK!`);
            return;
        } catch (error) {
            console.log(`Unable to connect to the database:`);
            console.log(error.message);
            if (index === retries) {
                return;
            } else {
                console.log(`Retrying in ${(2 ** index * 1)} seconds...`)
            }
            await wait(2 ** index * 1000);
        }
    }
}

const wait = (ms: number) => new Promise(res => setTimeout(res, ms));