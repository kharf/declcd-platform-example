package declcd

import (
	"github.com/kharf/declcd/schema"
)

_projectName: "dev"

project: schema.#Manifest & {
	dependencies: [crd.id]
	content: {
		apiVersion: "gitops.declcd.io/v1"
		kind:       "GitOpsProject"
		metadata: {
			name:      _projectName
			namespace: "declcd-system"
		}
		spec: {
			branch:              "main"
			pullIntervalSeconds: 30
			name:                _projectName
			suspend:             false
			url:                 "git@github.com:kharf/declcd-platform-example.git"
		}
	}
}
