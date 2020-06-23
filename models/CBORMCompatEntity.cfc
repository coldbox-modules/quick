/**
 * A custom BaseEntity that proxies the cbORM methods to their Quick equivalent.
 */
component extends="quick.models.BaseEntity" accessors="true" {

	property
		name      ="CBORMCriteriaBuilderCompat"
		inject    ="provider:CBORMCriteriaBuilderCompat@quick"
		persistent="false";

	/**
	 * Creates an internal attribute struct for each persistent property
	 * on the entity.
	 *
	 * @properties  The array of properties on the entity.
	 *
	 * @return      A struct of attributes for the entity.
	 */
	private struct function generateAttributesFromProperties( required array properties ) {
		return arguments.properties.reduce( function( acc, prop ) {
			var newProp = paramAttribute( arguments.prop );
			if ( !newProp.persistent || newProp.keyExists( "fieldtype" ) ) {
				return arguments.acc;
			}
			arguments.acc[ newProp.name ] = newProp;
			return arguments.acc;
		}, {} );
	}

	function list(
		struct criteria = {},
		string sortOrder,
		numeric offset,
		numeric max,
		numeric timeout,
		boolean ignoreCase,
		boolean asQuery = true
	) {
		structEach( criteria, function( key, value ) {
			retrieveQuery().where( retrieveColumnForAlias( key ), value );
		} );
		if ( !isNull( sortOrder ) ) {
			retrieveQuery().orderBy( sortOrder );
		}
		if ( !isNull( offset ) && offset > 0 ) {
			retrieveQuery().offset( offset );
		}
		if ( !isNull( max ) && max > 0 ) {
			retrieveQuery().limit( max );
		}
		if ( asQuery ) {
			return retrieveQuery().setReturnFormat( "query" ).get();
		} else {
			return super.get();
		}
	}

	function countWhere() {
		for ( var key in arguments ) {
			retrieveQuery().where( retrieveColumnForAlias( key ), arguments[ key ] );
		}
		return retrieveQuery().count();
	}

	function deleteById( id ) {
		guardAgainstCompositePrimaryKeys();
		arguments.id = isArray( arguments.id ) ? arguments.id : [ arguments.id ];
		retrieveQuery().whereIn( keyNames()[ 1 ], arguments.id ).delete();
		return this;
	}

	function deleteWhere() {
		for ( var key in arguments ) {
			retrieveQuery().where( retrieveColumnForAlias( key ), arguments[ key ] );
		}
		return this.deleteAll();
	}

	function exists( id ) {
		if ( !isNull( id ) ) {
			guardAgainstCompositePrimaryKeys();
			retrieveQuery().where( keyNames()[ 1 ], arguments.id );
		}
		return retrieveQuery().exists();
	}

	function findAllWhere( criteria = {}, sortOrder ) {
		structEach( criteria, function( key, value ) {
			retrieveQuery().where( retrieveColumnForAlias( key ), value );
		} );
		if ( !isNull( sortOrder ) ) {
			var sorts = listToArray( sortOrder, "," ).map( function( sort ) {
				return replace( sort, " ", "|", "ALL" );
			} );
			retrieveQuery().orderBy( sorts );
		}
		return super.get();
	}

	function findWhere( criteria = {} ) {
		structEach( criteria, function( key, value ) {
			retrieveQuery().where( retrieveColumnForAlias( key ), value );
		} );
		return super.first();
	}

	function get( id = 0, returnNew = true ) {
		if ( ( isNull( arguments.id ) || arguments.id == 0 ) && arguments.returnNew ) {
			return newEntity();
		}
		// This is written this way to avoid conflicts with the BIF `find`
		return invoke( this, "find", { id : arguments.id } );
	}

	function getAll( id, sortOrder ) {
		if ( isNull( id ) ) {
			if ( !isNull( sortOrder ) ) {
				var sorts = listToArray( sortOrder, "," ).map( function( sort ) {
					return replace( sort, " ", "|", "ALL" );
				} );
				retrieveQuery().orderBy( sorts );
			}
			return super.get();
		}
		guardAgainstCompositePrimaryKeys();
		var ids = isArray( id ) ? id : listToArray( id, "," );
		retrieveQuery().whereIn( keyNames()[ 1 ], ids );
		return super.get();
	}

	function new( properties = {} ) {
		return newEntity().fill( properties );
	}

	function populate( properties = {} ) {
		super.fill( properties );
		return this;
	}

	function save( entity ) {
		if ( isNull( entity ) ) {
			return super.save();
		}
		return entity.save();
	}

	function saveAll( entities = [] ) {
		entities.each( function( entity ) {
			entity.save();
		} );
		return this;
	}

	function newCriteria() {
		return CBORMCriteriaBuilderCompat.setEntity( this );
	}

	private void function guardAgainstCompositePrimaryKeys() {
		if ( keyNames().len() > 1 ) {
			throw(
				type    = "InvalidKeyLength",
				message = "The CBORMCompatEntity cannot be used with composite primary keys."
			);
		}
	}

}
