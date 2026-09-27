# LinkedDataHub-only targets. The canonical Makefile includes this file last and lists these
# names in LOCAL_TARGETS, which both marks them .PHONY and takes `sef` over from the shared
# recipe.

# Build the webapp and compile the platform's own client.xsl to a SEF. Unlike a deployment's
# `sef`, this one has the stylesheet source at hand and needs no image.
sef:
	mvn war:war
# expand entities in XSLT stylesheets. Same logic as in pom.xml using net.sf.saxon.Query.
	find ./target/ROOT/static/com/atomgraph -type f -name "*.xsl" -exec sh -c 'xmlstarlet c14n "$$1" > "$$1".c14n && mv "$$1".c14n "$$1"' x {} \;
# compile client.xsl to SEF. The output path is mounted in docker-compose.override.yml
	npx xslt3-he -t -xsl:./target/ROOT/static/com/atomgraph/linkeddatahub/xsl/client.xsl -export:./target/ROOT/static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json -nogo -ns:##html5 -relocate:on

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

# Install the Playwright runner and its browser. Separate from ui-tests so the common path
# does not pay for a dependency resolution it almost never needs.
ui-tests-install:
	cd ui-tests && npm ci && npx playwright install chromium

# Drive the browser UI against the running stack. Like the HTTP suite it builds its fixtures
# with ldh, so the CLI is built first and put on $PATH; unlike it, it needs the stack to have
# been published with `make sef` first - the preflight says so if it has not.
ui-tests: cli
	cd ui-tests && PATH="$(CURDIR)/cli/bin:$$PATH" npx playwright test
