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
	public boolean function addEagerConstraints( required array entities ) {
		variables.entities = arguments.entities;
		buildDictionary();
		return true;
	}

	/**
	 * Builds a dictionary of each type and each foreign key value inside each type.
	 * Uses the entities set in the variables scope and assigns the results to
	 * the variables scope.
	 *
	 * @return  {string: {any: quick.models.BaseEntity}}
	 */
	public struct function buildDictionary() {
		variables.dictionary = variables.entities.reduce( function( dict, entity ) {
			var type = arguments.entity.retrieveAttribute( variables.morphType );
			if ( !structKeyExists( arguments.dict, type ) ) {
				arguments.dict[ type ] = {};
			}
			var key = variables.foreignKeys
				.map( function( foreignKey ) {
					return entity.retrieveAttribute( foreignKey );
				} )
				.toList();
			if ( !structKeyExists( arguments.dict[ type ], key ) ) {
				arguments.dict[ type ][ key ] = [];
			}
			arrayAppend( arguments.dict[ type ][ key ], arguments.entity );
			return arguments.dict;
		}, {} );
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
	public array function getEager() {
		structKeyArray( variables.dictionary ).each( function( type ) {
			matchToMorphParents( arguments.type, getResultsByType( arguments.type ) );
		} );

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
	public array function getResultsByType( required string type ) {
		var instance = createModelByType( arguments.type ).with( variables.related.get_eagerLoad() );

		var localKeys = variables.localKeys.isEmpty() ? instance.keyNames() : variables.localKeys;

		var allKeys = gatherKeysByType( type );

		if ( allKeys.isEmpty() ) {
			return [];
		}

		return instance
			.where( function( q1 ) {
				gatherKeysByType( type ).each( function( keys ) {
					q1.orWhere( function( q2 ) {
						arrayZipEach( [ localKeys, keys ], function( localKey, keyValue ) {
							q2.where( localKey, keyValue );
						} );
					} );
				} );
			} )
			.get();
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
		return unique(
			structReduce(
				variables.dictionary[ arguments.type ],
				function( acc, key, values ) {
					var entity = arguments.values[ 1 ];
					arrayAppend(
						arguments.acc,
						variables.foreignKeys
							.map( function( foreignKey ) {
								return entity.retrieveAttribute( foreignKey );
							} )
							.toList()
					);
					return acc;
				},
				[]
			)
		).map( function( key ) {
			return key.listToArray();
		} );
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
	public PolymorphicBelongsTo function matchToMorphParents( required string type, required array results ) {
		for ( var result in arguments.results ) {
			var localDictionaryKey = variables.localKeys.isEmpty() ? result.keyValues().toList() : variables.localKeys
				.map( function( localKey ) {
					return result.retrieveAttribute( localKey );
				} )
				.toList();

			if ( variables.dictionary[ arguments.type ].keyExists( localDictionaryKey ) ) {
				var entities = variables.dictionary[ arguments.type ][ localDictionaryKey ];
				for ( var entity in entities ) {
					entity.assignRelationship( variables.relationMethodName, result );
				}
			}
		}
		return this;
	}

	public QuickBuilder function initialThroughConstraints() {
		var base = variables.related.newQuery().reselectRaw( 1 );

		arrayZipEach(
			[
				variables.localKeys,
				variables.foreignKeys
			],
			function( localKey, foreignKey ) {
				base.where(
					variables.related.qualifyColumn( localKey ),
					variables.parent.retrieveAttribute( foreignKey )
				);
			}
		);

		return base;
	}

}
