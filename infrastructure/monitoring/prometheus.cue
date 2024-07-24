package monitoring

import (
	"github.com/kharf/declcd-platform-example/templates/core"
)

ns: core.#Namespace & {
	#Name: "prometheus"
}
