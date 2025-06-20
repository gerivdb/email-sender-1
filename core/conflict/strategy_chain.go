package conflict

import "errors"

// StrategyChain allows chaining multiple strategies.
type StrategyChain struct {
	Strategies []ResolutionStrategy
}

func (s *StrategyChain) Execute(conflict Conflict) (Resolution, error) {
	for _, strat := range s.Strategies {
		res, err := strat.Execute(conflict)
		if err == nil {
			return res, nil
		}
	}
	return Resolution{}, errors.New("all strategies failed")
}

func (s *StrategyChain) Validate(res Resolution) error {
	for _, strat := range s.Strategies {
		if err := strat.Validate(res); err == nil {
			return nil
		}
	}
	return errors.New("no strategy validated the resolution")
}

func (s *StrategyChain) Rollback(res Resolution) error {
	for _, strat := range s.Strategies {
		_ = strat.Rollback(res)
	}
	return nil
}
