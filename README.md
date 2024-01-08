# flux-ephemeral-env
Proof of technology for ephemeral environments with Flux

# Setup
Following tools are required for this setup to work:
- [Task](https://taskfile.dev/)
- [k3d](https://k3d.io/v5.6.0/)
- [Flux CLI](https://fluxcd.io/flux/cmd/)

The first step is to fork and clone this repository.

Once done, run the following command to create a local k3d cluster:
```sh
task k3d-create
```
This command uses the manifest stored in `k3d/config.yaml`

Next, bootstrap Flux on your cluster with:
```sh
flux bootstrap git --url=ssh://git@github.com/<GIT USERNAME>/flux-ephemeral-env \
--path=k8s/ --branch=main --author-email=<AUTHOR EMAIL> \
--components-extra="image-reflector-controller,image-automation-controller"
```

> Note: This command prints out the deploy key to the terminal and waits for you to add it to your git respository. Instructions on how to add a deploy key can be found [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#set-up-deploy-keys).

After bootstrapping flux, you'll need to add the sync mechanisms to the cluster by -
```sh
kubectl apply -f k8s/app/overlays/main/sync.yaml
kubectl apply -f k8s/app/overlays/ephemeral-instances/sync.yaml
```

The first command adds the "production" instance of the application to the cluster. The second command tells flux to watch for any manifests in the `k8s/app/overlays/ephemeral-instance` directory.

For workflows stored in `.github/workflows/` to work, you'll need to give github actions write permissions to the repository. This can be done by navigating to your repository **Settings**, selecting **Actions** > **General** from the sidebar and click on `Read and write permissions` under `Workflow permissions` section. 

Now, you can submit a pull request against your repo and add a `/deploy-ephemeral` comment to add flux manifests that will deploy your application in a new namespace as per the configuration in `k8s/app/overlays/ephemeral/`. 

# How it works?
Whenever a user adds the `/deploy-ephemeral` comment to a pull request, the `create-ephemeral` workflow gets triggered. This workflow commits Flux manifests that contain a `GitRepository` resource pointing to the pull request branch, and a `Kustomization` resource pointing to the `k8s/app/overlays/ephemeral/` configuration. See `scripts/create-env.sh` for full spec. The workflow commits these manifests in a single YAML file with the `sync-<BRANCH_NAME>.yaml` naming convention to the `k8s/app/overlays/ephemeral-instance` directory to the `main` branch.

Flux watches this directory as per the configuration defined in `k8s/app/overlays/ephemeral-instances/sync.yaml` and reconciles the newly committed manifests to the cluster. Once reconciled, a new namespace with the pull request branch name is created and the application is deployed in it.

A similar strategy is followed by the `destroy-ephemeral` github workflow which deleted the manifests pertaining to the pull request. It gets triggered on the `/destroy-ephemeral` comment or when the pull request is closed / merged.
