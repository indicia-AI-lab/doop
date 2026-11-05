#!/usr/bin/env bash
# Boots the image with its embedded database: a module or config error stops the release here, not on prod.
set -euo pipefail
image="$1"
name="doop-smoke-$$"
trap 'docker logs "$name" 2>&1 | tail -20 || true; docker rm -f "$name" >/dev/null 2>&1 || true' EXIT
docker run -d --name "$name" -p 127.0.0.1:4400:4400 \
  -e BETTER_AUTH_SECRET=smoke-test-secret-smoke-test-secret \
  -e BETTER_AUTH_URL=http://localhost:4400 "$image" >/dev/null
for _ in $(seq 1 60); do
  if curl -fsS -m 2 http://127.0.0.1:4400/healthz | grep -Fq '"ok":true'; then
    echo "image smoke ok"
    exit 0
  fi
  sleep 2
done
echo "::error::image did not answer /healthz within 120s"
exit 1
