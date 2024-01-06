#!/bin/bash

set -feuo pipefail

BRANCH=$1

cat <<EOF > ./k8s/app/overlays/ephemeral-instances/sync-$BRANCH.yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: ephemeral-$BRANCH
  namespace: flux-system
spec:
  interval: 1m0s
  ref:
    branch: $BRANCH
  secretRef:
    name: flux-system
  url: ssh://git@github.com/vedantthapa/flux-ephemeral-env
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: ephemeral-$BRANCH
  namespace: flux-system
spec:
  interval: 1m0s
  path: ./k8s/app/overlays/ephemeral/
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  postBuild:
    substitute:
      BRANCH_NAME: $BRANCH
EOF

