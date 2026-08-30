TARGETS := sef drop cert release tests up
.PHONY: $(TARGETS)

# Treat goals that are not targets as arguments for docker-compose, not as make goals
ifneq (,$(filter up,$(MAKECMDGOALS)))
UP_ARGS := $(filter-out $(TARGETS),$(MAKECMDGOALS))
$(eval $(UP_ARGS):;@:)
endif

# Start the Docker Compose stack; extra arguments are passed to `docker-compose up`
# (e.g. `make up -- --build -d`, `make up nginx`, or `make up ARGS="--build -d"`)
up:
	docker-compose up $(ARGS) $(UP_ARGS)

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

# Run HTTP tests using owner and secretary certificates with passwords from secrets/
tests:
	cd http-tests && ./run.sh ../ssl/owner/cert.pem $$(cat ../secrets/owner_cert_password.txt) ../ssl/secretary/cert.pem $$(cat ../secrets/secretary_cert_password.txt)
