/**
 * Coordinates parallel eager-loading work on Quick's application-wide executor.
 */
component singleton {

	property name="executor"       inject="executor:quick-parallel-eager-loading";
	property name="controller"     inject="coldbox";
	property name="requestService" inject="coldbox:requestService";

	function init() {
		variables.currentWorker = createObject( "java", "java.lang.ThreadLocal" ).init();
		return this;
	}

	public any function submit( required any task ) {
		return variables.executor.submit( arguments.task, "run" );
	}

	public any function getExecutor() {
		return variables.executor;
	}

	public any function createWorkerRequestContext() {
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
