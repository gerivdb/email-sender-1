package conflict

import (
	"testing"
)

func TestAutoMergeStrategy(t *testing.T) {
	strat := &AutoMergeStrategy{}
	conf := Conflict{}
	res, err := strat.Execute(conf)
	if err != nil || res.Status != "merged" {
		t.Error("AutoMergeStrategy failed")
	}
	if err := strat.Validate(res); err != nil {
		t.Error("AutoMergeStrategy validate failed")
	}
}

func TestUserPromptStrategy(t *testing.T) {
	strat := &UserPromptStrategy{}
	conf := Conflict{}
	res, err := strat.Execute(conf)
	if err != nil || res.Status != "user_resolved" {
		t.Error("UserPromptStrategy failed")
	}
	if err := strat.Validate(res); err != nil {
		t.Error("UserPromptStrategy validate failed")
	}
}

func TestBackupAndReplaceStrategy(t *testing.T) {
	strat := &BackupAndReplaceStrategy{}
	conf := Conflict{}
	res, err := strat.Execute(conf)
	if err != nil || res.Status != "backup_replaced" {
		t.Error("BackupAndReplaceStrategy failed")
	}
	if err := strat.Validate(res); err != nil {
		t.Error("BackupAndReplaceStrategy validate failed")
	}
}

func TestPriorityBasedStrategy(t *testing.T) {
	strat := &PriorityBasedStrategy{}
	conf := Conflict{}
	res, err := strat.Execute(conf)
	if err != nil || res.Status != "priority_resolved" {
		t.Error("PriorityBasedStrategy failed")
	}
	if err := strat.Validate(res); err != nil {
		t.Error("PriorityBasedStrategy validate failed")
	}
}

func TestStrategyChain(t *testing.T) {
	chain := &StrategyChain{Strategies: []ResolutionStrategy{
		&AutoMergeStrategy{},
		&UserPromptStrategy{},
	}}
	conf := Conflict{}
	res, err := chain.Execute(conf)
	if err != nil {
		t.Error("StrategyChain execute failed")
	}
	if err := chain.Validate(res); err != nil {
		t.Error("StrategyChain validate failed")
	}
	_ = chain.Rollback(res)
}
