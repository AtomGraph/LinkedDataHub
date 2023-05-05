end_user_endpoint="http://localhost:3031/ds"
export admin_endpoint_url="http://localhost:3030/ds"

envsubst < ../../platform/sitemap/sitemap.rq.template > sitemap.rq

curl -k -G -H "Accept: application/sparql-results+xml" "$end_user_endpoint" --data-urlencode "query@sitemap.rq" -o results.xml

docker run --rm -v "$PWD/../../platform/sitemap/sitemap.xsl":"/transform/sitemap.xsl" -v "$PWD/results.xml":"/transform/results.xml" atomgraph/saxon -s:/transform/results.xml -xsl:/transform/sitemap.xsl