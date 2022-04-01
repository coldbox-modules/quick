/**
 * A custom BaseEntity that proxies the cbORM methods to their Quick equivalent.
 */
component extends="quick.models.BaseEntity" accessors="true" {

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
		var builder = newQuery();
		structEach( criteria, function( key, value ) {
			builder.where( retrieveColumnForAlias( key ), value );
		} );
		if ( !isNull( sortOrder ) ) {
			builder.orderBy( sortOrder );
		}
		if ( !isNull( offset ) && offset > 0 ) {
			builder.offset( offset );
		}
		if ( !isNull( max ) && max > 0 ) {
			builder.limit( max );
		}
		if ( asQuery ) {
			return builder
				.getQB()
				.setReturnFormat( "query" )
				.get();
		} else {
			return builder.get();
		}
	}

	function countWhere() {
		var builder = newQuery();
		for ( var key in arguments ) {
			builder.where( retrieveColumnForAlias( key ), arguments[ key ] );
		}
		return builder.count();
	}

	function deleteById( id ) {
		guardAgainstCompositePrimaryKeys();
		arguments.id = isArray( arguments.id ) ? arguments.id : [ arguments.id ];
		newQuery().whereIn( keyNames()[ 1 ], arguments.id ).delete();
		return this;
	}

	function deleteWhere() {
		var builder = newQuery();
		for ( var key in arguments ) {
			builder.where( retrieveColumnForAlias( key ), arguments[ key ] );
		}
		return builder.deleteAll();
	}

	function exists( id ) {
		var builder = newQuery();
		if ( !isNull( id ) ) {
			guardAgainstCompositePrimaryKeys();
			builder.where( keyNames()[ 1 ], arguments.id );
		}
		return builder.exists();
	}

	function findAllWhere( criteria = {}, sortOrder ) {
		var builder = newQuery();
		structEach( criteria, function( key, value ) {
			builder.where( retrieveColumnForAlias( key ), value );
		} );
		if ( !isNull( sortOrder ) ) {
			var sorts = listToArray( sortOrder, "," ).map( function( sort ) {
				return replace( sort, " ", "|", "ALL" );
			} );
			builder.orderBy( sorts );
		}
		return builder.get();
	}

	function findWhere( criteria = {} ) {
		var builder = newQuery();
		structEach( criteria, function( key, value ) {
			builder.where( retrieveColumnForAlias( key ), value );
		} );
		return builder.first();
	}

	function get( id = 0, returnNew = true ) {
		if ( ( isNull( arguments.id ) || arguments.id == 0 ) && arguments.returnNew ) {
			return newEntity();
		}
		return newQuery().find( arguments.id );
	}

	function getAll( id, sortOrder ) {
		var builder = newQuery();
		if ( isNull( id ) ) {
			if ( !isNull( sortOrder ) ) {
				var sorts = listToArray( sortOrder, "," ).map( function( sort ) {
					return replace( sort, " ", "|", "ALL" );
				} );
				builder.orderBy( sorts );
			}
			return builder.get();
		}
		guardAgainstCompositePrimaryKeys();
		var ids = isArray( id ) ? id : listToArray( id, "," );
		builder.whereIn( keyNames()[ 1 ], ids );
		return builder.get();
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
		return variables._wirebox
			.getInstance( "CBORMCriteriaBuilderCompat@quick" )
			.setEntity( this )
			.setReturnFormat( "array" )
			.setDefaultOptions( variables._queryOptions )
			.from( tableName() )
			.addSelect( retrieveQualifiedColumns() );
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
