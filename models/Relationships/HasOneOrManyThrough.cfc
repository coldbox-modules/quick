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
		var selectedColumns = variables.relationshipBuilder.getColumns();
		var base            = initialThroughConstraints();
		base.select( selectedColumns );
		variables.relationshipBuilder.populateQuery( base );
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
		var selectedColumns = variables.relationshipBuilder.getColumns();

		var localKeys   = variables.closestToParent.getQualifiedLocalKeys();
		var foreignKeys = variables.closestToParent.getForeignKeys();
		var constraints = arguments.base.getQB().forNestedWhere();
		for ( var i = 1; i <= localKeys.len(); i++ ) {
			constraints.whereColumn( localKeys[ i ], variables.closestToParent.qualifyColumn( foreignKeys[ i ] ) );
		}
		arguments.base.getQB().addNestedWhereQuery( constraints );
		var joiningQuery = variables.closestToParent
			.getRelated()
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( arguments.base.getQB() );

		return addNestedWhereExists( joiningQuery ).select( selectedColumns );
	}

	/**
	 * Adds a join to the intermediate tables for the relationship.
	 *
	 * @return  quick.models.Relationships.HasOneOrManyThrough
	 */
	public HasOneOrManyThrough function performJoin( any base = variables.relationshipBuilder ) {
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
	 * @return    quick.models.Relationships.HasOneOrManyThrough
	 */
	public boolean function addEagerConstraints( required array entities, required any baseEntity ) {
		var allKeys = getKeys(
			entities,
			variables.closestToParent.getLocalKeys(),
			arguments.baseEntity
		);
		if ( allKeys.isEmpty() ) {
			return false;
		}

		performJoin();

		// perform final join for eager loading
		var relationshipName = variables.relationships[ 1 ];
		var relation         = variables.relationshipsMap[ relationshipName ];
		relation.applyThroughJoin( variables.relationshipBuilder );

		var foreignKeys          = variables.parent.keyNames();
		var qualifiedForeignKeys = [];
		for ( var i = 1; i <= foreignKeys.len(); i++ ) {
			if ( i != 1 ) {
				qualifiedForeignKeys.append( "," );
			}
			qualifiedForeignKeys.append( variables.parent.qualifyColumn( foreignKeys[ i ] ) );
		}
		var qualifiedForeignKeyList = qualifiedForeignKeys.toList();
		if ( qualifiedForeignKeyList.listLen() > 1 ) {
			variables.relationshipBuilder.selectRaw( "CONCAT(#qualifiedForeignKeyList#) AS __QuickThroughKey__" );
		} else {
			variables.relationshipBuilder.addSelect( "#qualifiedForeignKeyList# AS __QuickThroughKey__" );
		}
		variables.relationshipBuilder.appendVirtualAttribute( name = "__QuickThroughKey__", excludeFromMemento = true );
		var eagerConstraints = variables.relationshipBuilder.getQB().forNestedWhere();
		for ( var keys in allKeys ) {
			var keyConstraints = eagerConstraints.forNestedWhere();
			for ( var i = 1; i <= foreignKeys.len(); i++ ) {
				keyConstraints.where(
					variables.parent.qualifyColumn( foreignKeys[ i ] ),
					variables.parent.generateQueryParamStruct( foreignKeys[ i ], keys[ i ] )
				);
			}
			eagerConstraints.addNestedWhereQuery( keyConstraints, "or" );
		}
		variables.relationshipBuilder.getQB().addNestedWhereQuery( eagerConstraints );

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
		var dictionary = {};
		for ( var result in arguments.results ) {
			var key = structKeyExists( result, "isQuickEntity" ) ? result.retrieveAttribute( "__QuickThroughKey__" ) : result[
				"__QuickThroughKey__"
			];
			if ( !structKeyExists( dictionary, key ) ) {
				dictionary[ key ] = [];
			}
			arrayAppend( dictionary[ key ], result );
		}
		return dictionary;
	}

	/**
	 * Matches the array of entity results to a single value for the relation.
	 *
	 * @entities  The entities being eager loaded.
	 * @results   The relationship results.
	 * @relation  The name of the relation being loaded.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function matchOne(
		required array entities,
		required array results,
		required string relation
	) {
		var dictionary = buildDictionary( arguments.results );
		for ( var entity in arguments.entities ) {
			var keyValues = [];
			for ( var localKey in variables.closestToParent.getLocalKeys() ) {
				keyValues.append(
					structKeyExists( entity, "isQuickEntity" ) ? entity.retrieveAttribute( localKey ) : entity[ localKey ]
				);
			}
			var key = keyValues.toList();
			if ( structKeyExists( dictionary, key ) ) {
				if ( structKeyExists( entity, "isQuickEntity" ) ) {
					entity.assignRelationship( relation, dictionary[ key ][ 1 ] );
				} else {
					entity[ relation ] = dictionary[ key ][ 1 ];
				}
			}
		}
		return arguments.entities;
	}

	/**
	 * Gets the query used to check for relation existance.
	 *
	 * @base    The base entity for the query.
	 *
	 * @return  quick.models.BaseEntity | qb.models.Query.QueryBuilder
	 */
	public any function addCompareConstraints( any base = variables.relationshipBuilder, any nested ) {
		if (
			variables.closestToParent.relationshipClass == "HasOneOrManyThrough" ||
			variables.closestToParent.relationshipClass == "BelongsToThrough"
		) {
			return variables.closestToParent.nestCompareConstraints(
				base   = arguments.base,
				nested = variables.closestToParent.addCompareConstraints()
			);
		}

		var query = arguments.base.select();
		performJoin( query );
		var localKeys   = variables.parent.keyNames();
		var foreignKeys = variables.closestToParent.getForeignKeys();
		var qb          = queryBuilderFor( query );
		var constraints = qb.forNestedWhere();
		for ( var i = 1; i <= localKeys.len(); i++ ) {
			constraints.whereColumn(
				variables.parent.qualifyColumn( localKeys[ i ] ),
				variables.closestToParent.qualifyColumn( foreignKeys[ i ] )
			);
		}
		qb.addNestedWhereQuery( constraints );
		return query;
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
	public any function applyAliasSuffix( required string suffix ) {
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
