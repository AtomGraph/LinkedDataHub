base="$1"
endpoint="${1}sparql"
query=$(cat "sitemap.rq")

curl -k -G -H "Accept: application/sparql-results+xml" "$endpoint" --data-urlencode "query@sitemap.rq" -o results.xml

docker run --rm -v "$PWD/sitemap.xsl":"/transform/sitemap.xsl" -v "$PWD/results.xml":"/transform/results.xml" atomgraph/saxon -s:/transform/results.xml -xsl:/transform/sitemap.xsl