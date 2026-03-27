# Example Infrastructure

Terraform configuration for a secure API platform on Google Cloud, serving Vertex AI Discovery Engine (Search) via Cloud Run behind a Global External Application Load Balancer. JWT authentication is handled by an Envoy sidecar proxy.

## Architecture

```mermaid
flowchart TD
    Client([Client])

    subgraph gcp["Google Cloud Platform"]
        subgraph lb["Global External Application Load Balancer"]
            IP[Static IP :80]
            Proxy[HTTP Proxy]
            URLMap[URL Map]
        end

        subgraph security["Cloud Armor"]
            DDoS[Adaptive L7 DDoS Protection]
            RateIP[Per-IP Rate Limiting\n100 req/min]
            RateKey[Per-API-Key Rate Limiting\n500 req/min]
        end

        NEG[Serverless NEG]

        subgraph cloudrun["Cloud Run — Internal Only"]
            Envoy[Envoy Sidecar :8080\nJWT Validation\nGoogle ID Tokens]
            App[Application Container :8081]
            CRSA[cloud-run-sa\nroles/discoveryengine.viewer]
        end

        subgraph vertex["Vertex AI"]
            Search[Discovery Engine\nSearch with LLM]
            DS[Data Store]
        end
    end

    Client -->|HTTP| IP
    IP --> Proxy --> URLMap
    URLMap --> security
    security --> NEG
    NEG --> Envoy
    Envoy -->|Validated requests| App
    CRSA -->|IAM| Search
    Search --> DS
```

## Security

| Requirement | Implementation |
|---|---|
| JWT Authentication | Envoy sidecar validates Google ID tokens via `jwt_authn` filter |
| Rate Limiting | Cloud Armor throttle rules — per-IP (100 req/min) and per-API-key header (500 req/min) |
| DDoS Protection | Cloud Armor adaptive L7 DDoS defense |
| Cloud Run Access | Ingress set to `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER` — not publicly accessible |
| Vertex AI Search Access | Dedicated Cloud Run service account with `roles/discoveryengine.viewer` via IAM |

## Resources

| File | Resources |
|---|---|
| `main.tf` | Project data source |
| `vertex_ai.tf` | Discovery Engine data store, search engine, datastore locals |
| `cloud_run.tf` | Cloud Run service (Envoy sidecar + app), inline Envoy config, service account, IAM bindings |
| `load_balancer.tf` | Static IP, serverless NEG, backend service, URL map, HTTP proxy, forwarding rule |
| `cloud_armor.tf` | Security policy with DDoS protection and rate limiting rules |
| `apis.tf` | GCP API enablement |
| `variables.tf` | Input variables |
| `outputs.tf` | Load balancer IP |

## Variables

| Name | Description | Default |
|---|---|---|
| `project_id` | GCP project ID | — (required) |
| `location` | Discovery Engine location | `eu` |
| `region` | Regional resources (Cloud Run, LB) | `europe-west2` |
| `google_audience` | Expected audience for Google ID tokens | `32555940559.apps.googleusercontent.com` |

## Outputs

| Name | Description |
|---|---|
| `load_balancer_ip` | Static IP address of the load balancer |
