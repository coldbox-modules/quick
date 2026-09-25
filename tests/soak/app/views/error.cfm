<cfscript>
// ColdBox's normal bootstrap exception path invokes Api.onException, then this template.
// renderData alone is not marshalled by Bootstrap.processException().
cfheader( statusCode=event.getRenderData().statusCode );
cfcontent( type="application/json", reset=true );
writeOutput( serializeJSON( event.getRenderData().data ) );
</cfscript>
