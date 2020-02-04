xquery version "3.1";

module namespace eXgroups="http://annotation.de.dariah.eu/eXanore-viewer/groups";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://annotation.de.dariah.eu/eXanore-viewer/config" at "config.xqm";
import module namespace exanoreParam="http://www.eXanore.com/param" at "../../eXanore/modules/params.xqm" ;

declare function eXgroups:form-action-to-current-url($node as node(), $model as map(*), $groupId) {
    <form action="{substring-after(request:get-uri(), "eXanore-viewer/")}?groupId={$groupId}">{
        $node/attribute()[not(name(.) = 'action')],
        $node/node()
    }</form>
};

declare function eXgroups:getAnnotationGroupNames($annotationId) {
    collection($config:grpHome)//eXgroups:group[(.//eXgroups:annotation/@id) = $annotationId ]/string(@name)
};

declare function eXgroups:groupsAvailable($userId) {
collection($config:grpHome)//eXgroups:group[.//eXgroups:member/@userId = $userId]/string(@id)
};

declare function local:check4admin($group) {
let $userId as xs:string := request:get-attribute("userId")
let $admin := $group/eXgroups:members/eXgroups:member[@role = "admin"]/string(@userId)
return
    $userId = $admin
};

declare function eXgroups:check4member($groupId) {
let $group := eXgroups:getGroup($groupId)
let $userId as xs:string := request:get-attribute("userId")
let $admin := $group/eXgroups:members/eXgroups:member/string(@userId)
return
    $userId = $admin
};


declare function eXgroups:check4adminByGroupId( $groupId ) {
let $group := collection($config:grpHome)//eXgroups:group[@id = $groupId]
let $userId as xs:string := request:get-attribute("userId")
let $admin := $group/eXgroups:members/eXgroups:member[@role = "admin"]/string(@userId)
return
    $userId = $admin
};

declare function eXgroups:nameTmpl($node as node(), $model as map(*), $groupId) {
    eXgroups:name($groupId)
};

declare function eXgroups:name($groupId) {
    collection($config:grpHome)
        //eXgroups:group[@id = $groupId]
            /string(@name)
};

