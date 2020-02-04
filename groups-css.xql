xquery version "3.1";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://annotation.de.dariah.eu/eXanore-viewer/config" at "modules/config.xqm";
import module namespace exanoreParam="http://www.eXanore.com/param" at "/db/apps/eXanore/modules/params.xqm" ;
import module namespace jwt="http://de.dariah.eu/ns/exist-jwt-module";

declare namespace eXgroups="http://annotation.de.dariah.eu/eXanore-viewer/groups";

declare option exist:serialize "method=text media-type=text/css omit-xml-declaration=yes";

(: will create a CSS with all style infos for all groups on the loded site :)
declare variable $userId := 
    if( request:get-parameter-names() = "userId" )
    then request:get-parameter("userId", "")||"@dariah.eu"
    else
        let $authToken := request:get-cookie-value("dariahAnnotationToken"),
            $authToken := if( string($authToken) = "" ) then "0" else $authToken,
            $user := jwt:verify($authToken, $exanoreParam:JwtSecret),
            $userValid := $user/@valid eq "true"
        return
            string($user//jwt:userId);

declare variable $uri := request:get-header("Referer");
declare variable $groups := collection( $config:grpHome )//eXgroups:group[.//eXgroups:member[@userId = $userId ][not(@hidden)] ];

for $group in $groups
let $color := if( $group//eXgroups:member[@userId = $userId]/@background )
                then string( $group//eXgroups:member[@userId = $userId]/@background )
                else string($group//eXgroups:style/eXgroups:background)
let $ids := for $annotation in $group//eXgroups:annotation/string(@id)
            return
                "span[data-annotation-id="||$annotation||"]"
return
    string-join($ids, ",") || "{background: "|| $color ||";}"