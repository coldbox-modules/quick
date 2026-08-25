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

	public any function getUnloadedDefault() {
		return newDefaultEntity();
	}

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
	public boolean function addEagerConstraints( required array entities, required any baseEntity ) {
		var allKeys = getKeys(
			entities,
			variables.closestToParent.getForeignKeys(),
			arguments.baseEntity
		);

		if ( allKeys.isEmpty() ) {
			return false;
		}

		performJoin( variables.relationshipBuilder );
		var relatedKeys          = variables.closestToParent.getLocalKeys();
		var qualifiedForeignKeys = [];
		for ( var i = 1; i <= relatedKeys.len(); i++ ) {
			if ( i != 1 ) {
				qualifiedForeignKeys.append( "," );
			}
			qualifiedForeignKeys.append( variables.closestToParent.qualifyColumn( relatedKeys[ i ] ) );
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
			for ( var i = 1; i <= relatedKeys.len(); i++ ) {
				keyConstraints.where(
					variables.closestToParent.qualifyColumn( relatedKeys[ i ] ),
					variables.closestToParent.generateQueryParamStruct( relatedKeys[ i ], keys[ i ] )
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
			var key = result.retrieveAttribute( "__QuickThroughKey__" );
			if ( !structKeyExists( dictionary, key ) ) {
				dictionary[ key ] = [];
			}
			arrayAppend( dictionary[ key ], result );
		}
		return dictionary;
	}

	/**
	 * Gets the query used to check for relation existance.
	 *
	 * @base    The base entity for the query.
	 *
	 * @return  quick.models.BaseEntity | qb.models.Query.QueryBuilder
	 */
	public any function addCompareConstraints( any base = variables.related, any nested ) {
		var query = arguments.base.select();
		performJoin( query );
		var localKeys   = variables.closestToParent.getForeignKeys();
		var foreignKeys = variables.closestToParent.getLocalKeys();
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
	 * This is ignored for `BelongsToThrough` because each of the relationship
	 * components inside `relationshipsMap` will already be aliased.
	 *
	 * @suffix   The suffix to use.
	 *
	 * @return  quick.models.Relationships.BelongsToThrough
	 */
	public any function applyAliasSuffix( required string suffix ) {
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
			var newEntity = variables.related.newEntity();
			variables.defaultAttributes( newEntity, variables.parent );
			return newEntity;
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
			var defaultEntity = newDefaultEntity();
			if ( structKeyExists( arguments.entity, "isQuickEntity" ) ) {
				arguments.entity.assignRelationship(
					relation,
					isNull( defaultEntity ) ? javacast( "null", "" ) : defaultEntity
				);
			} else {
				arguments.entity[ relation ] = isNull( defaultEntity ) ? {} : defaultEntity.getMemento();
			}
			return arguments.entity;
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
		var dictionary = buildDictionary( arguments.results );
		for ( var entity in arguments.entities ) {
			var keyValues = [];
			for ( var foreignKey in variables.closestToParent.getForeignKeys() ) {
				keyValues.append(
					structKeyExists( entity, "isQuickEntity" ) ? entity.retrieveAttribute( foreignKey ) : entity[
						foreignKey
					]
				);
			}
			var key = keyValues.toList();
			if ( structKeyExists( dictionary, key ) ) {
				if ( structKeyExists( entity, "isQuickEntity" ) ) {
					entity.assignRelationship( relation, getRelationValue( dictionary, key, "one" ) );
				} else {
					entity[ relation ] = getRelationValue( dictionary, key, "one" );
				}
			}
		}
		return arguments.entities;
	}

	/**
	 * Retrieves the value for the key from the dictionary.
	 * Also, returns either the first result for a "one" type or the entire
	 * array of results for a "many" type.
	 *
	 * @dictionary  A dictionary mapping the `foreignKey` value to related results.
	 * @key         The `foreignKey` value to look up in the dictionary.
	 * @type        The type of the relation value, "many" or "one".
	 *
	 * @return      quick.models.BaseEntity | [quick.models.BaseEntity]
	 */
	public any function getRelationValue(
		required struct dictionary,
		required string key,
		required string type
	) {
		var value = arguments.dictionary[ arguments.key ];
		return arguments.type == "one" ? value[ 1 ] : value;
	}

	/**
	 * Applies the constraints for the final relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the constraints to.
	 *
	 * @return  void
	 */
	public void function applyThroughConstraints( required any base ) {
		var query       = queryBuilderFor( arguments.base );
		var constraints = query.forNestedWhere();
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			constraints.where(
				variables.related.qualifyColumn( variables.foreignKeys[ i ] ),
				variables.parent.retrieveAttribute( variables.localKeys[ i ] )
			);
		}
		query.addNestedWhereQuery( constraints );
	}

	public array function getForeignKeys() {
		return variables.closestToParent.getLocalKeys();
	}

	public array function getLocalKeys() {
		return variables.closestToParent.getForeignKeys();
	}

}
