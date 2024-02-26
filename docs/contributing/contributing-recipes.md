## Contributing to Radius Recipes

This section describes the guidelines for contributing code / docs to Radius Recipes. Contribution can be in the form of adding new recipes for the supported resource types and IaC languages, improving existing recipes or the documentation.

### 1. How to write your first recipe

To write your first recipe, follow the steps below:

1. Familiarize yourself with the IaC language of your choice [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) or [Terraform](https://developer.hashicorp.com/terraform)
1. Familiarize yourself with the Radius [Recipe](https://docs.radapp.io/recipes) concept
1. Familiarize yourself with the [supported resource types](https://docs.radapp.io/guides/recipes/overview/#supported-resources) to write recipes for.
1. Review the existing recipes in this repository to understand the structure and best practices
1. Follow this [how-to guide](https://docs.radapp.io/guides/recipes/howto-author-recipes/) to write your first recipe, register your recipe in the environment.

### 2. How to test the recipe locally

>[!Note]
>Since we do not have an automated testing framework for recipes and is in our [backlog](https://github.com/radius-project/recipes/issues/62), we recommend testing the recipe locally in your environment before contributing it to the repository. 

To test the recipe locally, follow the steps below:

1. Publish the recipe to a Registry

    For Bicep, Recipes leverage [Bicep registries](https://learn.microsoft.com/azure/azure-resource-manager/bicep/private-module-registry) for template storage. Once you've authored a Recipe, you can publish it to your preferred OCI-compliant registry with [`rad bicep publish`](https://docs.radapp.io/reference/cli/rad_bicep_publish/).:

    - Make sure you have the right permissions to push to the registry. Owner or Contributor    alone won't allow you to push.

    - Make sure to login to your registry before publishing the recipe. Eg:

        ```bash
        az acr login --name <registryname>
        ``` 

    - Publish the recipe to the registry

        ```bash
        rad bicep publish --file myrecipe.bicep --target br:<registrypath>/myrecipe:1.1.0
        ```

    - Follow the [Terraform module publishing docs](https://developer.hashicorp.com/terraform/registry/modules/publish) to setup and publish a Terraform module to a Terraform registry.

1. Register the recipe in your environment using the `rad recipe register` command

    **Bicep Recipe via rad CLI**
    ```bash
    rad recipe register myrecipe --environment myenv --resource-type Applications.Datastores/redisCaches --template-kind bicep --template-path ghcr.io/USERNAME/recipes/myrecipe:1.1.0
    ```

    **Terraform recipe via rad CLI**
    ```bash
    rad recipe register myrecipe --environment myenv --resource-type Applications.Datastores/redisCaches --template-kind terraform --template-path user/recipes/myrecipe --template-version "1.1.0"
    ```

    **Via Radius environment bicep**
    ```bicep
    import radius as radius
    resource env 'Applications.Core/environments@2023-10-01-preview' = {
        name: 'prod'
        properties: {
            compute: {
                kind: 'kubernetes'
                resourceId: 'self'
                namespace: 'default'
            }
            recipes: {
                'Applications.Datastores/redisCaches':{
                    'redis-bicep': {
                        templateKind: 'bicep'
                        templatePath: 'https://ghcr.io/USERNAME/recipes/myrecipe:1.1.0'
                        // Optionally set parameters for all resources calling this Recipe
                        parameters: {
                            port: 3000
                        }
                    }
                    'redis-terraform': {
                        templateKind: 'terraform'
                        templatePath: 'user/recipes/myrecipe'
                        templateVersion: '1.1.0'
                        // Optionally set parameters for all resources calling this Recipe
                        parameters: {
                            port: 3000
                        }
                    }
                }   
            }
        }
    }
    ```

1. Use the recipe in your application and verify that it works as expected
    ```bicep
    resource redis 'Applications.Datastores/redisCaches@2023-10-01-preview'= {
        name: 'myresource'
        properties: {
            environment: environment
            application: application
            recipe: {
                name: 'myrecipe'
             }
        }
    }
    ``` 
    
### 3. How to add a new recipe to this repository

After you have tested the recipe in an application, you can follow the steps below to add the recipe to the repository:

1. Make sure there's an issue (bug or feature) raised, which sets the expectations for the contribution you are about to make.
1. Fork the repository and create a new branch
1. Add the recipe to the relevant directory following the [repository structure](./recipes/README.MD#repository-structure)
1. Update the README.md with the new recipe
1. Commit and open a PR
1. Wait for the CI process to finish and make sure all checks are green
1. A maintainer of the repo will be assigned, and you can expect a review within a few days

All contributions come through pull requests. To submit a proposed change, we recommend following this workflow:

#### Use work-in-progress PRs for early feedback

A good way to communicate before investing too much time is to create a draft PR and share it with your reviewers. The standard way of doing this is to mark your PR as draft within GitHub.