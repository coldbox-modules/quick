/**
 * Tracks parallel eager-loading workers without leaking state between threads.
 */
component singleton {

	function init() {
		variables.lifecycleEventsSuppressed = createObject( "java", "java.lang.ThreadLocal" ).init();
		return this;
	}

	public void function suppressLifecycleEvents() {
		variables.lifecycleEventsSuppressed.set( true );
	}

	public void function restoreLifecycleEvents() {
		variables.lifecycleEventsSuppressed.remove();
	}

	public boolean function areLifecycleEventsSuppressed() {
		var value = variables.lifecycleEventsSuppressed.get();
		return !isNull( value ) && value;
	}

}
