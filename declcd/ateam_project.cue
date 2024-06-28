package declcd

import (
	"github.com/kharf/declcd/schema/component"
	"github.com/kharf/declcd-platform-example/templates/core"
)

ateamTenantServiceAccount: core.#ServiceAccount & {
	dependencies: [
		ns.id,
	]
	#Name:      "ateam"
	#Namespace: ns.content.metadata.name
}

ateam: component.#Manifest & {
	dependencies: [
		crd.id,
		ns.id,
		ateamTenantServiceAccount.id,
	]
	content: {
		apiVersion: "gitops.declcd.io/v1beta1"
		kind:       "GitOpsProject"
		metadata: {
			name:      "ateam"
			namespace: "declcd-system"
			labels:    _ateamLabels
		}
		spec: {
			branch:              "main"
			serviceAccountName:  ateamTenantServiceAccount.#Name
			pullIntervalSeconds: 30
			suspend:             false
			url:                 "git@github.com:kharf/declcd-platform-team-a-example.git"
		}
	}
}
