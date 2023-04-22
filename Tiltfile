# -*- mode: Python -*

# Helm Values

helmValues = read_yaml('./helm/values.yaml')
appApiServicePort = int(helmValues['app']['api']['service']['port'])
appApiContainerPort = int(helmValues['app']['api']['container']['port'])
appWebServicePort = int(helmValues['app']['web']['service']['port'])
appWebContainerPort = int(helmValues['app']['web']['container']['port'])

# Docker

docker_build('app-api', '.',
  dockerfile='./app-api/docker/Dockerfile',
  ignore=['Tiltfile', '.vscode'],
  entrypoint='npm run start:dev',
  live_update=[
    sync('./app-api', '/app'),
    run('cd /app && npm install', trigger=[
      './app-api/package.json', './app-api/package-lock.json'
    ])
  ]
)

docker_build('app-web', '.',
  dockerfile='./app-web/docker/Dockerfile',
  ignore=['Tiltfile', '.vscode'],
  live_update=[
    sync('./app-web/src', '/usr/share/nginx/html')
  ]
)

# Kubernetes

k8s_yaml(helm('helm', name='app'))

k8s_resource('app-api',
  port_forwards=[
    port_forward(appApiServicePort, appApiContainerPort)
  ],
  labels=['App']
)

k8s_resource('app-web',
  port_forwards=[
    port_forward(appWebServicePort, appWebContainerPort)
  ],
  labels=['App']
)

k8s_resource('dynamodb',
  port_forwards=[
    port_forward(8000, 8000)
  ],
  labels=['Database']
)

k8s_resource('dynamodb-admin',
  port_forwards=[
    port_forward(8001, 8001)
  ],
  resource_deps=['dynamodb'],
  labels=['Database']
)

# Local

local_resource('dynamodb-table-setup',
  cmd='export AWS_REGION=us-east-1 && export AWS_ACCESS_KEY_ID=key && export AWS_SECRET_ACCESS_KEY=key && \
    aws dynamodb create-table \
    --table-name app-user-local \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url http://localhost:8000 || true',
  resource_deps=['dynamodb'],
  labels=['Job']
)

local_resource('dynamodb-data-setup',
  cmd='export AWS_REGION=us-east-1 && export AWS_ACCESS_KEY_ID=key && export AWS_SECRET_ACCESS_KEY=key && \
    aws dynamodb put-item \
    --table-name app-user-local \
    --item \'{"id":{"S":"1"},"email":{"S":"sjobs@apple.com"},"firstName":{"S":"Steve"},"lastName":{"S":"Jobs"}}\' \
    --endpoint-url http://localhost:8000 || true && \
    aws dynamodb put-item \
    --table-name app-user-local \
    --item \'{"id":{"S":"2"},"email":{"S":"bgates@microsoft.com"},"firstName":{"S":"Bill"},"lastName":{"S":"Gates"}}\' \
    --endpoint-url http://localhost:8000 || true && \
    aws dynamodb put-item \
    --table-name app-user-local \
    --item \'{"id":{"S":"3"},"email":{"S":"lpage@google.com"},"firstName":{"S":"Larry"},"lastName":{"S":"Page"}}\' \
    --endpoint-url http://localhost:8000 || true',
  resource_deps=[
    'dynamodb-table-setup'
  ],
  labels=['Job']
)