# LinkedDataHub's own settings for the canonical Makefile.
#
# This is the platform repository, not a deployment: it builds the image the others run, so it
# has no app to install and compiles its client stylesheet from source rather than from a
# published image. Everything it adds lives in make/local.mk.

LOCAL_TARGETS := sef release rdf cli cli-version tests ui-tests ui-tests-install load-tests

# only the deployment configuration is RDF worth parsing here; the rest of the tree is source
VALIDATE_PATHS := config datasets
