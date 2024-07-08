package declcd

import (
	"github.com/kharf/declcd/schema/component"
)

_ateamLabels: {
	"\(_controlPlaneKey)": "project-controller-ateam"
	"\(_shardKey)":        "ateam"
}

ateamServiceAccount: component.#Manifest & {
	dependencies: [ns.id]
	content: {
		apiVersion: "v1"
		kind:       "ServiceAccount"
		metadata: {
			name:      "project-controller-ateam"
			namespace: ns.content.metadata.name
			labels:    _ateamLabels
		}
	}
}

ateamClusteRoleBinding: component.#Manifest & {
	dependencies: [
		ns.id,
		clusterRole.id,
		ateamServiceAccount.id,
	]
	content: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name:   "project-controller-ateam"
			labels: _ateamLabels
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     clusterRole.content.kind
			name:     clusterRole.content.metadata.name
		}
		subjects: [
			{
				kind:      ateamServiceAccount.content.kind
				name:      ateamServiceAccount.content.metadata.name
				namespace: ateamServiceAccount.content.metadata.namespace
			},
		]
	}
}

_ateamLeaderRoleName: "ateam-leader-election"
ateamLeaderRole: component.#Manifest & {
	dependencies: [ns.id]
	content: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "Role"
		metadata: {
			name:      _ateamLeaderRoleName
			namespace: ns.content.metadata.name
			labels:    _ateamLabels
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

ateamLeaderRoleBinding: component.#Manifest & {
	dependencies: [
		ns.id,
		ateamLeaderRole.id,
	]
	content: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      _ateamLeaderRoleName
			namespace: ns.content.metadata.name
			labels:    _ateamLabels
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     ateamLeaderRole.content.kind
			name:     ateamLeaderRole.content.metadata.name
		}
		subjects: [
			{
				kind:      ateamServiceAccount.content.kind
				name:      ateamServiceAccount.content.metadata.name
				namespace: ateamServiceAccount.content.metadata.namespace
			},
		]
	}
}

ateamPVC: component.#Manifest & {
	dependencies: [
		ns.id,
		knownHostsCm.id,
	]
	content: {
		apiVersion: "v1"
		kind:       "PersistentVolumeClaim"
		metadata: {
			name:      "ateam"
			namespace: ns.content.metadata.name
			labels:    _ateamLabels
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

ateamProjectControllerDeployment: component.#Manifest & {
	dependencies: [
		ns.id,
		ateamPVC.id,
		knownHostsCm.id,
	]
	content: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "project-controller-ateam"
			namespace: ns.content.metadata.name
			labels:    _ateamLabels
		}
		spec: {
			selector: matchLabels: _ateamLabels
			replicas: 1
			template: {
				metadata: {
					labels: _ateamLabels
				}
				spec: {
					serviceAccountName: "project-controller-ateam"
					securityContext: {
						runAsNonRoot:        true
						fsGroup:             65532
						fsGroupChangePolicy: "OnRootMismatch"
					}
					volumes: [
						{
							name: "ateam"
							persistentVolumeClaim: claimName: "ateam"
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
							name:  "project-controller-ateam"
							image: "ghcr.io/kharf/declcd:0.24.2"
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
									name:      "ateam"
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

ateamService: component.#Manifest & {
	dependencies: [
		ns.id,
		ateamProjectControllerDeployment.id,
	]
	content: {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "project-controller-ateam"
			namespace: ns.content.metadata.name
			labels:    _ateamLabels
		}
		spec: {
			clusterIP: "None"
			selector:  _ateamLabels
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
