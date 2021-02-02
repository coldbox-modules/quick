/**
 * Represents a HasOneOrManyThrough relationship.
 *
 * This is a relationship where the parent entity has zero or more of the related
 * entity.  The related entity is found through an intermediate entity.
 * The inverse of this relationship is also a `HasOneOrManyThrough` relationship.
 *
 * For instance, a `User` may have zero or more `Role` entities associated
 * to it.  A `Role` can have zero or more `Permission` entities associated
 * to it.  Therefore, a `User` "has many" `Permissions` "through" `Role`.
 * This would be modeled in Quick by adding a method to the `User` entity
 * that returns a `HasOneOrManyThrough` relationship instance.
 *
 * ```
 * function permissions() {
 *     returns HasOneOrManyThrough( "Permission", "Role" );
 * }
 * ```
 */
component extends="quick.models.Relationships.BaseRelationship" accessors="true" {

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
	this.relationshipClass = "HasOneOrManyThrough";

	/**
	 * Creates a HasOneOrManyThrough relationship.
	 *
	 * @related             The related entity instance.
	 * @relationName        The WireBox mapping for the related entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 * @parent              The parent entity instance for the relationship.
	 * @relationships       An array of relationships between the parent entity
	 *                      and the related entity.
	 * @relationshipsMap    A dictionary of relationship name to relationship component.
	 *
	 * @returns             quick.models.Relationships.HasOneOrManyThrough
	 */
	public HasOneOrManyThrough function init(
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
	 * @return  quick.models.Relationships.HasOneOrManyThrough
	 */
	public HasOneOrManyThrough function addConstraints() {
		var selectedColumns = variables.related.getColumns();
		var base            = initialThroughConstraints();
		base.select( selectedColumns );
		variables.related.populateQuery( base );
		return this;
	}

	public QuickBuilder function addNestedWhereExists( required QuickBuilder base ) {
		for ( var index = 2; index <= variables.relationships.len(); index++ ) {
			var relationshipName = variables.relationships[ index ];
			var relation         = variables.relationshipsMap[ relationshipName ];
			arguments.base       = relation.applyThroughExists( arguments.base );
		}
		return arguments.base;
	}


	public QuickBuilder function initialThroughConstraints() {
		return addNestedWhereExists( variables.closestToParent.initialThroughConstraints() );
	}

	public QuickBuilder function applyThroughExists( required QuickBuilder base ) {
		var selectedColumns = variables.related.getColumns();

		var joiningQuery = variables.closestToParent
			.getRelated()
			.newQuery()
			.reselectRaw( 1 )
			.whereExists(
				arguments.base.where( function( q ) {
					arrayZipEach(
						[
							variables.parent.keyNames(),
							variables.closestToParent.getForeignKeys()
						],
						function( localKey, foreignKey ) {
							q.whereColumn(
								variables.parent.qualifyColumn( localKey ),
								variables.closestToParent.qualifyColumn( foreignKey )
							);
						}
					);
				} )
			);

		return addNestedWhereExists( joiningQuery ).select( selectedColumns );
	}

	/**
	 * Adds a join to the intermediate tables for the relationship.
	 *
	 * @return  quick.models.Relationships.HasOneOrManyThrough
	 */
	public HasOneOrManyThrough function performJoin( any base = variables.related ) {
		// no arrayReverse in ACF means for loops. :-(
		for ( var index = variables.relationships.len(); index > 0; index-- ) {
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
	 * @return    quick.models.Relationships.HasOneOrManyThrough
	 */
	public boolean function addEagerConstraints( required array entities ) {
		var allKeys = getKeys( entities, variables.closestToParent.getLocalKeys() );
		if ( allKeys.isEmpty() ) {
			return false;
		}

		performJoin();
		var foreignKeys             = variables.parent.keyNames();
		var qualifiedForeignKeyList = foreignKeys
			.reduce( function( acc, foreignKey, i ) {
				if ( i != 1 ) {
					acc.append( "," );
				}
				acc.append( variables.parent.qualifyColumn( foreignKey ) );
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
								variables.parent.qualifyColumn( foreignKey ),
								variables.parent.generateQueryParamStruct( foreignKey, keyValue )
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
		if (
			variables.closestToParent.relationshipClass == "HasOneOrManyThrough" ||
			variables.closestToParent.relationshipClass == "BelongsToThrough"
		) {
			return variables.closestToParent.nestCompareConstraints(
				base   = arguments.base,
				nested = variables.closestToParent.addCompareConstraints().retrieveQuery()
			);
		}

		return tap( arguments.base.select(), function( q ) {
			performJoin( q );
			q.where( function( q2 ) {
				arrayZipEach(
					[
						variables.parent.keyNames(),
						variables.closestToParent.getForeignKeys()
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
	 * This is ignored for `HasOneOrManyThrough` because each of the relationship
	 * components inside `relationshipsMap` will already be aliased.
	 *
	 * @suffix   The suffix to use.
	 *
	 * @return  quick.models.Relationships.HasOneOrManyThrough
	 */
	public HasOneOrManyThrough function applyAliasSuffix( required string suffix ) {
		return this;
	}

	/**
	 * Applies the join for relationship in a `HasOneOrManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public void function applyThroughJoin( required any base ) {
		performJoin( arguments.base );
		variables.closestToParent.applyThroughJoin( arguments.base );
	}

	public array function getForeignKeys() {
		return variables.closestToParent.getLocalKeys();
	}

	public array function getLocalKeys() {
		return variables.parent.keyNames();
	}

}
