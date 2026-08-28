/**
 * Base class for Laravel-inspired Quick model factories.
 *
 * Factory support lives under `resources/testing` so applications can omit the
 * entire directory from production deployments. Subclasses provide
 * `definition()` and may expose named states which return `state( ... )`.
 */
component {

	/**
	 * Create a factory for a Quick entity provider.
	 *
	 * @entityProvider  A WireBox provider for the Quick entity mapping.
	 * @context         Optional application-specific values available to definitions and states.
	 */
	public any function init( required any entityProvider, struct context = {} ) {
		variables.entityProvider         = arguments.entityProvider;
		variables.factoryContext         = arguments.context;
		variables.afterMakingCallbacks   = [];
		variables.afterCreatingCallbacks = [];
		configure();
		return this;
	}

	/**
	 * Return the default attributes for one entity.
	 */
	public struct function definition() {
		throw( type = "QuickFactory.AbstractMethod", message = "Factory subclasses must implement definition()." );
	}

	/**
	 * Register factory-wide callbacks in subclasses.
	 */
	public any function configure() {
		return this;
	}

	public any function state( required any transformation ) {
		return newBuilder().state( arguments.transformation );
	}

	public any function sequence( required array states ) {
		return newBuilder().sequence( arguments.states );
	}

	public any function count( required numeric amount ) {
		return newBuilder().count( arguments.amount );
	}

	public any function make( struct attributes = {} ) {
		return newBuilder().make( arguments.attributes );
	}

	public any function create( struct attributes = {} ) {
		return newBuilder().create( arguments.attributes );
	}

	public any function afterMaking( required any callback ) {
		if ( !isCallable( arguments.callback ) ) {
			throw( type = "QuickFactory.InvalidCallback", message = "Factory callbacks must be closures or functions." );
		}
		arrayAppend( variables.afterMakingCallbacks, arguments.callback );
		return this;
	}

	public any function afterCreating( required any callback ) {
		if ( !isCallable( arguments.callback ) ) {
			throw( type = "QuickFactory.InvalidCallback", message = "Factory callbacks must be closures or functions." );
		}
		arrayAppend( variables.afterCreatingCallbacks, arguments.callback );
		return this;
	}

	public struct function getFactoryContext() {
		return variables.factoryContext;
	}

	public any function newEntity( required struct attributes ) {
		return variables.entityProvider.newEntity().fill( arguments.attributes );
	}

	public array function getAfterMakingCallbacks() {
		return variables.afterMakingCallbacks;
	}

	public array function getAfterCreatingCallbacks() {
		return variables.afterCreatingCallbacks;
	}

	private any function newBuilder() {
		return new quick.resources.testing.FactoryBuilder( this );
	}

	private boolean function isCallable( required any candidate ) {
		return isClosure( arguments.candidate ) || isCustomFunction( arguments.candidate );
	}

}
