module github.com/Tal-or/rps-debug

go 1.18

require (
	github.com/openshift-kni/cnf-features-deploy v0.0.0-20220928145739-5314ce12b1c7
	golang.org/x/sys v0.0.0-20220722155257-8c9f86f7a55f
	k8s.io/klog v1.0.0
	k8s.io/kubernetes v1.25.2
)

require (
	github.com/go-logr/logr v1.2.3 // indirect
	k8s.io/klog/v2 v2.80.1 // indirect
)

replace (
	k8s.io/api => k8s.io/api v0.24.1
	k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.24.1
	k8s.io/apimachinery => k8s.io/apimachinery v0.24.1
	k8s.io/apiserver => k8s.io/apiserver v0.24.1
	k8s.io/cli-runtime => k8s.io/cli-runtime v0.24.1
	k8s.io/client-go => k8s.io/client-go v0.24.1
	k8s.io/cloud-provider => k8s.io/cloud-provider v0.24.1
	k8s.io/cluster-bootstrap => k8s.io/cluster-bootstrap v0.24.1
	k8s.io/code-generator => k8s.io/code-generator v0.24.1
	k8s.io/component-base => k8s.io/component-base v0.24.1
	k8s.io/component-helpers => k8s.io/component-helpers v0.24.1
	k8s.io/controller-manager => k8s.io/controller-manager v0.24.1
	k8s.io/cri-api => k8s.io/cri-api v0.24.1
	k8s.io/csi-translation-lib => k8s.io/csi-translation-lib v0.24.1
	k8s.io/kube-aggregator => k8s.io/kube-aggregator v0.24.1
	k8s.io/kube-controller-manager => k8s.io/kube-controller-manager v0.24.1
	k8s.io/kube-proxy => k8s.io/kube-proxy v0.24.1
	k8s.io/kube-scheduler => k8s.io/kube-scheduler v0.24.1
	k8s.io/kubectl => k8s.io/kubectl v0.24.1
	k8s.io/kubelet => k8s.io/kubelet v0.24.1
	k8s.io/kubernetes => k8s.io/kubernetes v1.24.1
	k8s.io/legacy-cloud-providers => k8s.io/legacy-cloud-providers v0.24.1
	k8s.io/metrics => k8s.io/metrics v0.24.1
	k8s.io/mount-utils => k8s.io/mount-utils v0.24.1
	k8s.io/pod-security-admission => k8s.io/pod-security-admission v0.24.1
	k8s.io/sample-apiserver => k8s.io/sample-apiserver v0.24.1
)
