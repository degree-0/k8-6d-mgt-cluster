# External Configurations

This folder contains configurations related to external dependencies and infrastructure-specific settings for the Kubernetes cluster. These configurations are decoupled from the application-specific manifests to improve modularity and portability.

## Purpose

- To manage provider-specific settings, such as external load balancers and DNS configurations.
- To isolate external infrastructure details from application deployments, making the cluster setup more maintainable and reusable.

## Files

### `external-lb.yaml`

- **Purpose**: Stores the external IP address configuration for the Linode Node Balancer.
- **Details**:
  - The `ConfigMap` in this file contains the external IP (`143.42.223.153`) used by the cluster's ingress.
  - This external IP is referenced in application deployments and ingress configurations for services like Rancher.

## Usage

1. Apply the `ConfigMap` to your cluster:

   ```bash
   kubectl apply -f external-lb.yaml
