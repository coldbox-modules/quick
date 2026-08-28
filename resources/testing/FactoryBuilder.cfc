/**
 * A one-use fluent builder produced by a Quick factory definition.
 */
component {

	public any function init( required any factory ) {
		variables.factory                = arguments.factory;
		variables.amount                 = 1;
		variables.explicitCount          = false;
		variables.transformations        = [];
		variables.afterMakingCallbacks   = [];
		variables.afterCreatingCallbacks = [];
		return this;
	}

	public any function count( required numeric amount ) {
		if ( arguments.amount < 0 || int( arguments.amount ) != arguments.amount ) {
			throw( type = "QuickFactory.InvalidCount", message = "Factory count must be a non-negative integer." );
		}
		variables.amount        = int( arguments.amount );
		variables.explicitCount = true;
		return this;
	}

	public any function state( required any transformation ) {
		if ( !isStruct( arguments.transformation ) && !isCallable( arguments.transformation ) ) {
			throw( type = "QuickFactory.InvalidState", message = "Factory state must be a struct or closure." );
		}
		arrayAppend( variables.transformations, arguments.transformation );
		return this;
	}

	public any function sequence( required array states ) {
		arrayAppend( variables.transformations, new quick.resources.testing.Sequence( arguments.states ) );
		return this;
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

	/**
	 * Forward named state methods to the factory definition so chains may use
	 * either `factory.count( 3 ).inactive()` or `factory.inactive().count( 3 )`.
	 */
	public any function onMissingMethod( required string missingMethodName, required struct missingMethodArguments ) {
		if ( !structKeyExists( variables.factory, arguments.missingMethodName ) ) {
			throw(
				type    = "QuickFactory.UnknownMethod",
				message = "Unknown factory method [#arguments.missingMethodName#]."
			);
		}
		var stateBuilder = invoke(
			variables.factory,
			arguments.missingMethodName,
			arguments.missingMethodArguments
		);
		if ( !isInstanceOf( stateBuilder, "quick.resources.testing.FactoryBuilder" ) ) {
			return stateBuilder;
		}
		arrayAppend(
			variables.transformations,
			stateBuilder.getTransformations(),
			true
		);
		arrayAppend(
			variables.afterMakingCallbacks,
			stateBuilder.getAfterMakingCallbacks(),
			true
		);
		arrayAppend(
			variables.afterCreatingCallbacks,
			stateBuilder.getAfterCreatingCallbacks(),
			true
		);
		return this;
	}

	public array function getTransformations() {
		return variables.transformations;
	}

	public array function getAfterMakingCallbacks() {
		return variables.afterMakingCallbacks;
	}

	public array function getAfterCreatingCallbacks() {
		return variables.afterCreatingCallbacks;
	}

	/**
	 * Build Quick entities without persisting them.
	 */
	public any function make( struct attributes = {} ) {
		var entities = [];
		for ( var index = 1; index <= variables.amount; index++ ) {
			var evaluatedAttributes = evaluateAttributes(
				attributes = arguments.attributes,
				index      = index,
				count      = variables.amount
			);
			var entity = variables.factory.newEntity( evaluatedAttributes );
			runCallbacks(
				variables.factory.getAfterMakingCallbacks(),
				entity,
				evaluatedAttributes
			);
			runCallbacks(
				variables.afterMakingCallbacks,
				entity,
				evaluatedAttributes
			);
			arrayAppend( entities, entity );
		}
		return variables.explicitCount ? entities : entities[ 1 ];
	}

	/**
	 * Build and persist Quick entities through `BaseEntity.save()`.
	 */
	public any function create( struct attributes = {} ) {
		var entities   = make( arguments.attributes );
		var collection = variables.explicitCount ? entities : [ entities ];
		for ( var entity in collection ) {
			entity.save();
			var persistedAttributes = entity.retrieveAttributesData();
			runCallbacks(
				variables.factory.getAfterCreatingCallbacks(),
				entity,
				persistedAttributes
			);
			runCallbacks(
				variables.afterCreatingCallbacks,
				entity,
				persistedAttributes
			);
		}
		return variables.explicitCount ? collection : collection[ 1 ];
	}

	private struct function evaluateAttributes(
		required struct attributes,
		required numeric index,
		required numeric count
	) {
		var definition = variables.factory.definition();
		if ( !isStruct( definition ) ) {
			throw( type = "QuickFactory.InvalidDefinition", message = "Factory definitions must return a struct." );
		}

		var values  = copyStruct( definition );
		var context = {
			index : arguments.index - 1,
			count : arguments.count
		};

		for ( var transformation in variables.transformations ) {
			var changes = {};
			if ( isInstanceOf( transformation, "quick.resources.testing.Sequence" ) ) {
				changes = transformation.next( copyStruct( values ), context );
			} else if ( isStruct( transformation ) ) {
				changes = transformation;
			} else if ( isCallable( transformation ) ) {
				changes = transformation( copyStruct( values ), context );
			}
			if ( !isStruct( changes ) ) {
				throw(
					type    = "QuickFactory.InvalidStateResult",
					message = "Factory state transformations must return a struct."
				);
			}
			structAppend( values, changes, true );
		}

		structAppend( values, arguments.attributes, true );
		for ( var key in values ) {
			if ( !isNull( values[ key ] ) && isCallable( values[ key ] ) ) {
				values[ key ] = values[ key ]( copyStruct( values ), context );
			}
		}
		return values;
	}

	private void function runCallbacks(
		required array callbacks,
		required any entity,
		required struct attributes
	) {
		for ( var callback in arguments.callbacks ) {
			callback( arguments.entity, arguments.attributes );
		}
	}

	private struct function copyStruct( required struct source ) {
		var copied = {};
		structAppend( copied, arguments.source, true );
		return copied;
	}

	private boolean function isCallable( required any candidate ) {
		return isClosure( arguments.candidate ) || isCustomFunction( arguments.candidate );
	}

}
