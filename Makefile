TARGETS := sef drop cert release tests up down cli cli-version
COMPOSE_TARGETS := up down
.PHONY: $(TARGETS)

# Treat goals that are not targets as arguments for docker-compose, not as make goals
ifneq (,$(filter $(COMPOSE_TARGETS),$(MAKECMDGOALS)))
COMPOSE_ARGS := $(filter-out $(TARGETS),$(MAKECMDGOALS))
$(eval $(COMPOSE_ARGS):;@:)
endif

# Start the Docker Compose stack; extra arguments are passed to `docker-compose up`
# (e.g. `make up -- --build -d`, `make up nginx`, or `make up ARGS="--build -d"`)
up:
	docker-compose up $(ARGS) $(COMPOSE_ARGS)

# Stop the Docker Compose stack; extra arguments are passed to `docker-compose down`
# (e.g. `make down -- -v` to remove the Varnish cache volumes as well)
down:
	docker-compose down $(ARGS) $(COMPOSE_ARGS)

# Generate Saxon-JS SEF files for client-side XSLT transformations
sef:
	mvn war:war
# expand entities in XSLT stylesheets. Same logic as in pom.xml using net.sf.saxon.Query.
	find ./target/ROOT/static/com/atomgraph -type f -name "*.xsl" -exec sh -c 'xmlstarlet c14n "$$1" > "$$1".c14n && mv "$$1".c14n "$$1"' x {} \;
# compile client.xsl to SEF. The output path is mounted in docker-compose.override.yml
	npx xslt3-he -t -xsl:./target/ROOT/static/com/atomgraph/linkeddatahub/xsl/client.xsl -export:./target/ROOT/static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json -nogo -ns:##html5 -relocate:on

# Tear down the stack (including the Varnish cache volumes) and wipe local data
# directories (datasets, Fuseki, SSL certs, uploads) — irreversible!
drop:
	@read -p "Are you sure? [y/N] " ans && [ "$$ans" = "y" ] || { echo "Aborted."; exit 0; }; \
	docker-compose down -v && sudo rm -rf datasets fuseki ssl uploads

# Generate server SSL certificate using the .env config
cert:
	server-cert-gen.sh .env nginx ssl

# Run the full Maven release process (prepare, deploy to Sonatype, merge to master/develop)
release:
	./release.sh

# Set cli/pom.xml to the platform version in pom.xml. The CLI ships with the platform release, so
# the two versions are kept in step; release.sh runs this around the release version bumps, and this
# target is for drift and for manual SNAPSHOT bumps
cli-version:
	@version=$$(mvn -q help:evaluate -Dexpression=project.version -DforceStdout); \
	cd cli && mvn -B -q versions:set -DnewVersion="$$version" -DgenerateBackupPoms=false && \
	echo "cli/pom.xml set to $$version"

# Build the ldh CLI (requires Java 21 and Maven) and print the line that puts it on $PATH.
# Released versions are also attached to the GitHub release, which needs neither.
cli:
	cd cli && mvn -B package
	@echo
	@echo "Add the ldh launcher to your \$$PATH:"
	@echo "    export PATH=\"$(CURDIR)/cli/bin:\$$PATH\""

# Run HTTP tests using owner and secretary certificates with passwords from secrets/.
# The suite builds its fixtures with ldh, so the CLI is built first and put on $PATH for run.sh
tests: cli
	cd http-tests && PATH="$(CURDIR)/cli/bin:$$PATH" ./run.sh ../ssl/owner/cert.pem $$(cat ../secrets/owner_cert_password.txt) ../ssl/secretary/cert.pem $$(cat ../secrets/secretary_cert_password.txt)
