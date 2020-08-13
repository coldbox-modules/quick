/**
 * Represents a BelongsToThrough relationship.
 *
 * This is a relationship where the parent entity belongs to the related entity.
 * The inverse of this relationship is a `hasMany` relationship.
 *
 * For instance, a `Post` would belong to a `Country` through a `User`.
 * This would be modeled in Quick by adding a method to the `Post` entity
 * that returns a `belongsToThrough` relationship instance.
 *
 * ```
 * function country() {
 *     returns belongsToThrough( [ "author", "country" ] );
 * }
 * ```
 */
component extends="quick.models.Relationships.BaseRelationship" {

	/**
	 * An array of relationships between the parent entity and the related entity.
	 */
	property name="relationships" type="array";

	/**
	 * A dictionary of relationship name to relationship component.
	 */
	property name="relationshipsMap" type="struct";

	/**
	 * A shortcut to access the entity closest to the parent entity.
	 * This is the result of the first relationship in the `relationships` chain.
	 */
	property name="closestToParent";

	/**
	 * Used to check for the type of relationship more quickly than using isInstanceOf.
	 */
	this.relationshipClass = "BelongsToThrough";

	/**
	 * Creates a BelongsToThrough relationship.
	 *
	 * @related             The related entity instance.
	 * @relationName        The WireBox mapping for the related entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 * @parent              The parent entity instance for the relationship.
	 * @relationships       An array of relationships between the parent entity
	 *                      and the related entity.
	 * @relationshipsMap    A dictionary of relationship name to relationship component.
	 *
	 * @returns             quick.models.Relationships.BelongsToThrough
	 */
	public BelongsToThrough function init(
		required any related,
		required string relationName,
		required string relationMethodName,
		required any parent,
		required array relationships,
		required struct relationshipsMap,
		boolean withConstraints = true
	) {
		variables.relationships    = arguments.relationships;
		variables.relationshipsMap = arguments.relationshipsMap;
		variables.closestToParent  = variables.relationshipsMap[ variables.relationships[ 1 ] ];

		return super.init(
			related            = arguments.related,
			relationName       = arguments.relationName,
			relationMethodName = arguments.relationMethodName,
			parent             = arguments.parent,
			withConstraints    = arguments.withConstraints
		);
	}

	/**
	 * Adds the constraints to the related entity.
	 *
	 * @return  quick.models.Relationships.BelongsToThrough
	 */
	public BelongsToThrough function addConstraints() {
		performJoin();
		variables.closestToParent.applyThroughConstraints( variables.related );
		return this;
	}

	/**
	 * Adds a join to the intermediate tables for the relationship.
	 *
	 * @return  quick.models.Relationships.BelongsToThrough
	 */
	public BelongsToThrough function performJoin( any base = variables.related ) {
		// no arrayReverse in ACF means for loops. :-(
		for ( var index = variables.relationships.len(); index > 1; index-- ) {
			var relationshipName = variables.relationships[ index ];
			var relation         = variables.relationshipsMap[ relationshipName ];
			relation.applyThroughJoin( arguments.base );
		}
		return this;
	}

	/**
	 * Adds the constraints for eager loading.
	 *
	 * @entities  The entities being eager loaded.
	 *
	 * @return    quick.models.Relationships.BelongsToThrough
	 */
	public boolean function addEagerConstraints( required array entities ) {
		var allKeys = getKeys( entities, variables.closestToParent.getLocalKeys() );

		if ( allKeys.isEmpty() ) {
			return false;
		}

		performJoin();
		var foreignKeys             = variables.closestToParent.getForeignKeys();
		var qualifiedForeignKeyList = foreignKeys
			.reduce( function( acc, foreignKey, i ) {
				if ( i != 1 ) {
					acc.append( "," );
				}
				acc.append( variables.closestToParent.qualifyColumn( foreignKey ) );
				return acc;
			}, [] )
			.toList();

		variables.related
			.when(
				( qualifiedForeignKeyList.listLen() > 1 ),
				function( q1 ) {
					q1.selectRaw( "CONCAT(#qualifiedForeignKeyList#) AS __QuickThroughKey__" );
				},
				function( q1 ) {
					q1.addSelect( "#qualifiedForeignKeyList# AS __QuickThroughKey__" );
				}
			)
			.appendVirtualAttribute( name = "__QuickThroughKey__", excludeFromMemento = true )
			.where( function( q1 ) {
				allKeys.each( function( keys ) {
					q1.orWhere( function( q2 ) {
						arrayZipEach( [ foreignKeys, keys ], function( foreignKey, keyValue ) {
							q2.where(
								variables.closestToParent.qualifyColumn( foreignKey ),
								variables.closestToParent.generateQueryParamStruct( foreignKey, keyValue )
							);
						} );
					} );
				} );
			} );

		return true;
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
			var key = result.retrieveAttribute( "__QuickThroughKey__" );
			if ( !structKeyExists( arguments.dict, key ) ) {
				arguments.dict[ key ] = [];
			}
			arrayAppend( arguments.dict[ key ], arguments.result );
			return arguments.dict;
		}, {} );
	}

	/**
	 * Gets the query used to check for relation existance.
	 *
	 * @base    The base entity for the query.
	 *
	 * @return  quick.models.BaseEntity | qb.models.Query.QueryBuilder
	 */
	public any function addCompareConstraints( any base = variables.related ) {
		return tap( arguments.base.select(), function( q ) {
			performJoin( q );
			q.where( function( q2 ) {
				arrayZipEach(
					[
						variables.closestToParent.getForeignKeys(),
						variables.closestToParent.getLocalKeys()
					],
					function( localKey, foreignKey ) {
						q2.whereColumn(
							variables.parent.qualifyColumn( localKey ),
							variables.closestToParent.qualifyColumn( foreignKey )
						);
					}
				);
			} );
		} );
	}

	/**
	 * Applies a suffix to an alias for the relationship.
	 * This is ignored for `BelongsToThrough` because each of the relationship
	 * components inside `relationshipsMap` will already be aliased.
	 *
	 * @suffix   The suffix to use.
	 *
	 * @return  quick.models.Relationships.BelongsToThrough
	 */
	public BelongsToThrough function applyAliasSuffix( required string suffix ) {
		return this;
	}

	/**
	 * Applies the join for relationship in a `BelongsToThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public void function applyThroughJoin( required any base ) {
		performJoin( arguments.base );
		variables.closestToParent.applyThroughJoin( arguments.base );
	}

	/**
	 * Returns the result of the relationship.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function getResults() {
		var result = variables.related.first();

		if ( !isNull( result ) ) {
			return result;
		}

		if ( !variables.returnDefaultEntity ) {
			return javacast( "null", "" );
		}

		if ( isClosure( variables.defaultAttributes ) || isCustomFunction( variables.defaultAttributes ) ) {
			return tap( variables.related.newEntity(), function( newEntity ) {
				variables.defaultAttributes( newEntity, variables.parent );
			} );
		}

		return variables.related.newEntity().fill( variables.defaultAttributes );
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
			return arguments.entity.assignRelationship( relation, javacast( "null", "" ) );
		} );
	}

	/**
	 * Matches the array of entity results to a single value for the relation.
	 * The matched record is populated into the matched entity's relation.
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
		return matchOne( argumentCollection = arguments );
	}

	/**
	 * Applies the constraints for the final relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the constraints to.
	 *
	 * @return  void
	 */
	public void function applyThroughConstraints( required any base ) {
		arguments.base.where( function( q ) {
			arrayZipEach(
				[
					variables.foreignKeys,
					variables.localKeys
				],
				function( foreignKey, localKey ) {
					q.where(
						variables.related.qualifyColumn( foreignKey ),
						variables.parent.retrieveAttribute( localKey )
					);
				}
			);
		} );
	}

	public array function getForeignKeys() {
		return variables.closestToParent.getLocalKeys();
	}

	public array function getLocalKeys() {
		return variables.parent.keyNames();
	}

}
