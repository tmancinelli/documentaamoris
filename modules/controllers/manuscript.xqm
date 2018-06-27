xquery version "3.1";

module namespace manuscript="http://exist-db.org/apps/documentidamore/controllers/manuscript";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://exist-db.org/apps/documentidamore/config" at "config.xqm";

declare function manuscript:resourceName($label, $carta, $layer) {
    concat("/db/apps/app-documentidamore/data/zone_", $label, "_", $carta, "_", $layer/data(), ".xml")
};

declare function manuscript:data($label, $carta) {
    (: Here the data struct for the manuscript :)
    element data {
        attribute label { $label },
        attribute prevLabel {
            let $manifest := doc("/db/apps/app-documentidamore/data/manifest.xml")
            let $canvas := $manifest//canvas[@label=$label]/preceding-sibling::canvas[1]
            return $canvas/@label
        },
        
        attribute nextLabel {
            let $manifest := doc("/db/apps/app-documentidamore/data/manifest.xml")
            let $canvas := $manifest//canvas[@label=$label]/following-sibling::canvas[1]
            return $canvas/@label
        },
        
        (: Let's take the canvas data from the manifest.xml :)
        let $manifest := doc("/db/apps/app-documentidamore/data/manifest.xml")
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
    let $id := request:get-parameter("id", $config:first-manuscript-id)
    let $carta := request:get-parameter("carta", $config:manuscript-recto)
    return manuscript:data($id, $carta)
};

declare function manuscript:viewImage($node as node(), $model as map(*)) {
    let $data := manuscript:currentData()
    return
        element img {
            attribute src {
                concat($data//canvas[1]/image/data(), "/full/full/0/default.jpg")
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