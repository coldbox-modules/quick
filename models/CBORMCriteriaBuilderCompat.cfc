/**
 * A proxy object from cbORM's CriteriaBuilder methods to their Quick equivalent.
 */
component accessors="true" {

	property name="entity";

	function init( entity, query ) {
		if ( !isNull( arguments.entity ) ) {
			variables.entity = arguments.entity;
		}
		return this;
	}

	function getSQL() {
		return getEntity().retrieveQuery().toSQL();
	}

	function between( column, start, end ) {
		getEntity().retrieveQuery().whereBetween( column, start, end );
		return this;
	}

	function eqProperty( left, right ) {
		getEntity().retrieveQuery().whereColumn( left, right );
		return this;
	}

	function isEQ( column, value ) {
		getEntity().retrieveQuery().where( column, "=", value );
		return this;
	}

	function isGT( column, value ) {
		getEntity().retrieveQuery().where( column, ">", value );
		return this;
	}

	function gtProperty( left, right ) {
		getEntity().retrieveQuery().whereColumn( left, ">", right );
		return this;
	}

	function isGE( column, value ) {
		getEntity().retrieveQuery().where( column, ">=", value );
		return this;
	}

	function geProperty( left, right ) {
		getEntity().retrieveQuery().whereColumn( left, ">=", right );
		return this;
	}

	function idEQ( id ) {
		guardAgainstCompositePrimaryKeys();
		getEntity().retrieveQuery().where( getEntity().keyNames()[ 1 ], id );
		return this;
	}

	function like( column, value ) {
		getEntity().retrieveQuery().where( column, "like", value );
		return this;
	}

	function ilike( column, value ) {
		getEntity().retrieveQuery().where( column, "ilike", value );
		return this;
	}

	function isIn( column, values ) {
		getEntity().retrieveQuery().whereIn( column, values );
		return this;
	}

	function isNull( column ) {
		getEntity().retrieveQuery().whereNull( column );
		return this;
	}

	function isNotNull( column ) {
		getEntity().retrieveQuery().whereNotNull( column );
		return this;
	}

	function isLT( column, value ) {
		getEntity().retrieveQuery().where( column, "<", value );
		return this;
	}

	function ltProperty( left, right ) {
		getEntity().retrieveQuery().whereColumn( left, "<", right );
		return this;
	}

	function neProperty( left, right ) {
		getEntity().retrieveQuery().whereColumn( left, "<>", right );
		return this;
	}

	function isLE( column, value ) {
		getEntity().retrieveQuery().where( column, "<=", value );
		return this;
	}

	function leProperty( left, right ) {
		getEntity().retrieveQuery().whereColumn( left, "<=", right );
		return this;
	}

	function maxResults( max ) {
		getEntity().retrieveQuery().limit( max );
		return this;
	}

	function firstResult( offset ) {
		getEntity().retrieveQuery().offset( offset );
		return this;
	}

	function order( orders ) {
		arguments.orders = isArray( arguments.orders ) ? arguments.orders : listToArray( arguments.orders, "," );
		getEntity()
			.retrieveQuery()
			.orderBy(
				arguments.orders.map( function( order ) {
					return replace( order, " ", "|" );
				} )
			);
		return this;
	}

	function list() {
		return getEntity().getAll();
	}

	function get() {
		return getEntity().first();
	}

	function count() {
		return getEntity().count();
	}

	function onMissingMethod( missingMethodName, missingMethodArguments ) {
		invoke(
			variables._builder,
			missingMethodName,
			missingMethodArguments
		);
		return this;
	}

	private void function guardAgainstCompositePrimaryKeys() {
		if ( getEntity().keyNames().len() > 1 ) {
			throw(
				type    = "InvalidKeyLength",
				message = "The CBORMCompatEntity cannot be used with composite primary keys."
			);
		}
	}

}
