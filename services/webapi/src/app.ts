import express from 'express';
import * as expressOasGenerator from 'express-oas-generator';
import * as http from 'http';
import * as bodyParser from 'body-parser';
import mountRoutes from './routes';
import db from './db/db';

export default class App {
	app = express();

	constructor() {
		/*
		 * NOTE: expressOasGenerator uses middleware placed before and after application routes to
		 *       generate a Swagger specification document and corresponding UI (at /api-spec and
		 *       /api-docs, respectively). This middleware can incur a performance penalty and so
		 *       is not recommended when the application is in production (and by default, the
		 *       middleware is disabled when NODE_ENV === 'production').
		 *
		 *       Should you wish to enable generating or serving Swagger in production, see the
		 *       options for configuring the middleware at:
		 * 
		 *       https://github.com/mpashkovskiy/express-oas-generator
		 */

		expressOasGenerator.handleResponses(this.app, {});
		this.app.use(bodyParser.json());
		mountRoutes(this.app);
		expressOasGenerator.handleRequests();
	};

	start = async () => {
		await this.checkDBConnection();

		var port = (process.env.PORT || '3000');
		var server = http.createServer(this.app);
		server.listen(port, () => console.log(`Server now listening on ${port}`));
	};

	checkDBConnection = async () => {
		try {
			console.log(`Trying to connect to: ${process.env.PGHOST}`);
			await db.authenticate();
			console.log(`Database connection OK!`);

		} catch (error) {
			console.log(`Unable to connect to the database:`);
			console.log(error.message);
		}
	};
};
