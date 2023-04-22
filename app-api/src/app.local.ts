import * as dotenv from 'dotenv';
import server from './server';

dotenv.config();

const port = process.env.PORT;
server.listen(port, () => console.info(`listening on http://localhost:${port}`));
