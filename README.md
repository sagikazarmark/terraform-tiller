# Tiller Terraform Module

[![CircleCI](https://circleci.com/gh/sagikazarmark/terraform-tiller.svg?style=svg)](https://circleci.com/gh/sagikazarmark/terraform-tiller)

Install [Tiller](https://docs.helm.sh/glossary/#tiller) on a Kubernetes cluster using Terraform.


## Installation / Usage

0. Configure a `kubernetes` provider in the parent module
1. Add the following snippet to your terraform config:

```hcl
module "tiller" {
  source  = "github.com/sagikazarmark/terraform-tiller"
  version = "~> 0.1.0"
}
```


## Configuration

| Name | Default | Description |
| rbac_enabled | false | Whether to create role-based access control resources (service account and cluster role binding). |
| tiller_namespace | kube-system | The Kubernetes namespace to use to deploy Tiller. |
| tiller_service_account | tiller | The Kubernetes service account to add to Tiller. |
| tiller_replicas | 1 | The amount of Tiller instances to run on the cluster. |
| tiller_image | gcr.io/kubernetes-helm/tiller | The image used to install Tiller. |
| tiller_version | v2.11.0 | The Tiller image version to install. |
| tiller_max_history | 0 (unlimited) | Limit the maximum number of revisions saved per release. Use 0 for no limit. |
| tiller_net_host | *empty* | Install Tiller with net=host. |
| tiller_node_selector | *empty* | Determine which nodes Tiller can land on. |


## Why

After a rather long development and review period Terraform accepted a [Helm provider](https://www.terraform.io/docs/providers/helm/index.html)
as an official plugin. It provides an option to automatically [install Tiller](https://www.terraform.io/docs/providers/helm/index.html#install_tiller)
on a cluster if necessary, but unfortunately it's a bit buggy. So I created this terraform module to install Tiller separately from
the Helm provider.


## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.
