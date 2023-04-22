import * as dotenv from 'dotenv';
import serverlessExpress from '@vendia/serverless-express';
import server from './server';
import { APIGatewayEvent, Context } from 'aws-lambda';

dotenv.config();

const isLambdaRuntime = !!process.env.AWS_LAMBDA_FUNCTION_NAME;

// kept in lambda memory during hot load
console.log('cold start');

async function bootstrap() {
  if (isLambdaRuntime) {
    console.log('bootstrap code here');
  }
}

let serverlessExpressInstance: any;

async function setup(event: APIGatewayEvent, context: Context) {
  await bootstrap();
  serverlessExpressInstance = serverlessExpress({ server } as any);
  return serverlessExpressInstance(event, context);
}

exports.handler = async (event: APIGatewayEvent, context: Context) => {
  if (serverlessExpressInstance) {
    return serverlessExpressInstance(event, context);
  }
  return setup(event, context);
};
