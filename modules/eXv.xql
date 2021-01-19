xquery version "3.1";

module namespace eXv="http://annotation.de.dariah.eu/eXanore-viewer/main";
import module namespace eXgroups="http://annotation.de.dariah.eu/eXanore-viewer/groups" at "groups.xql";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://annotation.de.dariah.eu/eXanore-viewer/config" at "config.xqm";

declare function eXv:table($node as node(), $model as map(*), $groupId){
let $userId := request:get-attribute("userId")
let $items := 
    if(string($groupId) != "" and eXgroups:check4member($groupId))
    then
        for $id in eXgroups:getGroup($groupId)//eXgroups:annotation/string(@id)
        where $id != ""
        return
            collection( $config:data-root )//item[@type="object"][pair[@name="id"]/string(.) = $id]
    else
        collection($config:data-root)//pair
            [@name="admin"]
            [string(./item) = $userId]
                /ancestor::item[@type="object"]

let $colums :=
        <tr>
            <th>#</th>
            <th>URL</th>
            <th>Comment</th>
            <th>Tag</th>
            <th>Quote</th>
            <th>Created</th>
            <th>Modified</th>
            <th>Groups</th>
        </tr>
return
<table id="annoTable" class="table" cellspacing="0" width="100%" 
    data-select="true"
    data-paging="false">
    <thead>
        {$colums}
    </thead>
    <tfoot>
        {$colums}
    </tfoot>
    <tbody>
        {   for $anno at $pos in $items
            let $uri := string($anno/pair[@name="uri"][1])
(:            let $displayURL := :)
(:                        string-join(tokenize( :)
(:                            tokenize( :)
(:                                substring-after($uri, "://"), '/':)
(:                            )[1]:)
(:                        , '\.')[position() gt (last() - 4)], '.'):)
            let $resource := substring-after($anno/base-uri(), $config:data-root || "/")
            let $created := xmldb:created($config:data-root, $resource)
            let $lastMod := xmldb:last-modified($config:data-root, $resource)
            let $groups := eXgroups:getAnnotationGroupNames(  string($anno/pair[@name="id"][1]) )
            return
                <tr id="{string($anno//pair[@name="id"][1])}">
                    <th>{$pos}</th>
                    <th><a href="{$uri}">{substring-after($uri, '://')}</a></th>
                    <th>{$anno//pair[@name="text"]/text()}</th>
                    <th>{$anno//pair[@name="tags"]/item/string(.)}</th>
                    <th><span class="trunc">{string($anno//pair[@name="quote"])}</span></th>
                    <th>{$created}</th>
                    <th>{if( $lastMod = $created ) then () else $lastMod}</th>
                    <th>{string-join( $groups, ", " )}</th>
                </tr>
        }
    </tbody>
</table>
};
