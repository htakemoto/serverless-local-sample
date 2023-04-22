/**
 * HttpException is used to throw as an exception
 * which API gateway can manage as a proper response to the client.
 * (i.e. throw new HttpException('Bad Request', 400))
 */
export default class HttpException {
  statusCode: number;
  message: string;
  /**
   * It takes a message and a status code, and returns an object
   * with a statusCode, headers, and body.
   * @param {string} message - The error message that will be returned to the client.
   * @param {number} statusCode - The HTTP status code of the response.
   */
  constructor(message = 'Internal Server Error', statusCode = 500) {
    this.statusCode = statusCode;
    this.message = message;
  }
}
