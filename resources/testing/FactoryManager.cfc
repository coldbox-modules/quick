/**
 * Lazily discovers application factory definitions by convention.
 *
 * A request for `User` resolves `<factorypath>.UserFactory` through WireBox and
 * supplies the matching Quick entity provider plus the per-test context.
 */
component {

	public any function init(
		required any wirebox,
		required string factoryPath,
		struct context = {}
	) {
		variables.wirebox     = arguments.wirebox;
		variables.factoryPath = arguments.factoryPath;
		variables.context     = arguments.context;
		variables.factories   = {};
		return this;
	}

	public any function factory( required string name ) {
		if ( !reFind( "^[A-Za-z][A-Za-z0-9]*$", arguments.name ) ) {
			throw( type = "QuickFactory.InvalidFactoryName", message = "Invalid factory name [#arguments.name#]." );
		}

		if ( !structKeyExists( variables.factories, arguments.name ) ) {
			variables.factories[ arguments.name ] = variables.wirebox.getInstance(
				name          = "#variables.factoryPath#.#arguments.name#Factory",
				initArguments = {
					entityProvider : variables.wirebox.getInstance(
						dsl          = "provider:#arguments.name#",
						targetObject = this
					),
					context : variables.context
				}
			);
		}

		return variables.factories[ arguments.name ];
	}

}
