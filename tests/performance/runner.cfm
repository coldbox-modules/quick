<cfsetting showDebugOutput="false" requestTimeout="600">
<cfscript>
param name="url.warmup"          default="5";
param name="url.samples"         default="9";
param name="url.iterations"      default="25";
param name="url.databaseRows"    default="1000";
param name="url.retainedItems"   default="250";
param name="url.includeDatabase" default="true";
param name="url.includeRetained" default="true";
param name="url.only"            default="";

function boundedInteger(
	required any value,
	required numeric minimum,
	required numeric maximum
) {
	if ( !isNumeric( arguments.value ) ) {
		return arguments.minimum;
	}
	return max( arguments.minimum, min( arguments.maximum, int( arguments.value ) ) );
}

try {
	controller    = request.coldBoxVirtualApp.getController();
	moduleService = controller.getModuleService();
	if ( !moduleService.isModuleRegistered( "qb" ) ) {
		moduleService.registerAndActivateModule( "qb", "root.modules" );
	}
	if ( !moduleService.isModuleRegistered( "quick" ) ) {
		moduleService.registerAndActivateModule( "quick", "testingModuleRoot" );
	}

	result = new tests.performance.QuickBenchmarkSuite(
		wirebox = controller.getWireBox(),
		config  = {
			"warmupIterations" : boundedInteger( url.warmup, 0, 1000 ),
			"samples"          : boundedInteger( url.samples, 1, 100 ),
			"iterations"       : boundedInteger( url.iterations, 1, 10000 ),
			"databaseRows"     : boundedInteger( url.databaseRows, 1, 10000 ),
			"retainedItems"    : boundedInteger( url.retainedItems, 1, 10000 ),
			"includeDatabase"  : isBoolean( url.includeDatabase ) && url.includeDatabase,
			"includeRetained"  : isBoolean( url.includeRetained ) && url.includeRetained,
			"only"             : url.only
		}
	).run();
	responseStatus = 200;
} catch ( any e ) {
	responseStatus = 500;
	result         = {
		"error"   : true,
		"type"    : e.type,
		"message" : e.message,
		"detail"  : e.detail
	};
}
</cfscript>
<cfheader statuscode="#responseStatus#">
<cfcontent type="application/json; charset=utf-8" reset="true"><cfoutput>#serializeJSON( result )#</cfoutput>
