<!-- Source: https://vercel.com/cli -->

# Vercel CLI Overview

Vercel gives you multiple ways to interact with and configure your Vercel Projects. With the command-line interface (CLI) you can interact with the Vercel platform using a terminal, or through an automated system, enabling you toretrieve logs, managecertificates, replicate your deployment environmentlocally, manage Domain Name System (DNS)records, and more.

[retrieve logs](/docs/cli/logs)
[certificates](/docs/cli/certs)
[locally](/docs/cli/dev)
[records](/docs/cli/dns)
If you'd like to interface with the platform programmatically, check out theREST API documentation.

[REST API documentation](/docs/rest-api)
## Installing Vercel CLI

[Installing Vercel CLI](#installing-vercel-cli)
To download and install Vercel CLI, run the following command:

```
pnpm i-g vercel
```

pnpm i-g vercel

## Updating Vercel CLI

[Updating Vercel CLI](#updating-vercel-cli)
When there is a new release of Vercel CLI, running any command will show you a message letting you know that an update is available.

If you have installed our command-line interface throughnpmorYarn, the easiest way to update it is by running the installation command yet again.

[npm](http://npmjs.org/)
[Yarn](https://yarnpkg.com)
```
pnpm i-g vercel@latest
```

pnpm i-g vercel@latest

If you see permission errors, please read npm'sofficial guide. Yarn depends on the same configuration as npm.

[official guide](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally)
## Checking the version

[Checking the version](#checking-the-version)
The--versionoption can be used to verify the version of Vercel CLI currently being used.

```
--version
```

```
vercel--version
```

vercel--version

```
vercel
```

```
--version
```

## Using in a CI/CD environment

[Using in a CI/CD environment](#using-in-a-ci/cd-environment)
Vercel CLI requires you to log in and authenticate before accessing resources or performing administrative tasks. In a terminal environment, you can usevercel login, which requires manual input. In a CI/CD environment where manual input is not possible, you can create a token on yourtokens pageand then use the--tokenoptionto authenticate.

[vercel login](/docs/cli/login)
```
vercel login
```

[tokens page](/account/tokens)
[--tokenoption](/docs/cli/global-options#token)
```
--token
```

## Available Commands

[Available Commands](#available-commands)
### alias

[alias](#alias)
Apply custom domain aliases to your Vercel deployments.

```
vercelaliasset[deployment-url] [custom-domain]vercelaliasrm[custom-domain]vercelaliasls
```

vercelaliasset[deployment-url] [custom-domain]vercelaliasrm[custom-domain]vercelaliasls

Learn more about the alias command

[Learn more about the alias command](/docs/cli/alias)
### api

[api](#api)
Make authenticated HTTP requests to the Vercel API from your terminal. This is a beta command.

```
vercelapi[endpoint]vercelapi/v2/uservercelapi/v9/projects-XPOST-Fname=my-project
```

vercelapi[endpoint]vercelapi/v2/uservercelapi/v9/projects-XPOST-Fname=my-project

Learn more about the api command

[Learn more about the api command](/docs/cli/api)
### bisect

[bisect](#bisect)
Perform a binary search on your deployments to help surface issues.

```
vercelbisectvercelbisect--good[deployment-url] --bad [deployment-url]
```

vercelbisectvercelbisect--good[deployment-url] --bad [deployment-url]

Learn more about the bisect command

[Learn more about the bisect command](/docs/cli/bisect)
### blob

[blob](#blob)
Interact with Vercel Blob storage to upload, download, list, delete, and copy files.

```
vercelbloblistvercelblobput[path-to-file]vercelblobget[url-or-pathname]vercelblobdel[url-or-pathname]vercelblobcopy[from-url] [to-pathname]
```

vercelbloblistvercelblobput[path-to-file]vercelblobget[url-or-pathname]vercelblobdel[url-or-pathname]vercelblobcopy[from-url] [to-pathname]

Learn more about the blob command

[Learn more about the blob command](/docs/cli/blob)
### build

[build](#build)
Build a Vercel Project locally or in your own CI environment.

```
vercelbuildvercelbuild--prod
```

vercelbuildvercelbuild--prod

Learn more about the build command

[Learn more about the build command](/docs/cli/build)
### cache

[cache](#cache)
Manage cache for your project (CDN cache and Data cache).

```
vercelcachepurgevercelcachepurge--typecdnvercelcachepurge--typedatavercelcacheinvalidate--tagfoovercelcachedangerously-delete--tagfoo
```

vercelcachepurgevercelcachepurge--typecdnvercelcachepurge--typedatavercelcacheinvalidate--tagfoovercelcachedangerously-delete--tagfoo

Learn more about the cache command

[Learn more about the cache command](/docs/cli/cache)
### certs

[certs](#certs)
Manage certificates for your domains.

```
vercelcertslsvercelcertsissue[domain]vercelcertsrm[certificate-id]
```

vercelcertslsvercelcertsissue[domain]vercelcertsrm[certificate-id]

Learn more about the certs command

[Learn more about the certs command](/docs/cli/certs)
### curl

[curl](#curl)
Make HTTP requests to your Vercel deployments with automatic deployment protection bypass. This is a beta command.

```
vercelcurl[path]vercelcurl/api/hellovercelcurl/api/data--deployment[deployment-url]
```

vercelcurl[path]vercelcurl/api/hellovercelcurl/api/data--deployment[deployment-url]

Learn more about the curl command

[Learn more about the curl command](/docs/cli/curl)
### deploy

[deploy](#deploy)
Deploy your Vercel projects. Default command when no subcommand is specified.

```
vercelverceldeployverceldeploy--prod
```

vercelverceldeployverceldeploy--prod

Learn more about the deploy command

[Learn more about the deploy command](/docs/cli/deploy)
### dev

[dev](#dev)
Replicate the Vercel deployment environment locally and test your project.

```
verceldevverceldev--port3000
```

verceldevverceldev--port3000

Learn more about the dev command

[Learn more about the dev command](/docs/cli/dev)
### dns

[dns](#dns)
Manage your DNS records for your domains.

```
verceldnsls[domain]verceldnsadd[domain] [name] [type] [value]verceldnsrm[record-id]
```

verceldnsls[domain]verceldnsadd[domain] [name] [type] [value]verceldnsrm[record-id]

Learn more about the dns command

[Learn more about the dns command](/docs/cli/dns)
### domains

[domains](#domains)
Buy, sell, transfer, and manage your domains.

```
verceldomainslsverceldomainsadd[domain] [project]verceldomainsrm[domain]verceldomainsbuy[domain]
```

verceldomainslsverceldomainsadd[domain] [project]verceldomainsrm[domain]verceldomainsbuy[domain]

Learn more about the domains command

[Learn more about the domains command](/docs/cli/domains)
### env

[env](#env)
Manage environment variables in your Vercel Projects.

```
vercelenvlsvercelenvadd[name] [environment]vercelenvupdate[name] [environment]vercelenvrm[name] [environment]vercelenvpull[file]vercelenvrun--<command>
```

vercelenvlsvercelenvadd[name] [environment]vercelenvupdate[name] [environment]vercelenvrm[name] [environment]vercelenvpull[file]vercelenvrun--<command>

Learn more about the env command

[Learn more about the env command](/docs/cli/env)
### flags

[flags](#flags)
Manage feature flags for your Vercel Project.

```
vercelflagslistvercelflagscreate[slug]vercelflagsset[flag] --environment [environment] --variant [variant]vercelflagsopen[flag]
```

vercelflagslistvercelflagscreate[slug]vercelflagsset[flag] --environment [environment] --variant [variant]vercelflagsopen[flag]

Learn more about the flags command

[Learn more about the flags command](/docs/cli/flags)
### git

[git](#git)
Manage your Git provider connections.

```
vercelgitlsvercelgitconnectvercelgitdisconnect[provider]
```

vercelgitlsvercelgitconnectvercelgitdisconnect[provider]

Learn more about the git command

[Learn more about the git command](/docs/cli/git)
### guidance

[guidance](#guidance)
Enable or disable guidance messages shown after CLI commands.

```
vercelguidanceenablevercelguidancedisablevercelguidancestatus
```

vercelguidanceenablevercelguidancedisablevercelguidancestatus

Learn more about the guidance command

[Learn more about the guidance command](/docs/cli/guidance)
### help

[help](#help)
Get information about all available Vercel CLI commands.

```
vercelhelpvercelhelp[command]
```

vercelhelpvercelhelp[command]

Learn more about the help command

[Learn more about the help command](/docs/cli/help)
### httpstat

[httpstat](#httpstat)
Visualize HTTP request timing statistics for your Vercel deployments with automatic deployment protection bypass.

```
vercelhttpstat[path]vercelhttpstat/api/hellovercelhttpstat/api/data--deployment[deployment-url]
```

vercelhttpstat[path]vercelhttpstat/api/hellovercelhttpstat/api/data--deployment[deployment-url]

Learn more about the httpstat command

[Learn more about the httpstat command](/docs/cli/httpstat)
### init

[init](#init)
Initialize example Vercel Projects locally from the examples repository.

```
vercelinitvercelinit[project-name]
```

vercelinitvercelinit[project-name]

Learn more about the init command

[Learn more about the init command](/docs/cli/init)
### inspect

[inspect](#inspect)
Retrieve information about your Vercel deployments.

```
vercelinspect[deployment-id-or-url]vercelinspect[deployment-id-or-url] --logsvercelinspect[deployment-id-or-url] --wait
```

vercelinspect[deployment-id-or-url]vercelinspect[deployment-id-or-url] --logsvercelinspect[deployment-id-or-url] --wait

Learn more about the inspect command

[Learn more about the inspect command](/docs/cli/inspect)
### install

[install](#install)
Install a marketplace integration and provision a resource. Alias forvercel integration add.

```
vercel integration add
```

```
vercelinstall<integration-name>
```

vercelinstall<integration-name>

Learn more about the install command

[Learn more about the install command](/docs/cli/install)
### integration

[integration](#integration)
Manage marketplace integrations: provision resources, discover available integrations, view setup guides, check balances, and more.

```
vercelintegrationadd<integration-name>vercelintegrationlist[project-name]vercelintegrationdiscoververcelintegrationguide<integration-name>vercelintegrationbalance<integration-name>vercelintegrationopen<integration-name>[resource-name]vercelintegrationremove<integration-name>
```

vercelintegrationadd<integration-name>vercelintegrationlist[project-name]vercelintegrationdiscoververcelintegrationguide<integration-name>vercelintegrationbalance<integration-name>vercelintegrationopen<integration-name>[resource-name]vercelintegrationremove<integration-name>

Learn more about the integration command

[Learn more about the integration command](/docs/cli/integration)
### integration-resource

[integration-resource](#integration-resource)
Manage individual resources from marketplace integrations: remove, disconnect from projects, and configure auto-recharge thresholds.

```
vercelintegration-resourceremove<resource-name>vercelintegration-resourcedisconnect<resource-name>[project-name]vercelintegration-resourcecreate-threshold<resource-name><minimum><spend><limit>
```

vercelintegration-resourceremove<resource-name>vercelintegration-resourcedisconnect<resource-name>[project-name]vercelintegration-resourcecreate-threshold<resource-name><minimum><spend><limit>

Learn more about the integration-resource command

[Learn more about the integration-resource command](/docs/cli/integration-resource)
### link

[link](#link)
Link a local directory to a Vercel Project.

```
vercellinkvercellink[path-to-directory]
```

vercellinkvercellink[path-to-directory]

Learn more about the link command

[Learn more about the link command](/docs/cli/link)
### list

[list](#list)
List recent deployments for the current Vercel Project.

```
vercellistvercellist[project-name]
```

vercellistvercellist[project-name]

Learn more about the list command

[Learn more about the list command](/docs/cli/list)
### login

[login](#login)
Login to your Vercel account through CLI.

```
vercelloginvercellogin[email]vercellogin--github
```

vercelloginvercellogin[email]vercellogin--github

Learn more about the login command

[Learn more about the login command](/docs/cli/login)
### logout

[logout](#logout)
Logout from your Vercel account through CLI.

```
vercellogout
```

vercellogout

Learn more about the logout command

[Learn more about the logout command](/docs/cli/logout)
### logs

[logs](#logs)
List runtime logs for a specific deployment.

```
vercellogs[deployment-url]vercellogs[deployment-url] --follow
```

vercellogs[deployment-url]vercellogs[deployment-url] --follow

Learn more about the logs command

[Learn more about the logs command](/docs/cli/logs)
### mcp

[mcp](#mcp)
Set up MCP client configuration for your Vercel Project.

```
vercelmcpvercelmcp--project
```

vercelmcpvercelmcp--project

Learn more about the mcp command

[Learn more about the mcp command](/docs/cli/mcp)
### microfrontends

[microfrontends](#microfrontends)
Work with microfrontends configuration.

```
vercelmicrofrontendspullvercelmicrofrontendspull--dpl[deployment-id-or-url]
```

vercelmicrofrontendspullvercelmicrofrontendspull--dpl[deployment-id-or-url]

Learn more about the microfrontends command

[Learn more about the microfrontends command](/docs/cli/microfrontends)
### open

[open](#open)
Open your current project in the Vercel Dashboard.

```
vercelopen
```

vercelopen

Learn more about the open command

[Learn more about the open command](/docs/cli/open)
### project

[project](#project)
List, add, inspect, remove, and manage your Vercel Projects.

```
vercelprojectlsvercelprojectaddvercelprojectrmvercelprojectinspect[project-name]
```

vercelprojectlsvercelprojectaddvercelprojectrmvercelprojectinspect[project-name]

Learn more about the project command

[Learn more about the project command](/docs/cli/project)
### promote

[promote](#promote)
Promote an existing deployment to be the current deployment.

```
vercelpromote[deployment-id-or-url]vercelpromotestatus[project]
```

vercelpromote[deployment-id-or-url]vercelpromotestatus[project]

Learn more about the promote command

[Learn more about the promote command](/docs/cli/promote)
### pull

[pull](#pull)
Update your local project with remote environment variables and project settings.

```
vercelpullvercelpull--environment=production
```

vercelpullvercelpull--environment=production

Learn more about the pull command

[Learn more about the pull command](/docs/cli/pull)
### redeploy

[redeploy](#redeploy)
Rebuild and redeploy an existing deployment.

```
vercelredeploy[deployment-id-or-url]
```

vercelredeploy[deployment-id-or-url]

Learn more about the redeploy command

[Learn more about the redeploy command](/docs/cli/redeploy)
### redirects

[redirects](#redirects)
Manage project-level redirects.

```
vercelredirectslistvercelredirectsadd/old/new--status301vercelredirectsuploadredirects.csv--overwritevercelredirectspromote<version-id>
```

vercelredirectslistvercelredirectsadd/old/new--status301vercelredirectsuploadredirects.csv--overwritevercelredirectspromote<version-id>

Learn more about the redirects command

[Learn more about the redirects command](/docs/cli/redirects)
### remove

[remove](#remove)
Remove deployments either by ID or for a specific Vercel Project.

```
vercelremove[deployment-url]vercelremove[project-name]
```

vercelremove[deployment-url]vercelremove[project-name]

Learn more about the remove command

[Learn more about the remove command](/docs/cli/remove)
### rollback

[rollback](#rollback)
Roll back production deployments to previous deployments.

```
vercelrollbackvercelrollback[deployment-id-or-url]vercelrollbackstatus[project]
```

vercelrollbackvercelrollback[deployment-id-or-url]vercelrollbackstatus[project]

Learn more about the rollback command

[Learn more about the rollback command](/docs/cli/rollback)
### rolling-release

[rolling-release](#rolling-release)
Manage your project's rolling releases to gradually roll out new deployments.

```
vercelrolling-releaseconfigure--cfg='[config]'vercelrolling-releasestart--dpl=[deployment-id]vercelrolling-releaseapprove--dpl=[deployment-id]vercelrolling-releasecomplete--dpl=[deployment-id]
```

vercelrolling-releaseconfigure--cfg='[config]'vercelrolling-releasestart--dpl=[deployment-id]vercelrolling-releaseapprove--dpl=[deployment-id]vercelrolling-releasecomplete--dpl=[deployment-id]

Learn more about the rolling-release command

[Learn more about the rolling-release command](/docs/cli/rolling-release)
### switch

[switch](#switch)
Switch between different team scopes.

```
vercelswitchvercelswitch[team-name]
```

vercelswitchvercelswitch[team-name]

Learn more about the switch command

[Learn more about the switch command](/docs/cli/switch)
### teams

[teams](#teams)
List, add, remove, and manage your teams.

```
vercelteamslistvercelteamsaddvercelteamsinvite[email]
```

vercelteamslistvercelteamsaddvercelteamsinvite[email]

Learn more about the teams command

[Learn more about the teams command](/docs/cli/teams)
### target

[target](#target)
Manage custom environments (targets) and use the--targetflag on relevant commands.

```
--target
```

```
verceltargetlistverceltargetlsverceldeploy--target=staging
```

verceltargetlistverceltargetlsverceldeploy--target=staging

Learn more about the target command

[Learn more about the target command](/docs/cli/target)
### telemetry

[telemetry](#telemetry)
Enable or disable telemetry collection.

```
verceltelemetrystatusverceltelemetryenableverceltelemetrydisable
```

verceltelemetrystatusverceltelemetryenableverceltelemetrydisable

Learn more about the telemetry command

[Learn more about the telemetry command](/docs/cli/telemetry)
### webhooks

[webhooks](#webhooks)
Manage webhooks for your account. This command is in beta.

```
vercelwebhookslistvercelwebhooksget<id>vercelwebhookscreate<url>--event<event>vercelwebhooksrm<id>
```

vercelwebhookslistvercelwebhooksget<id>vercelwebhookscreate<url>--event<event>vercelwebhooksrm<id>

Learn more about the webhooks command

[Learn more about the webhooks command](/docs/cli/webhooks)
### whoami

[whoami](#whoami)
Display the username of the currently logged in user.

```
vercelwhoami
```

vercelwhoami

Learn more about the whoami command

[Learn more about the whoami command](/docs/cli/whoami)
[PreviousCDN/Pricing & Usage](/docs/manage-cdn-usage)
[NextDeploying from CLI](/docs/cli/deploying-from-cli)
Was this helpful?

- Installing Vercel CLI
[Installing Vercel CLI](#installing-vercel-cli)
- Updating Vercel CLI
[Updating Vercel CLI](#updating-vercel-cli)
- Checking the version
[Checking the version](#checking-the-version)
- Using in a CI/CD environment
[Using in a CI/CD environment](#using-in-a-ci/cd-environment)
- Available Commands
[Available Commands](#available-commands)
- alias
[alias](#alias)
- api
[api](#api)
- bisect
[bisect](#bisect)
- blob
[blob](#blob)
- build
[build](#build)
- cache
[cache](#cache)
- certs
[certs](#certs)
- curl
[curl](#curl)
- deploy
[deploy](#deploy)
- dev
[dev](#dev)
- dns
[dns](#dns)
- domains
[domains](#domains)
- env
[env](#env)
- flags
[flags](#flags)
- git
[git](#git)
- guidance
[guidance](#guidance)
- help
[help](#help)
- httpstat
[httpstat](#httpstat)
- init
[init](#init)
- inspect
[inspect](#inspect)
- install
[install](#install)
- integration
[integration](#integration)
- integration-resource
[integration-resource](#integration-resource)
- link
[link](#link)
- list
[list](#list)
- login
[login](#login)
- logout
[logout](#logout)
- logs
[logs](#logs)
- mcp
[mcp](#mcp)
- microfrontends
[microfrontends](#microfrontends)
- open
[open](#open)
- project
[project](#project)
- promote
[promote](#promote)
- pull
[pull](#pull)
- redeploy
[redeploy](#redeploy)
- redirects
[redirects](#redirects)
- remove
[remove](#remove)
- rollback
[rollback](#rollback)
- rolling-release
[rolling-release](#rolling-release)
- switch
[switch](#switch)
- teams
[teams](#teams)
- target
[target](#target)
- telemetry
[telemetry](#telemetry)
- webhooks
[webhooks](#webhooks)
- whoami
[whoami](#whoami)