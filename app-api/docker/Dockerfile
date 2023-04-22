FROM node:18-slim

# Create app directory
WORKDIR /app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
ADD app-api/package*.json ./

RUN npm install

ENV PORT 3000

# Bundle app source
ADD app-api .

ENTRYPOINT [ "npm", "run", "start" ]