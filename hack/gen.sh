#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

source hack/utils.sh
export GOPATH="$(go_mod_gopath_hack)"
trap "rm -rf ${GOPATH}" EXIT
KC_PKG="carvel.dev/kapp-controller"

rm -rf pkg/client

# Based on vendor/k8s.io/code-generator/generate-groups.sh
# (Converted to "go runs" so that there is no dependency on installed binaries.)

echo "Generating deepcopy funcs"
rm -f $(find pkg/apis|grep zz_generated.deepcopy.go)
go run vendor/k8s.io/code-generator/cmd/deepcopy-gen/main.go \
	${KC_PKG}/pkg/apis/kappctrl/v1alpha1 \
	${KC_PKG}/pkg/apis/packaging/v1alpha1 \
	${KC_PKG}/pkg/apis/internalpackaging/v1alpha1 \
	--output-file zz_generated.deepcopy.go \
	--bounding-dirs ${KC_PKG}/pkg/apis \
	--go-header-file ./hack/gen-boilerplate.txt

echo "Generating clientset"
go run vendor/k8s.io/code-generator/cmd/client-gen/main.go \
	--clientset-name versioned \
	--input-base '' \
	--input ${KC_PKG}/pkg/apis/kappctrl/v1alpha1,${KC_PKG}/pkg/apis/packaging/v1alpha1,${KC_PKG}/pkg/apis/internalpackaging/v1alpha1 \
	--output-pkg ${KC_PKG}/pkg/client/clientset \
	--output-dir pkg/client/clientset \
	--go-header-file ./hack/gen-boilerplate.txt

echo "Generating listers"
go run vendor/k8s.io/code-generator/cmd/lister-gen/main.go \
	${KC_PKG}/pkg/apis/kappctrl/v1alpha1 \
	${KC_PKG}/pkg/apis/packaging/v1alpha1 \
	${KC_PKG}/pkg/apis/internalpackaging/v1alpha1 \
	--output-pkg ${KC_PKG}/pkg/client/listers \
	--output-dir pkg/client/listers \
	--go-header-file ./hack/gen-boilerplate.txt

echo "Generating informers"
go run vendor/k8s.io/code-generator/cmd/informer-gen/main.go \
	${KC_PKG}/pkg/apis/kappctrl/v1alpha1 \
	${KC_PKG}/pkg/apis/packaging/v1alpha1 \
	${KC_PKG}/pkg/apis/internalpackaging/v1alpha1 \
	--versioned-clientset-package ${KC_PKG}/pkg/client/clientset/versioned \
	--listers-package ${KC_PKG}/pkg/client/listers \
	--output-pkg ${KC_PKG}/pkg/client/informers \
	--output-dir pkg/client/informers \
	--go-header-file ./hack/gen-boilerplate.txt

echo GEN SUCCESS
