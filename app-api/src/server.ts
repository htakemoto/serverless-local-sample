import express, { Request, Response, NextFunction } from 'express';
import morgan from 'morgan';
import bodyParser from 'body-parser';
import infoController from './controllers/info.controller';
import userController from './controllers/user.controller';
import HttpException from './exceptions/http.exception';

const server = express();
const router = express.Router();

router.use(bodyParser.json());
router.use(bodyParser.urlencoded({ extended: true }));

router.get('/info', infoController.getInfo);
router.get('/users', userController.getUsers);
router.get('/users/:id', userController.getUser);
router.post('/users', userController.createUser);
router.put('/users/:id', userController.updateUser);
router.delete('/users/:id', userController.deleteUser);

// Error Handler
router.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
  console.error('Error: ', err);
  let error = err;
  // if error not thrown by us
  if (!(error instanceof HttpException)) {
    error = new HttpException(err.message);
  }
  const body = {
    statusCode: error.statusCode,
    message: error.message,
  };
  res.status(error.statusCode).send(body);
});

server.use(morgan('tiny'));
server.use('/', router);

// Error Handler for Not Found
server.use((_req: Request, res: Response, _next: NextFunction) => {
  const body = {
    statusCode: 404,
    message: 'Not Found',
  };
  res.status(body.statusCode).send(body);
});

export default server;
