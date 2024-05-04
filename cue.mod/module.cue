module: "github.com/kharf/declcd-platform-example@v0"
language: {
	version: "v0.8.2"
}
deps: {
	"github.com/kharf/cuepkgs/modules/k8s@v0": {
		v:       "v0.0.5"
		default: true
	}
	"github.com/kharf/declcd/schema@v0": {
		v: "v0.12.0-alpha.1"
	}
}
