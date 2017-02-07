xquery version "3.1";

import module namespace config="http://annotation.de.dariah.eu/eXanore-viewer/config" at "/db/apps/eXanore-viewer/modules/config.xqm";
declare option exist:serialize "method=text media-type=text/plain omit-xml-declaration=yes";

"TAG; URI; TEXT; TIMESTAMP; NUMBER; QUOTE
",
let $items := collection($config:data-root)//item[@type="object"][//pair[@name="read"]/string(.) = ("ThomasKollatz@dariah.eu", "")]
return
for $i in $items
let $TAG := string-join($i//pair[@name="tags"]/item/string(.), ' ')
let $TAG:= if($TAG = "") then '"empty"' else $TAG
let $URI := ($i//pair[@name="uri"]/string(.))[1]
let $URI := if($URI = "") then '"empty"' else $URI
let $TEXT := $i//pair[@name="text"]/string(.)
let $TEXT := if($TEXT = "") then '"empty"' else $TEXT
let $QUOTE := $i//pair[@name="quote"]/string(.)
let $QUOTE := if($QUOTE = "") then '"empty"' else $QUOTE
let $TIMESTAMP := $i/base-uri() ! xmldb:created(substring-before(., '/eXanore_'), substring-after(., 'annotations/'))
let $NUMBER := count(  $items//pair[@name="uri"][. = $URI]/string(.) )
where not( $QUOTE = $TAG )
return 
    string-join( ($TAG, $URI, $TEXT, $TIMESTAMP, $NUMBER, $QUOTE) , ';' )||"&#10;"