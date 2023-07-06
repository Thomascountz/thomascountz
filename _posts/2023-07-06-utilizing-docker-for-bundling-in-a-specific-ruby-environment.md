---
title: Utilizing Docker for Bundling in a Specific Ruby Environment
subtitle: A Light-weight Workflow
author: Thomas Countz
layout: post
tags: ["ruby"]
---
One of the tasks we often find ourselves completing on Zendesk's Core Ruby Engineering team is helping to keep a variety of projects up to date. This can involve running `bundle update` across dozens of repositories, each potentially requiring a different Ruby environment. Although we've developed tooling to accomplish this rather efficiently, there are often edge cases that require us to work in each repository locally. However, installing so many different versions of Ruby locally can be cumbersome and time-consuming.

In such scenarios, Ruby Docker images provide a lighter weight solution compared to running a project's Dockerfile (which can contain dozens of dependencies) or spinning up our Kubernetes-based development tooling (which gives us access to an entire structured environment of all of Zendesk). Individual Ruby images allow us to run commands like `bundle update` in a specific Ruby environment, such as JRuby, without needing to install that Ruby version locally.

Let's take an example of running `bundle install` in a project that requires JRuby. We'll use JRuby as an example as it's not always as straightforward to install as CRuby.

First (assuming you hav Docker running locally), pull the Docker image from DockerHub for the Ruby version you need.

```shell
docker pull jruby:latest
```

Next, we'll run the `bundle install` command within a Docker container using the JRuby image. If your project uses a private gem repository, you might need to pass in credentials. If you have these credentials stored in an environment variable locally, you can pass that to the Docker container. Docker will use the value from the local environment:

```shell
docker run --rm --volume "$(pwd)":/usr/src/app --workdir /usr/src/app --env PRIVATE_GEM_REPO_CREDS jruby:latest bundle update my_gem --conservative
```

Here's a breakdown of the command:

- `--rm` (`-rm` for short): This option removes the container after it exits.
- `--volume "$(pwd)":/usr/src/app` (`-v` for short): This mounts the current directory (assumed to be your project directory) to `/usr/src/app` in the container.
- `--workdir /usr/src/app` (`-w` for short): This sets the working directory inside the container.
- `--env PRIVATE_GEM_REPO_CREDS` (`-e` for short): This passes the `PRIVATE_GEM_REPO_CREDS` environment variable from your local environment to the Docker container. Replace `PRIVATE_GEM_REPO_CREDS` with your actual environment variable that holds the credentials for your private gem repository.
- `jruby:latest`: This is the Docker image we're using.
- `bundle update my_gem --conservative`: This is the command we're running inside the container. The `--conservative` flag with instruct Bundler to update as few gems as necessary.

This command runs `bundle update` in the context of the Docker container, using your stored credentials for authentication and modifying your local directory. Your `Gemfile.lock` should be modified (if applicable) and any vendor-ized gems will be updated. You can now commit and push the changes.

Docker's flexibility allows us to run `bundle update` in any Ruby environment, including but not limited to JRuby, without local installation, while also handling authentication via environment variables. This approach can be applied to similar scenarios where specific environments are required for package installation. It's a streamlined, efficient alternative to more heavyweight solutions.