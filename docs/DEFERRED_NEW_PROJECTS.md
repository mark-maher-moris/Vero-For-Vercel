# Deferred New Project Creation

## Status

The "Import GitHub Project" / new Vercel project creation feature is hidden from the app for now.

## What Was Hidden

The dashboard action button that opened `ImportGithubProjectScreen` was removed from `lib/screens/dashboard_screen.dart`.

The underlying screen and API methods are still present:

- `lib/screens/import_github_project_screen.dart`
- `lib/services/api_service.dart` `createProject(...)`
- `lib/services/api_service.dart` `createDeployment(...)`

## Why It Is Deferred

The current UI says "Import & Deploy", but the flow only creates/imports a Vercel project. It does not explicitly create a deployment after import, so the user-facing promise is stronger than the implemented behavior.

There are also product and API edge cases to handle before exposing this on mobile:

- GitHub repository permissions and Vercel Git integration access.
- Team/member permissions for creating projects.
- Private repositories.
- Monorepo root directory selection and validation.
- Environment variables required before the first successful deploy.
- Clear project creation vs deployment status messaging.

## Recommended Reimplementation

When restoring the feature, make the workflow explicit:

1. Rename the action to "Import GitHub Project" or "Create Project from GitHub".
2. Normalize and validate GitHub repo input, including trailing slashes and `.git` suffixes.
3. Call `createProject(...)` and show project creation progress.
4. Decide whether the app should automatically call `createDeployment(...)`.
5. If deploying automatically, show deployment status and errors before returning to the dashboard.
6. Refresh projects and navigate to the newly created project's workspace.

Only use "Deploy" in the UI if the app actually triggers and tracks a deployment.
