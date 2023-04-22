import { Request, Response, NextFunction } from 'express';
import { getCurrentInvoke } from '@vendia/serverless-express';
import config from '../services/config.service';

class InfoController {
  /**
   * GET /info
   */
  async getInfo(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const currentInvoke = getCurrentInvoke();
      const { context = {} } = currentInvoke;
      const response = {
        environment: config.ENVIRONMENT,
        appVersion: config.APP_VERSION,
        functionVersion: context.functionVersion,
      };
      res.status(200).json(response);
    } catch (err) {
      return next(err);
    }
  }
}

export default new InfoController();
