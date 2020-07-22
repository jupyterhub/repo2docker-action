# Contributing Guide

## Project Jupyter Contributing Guidelines

This project is also governed by the [Project Jupyter Contributing Guidelines](https://jupyter.readthedocs.io/en/latest/contributing/content-contributor.html).  In the case of any conflicts between what is written here and the Jupyter Contributing Guidelines the Jupyter guidelines will control.

_shamlessly borrowed many of these guidelines from [repo2docker](https://repo2docker.readthedocs.io/en/latest/contributing/contributing.html#types-of-contribution)_

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Process for making a contribution](#process-for-making-a-contribution)
- [Guidelines to getting a Pull Request merged](#guidelines-to-getting-a-pull-request-merged)
- [Setting up for Local Development](#setting-up-for-local-development)
- [Resources For Getting Started With Actions](#resources-for-getting-started-with-actions)

<!-- /TOC -->

# Process for making a contribution

- Update the documentation. If you’re reading a page or docstring and it doesn’t make sense (or doesn’t exist!), please let us know by opening a bug report. It’s even more amazing if you can give us a suggested change.

- Fix bugs or add requested features. Have a look through the issue tracker and see if there are any tagged as “help wanted”. As the label suggests, we’d love your help!

- Report a bug. If repo2docker-action isn’t doing what you thought it would do then open a bug report. That issue template will ask you a few questions described in more detail below.

- Suggest a new feature. We know that there are lots of ways to extend the repo2docker-action! If you’re interested in adding a feature then please open a feature request. That issue template will ask you a few questions described in detail below.

- Review someone’s Pull Request. Whenever somebody proposes changes to the repo2docker-action codebase, the community reviews the changes, and provides feedback, edits, and suggestions. Check out the open pull requests and provide feedback that helps improve the PR and get it merged. Please keep your feedback positive and constructive!

- Tell people about the repo2docker-action. As we said above, repo2docker-action is built by and for its community. If you know anyone who would like to use repo2docker-action, please tell them about the project! You could give a talk about it, or run a demonstration.

# Process for making a contribution

This outlines the process for getting changes to the repo2docker-action project merged.

1. Identify the correct issue template: bug report or feature request.

    Bug reports (examples, new issue) will ask you for a description of the problem, the expected behaviour, the actual behaviour, how to reproduce the problem, and your personal set up. Bugs can include problems with the documentation, or code not running as expected.

    It is really important that you make it easy for the maintainers to reproduce the problem you’re having. This guide on creating a minimal, complete and verifiable example is a great place to start.

    Feature requests (examples, new issue) will ask you for the proposed change, any alternatives that you have considered, a description of who would use this feature, and a best-guess of how much work it will take and what skills are required to accomplish.

    Very easy feature requests might be updates to the documentation to clarify steps for new users. Harder feature requests may be to add new functionality to the project and will need more in depth discussion about who can complete and maintain the work.

    Feature requests are a great opportunity for you to advocate for the use case you’re suggesting. They help others understand how much effort it would be to integrate the work,and - if you’re successful at convincing them that this effort is worth it - make it more likely that they to choose to work on it with you.

2. Open an issue. Getting consensus with the community is a great way to save time later.

3. Make edits in your fork of the repo2docker-action repository.

4. Make a pull request. Read the next section for guidelines for both reviewers and contributors on merging a PR.

5. Edit the changelog by appending your feature / bug fix to the development version.

5. Wait for a community member to merge your changes. Remember that someone else must merge your pull request. That goes for new contributors and long term maintainers alike.


# Guidelines to getting a Pull Request merged

These are suggestions to help complete your contribution as smoothly as possible.

- Create a PR as early as possible, marking it with [WIP] while you work on it. This avoids duplicated work, lets you get high level feedback on functionality or API changes, and/or helps find collaborators to work with you.

- Keep your PR focused. The best PRs solve one problem. If you end up changing multiple things, please open separate PRs for the different conceptual changes.

- Add tests to your code. PRs will not be merged if Travis is failing.

- Use merge commits instead of merge-by-squashing/-rebasing. This makes it easier to find all changes since the last deployment git log --merges --pretty=format:"%h %<(10,trunc)%an %<(15)%ar %s" <deployed-revision>.. and your PR easier to review.

- Make it clear when your PR is ready for review. Prefix the title of your pull request (PR) with [MRG] if the contribution is complete and should be subjected to a detailed review.

- Use commit messages to describe why you are proposing the changes you are proposing.

Try to not rush changes (the definition of rush depends on how big your changes are). Remember that everyone in the repo2docker-action team is a volunteer and we can not (nor would we want to) control their time or interests. Wait patiently for a reviewer to merge the PR. (Remember that someone else must merge your PR, even if you have the admin rights to do so.)

# Setting up for Local Development

To develop & test repo2docker-action locally, you need:

1. Familiarity with using a command line terminal
2. Familiary with [GitHub Actions](https://docs.github.com/en/actions)
2. A computer running macOS / Linux
3. Some knowledge of git
4. A recent version of Docker Community Edition, and familiarity with Docker

You can run the Action locally by editing and running [bootstrap.sh](./bootstrap.sh).  You will have to change and set environment variables to supply the various inputs to this Action.  Note that the various input parameters described in the [API Reference Section of the README](https://github.com/machine-learning-apps/repo2docker-action#api-reference), must be prepended by `INPUT_` as an environment variable for the local docker container.  For example, to supply the input `NOTEBOOK_USER` you would pass the environment variable `INPUT_NOTEBOOK_USER` as an environment variable into the container at runtime.  This is to emulate what happens in GitHub Actions.

Per the [Actions docs](https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions#inputs):

> When you specify an input to an action in a workflow file or use a default input value, GitHub creates an environment variable for the input with the name INPUT_<VARIABLE_NAME>. The environment variable created converts input names to uppercase letters and replaces spaces with _ characters.

Finally, you cannot completely replicate GitHub Actions locally and it might be helpful to interactively debug Actions in the context that are created and run.  Forking the repo and using [this debugging action](https://github.com/marketplace/actions/debugging-with-tmate) can be very useful for this purposes.

# Resources For Getting Started With GitHub Actions

- [Creating GitHub Actions - Official Documentation](https://docs.github.com/en/actions/creating-actions)
- [Live Demo: Actions For Data Science](https://youtu.be/S-kn4mmlxFU)
- [Blog Post re:Actions For Data Scientists](https://fastpages.fast.ai/actions/markdown/2020/03/06/fastpages-actions.html)
