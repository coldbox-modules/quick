/**
 * Represents a polymorphicBelongsTo relationship.
 *
 * A polymorphic relationship is one where the related entity can belong to
 * more than one type of entity.  As such, the type of entity it is related
 * to is stored alongside the foreign key values.
 *
 * This is a relationship where the related entity belongs to
 * exactly one of the polymorphic entity. The inverse of this relationship
 * is a `polymorphicHasMany` relationship.
 *
 * For instance, a `Comment` may belong to either a `Post` or a `Video`.
 * This would be modeled in Quick by adding a method to the `Comment` entity
 * that returns a `PolymorphicBelongsTo` relationship instance.
 *
 * ```
 * function source() {
 *     returns polymorphicBelongsTo( "commentable" );
 * }
 * ```
 */
component extends="quick.models.Relationships.BelongsTo" accessors="true" {

	/**
	 * The name of the column that contains the entity type
	 * of the polymorphic relationship.
	 */
	property name="morphType" type="string";

	/**
	 * Used to check for the type of relationship more quickly than using isInstanceOf.
	 */
	this.relationshipClass = "PolymorphicBelongsTo";

	/**
	 * Creates a belongsTo relationship.
	 *
	 * @related             The related entity instance.
	 * @relationName        The WireBox mapping for the related entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 * @parent              The parent entity instance for the relationship.
	 *                      In a `BelongsTo` relationship, this is also referred
	 *                      to internally as `child`.
	 * @foreignKeys         The column names on the `parent` entity that refers to
	 *                      the `localKeys` on the `related` entity.
	 * @localKeys           The column names on the `realted` entity that is referred
	 *                      to by the `foreignKeys` of the `parent` entity.
	 * @type                The name of the column that contains the entity type
	 *                      of the polymorphic relationship.
	 *
	 * @return              quick.models.Relationships.PolymorphicBelongsTo
	 */
	public PolymorphicBelongsTo function init(
		required any related,
		required string relationName,
		required string relationMethodName,
		required any parent,
		required array foreignKeys,
		required array localKeys,
		required string type,
		boolean withConstraints = true
	) {
		variables.morphType = arguments.type;

		return super.init(
			related            = arguments.related,
			relationName       = arguments.relationName,
			relationMethodName = arguments.relationMethodName,
			parent             = arguments.parent,
			foreignKeys        = arguments.foreignKeys,
			localKeys          = arguments.localKeys,
			withConstraints    = arguments.withConstraints
		);
	}

	/**
	 * Adds the constraints for eager loading.
	 *
	 * @entities  The entities being eager loaded.
	 *
	 * @return    quick.models.Relationships.PolymorphicBelongsTo
	 */
	public boolean function addEagerConstraints( required array entities, required any baseEntity ) {
		variables.entities = arguments.entities;
		buildDictionary( arguments.baseEntity );
		return true;
	}

	/**
	 * Builds a dictionary of each type and each foreign key value inside each type.
	 * Uses the entities set in the variables scope and assigns the results to
	 * the variables scope.
	 *
	 * @return  {string: {any: quick.models.BaseEntity}}
	 */
	public struct function buildDictionary( required any baseEntity ) {
		variables.dictionary = {};
		for ( var entity in variables.entities ) {
			var type = retrieveMorphType( entity, arguments.baseEntity );
			if ( !structKeyExists( variables.dictionary, type ) ) {
				variables.dictionary[ type ] = {};
			}
			var keyValues = [];
			for ( var foreignKey in variables.foreignKeys ) {
				keyValues.append(
					entityRetrieveAttribute(
						entity,
						foreignKey,
						arguments.baseEntity
					)
				);
			}
			var key = keyValues.toList();
			if ( !structKeyExists( variables.dictionary[ type ], key ) ) {
				variables.dictionary[ type ][ key ] = [];
			}
			arrayAppend( variables.dictionary[ type ][ key ], entity );
		}
		return variables.dictionary;
	}

	/**
	 * Returns the result of the relationship.
	 *
	 * @return  quick.models.BaseEntity | null
	 */
	public any function getResults() {
		return variables.localKeys.isEmpty() ? javacast( "null", "" ) : super.getResults();
	}

	/**
	 * Retrieves the entities for eager loading.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function getEager( boolean asQuery = false, boolean withAliases = false ) {
		for ( var type in variables.dictionary ) {
			var instance = createModelByType( type );
			matchToMorphParents(
				type,
				instance,
				getResultsByType(
					type,
					instance,
					arguments.asQuery,
					arguments.withAliases
				)
			);
		}

		return variables.entities;
	}

	/**
	 * Prepares each morph-type query on the calling thread.
	 *
	 * @internal
	 */
	public any function prepareEagerQuery( boolean asQuery = false, boolean withAliases = false ) {
		variables.parallelEagerQueries = [];
		for ( var type in variables.dictionary ) {
			var morphParent = createModelByType( type );
			var query       = prepareResultsQueryByType(
				type,
				morphParent,
				arguments.asQuery,
				arguments.withAliases
			);
			applyDefaultDatasourceToParallelQuery( query );
			variables.parallelEagerQueries.append( {
				"morphParent" : morphParent,
				"query"       : query,
				"type"        : type
			} );
		}
		return this;
	}

	private void function applyDefaultDatasourceToParallelQuery( required any query ) {
		var queryBuilder   = arguments.query.getQB();
		var defaultOptions = queryBuilder.getDefaultOptions();
		if ( defaultOptions.keyExists( "datasource" ) ) {
			return;
		}

		var applicationMetadata = getApplicationMetadata();
		if ( applicationMetadata.keyExists( "datasource" ) && !isNull( applicationMetadata.datasource ) ) {
			queryBuilder.mergeDefaultOptions( { "datasource" : applicationMetadata.datasource } );
		}
	}

	/**
	 * Executes the prepared morph queries without hydrating their rows.
	 *
	 * @internal
	 */
	public array function retrieveEagerRows() {
		var resultSets = [];
		for ( var eagerQuery in variables.parallelEagerQueries ) {
			resultSets.append( eagerQuery.query.retrieveUnhydratedResults() );
		}
		return resultSets;
	}

	/**
	 * Hydrates and matches each morph result set on the calling thread.
	 *
	 * @internal
	 */
	public array function hydrateEagerRows( required array rows ) {
		for ( var i = 1; i <= variables.parallelEagerQueries.len(); i++ ) {
			var eagerQuery = variables.parallelEagerQueries[ i ];
			matchToMorphParents(
				eagerQuery.type,
				eagerQuery.morphParent,
				eagerQuery.query.hydrateUnhydratedResults( arguments.rows[ i ] )
			);
		}
		return variables.entities;
	}

	/**
	 * Executes a query and returns the results for a given polymorphic type.
	 *
	 * @type         The polymorphic type to retrieve.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function getResultsByType(
		required string type,
		required any instance,
		boolean asQuery     = false,
		boolean withAliases = false
	) {
		var allKeys = gatherKeysByType( type );
		if ( allKeys.isEmpty() ) {
			return [];
		}
		return prepareResultsQueryByType(
			arguments.type,
			arguments.instance,
			arguments.asQuery,
			arguments.withAliases
		).get();
	}

	private any function prepareResultsQueryByType(
		required string type,
		required any instance,
		boolean asQuery     = false,
		boolean withAliases = false
	) {
		var localKeys = variables.localKeys.isEmpty() ? arguments.instance.keyNames() : variables.localKeys;
		var allKeys   = gatherKeysByType( arguments.type );
		var query     = arguments.instance.newQuery();
		if ( arguments.asQuery ) {
			query.asQuery( arguments.withAliases );
		}
		var eagerConstraints = query.getQB().forNestedWhere();
		for ( var keys in allKeys ) {
			var keyConstraints = eagerConstraints.forNestedWhere();
			for ( var i = 1; i <= localKeys.len(); i++ ) {
				keyConstraints.where( localKeys[ i ], keys[ i ] );
			}
			eagerConstraints.addNestedWhereQuery( keyConstraints, "or" );
		}
		query.getQB().addNestedWhereQuery( eagerConstraints );
		query.prepareUnhydratedQuery();
		return query;
	}

	/**
	 * Gets the foreign key values for a given type.
	 *
	 * @type         The type to retrieve the foreign key values.
	 *
	 * @doc_generic  any
	 * @return       [any]
	 */
	public array function gatherKeysByType( required string type ) {
		var serializedKeys = [];
		for ( var key in variables.dictionary[ arguments.type ] ) {
			var entity    = variables.dictionary[ arguments.type ][ key ][ 1 ];
			var keyValues = [];
			for ( var foreignKey in variables.foreignKeys ) {
				keyValues.append( entityRetrieveAttribute( entity, foreignKey, variables.parent ) );
			}
			serializedKeys.append( keyValues.toList() );
		}

		var keys = [];
		for ( var serializedKey in unique( serializedKeys ) ) {
			keys.append( serializedKey.listToArray() );
		}
		return keys;
	}

	/**
	 * Creates a new instance of an entity for a given type.
	 *
	 * @type    The type of entity to create.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function createModelByType( required string type ) {
		return variables.wirebox.getInstance( arguments.type );
	}

	/**
	 * Matches the results to the correct type and foreign key.
	 *
	 * @type     The polymorphic type being matched.
	 * @results  The relationship results.
	 *
	 * @return   quick.models.Relationships.PolymorphicBelongsTo
	 */
	public PolymorphicBelongsTo function matchToMorphParents(
		required string type,
		required any morphParent,
		required array results
	) {
		for ( var result in arguments.results ) {
			var localKeyValues = [];
			if ( variables.localKeys.isEmpty() ) {
				localKeyValues = entityRetrieveKeyValues(
					arguments.type,
					result,
					arguments.morphParent
				);
			} else {
				for ( var localKey in variables.localKeys ) {
					localKeyValues.append( result.retrieveAttribute( localKey ) );
				}
			}
			var localDictionaryKey = localKeyValues.toList();

			if ( variables.dictionary[ arguments.type ].keyExists( localDictionaryKey ) ) {
				var entities = variables.dictionary[ arguments.type ][ localDictionaryKey ];
				for ( var entity in entities ) {
					if ( structKeyExists( entity, "isQuickEntity" ) ) {
						entity.assignRelationship( variables.relationMethodName, result );
					} else {
						entity[ variables.relationMethodName ] = result;
					}
				}
			}
		}
		return this;
	}

	public QuickBuilder function initialThroughConstraints() {
		var base = variables.related.newQuery().reselectRaw( 1 );

		for ( var i = 1; i <= variables.localKeys.len(); i++ ) {
			base.where(
				variables.related.qualifyColumn( variables.localKeys[ i ] ),
				variables.parent.retrieveAttribute( variables.foreignKeys[ i ] )
			);
		}

		return base;
	}

	private string function retrieveMorphType( required any entity, required any baseEntity ) {
		if ( structKeyExists( arguments.entity, "isQuickEntity" ) ) {
			return arguments.entity.retrieveAttribute( variables.morphType );
		}

		if ( structKeyExists( arguments.entity, variables.morphType ) ) {
			return arguments.entity[ variables.morphType ];
		}

		return arguments.entity[ arguments.baseEntity.retrieveAliasForColumn( variables.morphType ) ];
	}

	private array function entityRetrieveKeyValues(
		required string type,
		required any entity,
		required any morphParent
	) {
		if ( structKeyExists( arguments.entity, "isQuickEntity" ) ) {
			return arguments.entity.keyValues();
		}

		var keyValues = [];
		for ( var key in arguments.morphParent.keyNames() ) {
			keyValues.append(
				entityRetrieveAttribute(
					arguments.entity,
					key,
					arguments.morphParent
				)
			);
		}
		return keyValues;
	}

}
