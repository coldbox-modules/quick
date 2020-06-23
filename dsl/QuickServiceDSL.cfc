/**
 * Processes WireBox DSL's starting with "quickService:"
 */
component {

	/**
	 * Creates the Quick Service DSL Processor.
	 *
	 * @injector  The WireBox injector.
	 *
	 * @return    QuickServiceDSL
	 */
	public QuickServiceDSL function init( required Injector injector ) {
		variables.injector = arguments.injector;
		return this;
	}

	/**
	 * Creates a Quick BaseService from the dsl.
	 * The portion after the colon is used as the entity mapping.
	 *
	 * @definition  The dsl struct definition.
	 *
	 * @return      BaseService or extending component.
	 */
	public any function process( required struct definition ) {
		return variables.injector.getInstance(
			name          = "BaseService@quick",
			initArguments = { entity : variables.injector.getInstance( listRest( arguments.definition.dsl, ":" ) ) }
		);
	}

}
