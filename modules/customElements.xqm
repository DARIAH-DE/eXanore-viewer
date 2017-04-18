xquery version "3.1";
module namespace customElements="http://annotation.de.dariah.eu/eXanore-viewer/customElements";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";


declare function customElements:prepare($node as node(), $model as map(*), $uri as xs:string) {
    let $data := doc("https://textgridlab.org/1.0/tgcrud-public/rest/" || $uri || "/data")
    let $node := $node/parent::*/parent::*
    return
        local:transform($data/*, name($data/*))
};

(:~
 : recursive transformation of XML-Nodes
 :   :)
declare function local:transform($nodes as node()*, $root as xs:string) as node()* {
for $node in $nodes
return
    typeswitch ( $node )
        case attribute( * ) return $node
        case text() return $node
        default return
            element
                { $root || "-" || local-name($node) }
                {   $node/@*,
                    attribute { "data-info" } { string-join($node/ancestor-or-self::*/local-name(.), "/") },
                    local:transform($node/node(), $root) }
};
