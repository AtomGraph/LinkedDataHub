# build WAR file

mvn war:war

# expand entities in XSLT stylesheets. Same logic as in pom.xml using net.sf.saxon.Query.

find ./target/ROOT/static/com/atomgraph  -type f -name "*.xsl" -exec sh -c 'xmlstarlet c14n "$1" > "$1".c14n && mv "$1".c14n "$1"' x {} \;

# compile client.xsl to SEF. The output path is mounted in docker-compose.override.yml

npx xslt3 -t -xsl:./target/ROOT/static/com/atomgraph/linkeddatahub/xsl/client.xsl -export:./target/ROOT/static/com/atomgraph/linkeddatahub/xsl/client.xsl.sef.json -nogo -ns:##html5