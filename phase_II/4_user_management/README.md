# User Management

This document will discuss general best practices for setting up authentication and authorization for Users.

## Authentication

Rancher allows you to create local users to grant access to an environment, but it is a much better idea to configure one of the authentication plugins that Rancher provides.  This allows you to leverage existing users and groups from a provider like Active Directory, other LDAP services, and SAML providers.  This configuration is done at the Global level, which means that all clusters managed by a single Rancher will use the same authentication provider.

#### Note On Provider Searches

     If you leverage an LDAP solution, you will be able to search for users and groups below the group and user search bases you define, on a list of attributes you can provide.  This can be done even before a user logs into the platform, so that you can setup roles beforehand.  SAML providers however only return information about an individual user, and do not provide a searchable tree.  Because of that you won't be able to search for other users or groups you are not a member of when assigning roles.

### Terraform

In the HA Deployment terraform file `rancher-ha.tf` there is a section commented out that configures the authentication.  This example is using github authentication and only allows the admin to login by default.  This should be configured using whatever authentication provider your company plans to use.

```
/*resource "rancher2_auth_config_github" "github" {
  count         = local.rancher2_auth_config_github_count
  client_id     = var.github_client_id
  client_secret = var.github_client_secret
  access_mode   = "restricted"

  # Concatanate the local Rancher id with any specified GitHub principals
  allowed_principal_ids = ["local://${data.rancher2_user.admin.id}"]
}*/
```
## Authorizaiton

### Global

At the global level you can set a default access level for new users.  This will define what a user can do when first logging in within the Global context.  Usually you will not want all of your users to be able to create or delete clusters, modify Global settings, etc. To avoid this you can set the default Global Role to `User` or `User Base`.  The main difference is that `User` can create clusters and node templates.

If you want to put more controls around the type of cluster users can create, you can leverage RKE Templates.  This allows you to define the options that user's can modify while deploying a cluster.  You can either provide example templates to users, or require they use them by changing `cluster-template-enforcement` to true in global settings.

### Cluster

Cluster level settings are useful if you have operations teams who need to be able to set up cluster tooling and create projects, but not actually deploy applications into specific projects.  You can also give someone the `Cluster Owner` role, which will give them access to all resources in any project within the cluster.

### Project

Projects are a custom resource Rancher has created to make it easier to manage namespaces.  A project is a collection of one or more namespaces that allows you to apply RBAC rules, resource quotas and pod security policies to the entire set of namespaces.

Projects will be the level that you split up access control within the cluster to enable multitenancy.  Often times projects will be created like `DevTeamA`,`DevTeamB`, or by line of business.  Roles can then be applied to users and groups through your authentication provider. If you want a user to have complete access within a particular project, `Project Owner` and `Project Member` can be used.  The main difference between these is an Owner can modify other project role bindings, so it often makes more sense to give users `Project Member`. 

These roles also inherit from the kubernetes built in roles (listed within Rancher as kubernetes view, edit and admin), which are discussed here [User Facing Roles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles).  When creating your own roles you can reference these built in user roles, or other roles defined within Rancher as a baseline.

#### Note On UI Visibility
        Only projects a user has some level of access to will display in the UI.  If a user does not have access to any project in a cluster, that cluster will not display in their dropdown.

### Terraform

In the _Automated Kubernetes Cluster Deployment_ section, we create a local user and two projects, `DevTeamA` and `DevTeamB`.  We have given the local user the `Project Member` role in `DevTeamA` and the `Read-Only` role in `DevTeamB`.  This is just for example purposes to demonstrate how project creaton and authorization can be done through terraform.
