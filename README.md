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
| ---- | ------- | ----------- |
| rbac_enabled | false | Whether to create role-based access control resources (service account and cluster role binding). |
| tiller_namespace | kube-system | The Kubernetes namespace to use to deploy Tiller. |
| tiller_service_account | tiller | The Kubernetes service account to add to Tiller. |
| tiller_replicas | 1 | The amount of Tiller instances to run on the cluster. |
| tiller_image | gcr.io/kubernetes-helm/tiller | The image used to install Tiller. |
| tiller_version | v2.11.0 | The Tiller image version to install. |
| tiller_max_history | 0 (unlimited) | Limit the maximum number of revisions saved per release. Use 0 for no limit. |
| tiller_net_host | *empty* | Install Tiller with net=host. |
| tiller_node_selector | *empty* | Determine which nodes Tiller can land on. |


## Initial Chart installation

You might want to preinstall your servers with Kubernetes plugins such as unsupported ingress controllers, right after Tiller is installed. Since Terraform still doesn't support `depends_on` feature on modules, such as this one, there's manual work that needs to be done. This is an example how you can make sure Helm Chart installation starts after the Tiller service is ready:

```hcl
module "tiller" {
  ...
}

resource "null_resource" "install_voyager" {
  provisioner "local-exec" {
    command     = "./helm/voyager.sh ${local_file.kube_cluster_yaml.filename}"
    interpreter = ["bash", "-c"]
  }
}
```

```bash
#!/usr/bin/env bash

wait_for_tiller () {
	KUBECONFIG=$1 kubectl --namespace kube-system get pods \
		--field-selector=status.phase==Running | grep 'tiller-deploy' \
		| grep '1/1' \
		> /dev/null 2>&1
}

until wait_for_tiller $1; do
	echo "Waiting for tiller-deploy to get ready..."
	sleep 5
done

echo "Installing Voyager Ingress..."

helm repo add appscode https://charts.appscode.com/stable --kubeconfig $CWD/../kube_config_cluster.yml
helm repo update --kubeconfig $CWD/../kube_config_cluster.yml

helm install appscode/voyager --name voyager-operator --version 8.0.1 \
	--namespace kube-system --set cloudProvider=baremetal \
	--kubeconfig $1 > /dev/null 2>&1

echo "Voyager Ingress installed!"
```


## Why

After a rather long development and review period Terraform accepted a [Helm provider](https://www.terraform.io/docs/providers/helm/index.html)
as an official plugin. It provides an option to automatically [install Tiller](https://www.terraform.io/docs/providers/helm/index.html#install_tiller)
on a cluster if necessary, but unfortunately it's a bit buggy and it usually comes with an older Helm/Tiller version
(at the time of this writing the included version is 2.9.0 while the latest is 2.12.0).
So I created this terraform module to install Tiller separately from the Helm provider.


## License

The MIT License (MIT). Please see [License File](LICENSE) for more information.
