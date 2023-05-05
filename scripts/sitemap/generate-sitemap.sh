base="$1"
endpoint="${1}sparql"

curl -k -G -H "Accept: application/sparql-results+xml" "$endpoint" --data-urlencode "query@../../platform/sitemap/sitemap.rq" -o results.xml

docker run --rm -v "$PWD/../../platform/sitemap/sitemap.xsl":"/transform/sitemap.xsl" -v "$PWD/results.xml":"/transform/results.xml" atomgraph/saxon -s:/transform/results.xml -xsl:/transform/sitemap.xsl