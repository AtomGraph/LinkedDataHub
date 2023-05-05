# This script directly queries the fuseki-end-user endpoint exposed on localhost:3030. You can configure in docker-compose.override.yml like this:
#  fuseki-end-user:
#    ports:
#      - 3031:3030

end_user_endpoint="http://localhost:3031/ds"
export admin_endpoint_url="http://fuseki-admin:3030/ds"

envsubst < ../../platform/sitemap/sitemap.rq.template > sitemap.rq

curl -k -G -H "Accept: application/sparql-results+xml" "$end_user_endpoint" --data-urlencode "query@sitemap.rq" -o results.xml

docker run --rm -v "$PWD/../../platform/sitemap/sitemap.xsl":"/transform/sitemap.xsl" -v "$PWD/results.xml":"/transform/results.xml" atomgraph/saxon -s:/transform/results.xml -xsl:/transform/sitemap.xsl