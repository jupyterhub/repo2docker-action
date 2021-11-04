# Making a release

Releases are automated through
[.github/workflows/release-updates.yaml](https://github.com/jupyterhub/repo2docker-action/blob/HEAD/.github/workflows/release-updates.yaml).

To cut a release, visit the projects [releases
page](https://github.com/jupyterhub/repo2docker-action/releases) where
you create a new GitHub release. Enter a _tag name_ and _release name_ of
"vX.Y.Z". Doing so will automatically update the "vX" branch allowing users to
reference this action with `jupyterhub/repo2docker-action@vX`.

If you are to cut a major release, make sure to also update references to the
`@vX` branch to the `@vX+1` branch.
