# Serverless Local Setup Sample

This project demonstrate how to set up a local dev environment considering the following serverless components

- API Gateway
- Lambda
- DynamoDB

## Local Environment Setup

### Prerequisites

- Docker ([Docker Desktop](https://www.docker.com/) or [Rancher Desktop](https://rancherdesktop.io)
- [Tilt](https://tilt.dev/)
- [AWS CLI](https://aws.amazon.com/cli/)

### Run App

```bash
tilt up
```

**Frontend**

```bash
open http://localhost:8080
```

**Backend**

```bash
curl http://localhost:3000/users
curl http://localhost:3000/users/1
```

**Database**

```bash
open http://localhost:8000
```

## Deploy Serverless Components to AWS

```bash
cd terraform
terraform init
terraform workspace new dev
# terraform workspace select dev
terraform apply
```

Note: UI is not included in AWS Deployment
