/**
 * Coordinates parallel eager-loading work on Quick's application-wide executor.
 */
component singleton {

	property name="asyncManager"   inject="AsyncManager@coldbox";
	property name="controller"     inject="coldbox";
	property name="executorName"   inject="box:setting:parallelEagerLoadingExecutor@quick";
	property name="requestService" inject="coldbox:requestService";

	function init() {
		variables.currentWorker = createObject( "java", "java.lang.ThreadLocal" ).init();
		return this;
	}

	public any function submit( required any task ) {
		return getExecutor().submit( arguments.task, "run" );
	}

	public any function getExecutor() {
		return variables.asyncManager.getExecutor( variables.executorName );
	}

	public numeric function getMaximumThreads() {
		return max( 1, getExecutor().getMaximumPoolSize() );
	}

	public struct function getWorkerApplicationSettings() {
		if ( server.keyExists( "boxlang" ) || server.keyExists( "lucee" ) ) {
			var applicationSettings = getApplicationSettings();
			var workerSettings      = { "mappings" : structCopy( applicationSettings.mappings ) };
			if ( applicationSettings.keyExists( "datasource" ) && !isNull( applicationSettings.datasource ) ) {
				workerSettings.datasource = applicationSettings.datasource;
			}
			return workerSettings;
		}
		return {};
	}

	public any function createWorkerRequestContext( required string workerName ) {
		var sourceContext = variables.requestService.getContext();
		var workerContext = createObject( "component", "coldbox.system.web.context.RequestContext" ).init(
			properties = variables.controller.getConfigSettings(),
			controller = variables.controller
		);
		workerContext.collectionAppend( structCopy( sourceContext.getCollection() ), true );
		workerContext.collectionAppend(
			structCopy( sourceContext.getPrivateCollection() ),
			true,
			true
		);
		workerContext.setPrivateValue( "__quickParallelWorkerContextId", arguments.workerName );
		return workerContext;
	}

	public void function enterWorker( required string name ) {
		variables.currentWorker.set( arguments.name );
	}

	public void function leaveWorker() {
		variables.currentWorker.remove();
	}

	public boolean function isWorker() {
		return !isNull( variables.currentWorker.get() );
	}

	public string function getWorkerName() {
		var workerName = variables.currentWorker.get();
		return isNull( workerName ) ? "" : workerName;
	}

}
