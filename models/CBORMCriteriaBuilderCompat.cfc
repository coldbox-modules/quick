/**
 * A proxy object from cbORM's CriteriaBuilder methods to their Quick equivalent.
 */
component extends="quick.models.QuickBuilder" accessors="true" {

	property name="entity";

	function init( entity, query, defaultReturnFormat='array' ) {
		if ( !isNull( arguments.entity ) ) {
			variables.entity = arguments.entity;
		}
		return super.init(defaultReturnFormat);
	}

	function getSQL() {
		return variables.qb.toSQL();
	}

	function between( column, start, end ) {
		variables.qb.whereBetween( column, start, end );
		return this;
	}

	function eqProperty( left, right ) {
		variables.qb.whereColumn( left, right );
		return this;
	}

	function isEQ( column, value ) {
		variables.qb.where( column, "=", value );
		return this;
	}

	function isGT( column, value ) {
		variables.qb.where( column, ">", value );
		return this;
	}

	function gtProperty( left, right ) {
		variables.qb.whereColumn( left, ">", right );
		return this;
	}

	function isGE( column, value ) {
		variables.qb.where( column, ">=", value );
		return this;
	}

	function geProperty( left, right ) {
		variables.qb.whereColumn( left, ">=", right );
		return this;
	}

	function idEQ( id ) {
		guardAgainstCompositePrimaryKeys();
		variables.qb.where( getEntity().keyNames()[ 1 ], id );
		return this;
	}

	function like( column, value ) {
		variables.qb.where( column, "like", value );
		return this;
	}

	function ilike( column, value ) {
		variables.qb.where( column, "ilike", value );
		return this;
	}

	function isIn( column, values ) {
		variables.qb.whereIn( column, values );
		return this;
	}

	function isNull( column ) {
		variables.qb.whereNull( column );
		return this;
	}

	function isNotNull( column ) {
		variables.qb.whereNotNull( column );
		return this;
	}

	function isLT( column, value ) {
		variables.qb.where( column, "<", value );
		return this;
	}

	function ltProperty( left, right ) {
		variables.qb.whereColumn( left, "<", right );
		return this;
	}

	function neProperty( left, right ) {
		variables.qb.whereColumn( left, "<>", right );
		return this;
	}

	function isLE( column, value ) {
		variables.qb.where( column, "<=", value );
		return this;
	}

	function leProperty( left, right ) {
		variables.qb.whereColumn( left, "<=", right );
		return this;
	}

	function maxResults( max ) {
		variables.qb.limit( max );
		return this;
	}

	function firstResult( offset ) {
		variables.qb.offset( offset );
		return this;
	}

	function order( orders ) {
		arguments.orders = isArray( arguments.orders ) ? arguments.orders : listToArray( arguments.orders, "," );
		variables.qb.orderBy(
			arguments.orders.map( function( order ) {
				return replace( order, " ", "|" );
			} )
		);
		return this;
	}

	function list() {
		return super.get();
	}

	function get() {
		return super.first();
	}

	function count() {
		return variables.qb.count();
	}

	function onMissingMethod( missingMethodName, missingMethodArguments ) {
		invoke(
			variables.qb,
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
