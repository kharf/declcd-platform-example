package declcd

import (
	"github.com/kharf/declcd/schema/component"
)

foundation: component.#Manifest & {
	dependencies: [
		crd.id,
		ns.id,
	]
	content: {
		apiVersion: "gitops.declcd.io/v1beta1"
		kind:       "GitOpsProject"
		metadata: {
			name:      "foundation"
			namespace: "declcd-system"
			labels: _primaryLabels
		}
		spec: {
			branch:              "main"
			pullIntervalSeconds: 30
			suspend:             false
			url:                 "git@github.com:kharf/declcd-platform-example.git"
		}
	}
}
