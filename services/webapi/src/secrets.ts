import * as fs from 'fs';

export function getSecret(name) {
    console.log(`Checking for secret ${name}`);

    const secretEnv = process.env[name];
    const secretFile = process.env[name + "_FILE"];

    if(secretEnv !== undefined) {
        console.log(`Secret ${name} has been read from environment variable`);
        return secretEnv;
    } else if (secretFile !== undefined) {
        console.log(`Secret ${name} has been read from file ${secretFile}`);
        return fs.readFileSync(secretFile, 'utf8');
    } else {
        throw new Error("Required secret not defined");
    }

}