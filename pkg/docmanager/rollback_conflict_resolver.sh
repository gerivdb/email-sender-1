#!/bin/bash
# Script de rollback granularisé pour ConflictResolverImpl
cd "$(dirname "$0")"
git checkout conflict_resolver.go
