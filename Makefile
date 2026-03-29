.PHONY: sef drop cert release tests

# Generate Saxon-JS SEF files for client-side XSLT transformations
sef:
	./generate-sef.sh

# Wipe local data directories (datasets, Fuseki, SSL certs, uploads) — irreversible!
drop:
	@read -p "Are you sure? [y/N] " ans && [ "$$ans" = "y" ] && sudo rm -rf datasets fuseki ssl uploads || echo "Aborted."

# Generate server SSL certificate using the .env config
cert:
	server-cert-gen.sh .env nginx ssl

# Run the full Maven release process (prepare, deploy to Sonatype, merge to master/develop)
release:
	./release.sh

# Run HTTP tests using owner and secretary certificates with passwords from secrets/
tests:
	cd http-tests && ./run.sh ../ssl/owner/cert.pem $$(cat ../secrets/owner_cert_password.txt) ../ssl/secretary/cert.pem $$(cat ../secrets/secretary_cert_password.txt)
