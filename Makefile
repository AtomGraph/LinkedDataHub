# Canonical LinkedDataHub deployment Makefile.
#
# Byte-identical across LinkedDataHub and every LDH-based deployment repo, the same convention
# docker-compose.yml follows. Do not edit it per repo - re-sync with
#
#     cp ../LinkedDataHub/Makefile Makefile
#
# and keep everything repo-specific in the two optional includes:
#
#     make/config.mk   variables: which scripts to call, what `drop` wipes, what `sef` stages
#     make/local.mk    targets this repo adds - or replaces, by naming them in LOCAL_TARGETS
#
# `diff ../LinkedDataHub/Makefile Makefile` must print nothing.

SHELL := /bin/bash

-include make/config.mk

# This deployment's settings, the same file docker compose reads. Optional, so targets that need
# no base URI still run before it is written; the URI variables below are lazily expanded and say
# so when it is missing.
-include .env

COMPOSE             ?= docker compose
CERT_GEN            ?= ./bin/server-cert-gen.sh
LDH_HOME            ?= ../LinkedDataHub
LDH                 ?= $(LDH_HOME)/cli/bin/ldh
OWNER_CERT          ?= ssl/owner/keystore.p12
OWNER_PASSWORD_FILE ?= secrets/owner_cert_password.txt
LOGS_SERVICE        ?= linkeddatahub
SEF_ENTRY           ?= files/client.xsl
SEF_OUT             ?= files/client.xsl.sef.json
SEF_EXTRA           ?=
DROP_PATHS          ?= datasets fuseki ssl uploads sef packages settings
VALIDATE_PATHS      ?= .
LOAD_STAGING        ?=
HTTPS_CLIENT_CERT_PORT ?= 5443
PROJECT             ?= $(or $(COMPOSE_PROJECT_NAME),$(notdir $(CURDIR)))

