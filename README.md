# Radius Community Recipes

This repository contains commonly used [Recipe](https://docs.radapp.io/guides/recipes/overview/) templates for Radius Environments.

## Recipes

Recipes provide self-service infrastructure provisioning for developers. Developers select the resource(s) they need, and operators can configure Recipes with secure, approved, infrastructure. For more information about the supported resource types and the IaC languages, please refer to the [Recipes overview](https://docs.radapp.io/guides/recipes/overview/) page.

## Repository Structure

Recipes in this repository are organized by the environments and the resource types they support. Below is the structure:

        - <environment> eg : aws
          - <resourcetype.bicep> eg : rediscaches.bicep
          - <resourcetype> eg : rediscaches
             - <main.tf>
             - <variables.tf>

All the available Recipes can be found in the folders below:

  - [Local Dev](/local-dev) 
  - [Azure](/azure)
  - [AWS](/aws) 

## Versioning and Tags

Recipes are versioned using [semantic versioning](https://semver.org/). Main builds publish `edge`, never `latest`. Release builds publish the full version first; after publication and provenance attestation succeed, the publisher promotes the matching major/minor channel and `latest` by digest. `latest` identifies the newest stable version, not main. RCs and other prereleases do not move stable aliases. For example, Radius v0.21 uses the `0.21` tag for each Recipe:

```
ghcr.io/radius-project/recipes/azure/rediscaches:0.21
```

### Patching

Patched versions of Recipes are tagged with the patch number, e.g. `0.21.1`. The `0.21` channel advances to that verified digest only when no newer full version exists in the same channel. `latest` advances only when no newer stable full version exists in the repository, so an older-line patch cannot replace it. Retain full-version tags: they are also the rollback-prevention history. If a newer version was staged but publication failed, finish that run rather than promote an older version over it. It is recommended to use the minor tag when consuming Recipes, e.g. `0.21`.

Source-commit tags let retries and later builds of the same commit reuse its compiled bytes. A release tagged on an already built commit, such as its last RC, therefore attests and promotes those bytes. A full-version tag with a different digest fails instead of being overwritten. The workflow serializes publication across main, release tags, and retries. Before switching an existing installation from main-owned `latest`, use `edge` for development; stable consumers may keep `latest`. Updating the workflow does not rewrite existing registry tags, and historical workflow reruns must not be used to restore the old alias behavior.

### Provenance

Recipes published from a release tag carry signed SLSA build provenance. Builds from `main` are not attested. To verify a released Recipe, use its full version tag:

```bash
gh attestation verify oci://ghcr.io/radius-project/recipes/azure/rediscaches:<version> \
  --repo radius-project/recipes \
  --signer-workflow radius-project/recipes/.github/workflows/publish-recipes.yaml \
  --source-ref refs/tags/v<version>
```

Run the publication regressions without credentials or a cluster using `bash .github/scripts/tests/test-recipe-publication.sh` with Bash and jq. The version parser and the test harness require no Python. The test workflow runs the same suite on pull requests.

## Usage

To use a community recipe from this repo, simply use [`rad recipe register`](https://docs.radapp.io/reference/cli/rad_recipe_register) with the Recipe's template path, or update your environment's Bicep definition with the Recipe:

### CLI

```bash
rad recipe register azure \
  --environment myenv \
  --template-kind bicep \ 
  --template-path "ghcr.io/radius-project/recipes/azure/rediscaches:TAG" \
  --resource-type "Applications.Datastores/redisCaches"
```

### Bicep

```bicep
extension radius 

resource myenv 'Applications.Core/environments' = {
  name: 'myenv'
  properties: {
    compute: {...}
    recipes: {
      'Applications.Core/redisCaches': {
        'azure': {
          template-kind: 'bicep'
          template-path: 'ghcr.io/radius-project/recipes/azure/rediscaches:0.21'
        }
      }
    }
  }
}
```

For more information on using Recipes refer to the [Radius docs](https://docs.radapp.io/guides/recipes/overview/).

## How to Contribute to Recipes

Visit the [contributions guide](CONTRIBUTING.md) to learn how to write your own Recipes and contribute to the community.

## Code of Conduct

Please refer to our [Radius Community Code of Conduct](https://github.com/radius-project/radius/blob/main/CODE_OF_CONDUCT.md)
