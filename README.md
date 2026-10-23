# olca-ipc-container

This repository contains an example for packaging an openLCA v2 IPC server in a Docker container. This is done in a multi-stage build where the final image only contains the necessary resources to run the server. To build the image, just run:

```bash
cd olca-ipc-container
docker build -t olca-ipc-server .
```

This will package the IPC server and native calculation libraries in an image tagged as `olca-ipc-server`. The following example will start a container from that image:

```bash
docker run \
  -p 3000:8080 \
  -v $HOME/openLCA-data-1.4:/app/data \
  --rm -d olca-ipc-server \
  -db example --readonly
```

This will start the server in the container at port `8080` using `/app/data` as data folder. The data folder is mapped to the default openLCA workspace in the example and the port to `3000` of the host. More options can be passed in to the container after the image name (`olca-ipc-server`). In the example, the database is set to `example` (so `~/openLCA-data-1.4/databases/example` would be the full path of the database) and the server is run in `readonly` mode.

The server implements the JSON-RPC protocol of the openLCA API (see https://greendelta.github.io/openLCA-ApiDoc/ipc/). Here is an example `curl` command to list the product systems via the API:

```bash
curl -d '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "data/get/descriptors",
  "params": { "@type": "ProductSystem" }}'\
  -H "Content-Type: application/json"\
  -X POST http://localhost:3000
```

## Release procedure
To deploy a new version of the microservice in the production environment, follow these steps:

1. Confirm that all modifications have been merged into the main branch.
2. Go to the "Releases" section and click on "Draft a new release".
3. In the "Choose a tag" interface, generate a new tag conforming to the semantic versioning convention (vMAJOR.MINOR.PATCH).
4. Publish the release and await the completion of the CI/CD process.

## CI/CD workflows

The workflows follow `idener/generic-repo-template` and run on `idener-runners`.
The container image is `registry.idener.ai/terasun/openlca`.

- **Code Analysis**: lints changed files in pull requests to `main`; manual runs
  lint the full codebase.
- **Create Issue Branch**: creates a branch when an issue is assigned, using
  `.github/issue-branch.yml`.
- **Draft Release**: updates the release draft on pushes to `main` and labels pull
  requests using `.github/release-drafter.yml`.
- **Image deployment** (`deployment.yaml`): publishes a semantic version tag
  (e.g. `1.2.3`) when a release is published. Manual execution and image
  tagging follow the generic repository template.
- **Image deployment on development environment** (`deployment-dev.yaml`): run
  manually from Actions, selecting the branch to build. Publishes `latest` and
  `sha-<short-commit>` tags.

The image workflows build and publish containers; Kubernetes rollouts are managed
separately.

Required Actions secrets: `REGISTRY_USERNAME` and `REGISTRY_PASSWORD`.
Both image workflows also need `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`
to pull the Docker Hardened Images from `dhi.io`, using the same base images for
development and releases.

The runner must support `actions/checkout@v6` (Actions Runner 2.329.0 or newer
for authenticated Git operations from container actions) and Docker/Buildx.
