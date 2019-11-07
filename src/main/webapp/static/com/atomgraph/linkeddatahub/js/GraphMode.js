/* global d3 */

// https://bl.ocks.org/mbostock/533daf20348023dfdd76
// https://bl.ocks.org/mbostock/950642
// https://bl.ocks.org/mbostock/1095795
// https://bl.ocks.org/mbostock/3355967

window.GraphMode = GraphMode = function(container, width, height) {
    this.APPLICATION_LD_JSON = "application/ld+json";
    this.width = width,
    this.height = height;
    this.minRadius = 15;
    this.maxRadius = 30;
    this.force = d3.layout.force();
    this.force.size([this.width, this.height])
        .charge(-400)
        .gravity(0.5)
        //.on("tick", tick)
        .linkStrength(0.5)
        .linkDistance(this.width / 3);
    this.svg = d3.select(container).append("svg:svg")
        //.attr("width", width)
        //.attr("height", height);
        .attr("viewBox", "0 0 " + width + " " + height)
        .attr("preserveAspectRatio", "xMidYMid meet");
    this.maxOutDegree = 0;
};

GraphMode.prototype.outDegree = function(node, links)
{
    return links.filter(function(link) // this.force.links().filter(...
    {
        return link.source["@id"] === node["@id"];
    }).length;
};

GraphMode.prototype.radius = function(node)
{
    var scale = d3.scale.linear().domain([0, this.maxOutDegree]).range([this.minRadius, this.maxRadius]);
    return scale(this.outDegree(node, this.force.links()));
};

GraphMode.prototype.load = function(uri)
{
    new Client($).resource(uri).accept(this.APPLICATION_LD_JSON).get($.proxy(this.responseHandler, this));
};

GraphMode.prototype.start = function(nodes, links)
{
    this.force.nodes(this.force.nodes().concat(nodes));
    this.force.links(this.force.links().concat(links));

    console.log(this.force.nodes());
    console.log(this.force.links());
    
    var link = this.svg.selectAll(".link")
        .data(this.force.links(), function(d) { return d.source["@id"] + d["property"] + d.target["@id"]; })
        .enter().append("svg:line")
        .attr("class", "link");

    //link.append("svg:title")
    //    .text(function(d) { console.log(d); return d["@id"]; });

    var node = this.svg.selectAll(".node")
        .data(this.force.nodes(), function (d) { return d["@id"]; } )
        .enter().append("svg:g")
        .attr("class", "node")
        .on("click", $.proxy(this.nodeClick, this))
        .call(this.force.drag);

    node.append("svg:title")
        .text(function(d) { return d["@id"]; });

    node.append("svg:circle")
        //.attr("r", width / 70);
        .attr("r", $.proxy(this.radius, this));

    node.append("svg:text")
        .attr("dx", 0)
        .attr("dy", ".35em")
        .text(function(d) { return d["dc:title"]; });

    this.force.on("end", function() {
        node.attr("transform", function(d) { return "translate(" + d.x + ","+ d.y + ")"; });

        link.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });
    });

    this.force.start();
};

GraphMode.prototype.nodeClick = function(node, i)
{
    this.load(node["@id"]);
};

GraphMode.prototype.responseHandler = function(uri, clientResponse)
{
    var nodes = new Array();
    var links = new Array();
    var nodeById = d3.map();
    
    clientResponse.getEntity()["@graph"].forEach(function(resource)
    {
        if (resource.hasOwnProperty("@id") &&
            !resource.hasOwnProperty("pageOf") && !resource.hasOwnProperty("viewOf") && !resource.hasOwnProperty("constructorOf"))
        {
            if (!nodeById.has(resource["@id"])) nodes.push(resource);
            nodes.forEach(function(node) {
              nodeById.set(node["@id"], node);
            });
            
            for (var property in resource)
                if (resource.hasOwnProperty(property) && resource[property]["@id"] &&
                        property !== "inDataset") // what about literals?
                {
                    //console.log(property);
                    // add new node if one with such ID does not exist
                    if (!nodeById.has(resource[property]["@id"])) nodes.push({ "@id": resource[property]["@id"] });
                    links.push({ "source": resource["@id"], "property": property, "target": resource[property]["@id"] });
                }
        }
    });

    nodes.forEach(function(node)
    {
        nodeById.set(node["@id"], node);
    });
    //console.log(nodes);
    
    links.forEach(function(link) {
      link.source = nodeById.get(link.source);
      link.target = nodeById.get(link.target);
    });

    var nodeOutDegrees = d3.map();
    nodes.forEach($.proxy(function(node)
    {
        nodeOutDegrees.set(node["@id"], this.outDegree(node, links));
    }), this);
    this.maxOutDegree = d3.max(nodeOutDegrees.values());
    //console.log("Max out-degree: " + this.maxOutDegree);    

    this.start(nodes, links);
};