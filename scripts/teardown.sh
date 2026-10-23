#!/usr/bin/env bash
kind delete cluster --name uniphore-lab
docker rm -f harbor-lite localstack 2>/dev/null || true
