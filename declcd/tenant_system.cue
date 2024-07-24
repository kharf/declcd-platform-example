package declcd

import (
	"github.com/kharf/declcd/schema/component"
)

_tenantLabels: {
	"\(_controlPlaneKey)": "project-controller-tenant"
	"\(_shardKey)":   "tenant"
}

tenantServiceAccount: component.#Manifest & {
	dependencies: [ns.id]
	content: {
		apiVersion: "v1"
		kind:       "ServiceAccount"
		metadata: {
			name:      "project-controller-tenant"
			namespace: ns.content.metadata.name
			labels:    _tenantLabels
		}
	}
}

tenantClusteRoleBinding: component.#Manifest & {
	dependencies: [
		ns.id,
		clusterRole.id,
		tenantServiceAccount.id,
	]
	content: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name:   "project-controller-tenant"
			labels: _tenantLabels
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     clusterRole.content.kind
			name:     clusterRole.content.metadata.name
		}
		subjects: [
			{
				kind:      tenantServiceAccount.content.kind
				name:      tenantServiceAccount.content.metadata.name
				namespace: tenantServiceAccount.content.metadata.namespace
			},
		]
	}
}

_tenantLeaderRoleName: "tenant-leader-election"
tenantLeaderRole: component.#Manifest & {
	dependencies: [ns.id]
	content: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "Role"
		metadata: {
			name:      _tenantLeaderRoleName
			namespace: ns.content.metadata.name
			labels:    _tenantLabels
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

tenantLeaderRoleBinding: component.#Manifest & {
	dependencies: [
		ns.id,
		tenantLeaderRole.id,
	]
	content: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      _tenantLeaderRoleName
			namespace: ns.content.metadata.name
			labels:    _tenantLabels
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     tenantLeaderRole.content.kind
			name:     tenantLeaderRole.content.metadata.name
		}
		subjects: [
			{
				kind:      tenantServiceAccount.content.kind
				name:      tenantServiceAccount.content.metadata.name
				namespace: tenantServiceAccount.content.metadata.namespace
			},
		]
	}
}

tenantPVC: component.#Manifest & {
	dependencies: [
		ns.id,
		knownHostsCm.id,
	]
	content: {
		apiVersion: "v1"
		kind:       "PersistentVolumeClaim"
		metadata: {
			name:      "tenant"
			namespace: ns.content.metadata.name
			labels:    _tenantLabels
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

tenantProjectControllerDeployment: component.#Manifest & {
	dependencies: [
		ns.id,
		tenantPVC.id,
		knownHostsCm.id,
	]
	content: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "project-controller-tenant"
			namespace: ns.content.metadata.name
			labels:    _tenantLabels
		}
		spec: {
			selector: matchLabels: _tenantLabels
			replicas: 1
			template: {
				metadata: {
					labels: _tenantLabels
				}
				spec: {
					serviceAccountName: "project-controller-tenant"
					securityContext: {
						runAsNonRoot:        true
						fsGroup:             65532
						fsGroupChangePolicy: "OnRootMismatch"
					}
					volumes: [
						{
							name: "tenant"
							persistentVolumeClaim: claimName: "tenant"
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
							name:  "project-controller-tenant"
							image: "ghcr.io/kharf/declcd:0.24.9"
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
									name:      "tenant"
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

tenantService: component.#Manifest & {
	dependencies: [
		ns.id,
		tenantProjectControllerDeployment.id,
	]
	content: {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "project-controller-tenant"
			namespace: ns.content.metadata.name
			labels:    _tenantLabels
		}
		spec: {
			clusterIP: "None"
			selector:  _tenantLabels
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
