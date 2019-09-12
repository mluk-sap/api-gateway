package validation

import (
	"fmt"

	gatewayv2alpha1 "github.com/kyma-incubator/api-gateway/api/v2alpha1"
)

type oauth struct{}

func (o *oauth) Validate(gate *gatewayv2alpha1.Gate) error {
	if len(gate.Spec.Paths) != 1 {
		return fmt.Errorf("supplied config should contain exactly one path")
	}
	if hasDuplicates(gate.Spec.Paths) {
		return fmt.Errorf("supplied config is invalid: multiple definitions of the same path detected")
	}
	return nil
}