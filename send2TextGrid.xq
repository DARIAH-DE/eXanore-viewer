xquery version "3.1";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace config="http://annotation.de.dariah.eu/eXanore-viewer/config" at "modules/config.xqm";

declare namespace http="http://expath.org/ns/http-client"; 
declare namespace tgmd="http://textgrid.info/namespaces/metadata/core/2010";

(: 
 : TextGrid CRUD
 : Store nodes in the TextGrid Repository
 : https://textgridlab.org/doc/services/submodules/tg-crud/docs/index.html#create
 :  :)
declare function local:createData( $sessionId, $projectId, $tgcrudURL, $title, $format, $data) as node() {
let $url := $tgcrudURL || "?sessionId=" || $sessionId || "&amp;projectId=" || $projectId

let $objectMetadata :=    <tgmd:tgObjectMetadata
                            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                            xsi:schemaLocation="http://textgrid.info/namespaces/metadata/core/2010
                            http://textgridlab.org/schema/textgrid-metadata_2010.xsd">
                                  <tgmd:object>
                                     <tgmd:generic>
                                        <tgmd:provided>
                                           <tgmd:title>{$title}</tgmd:title>
                                           <tgmd:format>{$format}</tgmd:format>
                                        </tgmd:provided>
                                     </tgmd:generic>
                                     <tgmd:item />
                                  </tgmd:object>
      </tgmd:tgObjectMetadata>

let $objectData := $data

let $request :=
    <http:request method="POST" href="{$url}" http-version="1.0">
        <http:multipart media-type="multipart/form-data" boundary="xYzBoundaryzYx">
            <http:header name="Content-Disposition" value='form-data; name="tgObjectMetadata";'/>
            <http:header name="Content-Type" value="text/xml"/>
            <http:body media-type="application/xml">{$objectMetadata}</http:body>
            <http:header name="Content-Disposition" value='form-data; name="tgObjectData";'/>
            <http:header name="Content-Type" value="application/octet-stream"/>
            <http:body media-type="{$format}">{$objectData}</http:body>
        </http:multipart> 
    </http:request>
let $response := http:send-request($request)

return
    if( $response/@status = "200" ) then $response//tgmd:MetadataContainerType
	else <error> <status>{$response/@status}</status> <message>{$response/@message}</message> </error>
};

let $sessionId := request:get-parameter("sessionId", "0")
let $projectId := request:get-parameter("projectId", "0")
let $tgcrudURL := "https://textgridlab.org/1.0/tgcrud/rest/create"
let $data := <AnnotationExport>
    {for $anno in tokenize(request:get-parameter("annos", "0"), ',')
    let $file := collection( $config:data-root )//pair[@name="id"][string(.) = $anno]/ancestor::item[@type="object"]
    return
        $file
    }
</AnnotationExport>
let $title := "Annotation Export"
let $format := "text/xml"
return
    local:createData($sessionId, $projectId, $tgcrudURL, $title, $format, $data)