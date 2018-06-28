xquery version "3.1";

module namespace manuscript="http://exist-db.org/apps/documentidamore/controllers/manuscript";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://exist-db.org/apps/documentidamore/config" at "config.xqm";

declare function manuscript:resourceName($label, $carta, $layer) {
    concat("/db/apps/app-documentidamore/data/zone_", $label, "_", $carta, "_", $layer/data(), ".xml")
};

declare function manuscript:data($label, $carta) {
    let $manifest := doc("/db/apps/app-documentidamore/data/manifest.xml")
    return
        (: Here the data struct for the manuscript :)
        element data {
            attribute label { $label },
            attribute carta { $carta },

            let $prevCanvas := $manifest//canvas[@label=$label]/preceding-sibling::canvas[1]
            return
                if ($prevCanvas and $prevCanvas/@label/data() != "") then
                    attribute prevLabel { $prevCanvas/@label/data() }
                else
                    (),

            let $nextCanvas := $manifest//canvas[@label=$label]/following-sibling::canvas[1]
            return
                if ($nextCanvas and $nextCanvas/@label/data() != "") then
                    attribute nextLabel { $nextCanvas/@label/data() }
                else
                    (),

            (: Let's take the canvas data from the manifest.xml :)
            let $canvas := $manifest//canvas[@label=$label]
            return $canvas,

            (: Facsimile :)
            element facsimile {
                for $layer in $config:manuscript-layers
                return
                    let $resource := manuscript:resourceName($label, $carta, $layer)
                    let $obj := doc($resource)
                    return $obj//tei:surface
            },

            (: here the text :)
            element text {
                for $layer in $config:manuscript-layers
                return
                    let $resource := manuscript:resourceName($label, $carta, $layer)
                    let $obj := doc($resource)
                    return $obj//tei:text//tei:body
            }
        }
};

declare function manuscript:currentData() {
    let $id := request:get-parameter("id", $config:first-manuscript-id/data())
    let $carta := request:get-parameter("carta", $config:first-manuscript-id/@carta)
    return manuscript:data($id, $carta)
};

declare function manuscript:viewImage($node as node(), $model as map(*)) {
    let $data := manuscript:currentData()
    let $pct :=
        if ($data/@carta/data() = $config:manuscript-recto) then
            "pct:0,0,50,100"
        else
            "pct:50,0,50,100"
    return
        element img {
            attribute src {
                concat($data//canvas[1]/image/data(), "/", $pct, "/800,/0/default.jpg?", $data/@carta/data())
            }
        }
};

declare function manuscript:viewText($node as node(), $model as map(*)) {
    let $data := manuscript:currentData()
    return
        element div {
            attribute class { "card-block" },

            for $layer in $config:manuscript-layers
            return (
                element h3 { $layer/@name/data() },
                element div { $data/text/tei:body/tei:div[@type=$layer] }
            )
        }
};

declare function manuscript:viewPages($node as node(), $model as map(*)) {
    let $data := manuscript:currentData()
    return
        element ul {
            attribute class { "pagination" },
            if ($data/@carta = $config:manuscript-verso) then
                element li {
                    attribute class { "page-item" },
                    element a {
                        attribute class { "page-link" },
                        attribute href { concat("index.html?id=", $data/@label, "&amp;carta=", $config:manuscript-recto) },
                        "Previous"
                    }
                }
            else if ($data/@prevLabel) then
                element li {
                    attribute class { "page-item" },
                    element a {
                        attribute class { "page-link" },
                        attribute href { concat("index.html?id=", $data/@prevLabel) },
                        "Previous"
                    }
                }
            else
                (),

            if ($data/@carta = $config:manuscript-recto) then
                element li {
                    attribute class { "page-item" },
                    element a {
                        attribute class { "page-link" },
                        attribute href { concat("index.html?id=", $data/@label, "&amp;carta=", $config:manuscript-verso) },
                        "Next"
                    }
                }
            else if ($data/@nextLabel) then
                element li {
                    attribute class { "page-item" },
                    element a {
                        attribute class { "page-link" },
                        attribute href { concat("index.html?id=", $data/@nextLabel) },
                        "Next"
                    }
                }
            else
                ()
        }
};
