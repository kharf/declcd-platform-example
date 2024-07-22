package declcd

import (
	"github.com/kharf/declcd/schema/component"
)

ateam: component.#Manifest & {
	dependencies: [
		crd.id,
		ns.id,
	]
	content: {
		apiVersion: "gitops.declcd.io/v1beta1"
		kind:       "GitOpsProject"
		metadata: {
			name:      "ateam"
			namespace: "declcd-system"
			labels: _tenantLabels
		}
		spec: {
			branch:              "main"
			pullIntervalSeconds: 30
			suspend:             false
			url:                 "git@github.com:kharf/declcd-platform-team-a-example.git"
		}
	}
}
