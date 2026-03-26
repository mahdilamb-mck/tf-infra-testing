openapi: "3.0.0"
info:
  title: Example API
  version: "1.0.0"
paths:
  /:
    get:
      operationId: root
      responses:
        "200":
          description: OK
security:
  - google_id_token: []
components:
  securitySchemes:
    google_id_token:
      type: openIdConnect
      openIdConnectUrl: "https://accounts.google.com/.well-known/openid-configuration"
      x-google-auth:
        issuer: "https://accounts.google.com"
        jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
        audiences:
          - "${gateway_audience}"
          - 32555940559.apps.googleusercontent.com
        jwtLocations:
        - header: Authorization
          valuePrefix: 'Bearer '
        - header: Authorization
          valuePrefix: 'bearer '
        - header: Authorization
          valuePrefix: 'BEARER '
servers:
- url: ${gateway_audience}
  x-google-endpoint:
    allowCors: true
x-google-api-management:
  backends:
    cloudrun_backend:
      address: ${cloud_run_url}
      deadline: 30.0
      path_translation: APPEND_PATH_TO_ADDRESS
      protocol: http/1.1
x-google-backend: cloudrun_backend
