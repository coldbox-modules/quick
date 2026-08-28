/**
 * Cycles factory state values across a counted make/create operation.
 */
component {

	public any function init( required array states ) {
		if ( arrayLen( arguments.states ) == 0 ) {
			throw( type = "QuickFactory.EmptySequence", message = "Factory sequences require at least one state." );
		}
		variables.states = arguments.states;
		return this;
	}

	public struct function next( required struct attributes, required struct context ) {
		var position = ( arguments.context.index mod arrayLen( variables.states ) ) + 1;
		var value    = variables.states[ position ];
		if ( !isNull( value ) && ( isClosure( value ) || isCustomFunction( value ) ) ) {
			value = value( arguments.attributes, arguments.context );
		}
		if ( isNull( value ) || !isStruct( value ) ) {
			throw(
				type    = "QuickFactory.InvalidSequenceState",
				message = "Each factory sequence value must be a struct or closure returning a struct."
			);
		}
		return value;
	}

}
