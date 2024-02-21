## Contributing to Issues

This section describes the guidelines for submitting issues

### Issue Types

There are 2 types of issues:

- bug: You've found a bug with the code, and want to report it, or create an issue to track the bug.
- feature: Used for items that propose a new idea or functionality. This allows feedback from others before code is written.

> For questions or feedback please refer to the [Radius Community docs](https://docs.radapp.dev/community/). Discord will be the best way to get in touch with the community and the maintainers.

### Before You File

Before you file an issue, make sure you've checked the following:

1. Is it the right repository?
    - The Radius project is distributed across multiple repositories. Check the list of [repositories](https://github.com/radius-project) if you aren't sure which repo is the correct one.
1. Check for existing issues
    - Before you create a new issue, please do a search in [open issues](https://github.com/radius-project/recipes/issues) to see if the issue or feature request has already been filed.
    - If you find your issue already exists, make relevant comments and add your [reaction](https://github.com/blog/2119-add-reaction-to-pull-requests-issues-and-comments). Use a reaction:
        - 👍 up-vote
        - 👎 down-vote
1. For bugs
    - Check it's not an environment issue. For example, if running on Kubernetes, make sure prerequisites are in place.
    - Ensure you have as much data as possible. This usually comes in the form of logs and/or stacktrace. If running on Kubernetes or other environment, look at the logs of the Radius services (UCP, RP, DE). More details on how to get logs can be found [here](https://docs.radapp.dev/reference/troubleshooting-radius/).
1. For proposals
    - Many changes to the Radius runtime may require changes to the API. In that case, the best place to discuss the potential feature is the main [Radius repo](https://github.com/radius-project/radius).
    - Recipes runtime changes can be discussed in the [Radius repo](https://github.com/radius-project/radius).
    - Community Recipes can be discussed within [this repo](https://github.com/radius-project/recipes/issues).