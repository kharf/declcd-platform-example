package declcd

import (
	"github.com/kharf/declcd/schema/component"
)


marketing: component.#Manifest & {
	dependencies: [
		crd.id,
		ns.id,
	]
	content: {
		apiVersion: "gitops.declcd.io/v1beta1"
		kind:       "GitOpsProject"
		metadata: {
			name:      "marketing"
			namespace: "declcd-system"
			labels: _secondaryLabels
		}
		spec: {
			branch:              "main"
			pullIntervalSeconds: 30
			suspend:             false
			url:                 "git@github.com:kharf/declcd-platform-example.git"
		}
	}
}
