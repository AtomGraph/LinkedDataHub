#!/bin/bash
set -e

echo "=== Tentris GSP Test ==="

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    docker stop tentris-test 2>/dev/null || true
    docker rm tentris-test 2>/dev/null || true
    rm -f test-data.nt
}

# Set trap for cleanup on exit (commented out for debugging)
# trap cleanup EXIT

# Start Tentris container
echo "Starting Tentris container..."
docker run -d \
    --name tentris-test \
    -p 19080:9080 \
    -v "$PWD/tentris-license.toml:/config/tentris-license.toml:ro" \
    ghcr.io/tentris/tentris:latest

# Wait for Tentris to start
echo "Waiting for Tentris to start..."
sleep 5

# Check container status
echo "Checking container status..."
docker ps -a | grep tentris-test

echo "Checking container logs..."
docker logs tentris-test

# Check if Tentris is responding
echo "Testing Tentris endpoints..."
for i in {1..10}; do
    echo "Attempt $i: Testing root endpoint..."
    if curl -s http://localhost:19080/ >/dev/null 2>&1; then
        echo "Tentris is responding!"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "Tentris not responding after 10 attempts"
        echo "Container logs:"
        docker logs tentris-test
        exit 1
    fi
    sleep 2
done

# Create sample N-Triples data
echo "Creating sample N-Triples data..."
cat > test-data.nt << 'EOF'
<https://example.org/person1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://schema.org/Person> .
<https://example.org/person1> <https://schema.org/name> "John Doe" .
<https://example.org/person1> <https://schema.org/age> "30" .
<https://example.org/person2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://schema.org/Person> .
<https://example.org/person2> <https://schema.org/name> "Jane Smith" .
EOF

echo "Sample data:"
cat test-data.nt
echo ""

# Test basic Tentris endpoints
echo "=== Testing Tentris endpoints ==="
echo "1. Testing root endpoint..."
curl -v http://localhost:19080/ || echo "Root endpoint failed"
echo ""

echo "2. Testing /graph-store endpoint..."
curl -v -X GET http://localhost:19080/graph-store || echo "Graph-store GET failed"
echo ""

# Test GSP POST request (same as our entrypoint)
echo "=== Testing GSP POST request ==="
graph_uri="<https://example.org/test-graph>"
graph_store_url="http://localhost:19080/graph-store"

echo "Graph URI: $graph_uri"
echo "Graph Store URL: $graph_store_url"
echo "Content-Type: application/n-triples"
echo ""

echo "Making GSP POST request..."
curl -v \
    --url-query "graph=$graph_uri" \
    "$graph_store_url" \
    -H "Content-Type: application/n-triples" \
    --data-binary @test-data.nt

echo ""
echo "=== Test completed ==="