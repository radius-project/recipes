## Contributing to Radius Recipes

This section describes the guidelines for contributing code / docs to Radius Recipes.

### How to write your first recipe

To write your first recipe, follow the steps below:

1. Familiarize yourself with the IaC language of your choice [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) or [Terraform](https://developer.hashicorp.com/terraform)
1. Familiarize yourself with the Radius [Recipe](https://docs.radapp.io/recipes) concept
1. Familiarize yourself with the [supported resource types](https://docs.radapp.io/guides/recipes/overview/#supported-resources) to write recipes for.
1. Review the existing recipes in this repository to understand the structure and best practices
1. Follow this [how-to guide](https://docs.radapp.io/guides/recipes/howto-author-recipes/) to write your first recipe, register your recipe in the environment.
1. Test the custom recipe in your application 

### How to add a new recipe to this repository

To add a recipe to this repository, follow the steps below:

1. Make sure there's an issue (bug or feature) raised, which sets the expectations for the contribution you are about to make.
1. Fork the repository and create a new branch
1. Add the recipe to the relevant directory
    1. If the recipe is for local dev, add the recipe to the `local-dev` directory
    1. If the recipe is for Azure, add the recipe to the `azure` directory
    1. If the recipe is for AWS, add the recipe to the `aws` directory
    1. If its a terraform recipe, create a `terraform` directory under the relevant environment and add the recipe (e.g. `azure/terraform/redis.tf`) 
1. Update the README.md with the new recipe
1. Commit and open a PR
1. Wait for the CI process to finish and make sure all checks are green
1. A maintainer of the repo will be assigned, and you can expect a review within a few days

All contributions come through pull requests. To submit a proposed change, we recommend following this workflow:

#### Use work-in-progress PRs for early feedback

A good way to communicate before investing too much time is to create a draft PR and share it with your reviewers. The standard way of doing this is to mark your PR as draft within GitHub.