declare function eXgroups:receiver($node as node(), $model as map(*)) {
if( request:get-parameter("todo", "0") = "colorAdmin" )
    then
        let $groupId := request:get-parameter("groupId", "0")
        return
        if( eXgroups:check4adminByGroupId( $groupId ) )
        then
            let $hex := upper-case( replace(request:get-parameter("colorAdmin", "0"), "#", "") )
            let $r := local:hex2int( substring($hex, 1, 2) )
            let $g := local:hex2int( substring($hex, 3, 2) )
            let $b := local:hex2int( substring($hex, 5, 2) )
            let $rgba := "rgba("|| string-join( ($r,$g,$b), "," ) ||",0.5);"
            return
                update replace eXgroups:getGroup( $groupId )//eXgroups:background/text() with $rgba
        else "forbidden"
else if(request:get-parameter("todo", "0") = "colorContributor")
    then
        let $groupId := request:get-parameter("groupId", "0")
        return
        if( eXgroups:check4adminByGroupId( $groupId ) )
        then
            let $hex := upper-case( replace(request:get-parameter("colorContributor", "0"), "#", "") )
            let $r := local:hex2int( substring($hex, 1, 2) )
            let $g := local:hex2int( substring($hex, 3, 2) )
            let $b := local:hex2int( substring($hex, 5, 2) )
            let $rgba := "rgba("|| string-join( ($r,$g,$b), "," ) ||",0.5);"
            return
                update insert  attribute background { $rgba } into eXgroups:getGroup( $groupId )//eXgroups:member[@userId = request:get-attribute("userId")]
        else "forbidden"

else
(: NEW GROUP :)
if( request:get-parameter-names() = "grpName" ) 
    then
    let $grpname := request:get-parameter("grpName", ())
    let $grpMembers := for $i in request:get-parameter("grpMember", ()) where string($i) != "" return $i || "@dariah.eu"
    let $admin := request:get-attribute("userId")
    let $hash :=  util:hash( $grpname || $admin, "md5")
    let $groupId := substring($hash, 1, 7)
    let $createCollection := xmldb:create-collection($config:grpHome, $groupId)
    let $do := if( $createCollection = "collection exists" )
                then ()
                else 
                    let $doc :=
                        <group xmlns="http://annotation.de.dariah.eu/eXanore-viewer/groups" id="{$groupId}" name="{$grpname}">
                            <members>
                                <member userId="{$admin}" role="admin" />
                                { for $member in $grpMembers where $member != $admin return <member userId="{$member}" role="contributor" /> }
                            </members>
                            <style>
                                <background>rgba(255,47,173,0.4);</background>
                            </style>
                            <annotations/>
                        </group>
                    return
                        xmldb:store( $createCollection , "meta.xml", $doc)
    return
        if( $createCollection = "collection exists" )
        then
            <div class="alert alert-danger">
                <strong>Error!</strong> You already set up a group with this name. You might want to edit this.
            </div>
        else 
            <div class="alert alert-success">
                <strong>Success!</strong> Group is set up.
            </div>
else
    if( eXgroups:check4adminByGroupId( request:get-parameter("groupId", "0") ) )
    then
        (: ADD ADMIN :)
        if( request:get-parameter("addAdmin", ()) = "1")
        then
            let $grpMembers := for $i in request:get-parameter("grpMember", ()) where string($i) != "" return $i || "@dariah.eu"
            let $group := collection($config:grpHome)//eXgroups:group[@id = request:get-parameter("groupId", "0")]
            let $contributor := 
                for $member in $grpMembers
                let $node := <member xmlns="http://annotation.de.dariah.eu/eXanore-viewer/groups" userId="{$member}" role="admin" />
                where $group//eXgroups:member/string(@userId) != $member
                return
                    update insert $node into $group//eXgroups:members
            return
                <div class="alert alert-success">
                    admin(s) updated
                </div>
        else
        (: ADD CONTRIBUTOR :)
        if( request:get-parameter("addContributor", ()) = "1")
        then
            let $grpMembers := for $i in request:get-parameter("grpMember", ()) where string($i) != "" return $i || "@dariah.eu"
            let $group := collection($config:grpHome)//eXgroups:group[@id = request:get-parameter("groupId", "0")]
            let $contributor := 
                for $member in $grpMembers
                let $node := <member xmlns="http://annotation.de.dariah.eu/eXanore-viewer/groups" userId="{$member}" role="contributor" />
                where $group//eXgroups:member/string(@userId) != $member
                return
                    update insert $node into $group//eXgroups:members
            return
                <div class="alert alert-success">
                    contributor(s) updated
                </div>
        else ()
else ()
};

declare function eXgroups:groups($node as node(), $model as map(*), $role) {
let $collection := collection($config:grpHome)
let $groups := $collection//eXgroups:group[eXgroups:members/eXgroups:member[@userId = request:get-attribute("userId")][@role = $role ] ]
return
    <ul>
        {for $grp in $groups
            let $id := string($grp/@id)
            let $actions :=
                switch ($role)
                    case "admin" return (<span class="groupActions"><a href="index.html?groupId={$id}">view</a>, <a href="groups-edit.html?groupId={$id}">edit</a></span>) 
                    case "contributor" return (<span class="groupActions"><a href="index.html?groupId={$id}">view</a></span>) 
                    default return ()
            return <li>{string($grp/@name)} [id: { $id }] ({$actions})</li>}
    </ul>
};

declare function eXgroups:manage($node as node(), $model as map(*), $role, $groupId) {
let $group := collection($config:grpHome)//eXgroups:group[@id = $groupId]
return
    if( local:check4admin( $group ) )
    then
        <ul>
            {for $member in $group//eXgroups:member[@role = $role]
            return <li>{string($member/@userId)}</li>}
        </ul>
    else "You are not admin of the group " || $groupId
};

declare function eXgroups:listUserGroups($node as node(), $model as map(*)) {
    let $userId := request:get-attribute("userId")
    let $userGroups := collection($config:grpHome)//eXgroups:group[eXgroups:members/eXgroups:member[@userId = $userId]]
    return
        <ul class="checkGroups">
            {for $group in $userGroups
            let $role := $group/eXgroups:members/eXgroups:member[@userId = $userId]/string(@role)
            return
            <li class="{$role}">
                <div class="checkbox inline">
                  <label><input class="grpId" name="grpId" type="checkbox" value="{$group/string(@id)}"/>{string($group/@name)}</label>
                </div>
            </li>
            }
        </ul>
};

declare function eXgroups:getGroup($groupId) {
    collection($config:grpHome)//eXgroups:group[@id = $groupId]
};

