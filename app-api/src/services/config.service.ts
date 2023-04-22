import * as dotenv from 'dotenv';

class ConfigService {
  ENVIRONMENT: string;
  APP_VERSION: string;
  isLambdaRuntime: boolean;
  // Database
  DB_ENDPOINT: string;
  DB_NAME_USER: string;

  constructor() {
    dotenv.config();
    // System
    this.ENVIRONMENT = process.env.ENVIRONMENT || '';
    this.APP_VERSION = process.env.APP_VERSION || '';
    this.isLambdaRuntime = !!process.env.AWS_LAMBDA_FUNCTION_NAME;
    this.DB_ENDPOINT = process.env.DB_ENDPOINT || '';
    this.DB_NAME_USER = process.env.DB_NAME_USER || '';
  }
}

export default new ConfigService();