# A dataspace serves its documents from the root of its origin, so the base URI is that root and
# has no path component. Lazily expanded (`=`, not `:=`), so the error fires only when a target
# actually needs a URI.
ORIGIN    = $(if $(and $(PROTOCOL),$(HOST)),$(PROTOCOL)://$(HOST)$(if $(filter-out 443,$(HTTPS_PORT)),:$(HTTPS_PORT)),$(error .env is missing or incomplete: PROTOCOL and HOST are required))
BASE_URI   = $(ORIGIN)/
PROXY_URI  = $(PROTOCOL)://$(HOST):$(HTTPS_CLIENT_CERT_PORT)/

TARGETS         := up down stop restart ps logs cert secrets sef public load validate drop
COMPOSE_TARGETS := up down stop restart ps logs

.PHONY: $(TARGETS) $(LOCAL_TARGETS)

# Treat goals that are not targets as arguments for docker compose rather than as make goals, so
# `make up -- --build -d` and `make up nginx` work.
ifneq (,$(filter $(COMPOSE_TARGETS),$(MAKECMDGOALS)))
COMPOSE_ARGS := $(filter-out $(TARGETS) $(LOCAL_TARGETS),$(MAKECMDGOALS))
$(eval $(COMPOSE_ARGS):;@:)
endif

# --- stack -------------------------------------------------------------------

up: secrets cert
	$(COMPOSE) up $(ARGS) $(COMPOSE_ARGS)

down:
	$(COMPOSE) down $(ARGS) $(COMPOSE_ARGS)

stop:
	$(COMPOSE) stop $(ARGS) $(COMPOSE_ARGS)

restart:
	$(COMPOSE) restart $(ARGS) $(COMPOSE_ARGS)

ps:
	$(COMPOSE) ps $(ARGS) $(COMPOSE_ARGS)

# Follows LOGS_SERVICE unless the command line names other services.
logs:
	$(COMPOSE) logs -f $(ARGS) $(or $(COMPOSE_ARGS),$(LOGS_SERVICE))

# --- first-run bootstrap ------------------------------------------------------

SECRET_FILES := secrets/owner_cert_password.txt \
                secrets/secretary_cert_password.txt \
                secrets/client_truststore_password.txt

secrets: $(SECRET_FILES)

secrets/%.txt:
	@mkdir -p secrets
	openssl rand -base64 24 > $@

# Generate the server SSL certificate from .env. A file target, so `make up` does not regenerate
# it on every start.
cert: ssl/server/server.crt

ssl/server/server.crt:
	$(CERT_GEN) .env nginx ssl

# --- client stylesheet --------------------------------------------------------

ifeq ($(filter sef,$(LOCAL_TARGETS)),)
ifneq ($(wildcard $(SEF_ENTRY)),)
# Compile this deployment's client.xsl override to a Saxon-JS SEF. Stages the deployed image's
# ROOT/static tree in a temp dir so the stylesheet's ../com/atomgraph/linkeddatahub/xsl/client.xsl
# import resolves, canonicalizes every stylesheet there (the platform build inlines XML entities
# the same way), then compiles. Run it before the first `make up` - the compose mount needs the
# file to exist - and after every edit, then recreate the container to reload it.
#
# Resolve the EFFECTIVE image from the merged compose config, never from docker-compose.yml
# alone: an image pin in an override has to win, or the SEF compiles against a different
# stylesheet tree than the runtime serves and CSR diverges from SSR. The pattern is anchored on
# the tag (or digest) separator because `--images <service>` ignores the service filter and lists
# every image, so a bare `linkeddatahub` also matches the sef-compiler's, in an order Compose
# does not guarantee.
sef:
	@set -e; \
	LDH_IMAGE=$$($(COMPOSE) config --images linkeddatahub | grep -m1 -E 'linkeddatahub[:@]'); \
	[ -n "$$LDH_IMAGE" ] || { echo "ERROR: no linkeddatahub image in the merged compose config" >&2; exit 1; }; \
	echo "Using LDH image: $$LDH_IMAGE"; \
	docker image inspect "$$LDH_IMAGE" >/dev/null 2>&1 || docker pull "$$LDH_IMAGE" >/dev/null 2>&1 || \
		{ echo "ERROR: $$LDH_IMAGE is neither built locally nor pullable - fix the image pin in docker-compose.override.yml" >&2; exit 1; }; \
	TMP_DIR=$$(mktemp -d); \
	trap 'rm -rf "$$TMP_DIR"; docker rm -f $(PROJECT)-sef-tmp >/dev/null 2>&1 || true' EXIT; \
	docker create --name $(PROJECT)-sef-tmp "$$LDH_IMAGE" >/dev/null; \
	docker cp $(PROJECT)-sef-tmp:/usr/local/tomcat/webapps/ROOT/static "$$TMP_DIR/"; \
	docker rm $(PROJECT)-sef-tmp >/dev/null; \
	find "$$TMP_DIR/static" -name '*.xsl' -print0 | while IFS= read -r -d '' f; do xmlstarlet c14n "$$f" > "$$f.tmp" 2>/dev/null && mv "$$f.tmp" "$$f" || rm -f "$$f.tmp"; done; \
	mkdir -p "$$TMP_DIR/static/files"; \
	for f in $(SEF_ENTRY) $(SEF_EXTRA); do xmlstarlet c14n "./$$f" > "$$TMP_DIR/static/files/$$(basename "$$f")"; done; \
	npx xslt3-he -t -xsl:"$$TMP_DIR/static/files/$$(basename $(SEF_ENTRY))" -export:"$$TMP_DIR/out.sef.json" -nogo -ns:##html5 -relocate:on || \
		{ echo "SEF compile FAILED - $(SEF_OUT) left unchanged" >&2; exit 1; }; \
	[ -s "$$TMP_DIR/out.sef.json" ] || { echo "SEF compile produced nothing - $(SEF_OUT) left unchanged" >&2; exit 1; }; \
	mv "$$TMP_DIR/out.sef.json" $(SEF_OUT); \
	echo "Wrote $(SEF_OUT)"
else
sef:
	@echo "ERROR: $(SEF_ENTRY) not found - this deployment overrides no client stylesheet" >&2; exit 1
endif
endif

# --- app ----------------------------------------------------------------------

# `install` is deliberately absent: every deployment installs its own app structure its own
# way, so each defines `install` (and any install-prod) in make/local.mk.

ifeq ($(filter public,$(LOCAL_TARGETS)),)
# Grant anonymous read on every end-user document. Idempotent - the CLI PATCHes one authorization.
public:
	@[ -x "$(LDH)" ] || { echo "ERROR: ldh CLI not found at $(LDH) - run 'make cli' in $(LDH_HOME)"; exit 1; }
	@[ -f $(OWNER_PASSWORD_FILE) ] || { echo "ERROR: $(OWNER_PASSWORD_FILE) not found - run 'make secrets' and install first"; exit 1; }
	LDH_BASE="$(BASE_URI)" \
	LDH_CERT_FILE="$(OWNER_CERT)" \
	LDH_CERT_PASSWORD="$$(cat $(OWNER_PASSWORD_FILE))" \
	LDH_PROXY="$(PROXY_URI)" \
	$(LDH) admin make-public

endif

ifneq ($(LOAD_STAGING),)
# Bulk-load $(LOAD_STAGING)/*/*.trig straight into the end-user TDB2 dataset, bypassing the HTTP
# API - minutes instead of hours for millions of quads. The committed TriG is base-relative, so
# the loader resolves it against BASE_URI and the same files load at whatever base this
# deployment uses. APPEND-ONLY: for a clean rebuild delete fuseki/end-user first. One Fuseki
# serves both roles, so stopping it for the load takes the admin store down with it - and its
# stop leaves a PID-1 tdb.lock in every dataset, each of which would block the restart, so all
# of them are cleared and not just the one being loaded.
load:
	@ls $(LOAD_STAGING)/*/*.trig >/dev/null 2>&1 || \
		{ echo "ERROR: no TriG files under $(LOAD_STAGING)/ - run 'make -C etl' first."; exit 1; }
	@[ -n "$$($(COMPOSE) ps -q fuseki)" ] || \
		{ echo "ERROR: fuseki container not found - run 'make up' first."; exit 1; }
	@echo "Waiting for LinkedDataHub health (first-boot seeding must finish)..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' $$($(COMPOSE) ps -q linkeddatahub))" = "healthy" ]; do \
		sleep 5; echo "  ...waiting"; \
	done
	$(COMPOSE) stop fuseki
	rm -f fuseki/*/DB2/tdb.lock
	$(COMPOSE) run --rm -e BASE_URI="$(BASE_URI)" tdb-loader
	$(COMPOSE) up -d fuseki
	$(COMPOSE) restart varnish-end-user varnish-frontend
	$(MAKE) public
else
load:
	@echo "ERROR: this deployment has no bulk loader (set LOAD_STAGING in make/config.mk)" >&2; exit 1
endif

# --- housekeeping -------------------------------------------------------------

# Parse every RDF file under VALIDATE_PATHS. Needs Jena's riot on PATH ($JENA_HOME/bin).
validate:
	@find $(VALIDATE_PATHS) \( -name '*.ttl' -o -name '*.trig' \) -type f -print0 | xargs -0 riot --validate

# Stop the stack, remove its volumes and wipe this deployment's local state - irreversible.
# Stops first on purpose: deleting the directories under a running Fuseki leaves it writing into
# paths that no longer exist.
drop:
	@read -p "Stop the stack and delete $(DROP_PATHS)? [y/N] " ans && [ "$$ans" = "y" ] || { echo "Aborted."; exit 0; }; \
	$(COMPOSE) down -v && sudo rm -rf $(DROP_PATHS)

-include make/local.mk
