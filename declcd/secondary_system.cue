package declcd

import (
	"github.com/kharf/declcd/schema/component"
)

_secondaryLabels: {
	"\(_controlPlaneKey)": "project-controller-secondary"
	"\(_shardKey)":        "secondary"
}

secondaryServiceAccount: component.#Manifest & {
	dependencies: [ns.id]
	content: {
		apiVersion: "v1"
		kind:       "ServiceAccount"
		metadata: {
			name:      "project-controller-secondary"
			namespace: ns.content.metadata.name
			labels:    _secondaryLabels
		}
	}
}

_secondaryLeaderRoleName: "secondary-leader-election"
secondaryLeaderRole: component.#Manifest & {
	dependencies: [ns.id]
	content: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "Role"
		metadata: {
			name:      _secondaryLeaderRoleName
			namespace: ns.content.metadata.name
			labels:    _secondaryLabels
		}
		rules: [
			{
				apiGroups: ["coordination.k8s.io"]
				resources: ["leases"]
				verbs: [
					"get",
					"create",
					"update",
				]
			},
			{
				apiGroups: [""]
				resources: ["events"]
				verbs: [
					"create",
					"patch",
				]
			},
		]
	}
}

secondaryLeaderRoleBinding: component.#Manifest & {
	dependencies: [
		ns.id,
		secondaryLeaderRole.id,
	]
	content: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      _secondaryLeaderRoleName
			namespace: ns.content.metadata.name
			labels:    _secondaryLabels
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     secondaryLeaderRole.content.kind
			name:     secondaryLeaderRole.content.metadata.name
		}
		subjects: [
			{
				kind:      secondaryServiceAccount.content.kind
				name:      secondaryServiceAccount.content.metadata.name
				namespace: secondaryServiceAccount.content.metadata.namespace
			},
		]
	}
}

secondaryClusteRoleBinding: component.#Manifest & {
	dependencies: [
		ns.id,
		clusterRole.id,
		secondaryServiceAccount.id,
	]
	content: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name:   "project-controller-secondary"
			labels: _secondaryLabels
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     clusterRole.content.kind
			name:     clusterRole.content.metadata.name
		}
		subjects: [
			{
				kind:      secondaryServiceAccount.content.kind
				name:      secondaryServiceAccount.content.metadata.name
				namespace: secondaryServiceAccount.content.metadata.namespace
			},
		]
	}
}

secondaryPVC: component.#Manifest & {
	dependencies: [
		ns.id,
		knownHostsCm.id,
	]
	content: {
		apiVersion: "v1"
		kind:       "PersistentVolumeClaim"
		metadata: {
			name:      "secondary"
			namespace: ns.content.metadata.name
			labels:    _secondaryLabels
		}
		spec: {
			accessModes: [
				"ReadWriteOnce",
			]
			resources: {
				requests: {
					storage: "200Mi"
				}
			}
		}
	}
}

secondaryProjectControllerDeployment: component.#Manifest & {
	dependencies: [
		ns.id,
		secondaryPVC.id,
		knownHostsCm.id,
	]
	content: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "project-controller-secondary"
			namespace: ns.content.metadata.name
			labels:    _secondaryLabels
		}
		spec: {
			selector: matchLabels: _secondaryLabels
			replicas: 1
			template: {
				metadata: {
					labels: _secondaryLabels
				}
				spec: {
					serviceAccountName: "project-controller-secondary"
					securityContext: {
						runAsNonRoot:        true
						fsGroup:             65532
						fsGroupChangePolicy: "OnRootMismatch"
					}
					volumes: [
						{
							name: "secondary"
							persistentVolumeClaim: claimName: "secondary"
						},
						{
							name: "podinfo"
							downwardAPI: {
								items: [
									{
										path: "namespace"
										fieldRef: fieldPath: "metadata.namespace"
									},
									{
										path: "name"
										fieldRef: fieldPath: "metadata.labels['\(_controlPlaneKey)']"
									},
									{
										path: "shard"
										fieldRef: fieldPath: "metadata.labels['\(_shardKey)']"
									},
								]
							}
						},
						{
							name: "ssh"
							configMap: name: knownHostsCm.content.metadata.name
						},
						{
							name: "cache"
							emptyDir: {}
						},
					]
					containers: [
						{
							name:  "project-controller-secondary"
							image: "ghcr.io/kharf/declcd:0.24.0-dev.2"
							command: [
								"/controller",
							]
							args: [
								"--log-level=0",
							]
							securityContext: {
								allowPrivilegeEscalation: false
								capabilities: {
									drop: [
										"ALL",
									]
								}
							}
							resources: {
								limits: {
									memory: "1.5Gi"
								}
								requests: {
									memory: "1.5Gi"
									cpu:    "500m"
								}
							}
							ports: [
								{
									name:          "http"
									protocol:      "TCP"
									containerPort: 8080
								},
							]
							volumeMounts: [
								{
									name:      "secondary"
									mountPath: "/inventory"
								},
								{
									name:      "podinfo"
									mountPath: "/podinfo"
									readOnly:  true
								},
								{
									name:      "ssh"
									mountPath: "/.ssh"
									readOnly:  true
								},
								{
									name:      "cache"
									mountPath: "/.cache"
								},
							]
						},
					]
				}
			}
		}
	}
}

secondaryService: component.#Manifest & {
	dependencies: [
		ns.id,
		secondaryProjectControllerDeployment.id,
	]
	content: {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "project-controller-secondary"
			namespace: ns.content.metadata.name
			labels:    _secondaryLabels
		}
		spec: {
			clusterIP: "None"
			selector:  _secondaryLabels
			ports: [
				{
					name:       "http"
					protocol:   "TCP"
					port:       8080
					targetPort: "http"
				},
			]
		}
	}
}
