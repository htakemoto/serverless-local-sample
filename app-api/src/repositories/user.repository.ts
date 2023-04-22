import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  ScanCommand,
  GetCommand,
  PutCommand,
  DeleteCommand,
} from '@aws-sdk/lib-dynamodb';
import config from '../services/config.service';
import { User } from '../types';

class UserRepository {
  client: DynamoDBClient;
  docClient: DynamoDBDocumentClient;

  constructor() {
    const params = {} as any;
    // set endpoint for DynamoDB Local
    if (config.DB_ENDPOINT) {
      params.endpoint = config.DB_ENDPOINT;
    }
    this.client = new DynamoDBClient(params);
    this.docClient = DynamoDBDocumentClient.from(this.client);
  }

  async getUsers(): Promise<User[]> {
    const input = {
      TableName: config.DB_NAME_USER,
    };
    const command = new ScanCommand(input);
    const result = await this.docClient.send(command);
    return result.Items as User[];
  }

  async getUserById(id: string): Promise<User> {
    const input = {
      TableName: config.DB_NAME_USER,
      Key: {
        id,
      },
    };
    const command = new GetCommand(input);
    const result = await this.docClient.send(command);
    return result.Item as User;
  }

  async putUser(user: User): Promise<User> {
    const input = {
      TableName: config.DB_NAME_USER,
      Item: user,
    };
    const command = new PutCommand(input);
    await this.docClient.send(command);
    return user;
  }

  async deleteUserById(id: string): Promise<void> {
    const input = {
      TableName: config.DB_NAME_USER,
      Key: {
        id,
      },
    };
    const command = new DeleteCommand(input);
    await this.docClient.send(command);
  }
}

export default new UserRepository();
