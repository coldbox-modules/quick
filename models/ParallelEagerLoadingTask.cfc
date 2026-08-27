/**
 * Retrieves the database rows for one prepared eager-loading relationship.
 * Relationship preparation and entity hydration remain on the calling thread.
 */
component {

	function init(
		required struct plan,
		required string name,
		required any coordinator,
		required any requestContext,
		required any completionQueue
	) {
		variables.plan            = arguments.plan;
		variables.name            = arguments.name;
		variables.coordinator     = arguments.coordinator;
		variables.requestContext  = arguments.requestContext;
		variables.completionQueue = arguments.completionQueue;
		return this;
	}

	public void function run() {
		var requestContextInstalled = false;
		var workerEntered           = false;
		try {
			request.cb_requestContext = variables.requestContext;
			requestContextInstalled   = true;
			variables.coordinator.enterWorker( variables.name );
			workerEntered = true;
			variables.completionQueue.offer( {
				"name"    : variables.name,
				"success" : true,
				"rows"    : variables.plan.relation.retrieveEagerRows()
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
