/**
 * Provides application-wide admission control for parallel eager-loading work.
 */
component singleton {

	property
		name   ="maxWorkers"
		default="4"
		inject ="box:setting:parallelEagerLoadingMaxThreads@quick";

	function init() {
		param variables.maxWorkers = 4;
		return this;
	}

	function onDIComplete() {
		variables.semaphore = createObject( "java", "java.util.concurrent.Semaphore" ).init(
			javacast( "int", max( 1, int( variables.maxWorkers ) ) ),
			javacast( "boolean", true )
		);
		variables.currentWorker = createObject( "java", "java.lang.ThreadLocal" ).init();
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

	public boolean function acquire( required numeric timeout ) {
		return variables.semaphore.tryAcquire(
			javacast( "long", arguments.timeout ),
			createObject( "java", "java.util.concurrent.TimeUnit" ).MILLISECONDS
		);
	}

	public void function release() {
		variables.semaphore.release();
	}

	public numeric function availablePermits() {
		return variables.semaphore.availablePermits();
	}

}
