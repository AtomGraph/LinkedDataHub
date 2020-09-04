#!/bin/bash

pushd . > /dev/null

cd ./target/ROOT/static/com/atomgraph/

find . -type f -name '*.xsl' -exec /bin/bash -c 'xmlstarlet c14n {} > {}.tmp; mv {}.tmp {}' \;

npx xslt3 -t -xsl:./linkeddatahub/xsl/client.xsl -export:./linkeddatahub/xsl/client.xsl.sef.json -nogo -ns:##html5

popd