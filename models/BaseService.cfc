/**
 * This class is a thin wrapper around an entity.  It is useful in situations
 * where you want to inject a component as a singleton.  It would not be
 * needed if CFML engines had 1) static support and 2) onMissingStaticMethod
 *
 * Most services used will be created using the custom WireBox DSL:
 *
 * ```
 * property name="userService" inject="quickService:User";
 * ```
 */
component {

	/**
	 * The WireBox injector.  Used to inject other entities.
	 */
	property name="wirebox" inject="wirebox";

	/**
	 * The entity component that calls will be proxied to.
	 */
	property name="entity";

	/**
	 * Returns a new BaseService with the given entity.
	 *
	 * @entity  Either a WireBox mapping to an entity or an instance of an entity.
	 *
	 * @return  quick.models.BaseService
	 */
	public any function init( required any entity ) {
		variables.entity = arguments.entity;
		return this;
	}

	/**
	 * Ensures the entity is a component instance if a mapping was passed in.
	 */
	public void function onDIComplete() {
		if ( isSimpleValue( variables.entity ) ) {
			variables.entity = wirebox.getInstance( variables.entity );
		}
	}

	/**
	 * Forwards on method calls to a fresh version of the entity.
	 *
	 * @missingMethodName       The method name being called.
	 * @missingMethodArguments  The method arguments sent.
	 *
	 * @return                  any
	 */
	public any function onMissingMethod( required string missingMethodName, struct missingMethodArguments = {} ) {
		return invoke(
			variables.entity.newEntity(),
			missingMethodName,
			missingMethodArguments
		);
	}

}
