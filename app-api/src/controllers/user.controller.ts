import { Request, Response, NextFunction } from 'express';
import userRepository from '../repositories/user.repository';
import HttpException from '../exceptions/http.exception';

class UserController {
  /**
   * GET /users
   */
  async getUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const users = await userRepository.getUsers();
      res.status(200).json(users);
    } catch (err) {
      return next(err);
    }
  }

  /**
   * GET /users/:id
   */
  async getUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const user = await userRepository.getUserById(id);
      if (!user) {
        throw new HttpException('user is not found', 404);
      }
      res.status(200).json(user);
    } catch (err) {
      return next(err);
    }
  }

  /**
   * POST /users
   */
  async createUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.body;
      if (user.id) {
        throw new HttpException(`user.id=${user.id} exists`, 400);
      }
      const users = await userRepository.getUsers();
      user.id = (users.length + 1).toString();
      console.log(user);
      const createdUser = await userRepository.putUser(user);
      res.status(200).json(createdUser);
    } catch (err) {
      return next(err);
    }
  }

  /**
   * PUT /users/:id
   */
  async updateUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const user = req.body;
      if (id != user.id) {
        throw new HttpException('id in url and payload does not match', 400);
      }
      const response = await userRepository.putUser(user);
      res.status(200).json(response);
    } catch (err) {
      return next(err);
    }
  }

  /**
   * DELETE /users/:id
   */
  async deleteUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const user = await userRepository.getUserById(id);
      if (!user) {
        throw new HttpException(`user.id=${id} does not exist`, 400);
      }
      await userRepository.deleteUserById(id);
      res.status(200).json(undefined);
    } catch (err) {
      return next(err);
    }
  }
}

export default new UserController();
