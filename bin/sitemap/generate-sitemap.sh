# This script directly queries the fuseki-admin and fuseki-end-user endpoints exposed on localhost, as the entrypoint does
# inside the stack. You can expose them in docker-compose.override.yml like this:
#  fuseki-admin:
#    ports:
#      - 3030:3030
#  fuseki-end-user:
#    ports:
#      - 3031:3030
#
# One dataspace per run, because a sitemap may only list the documents of the origin serving it. Pass that origin:
#  ./generate-sitemap.sh https://northwind-traders.demo.localhost:4443

origin="${1:-https://localhost:4443}"
admin_origin=$(echo "$origin" | sed 's|://|://admin.|')

admin_endpoint="http://localhost:3030/ds/"
end_user_endpoint="http://localhost:3031/ds/"

admin_base="${admin_origin}/" envsubst '$admin_base' < ../../platform/sitemap/public-rules.rq > public-rules.rq

curl -k -f -sS -H "Content-Type: application/sparql-query" -H "Accept: application/sparql-results+xml" --data-binary @public-rules.rq "$admin_endpoint" -o public-rules.xml

class_rules=$(xmlstarlet sel -N srx="http://www.w3.org/2005/sparql-results#" -T -t -m "/srx:sparql/srx:results/srx:result[srx:binding[@name = 'Type']/srx:uri]" -o "<" -v "srx:binding[@name = 'Type']/srx:uri" -o "> " public-rules.xml)
document_rules=$(xmlstarlet sel -N srx="http://www.w3.org/2005/sparql-results#" -T -t -m "/srx:sparql/srx:results/srx:result[srx:binding[@name = 'to']/srx:uri]" -o "<" -v "srx:binding[@name = 'to']/srx:uri" -o "> " public-rules.xml)

base="${origin}/" class_rules="$class_rules" document_rules="$document_rules" envsubst '$base $class_rules $document_rules' < ../../platform/sitemap/sitemap.rq.template > sitemap.rq

curl -k -f -sS -H "Content-Type: application/sparql-query" -H "Accept: application/sparql-results+xml" --data-binary @sitemap.rq "$end_user_endpoint" -o results.xml

docker run --rm -v "$PWD/../../platform/sitemap/sitemap.xsl":"/transform/sitemap.xsl" -v "$PWD/results.xml":"/transform/results.xml" atomgraph/saxon -s:/transform/results.xml -xsl:/transform/sitemap.xsl
