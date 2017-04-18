xquery version "3.0";

import module namespace jwt="http://de.dariah.eu/ns/exist-jwt-module";
import module namespace exanoreParam="http://www.eXanore.com/param" at "../eXanore/modules/params.xqm" ;

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $authToken := string(request:get-cookie-value("dariahAnnotationToken"));
declare variable $authTokenInParameter :=
    if(
        $authToken = "" and request:get-parameter-names() = "dariahAnnotationToken")
    then request:get-parameter("dariahAnnotationToken", "1")
    else $authToken;
declare variable $user := jwt:verify( $authTokenInParameter, $exanoreParam:JwtSecret);

    if ($exist:path eq '') then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{request:get-uri()}/"/>
        </dispatch>

    else if ($exist:path eq "/") then
        (: forward root path to index.html :)
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="index.html"/>
        </dispatch>
    else
        if($user/@valid = "true") then
            if (ends-with($exist:resource, ".html")) then
            (: the html page is run through view.xql to expand templates :)
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <set-attribute name="userId" value="{string($user//jwt:userId)}"/>
                        <set-attribute name="displayName" value="{string($user//jwt:displayName)}"/>
                        <set-attribute name="memberOf" value="{string($user//jwt:memberOf)}"/>
                    </forward>
                </view>
        		<error-handler>
        			<forward url="{$exist:controller}/error-page.html" method="get"/>
        			<forward url="{$exist:controller}/modules/view.xql"/>
        		</error-handler>
            </dispatch>
        (: Resource paths starting with $shared are loaded from the shared-resources app :)
        else if (contains($exist:path, "/$shared/")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
                    <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
                </forward>
            </dispatch>
(:        else if (contains($exist:path, "resources/")) then:)
(:            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">:)
(:                <forward url="templates/resources/{substring-after($exist:path, '/resources/')}">:)
(:                    <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>:)
(:                </forward>:)
(:            </dispatch>:)
        else
            (: everything else is passed through :)
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <cache-control cache="yes"/>
            </dispatch>
    else
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="https://annotation.de.dariah.eu/secure/getJWT.php?return=%2FAnnotationViewer{encode-for-uri( substring-after(request:get-url(), $exist:controller) || "?" || request:get-query-string() )}"/>
            </dispatch>
