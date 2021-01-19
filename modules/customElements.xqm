xquery version "3.1";
module namespace customElements="http://annotation.de.dariah.eu/eXanore-viewer/customElements";

declare function customElements:prepare($node as node(), $model as map(*), $uri as xs:string) {
    let $prefix := tokenize($uri, ":")[1]

    let $repoUrl := switch ($prefix)
                        case "textgrid" return "https://textgridlab.org/1.0/tgcrud-public/rest/"
                        case "dta" return "http://www.deutschestextarchiv.de/book/download_xml/"
                        case "ota" return "https://ota.bodleian.ox.ac.uk/repository/xmlui/bitstream/handle/20.500.12024/"
                        default return ()

    let $urlUri := switch ($prefix)
                        case "textgrid" return $uri
                        case "dta" return substring-after( $uri, "dta:")
                        case "ota" return substring-after( $uri, "ota:") || "/" || substring-after( $uri, "ota:") || ".xml"
                        default return ()

    let $repoSuffix := switch ($prefix)
                        case "textgrid" return "/data"
                        default return ()

    let $data := doc($repoUrl || $urlUri || $repoSuffix )

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
