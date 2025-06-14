/**
 * Represents a hasManyDeep relationship.
 */
component
	extends   ="quick.models.Relationships.BaseRelationship"
	implements="IConcatenatableRelationship"
	accessors ="true"
{

	/**
	 * The through parent entities being traversed.
	 */
	property name="throughParents" type="array";

	/**
	 * The foreign keys traversing the related entities.
	 */
	property name="foreignKeys" type="array";

	/**
	 * The local keys traversing the related entities.
	 */
	property name="localKeys" type="array";

	property
		name   ="nested"
		type   ="boolean"
		default="false";

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
		boolean nested          = false,
		boolean withConstraints = true
	) {
		variables.throughParents = arguments.throughParents;
		variables.localKeys      = arguments.localKeys;
		variables.foreignKeys    = arguments.foreignKeys;
		// TODO: figure out a way to not need this field
		variables.nested         = arguments.nested;

		var instance = super.init(
			related             = arguments.related.getEntity(),
			relationName        = arguments.relationName,
			relationMethodName  = arguments.relationMethodName,
			parent              = arguments.parent,
			withConstraints     = arguments.withConstraints,
			relationshipBuilder = arguments.related
		);

		performJoin();

		return instance;
	}

	public void function addConstraints() {
		if ( !nested ) {
			var firstForeignKey = variables.foreignKeys[ 1 ]
			if ( isArray( firstForeignKey ) ) {
				variables.relationshipBuilder.where(
					variables.throughParents[ 1 ].qualifyColumn( firstForeignKey[ 1 ] ),
					"=",
					variables.parent.mappingName()
				);
				firstForeignKey = firstForeignKey[ 2 ];
			}
			if ( isStruct( firstForeignKey ) ) {
				firstForeignKey = firstForeignKey.foreignKeys[ 1 ];
			}

			var qualifiedFirstForeignKey = variables.throughParents[ 1 ].qualifyColumn( firstForeignKey );
			var firstLocalValue          = variables.parent.retrieveAttribute( variables.localKeys[ 1 ] );
			variables.relationshipBuilder.where( qualifiedFirstForeignKey, firstLocalValue );
		}
	}

	public void function performJoin( any builder = variables.relationshipBuilder ) {
		var segments = arguments.builder
			.getQB()
			.getTableName()
			.split( "\s(?:[Aa][Ss]\s)?" );
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
			builder.addAliasesFromBuilder( throughParent );
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

		arguments.localKey   = arrayWrap( arguments.localKey );
		arguments.foreignKey = arrayWrap( arguments.foreignKey );

		guardAgainstKeyLengthMismatch( arguments.foreignKey, arguments.localKey );

		for ( var i = 1; i <= arguments.localKey.len(); i++ ) {
			if ( isStruct( arguments.foreignKey[ i ] ) ) {
				if ( isStruct( arguments.localKey[ i ] ) ) {
					throw( "Not sure what's going on here" );
				}

				// add the polymorphic where clause
				arguments.builder.where(
					arguments.predecessor.qualifyColumn( arguments.foreignKey[ i ].morphType ),
					arguments.throughParent.mappingName()
				);

				// add the joins
				arrayZipEach(
					[
						arrayWrap( arguments.foreignKey[ i ].foreignKeys ),
						arrayWrap( arguments.localKey[ i ] )
					],
					function( foreignKey, localKey ) {
						joins.append( [
							throughParent.qualifyColumn( localKey ),
							predecessor.qualifyColumn( foreignKey )
						] );
					}
				);
			} else {
				joins.append( [
					arguments.throughParent.qualifyColumn( arguments.localKey[ i ] ),
					arguments.predecessor.qualifyColumn( arguments.foreignKey[ i ] )
				] );
			}
		}

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
			.getTableName()
			.split( "\s(?:[Aa][Ss]\s)?" );
		var alias = segments[ 2 ] ?: "";

		var foreignKeys = [];
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			if ( i > variables.throughParents.len() ) {
				arrayWrap( variables.foreignKeys[ i ] ).each( function( foreignKey ) {
					if ( isStruct( foreignKey ) ) {
						foreignKey.foreignKeys.each( function( fk ) {
							foreignKeys.append( variables.related.qualifyColumn( fk ) );
						} );
					} else {
						foreignKeys.append( variables.related.qualifyColumn( foreignKey ) );
					}
				} );
			} else {
				arrayWrap( variables.foreignKeys[ i ] ).each( function( foreignKey ) {
					if ( isStruct( foreignKey ) ) {
						foreignKey.foreignKeys.each( function( fk ) {
							foreignKeys.append( variables.throughParents[ i ].qualifyColumn( fk ) );
						} );
					} else {
						foreignKeys.append( variables.throughParents[ i ].qualifyColumn( foreignKey ) );
					}
				} );
			}
		}
		return foreignKeys;
	}

	public array function getQualifiedLocalKeys( any builder = variables.relationshipBuilder ) {
		var segments = arguments.builder
			.getQB()
			.getTableName()
			.split( "\s(?:[Aa][Ss]\s)?" );
		var alias = segments[ 2 ] ?: "";

		var qualifiedLocalKeys = [];
		for ( var i = 1; i <= variables.localKeys.len(); i++ ) {
			if ( i == 1 ) {
				arrayWrap( variables.localKeys[ i ] ).each( function( localKey ) {
					if ( isStruct( localKey ) ) {
						localKey.localKeys.each( function( lk ) {
							qualifiedLocalKeys.append( variables.parent.qualifyColumn( lk ) );
						} );
					} else {
						qualifiedLocalKeys.append( variables.parent.qualifyColumn( localKey ) );
					}
				} );
			} else {
				arrayWrap( variables.localKeys[ i ] ).each( function( localKey ) {
					if ( isStruct( localKey ) ) {
						localKey.localKeys.each( function( lk ) {
							qualifiedLocalKeys.append( variables.throughParents[ i - 1 ].qualifyColumn( lk ) );
						} );
					} else {
						qualifiedLocalKeys.append( variables.throughParents[ i - 1 ].qualifyColumn( localKey ) );
					}
				} );
			}
		}
		return qualifiedLocalKeys;
	}

	public boolean function addEagerConstraints( required array entities, required any baseEntity ) {
		performJoin();

		var firstKey = variables.foreignKeys[ 1 ];
		if ( isArray( firstKey ) ) {
			firstKey = firstKey[ 2 ];
		}
		var qualifiedFirstKey = variables.throughParents[ 1 ].qualifyColumn( firstKey );
		var modelKeys         = getKeys(
			arguments.entities,
			arrayWrap( variables.localKeys[ 1 ] ),
			arguments.baseEntity
		);

		variables.relationshipBuilder.whereIn( qualifiedFirstKey, modelKeys );
		variables.relationshipBuilder.addSelect( "#qualifiedFirstKey# AS __QuickThroughKey__" );
		variables.relationshipBuilder.appendVirtualAttribute( "__QuickThroughKey__" );

		if ( isArray( variables.foreignKeys[ 1 ] ) ) {
			variables.relationshipBuilder.where(
				variables.throughParent[ 1 ].qualifyColumn( variables.foreignKeys[ 1 ][ 1 ] ),
				variables.parent.mappingName()
			);
		}

		return true;
	}

	/**
	 * Initializes the relation to the null value for each entity in an array.
	 *
	 * @entities     The entities to initialize the relation.
	 * @relation     The name of the relation to initialize.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function initRelation( required array entities, required string relation ) {
		return arguments.entities.map( function( entity ) {
			if ( structKeyExists( arguments.entity, "isQuickEntity" ) ) {
				arguments.entity.assignRelationship( relation, [] );
			} else {
				arguments.entity[ relation ] = [];
			}
			return arguments.entity;
		} );
	}

	/**
	 * Matches the array of entity results to an array of entities for a relation.
	 * Any matched records are populated into the matched entity's relation.
	 *
	 * @entities     The entities being eager loaded.
	 * @results      The relationship results.
	 * @relation     The relation name being loaded.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function match(
		required array entities,
		required array results,
		required string relation
	) {
		var dictionary = buildDictionary( arguments.results );
		arguments.entities.each( function( entity ) {
			var key = arrayWrap( variables.localKeys[ 1 ] )
				.map( function( localKey ) {
					return structKeyExists( entity, "isQuickEntity" ) ? entity.retrieveAttribute( localKey ) : entity[
						localKey
					];
				} )
				.toList();
			if ( structKeyExists( dictionary, key ) ) {
				if ( structKeyExists( entity, "isQuickEntity" ) ) {
					entity.assignRelationship( relation, dictionary[ key ] );
				} else {
					entity[ relation ] = dictionary[ key ];
				}
			}
		} );
		return arguments.entities;
	}

	/**
	 * Builds a dictionary mapping the `firstKey` value to related results.
	 *
	 * @results      The array of entities from retrieving the relationship.
	 *
	 * @doc_generic  any,quick.models.BaseEntity
	 * @return       {any: quick.models.BaseEntity}
	 */
	public struct function buildDictionary( required array results ) {
		return arguments.results.reduce( function( dict, result ) {
			var key = structKeyExists( result, "isQuickEntity" ) ? result.retrieveAttribute( "__QuickThroughKey__" ) : result[
				"__QuickThroughKey__"
			];
			if ( !structKeyExists( arguments.dict, key ) ) {
				arguments.dict[ key ] = [];
			}
			arrayAppend( arguments.dict[ key ], arguments.result );
			return arguments.dict;
		}, {} );
	}

	public struct function appendToDeepRelationship(
		required array through,
		required array foreignKeys,
		required array localKeys,
		required numeric position
	) {
		for ( var throughParent in variables.throughParents ) {
			var mapping = throughParent.tableName();
			if ( !structKeyExists( throughParent, "isPivotTable" ) ) {
				mapping = throughParent.mappingName();
			}

			if ( throughParent.tableName() != throughParent.tableAlias() ) {
				mapping &= " as " & throughParent.tableAlias();
			}

			arguments.through.append( mapping );
		}

		arrayAppend(
			arguments.foreignKeys,
			variables.foreignKeys,
			true
		);
		arrayAppend(
			arguments.localKeys,
			variables.localKeys,
			true
		);

		return {
			"through"     : arguments.through,
			"foreignKeys" : arguments.foreignKeys,
			"localKeys"   : arguments.localKeys
		};
	}

}