declare function eXgroups:getMember($groupId) {
    collection($config:grpHome)//eXgroups:group[@id = $groupId]//eXgroups:member[@userId = request:get-attribute("userId")]
};

declare function eXgroups:addAnno2Group($node as node(), $model as map(*)) {
let $userId := request:get-attribute("userId")
let $groupsAvailable := eXgroups:groupsAvailable($userId)
let $add2 :=  for $i in request:get-parameter("grpId", ()) where string($i) != "" return $i
let $annotations := tokenize(request:get-parameter("annotations", ()), ",")
return
    for $group in $add2
    return
        if($group = $groupsAvailable)
        then
            let $groupNode := eXgroups:getGroup($group)
            let $annosInGroup:= $groupNode/eXgroups:annotations/eXgroups:annotation/string(@id)
            let $do := for $annotation in $annotations
                        where string( index-of($annosInGroup, $annotation) ) = ""
                        return
                            update insert <annotation xmlns="http://annotation.de.dariah.eu/eXanore-viewer/groups" id="{$annotation}"/> into $groupNode/eXgroups:annotations
            return
            <div class="alert alert-success">
                Added the annotations to {$group}
            </div>
        else
            <div class="alert alert-danger">
                <strong>Error!</strong> You are not allowed to contribute to the selected collection ({$group}).
            </div>
};

declare function eXgroups:colorAdmin($node as node(), $model as map(*), $groupId) {
let $defaultColor := substring-before(substring-after(eXgroups:getGroup($groupId)//eXgroups:background, "rgba("), ")")
let $colors := tokenize($defaultColor, ",")
let $hexVals := for $c in $colors[position() lt 4]
                let $return := local:int2hex( number($c) )
                return
                    if( matches( $return, "^.$" )) then "0"||$return else $return
let $hex := string-join( $hexVals )
return
<div class="form-group">
    { $node/@style }
  <label for="color-input" class="col-2 col-form-label">default color for this group</label>
  <div class="col-10">
    <input class="form-control" type="color" name="colorAdmin" value="#{$hex}" id="color-input-admin"/>
  </div>
</div>
};

declare function eXgroups:colorContributor($node as node(), $model as map(*), $groupId) {
let $defaultColor := substring-before(substring-after(eXgroups:getMember($groupId)/@background, "rgba("), ")")
let $colors := tokenize($defaultColor, ",")
let $hexVals := for $c in $colors[position() lt 4]
                let $return := local:int2hex( number($c) )
                return
                    if( matches( $return, "^.$" )) then "0"||$return else $return
let $hex := string-join( $hexVals )
return
<div class="form-group">
    { $node/@style }
  <label for="color-input" class="col-2 col-form-label">set a personal color for this group</label>
  <div class="col-10">
    <input class="form-control" type="color" name="colorContributor" value="#{$hex}" id="color-input-contributor"/>
  </div>
</div>
};

declare function eXgroups:setGroupInput($node as node(), $model as map(*), $groupId) {
    <input value="{$groupId}">{$node/@*[not( local-name(.) = "data-template" )]}</input>
};

declare function local:hex($number as xs:integer) {
    let $div := floor($number div 16)
    let $mod := $number mod 16
    return
        if( $div = 0 ) then $mod
        else ($mod, local:hex( $div ))
};

declare function local:int2hex($number as xs:integer) {
    let $hexSeq := local:hex($number)
    let $count := count($hexSeq)
    let $seq :=
        for $pos in 1 to $count
        let $valNum := string( $hexSeq[$count + 1 - $pos] )
        let $val := switch ($valNum)
            case "10" return "A"
            case "11" return "B"
            case "12" return "C"
            case "13" return "D"
            case "14" return "E"
            case "15" return "F"
            default return $valNum
        return
            $val
return
    string-join( $seq )
};

declare function local:square($num as xs:integer) {
    $num * $num
};

declare function local:hexString($hex) {
switch ($hex)
    case "A" return 10
    case "B" return 11
    case "C" return 12
    case "D" return 13
    case "E" return 14
    case "F" return 15
    default return number( $hex )
};

declare function local:hex2int($hex as xs:string) {
let $seq0 := tokenize( replace($hex, ".", "$0 "), " " )[. != ""]
let $one := local:hexString($seq0[1])
let $two := local:hexString($seq0[2])
let $seq1 := sum( ($one * 16), $two)
return
    $seq1
};