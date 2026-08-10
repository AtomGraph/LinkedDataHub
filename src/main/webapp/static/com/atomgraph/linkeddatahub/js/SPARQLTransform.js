/**
 *  Copyright 2026 Martynas Jusevičius <martynas@atomgraph.com>
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

/*
 * Client-side SPARQL CONSTRUCT execution, replacing the former server-side /transform endpoint.
 * Runs a CONSTRUCT query over a Linked Data source entirely in the browser and returns the result
 * serialized as Turtle, ready to be appended to the target document over the Graph Store Protocol.
 *
 * The (large) SPARQL engine bundle is loaded lazily on first use, so it is fetched only when an
 * agent actually runs a transform, never on ordinary page loads.
 */
"use strict";

window.LinkedDataHub = window.LinkedDataHub || {};

(function(ldh)
{
    var enginePromise = null;

    // inject the engine bundle once and resolve with a query engine when its global is ready
    function loadEngine(engineSrc)
    {
        if (enginePromise) return enginePromise;

        enginePromise = new Promise(function(resolve, reject)
        {
            if (window.Comunica && window.Comunica.QueryEngine)
            {
                resolve(new window.Comunica.QueryEngine());
                return;
            }

            var script = document.createElement("script");
            script.src = engineSrc;
            script.onload = function()
            {
                if (window.Comunica && window.Comunica.QueryEngine) resolve(new window.Comunica.QueryEngine());
                else reject(new Error("SPARQL engine loaded but Comunica.QueryEngine is undefined"));
            };
            script.onerror = function() { reject(new Error("Failed to load SPARQL engine bundle: " + engineSrc)); };
            document.head.appendChild(script);
        });

        return enginePromise;
    }

    // read the serializer's output (a Node-style readable stream, or an async iterable) into a string
    function readToString(data)
    {
        if (data && typeof data.on === "function")
        {
            return new Promise(function(resolve, reject)
            {
                var text = "";
                data.on("data", function(chunk) { text += chunk; });
                data.on("end", function() { resolve(text); });
                data.on("error", reject);
            });
        }

        return (async function()
        {
            var text = "";
            for await (var chunk of data) text += chunk;
            return text;
        })();
    }

    /*
     * Run a CONSTRUCT query over the RDF source at sourceURL and resolve with the result as Turtle.
     * sourceURL must be same-origin (route external sources through the ?uri= proxy) to avoid CORS;
     * the engine fetches, content-negotiates and parses it, so any Jena-serializable format works.
     */
    ldh.construct = function(engineSrc, sourceURL, queryString)
    {
        return loadEngine(engineSrc).then(function(engine)
        {
            return engine.query(queryString, { sources: [ sourceURL ] }).then(function(result)
            {
                return engine.resultToString(result, "text/turtle").then(function(serialized)
                {
                    return readToString(serialized.data);
                });
            });
        });
    };

})(window.LinkedDataHub);
