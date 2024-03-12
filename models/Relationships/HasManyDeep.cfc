/**
 * Represents a hasManyDeep relationship.
 */
component extends="quick.models.Relationships.BaseRelationship" accessors="true" {

	/**
	 * The foreign keys traversing the related entities.
	 */
	property name="foreignKeys" type="array";

	/**
	 * The local keys traversing the related entities.
	 */
	property name="localKeys" type="array";

	/**
	 * Used to check for the type of relationship more quickly than using isInstanceOf.
	 */
	this.relationshipClass = "HasManyDeep";

	/**
	 * Creates a HasManyDeep relationship.
	 *
	 * @related             The related entity instance.
	 * @relationName        The WireBox mapping for the related entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 * @parent              The parent entity instance for the relationship.
	 * @through             The entities to traverse from the parent entity to get to the related entity.
	 * @foreignKeys         The foreign keys traversing the related entities.
	 * @localKeys           The local keys traversing the related entities.
	 *
	 * @return              quick.models.Relationships.HasManyDeep
	 */
	public HasManyDeep function init(
		required any related,
		required string relationName,
		required string relationMethodName,
		required any parent,
		required array throughParents,
		required array foreignKeys,
		required array localKeys,
		boolean withConstraints = true
	) {
		variables.throughParents = arguments.throughParents;
		variables.localKeys      = arguments.localKeys;
		variables.foreignKeys    = arguments.foreignKeys;

		return super.init(
			related             = arguments.related.getEntity(),
			relationName        = arguments.relationName,
			relationMethodName  = arguments.relationMethodName,
			parent              = arguments.parent,
			withConstraints     = arguments.withConstraints,
			relationshipBuilder = arguments.related
		);
	}

	public void function addConstraints() {
		performJoin();

		var qualifiedFirstForeignKey = throughParents[ 1 ].qualifyColumn( variables.foreignKeys[ 1 ] );
		var firstLocalValue          = variables.parent.retrieveAttribute( variables.localKeys[ 1 ] );
		variables.relationshipBuilder.where( qualifiedFirstForeignKey, firstLocalValue );
	}

	public void function performJoin( any builder = variables.relationshipBuilder ) {
		var segments = arguments.builder
			.getQB()
			.getFrom()
			.split( "[Aa][Ss]" );
		var alias = segments[ 2 ] ?: "";

		var chainLength = variables.throughParents.len();
		for ( var i = chainLength; i > 0; i-- ) {
			var throughParent = variables.throughParents[ i ];
			var predecessor   = i < chainLength ? variables.throughParents[ i + 1 ] : variables.related;
			var prefix        = i == chainLength && alias != "" ? alias & "." : "";
			joinThroughParent(
				builder,
				throughParent,
				predecessor,
				variables.foreignKeys[ i + 1 ],
				variables.localKeys[ i + 1 ],
				prefix
			);
		}
	}

	private void function joinThroughParent(
		required any builder,
		required any throughParent,
		required any predecessor,
		required any foreignKey,
		required any localKey,
		string prefix = ""
	) {
		var joins = throughParentJoins(
			arguments.builder,
			arguments.throughParent,
			arguments.predecessor,
			arguments.foreignKey,
			arguments.localKey
		);
		var qualifiedJoins = [];
		for ( var i = 1; i <= joins.len(); i++ ) {
			var first  = joins[ i ][ 1 ];
			var second = joins[ i ][ 2 ];
			qualifiedJoins.append( [
				arguments.throughParent.qualifyColumn( first ),
				arguments.predecessor.qualifyColumn( prefix & second )
			] );
		}

		arguments.builder.join( arguments.throughParent.tableName(), function( j ) {
			j.getParentQuery().setQuickBuilder( throughParent );
			j.setWheres( throughParent.getWheres() );
			j.addBindings( throughParent.getRawBindings().where, "where" );
			for ( var join in qualifiedJoins ) {
				j.on( join[ 1 ], "=", join[ 2 ] );
			}
		} );
	}

	public array function throughParentJoins(
		required any builder,
		required any throughParent,
		required any predecessor,
		required any foreignKey,
		required any localKey
	) {
		var joins = [];
		if ( isArray( arguments.localKey ) ) {
			arguments.builder.where(
				arguments.throughParent.qualifyColumn( arguments.localKey[ 1 ] ),
				arguments.predecessor.mappingName()
			);

			arguments.localKey = arguments.localKey[ 2 ];
		}

		if ( isArray( arguments.foreignKey ) ) {
			arguments.builder.where(
				arguments.predecessor.qualifyColumn( arguments.foreignKey[ 1 ] ),
				arguments.throughParent.mappingName()
			);

			arguments.foreignKey = arguments.foreignKey[ 2 ];
		}

		joins.append( [
			arguments.throughParent.qualifyColumn( arguments.localKey ),
			arguments.predecessor.qualifyColumn( arguments.foreignKey )
		] );

		return joins;
	}

	public any function getResults() {
		if ( variables.parent.isNullValue( variables.localKeys[ 1 ] ) ) {
			return variables.related.newCollection();
		} else {
			return variables.relationshipBuilder.get();
		}
	}

	public any function addCompareConstraints( any base = variables.relationshipBuilder, any nested ) {
		performJoin( base );
		return arguments.base
			.select( variables.relationshipBuilder.raw( 1 ) )
			.where( function( q ) {
				arrayZipEach(
					[
						getExistenceLocalKeys( base ),
						getExistenceCompareKeys( base )
					],
					function( qualifiedLocalKey, existenceCompareKey ) {
						q.whereColumn( qualifiedLocalKey, existenceCompareKey );
					}
				);
			} );
	}

	public array function getQualifiedForeignKeyNames( any builder = variables.relationshipBuilder ) {
		var segments = arguments.builder
			.getQB()
			.getFrom()
			.split( "[Aa][Ss]" );
		var alias = segments[ 2 ] ?: "";

		var foreignKeys = [];
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			if ( i > variables.throughParents.len() ) {
				foreignKeys.append( variables.related.qualifyColumn( variables.foreignKeys[ i ] ) );
			} else {
				foreignKeys.append( variables.throughParents[ i ].qualifyColumn( variables.foreignKeys[ i ] ) );
			}
		}
		return foreignKeys;
	}

	public array function getQualifiedLocalKeys( any builder = variables.relationshipBuilder ) {
		var segments = arguments.builder
			.getQB()
			.getFrom()
			.split( "[Aa][Ss]" );
		var alias = segments[ 2 ] ?: "";

		var localKeys = [];
		for ( var i = 1; i <= variables.localKeys.len(); i++ ) {
			if ( i == 1 ) {
				localKeys.append( variables.parent.qualifyColumn( variables.localKeys[ i ] ) );
			} else {
				localKeys.append( variables.throughParents[ i - 1 ].qualifyColumn( variables.localKeys[ i ] ) );
			}
		}
		return localKeys;
	}

}
