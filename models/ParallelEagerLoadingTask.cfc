/**
 * Retrieves and hydrates one prepared top-level eager-loading branch.
 * Relationship preparation and parent matching remain on the calling thread.
 */
component {

	function init(
		required struct plan,
		required string name,
		required any coordinator,
		required any requestContext,
		required struct applicationSettings,
		required any completionQueue
	) {
		variables.plan                = arguments.plan;
		variables.name                = arguments.name;
		variables.coordinator         = arguments.coordinator;
		variables.requestContext      = arguments.requestContext;
		variables.applicationSettings = arguments.applicationSettings;
		variables.completionQueue     = arguments.completionQueue;
		return this;
	}

	public void function run() {
		// ColdBox's BoxLang executor context retains the caller's request scope.
		// Enter a fresh application request so concurrent workers cannot overwrite
		// each other's ColdBox RequestContext.
		if ( server.keyExists( "boxlang" ) ) {
			runThreadInContext(
				applicationName = getApplicationMetadata().name,
				callback        = function() {
					if ( variables.applicationSettings.keyExists( "datasource" ) ) {
						application
							action    ="update"
							mappings  =variables.applicationSettings.mappings
							datasource=variables.applicationSettings.datasource;
					} else {
						application action="update" mappings=variables.applicationSettings.mappings;
					}
					execute();
				}
			);
			return;
		}
		execute();
	}

	private void function execute() {
		var requestContextInstalled = false;
		var workerEntered           = false;
		try {
			request.cb_requestContext = variables.requestContext;
			requestContextInstalled   = true;
			variables.coordinator.enterWorker( variables.name );
			workerEntered = true;
			var rows      = variables.plan.relation.retrieveEagerRows();
			variables.completionQueue.offer( {
				"name"    : variables.name,
				"results" : variables.plan.relation.hydrateEagerRows( rows ),
				"success" : true
			} );
		} catch ( any e ) {
			variables.completionQueue.offer( {
				"name"    : variables.name,
				"success" : false,
				"error"   : e
			} );
		} finally {
			if ( workerEntered ) {
				variables.coordinator.leaveWorker();
			}
			if ( requestContextInstalled ) {
				structDelete( request, "cb_requestContext" );
			}
		}
	}

}
