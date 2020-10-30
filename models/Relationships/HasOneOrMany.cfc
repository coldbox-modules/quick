/**
 * Abstract HasOneOrMany used to provide shared methods across
 * `hasOne` and `hasMany` relationships.
 *
 * @doc_abstract true
 */
component extends="quick.models.Relationships.BaseRelationship" accessors="true" {

	/**
	 * The foreign keys on the parent entity.
	 */
	property name="foreignKeys";

	/**
	 * The local primary keys on the parent entity.
	 */
	property name="localKeys";

	/**
	 * Used to check for the type of relationship more quickly than using isInstanceOf.
	 */
	this.relationshipClass = "HasOneOrMany";

	/**
	 * Creates a HasOneOrMany relationship.
	 *
	 * @related             The related entity instance.
	 * @relationName        The WireBox mapping for the related entity.
	 * @relationMethodName  The method name called to retrieve this relationship.
	 * @parent              The parent entity instance for the relationship.
	 * @foreignKeys         The foreign keys on the parent entity.
	 * @localKeys           The local primary keys on the parent entity.
	 *
	 * @return              quick.models.Relationships.HasOneOrMany
	 */
	public HasOneOrMany function init(
		required any related,
		required string relationName,
		required string relationMethodName,
		required any parent,
		required array foreignKeys,
		required array localKeys,
		boolean withConstraints = true
	) {
		variables.localKeys   = arguments.localKeys;
		variables.foreignKeys = arguments.foreignKeys;

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
	 * @return  quick.models.Relationships.HasOneOrMany
	 */
	public HasOneOrMany function addConstraints() {
		variables.related.where( function( q ) {
			arrayZipEach(
				[
					getQualifiedForeignKeyNames(),
					getParentKeys()
				],
				function( keyName, parentKey ) {
					q.where( keyName, parentKey ).whereNotNull( keyName );
				}
			);
		} );
		return this;
	}

	/**
	 * Adds the constraints for eager loading.
	 *
	 * @entities  The entities being eager loaded.
	 *
	 * @return    quick.models.Relationships.HasOneOrMany
	 */
	public boolean function addEagerConstraints( required array entities ) {
		var allKeys = getKeys( entities, variables.localKeys );
		if ( allKeys.isEmpty() ) {
			return false;
		}

		variables.related
			.retrieveQuery()
			.where( function( q ) {
				allKeys.each( function( keys ) {
					q.orWhere( function( q2 ) {
						arrayZipEach( [ variables.foreignKeys, keys ], function( foreignKey, keyValue ) {
							q2.where(
								variables.related.qualifyColumn( foreignKey ),
								variables.related.generateQueryParamStruct( foreignKey, keyValue )
							);
						} );
					} );
				} );
			} );

		return true;
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
	public array function matchOne(
		required array entities,
		required array results,
		required string relation
	) {
		arguments.type = "one";
		return matchOneOrMany( argumentCollection = arguments );
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
	public array function matchMany(
		required array entities,
		required array results,
		required string relation
	) {
		arguments.type = "many";
		return matchOneOrMany( argumentCollection = arguments );
	}

	/**
	 * Matches the array of entity results to either an array of entities for a
	 * "many" relation type or a single entity for a "one" relation type.
	 * Any matched records are populated into the matched entity's relation.
	 *
	 * @entities     The entities being eager loaded.
	 * @results      The relationship results.
	 * @relation     The relation name being loaded.
	 * @type         The type of the relation value, "many" or "one".
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function matchOneOrMany(
		required array entities,
		required array results,
		required string relation,
		required string type
	) {
		var dictionary = buildDictionary( arguments.results );
		arguments.entities.each( function( entity ) {
			var key = variables.localKeys
				.map( function( localKey ) {
					return entity.retrieveAttribute( localKey );
				} )
				.toList();
			if ( structKeyExists( dictionary, key ) ) {
				arguments.entity.assignRelationship( relation, getRelationValue( dictionary, key, type ) );
			}
		} );
		return arguments.entities;
	}

	/**
	 * Builds a dictionary mapping the `foreignKey` value to related results.
	 *
	 * @results      The array of entities from retrieving the relationship.
	 *
	 * @doc_generic  any,quick.models.BaseEntity
	 * @return       {any: quick.models.BaseEntity}
	 */
	public struct function buildDictionary( required array results ) {
		return arguments.results.reduce( function( dict, result ) {
			var key = variables.foreignKeys
				.map( function( foreignKey ) {
					return result.retrieveAttribute( foreignKey );
				} )
				.toList();
			if ( !structKeyExists( arguments.dict, key ) ) {
				arguments.dict[ key ] = [];
			}
			arrayAppend( arguments.dict[ key ], arguments.result );
			return arguments.dict;
		}, {} );
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
	 * Retrieves the parent's local key value.
	 *
	 * @return   any
	 */
	public any function getParentKeys() {
		return variables.localKeys.map( function( localKey ) {
			return variables.parent.retrieveAttribute( localKey );
		} );
	}

	/**
	 * Associates the given entity when the relationship is used as a setter.
	 *
	 * Relationships on entities can be called with `set` in front of it.
	 * If it is, a `HasOne` or `HasMany` relationship forwards the call to `saveMany`.
	 *
	 * @entities      An array of entities to set.
	 *
	 * @doc_abstract  quick.models.BaseEntity
	 * @return        [quick.models.BaseEntity]
	 */
	public array function applySetter() {
		variables.related.updateAll(
			attributes = variables.foreignKeys.reduce( function( acc, foreignKey ) {
				acc[ foreignKey ] = {
					"value"     : "",
					"cfsqltype" : "varchar",
					"null"      : true,
					"nulls"     : true
				};
				return acc;
			}, {} ),
			force = true
		);
		return saveMany( argumentCollection = arguments );
	}

	/**
	 * Associates each of the passed in entities with the parent entity.
	 *
	 * @entities      An single entity or array of entities to be associated.
	 *
	 * @doc_abstract  quick.models.BaseEntity
	 * @return        [quick.models.BaseEntity]
	 */
	public array function saveMany( required any entities ) {
		arguments.entities = isArray( arguments.entities ) ? arguments.entities : [ arguments.entities ];

		return arguments.entities.map( function( entity ) {
			return save( arguments.entity );
		} );
	}

	/**
	 * Associates an entity or key value for an entity to the parent entity.
	 *
	 * @entity   An entity or key value for an entity to associate.
	 *
	 * @return   quick.models.BaseEntity
	 */
	public any function save( required any entity ) {
		if ( !isObject( arguments.entity ) ) {
			arguments.entity = arrayWrap( arguments.entity );
			guardAgainstKeyLengthMismatch( arguments.entity, variables.related.keyNames() );
			arguments.entity = tap( variables.related.newEntity(), function( e ) {
				e.set_loaded( true );
				arrayZipEach( [ variables.related.keyNames(), entity ], function( keyName, value ) {
					e.forceAssignAttribute( keyName, value );
				} );
			} );
		}
		setForeignAttributesForCreate( arguments.entity );
		return arguments.entity.save();
	}

	/**
	 * Creates a new entity, associates it to the parent entity, and returns it.
	 *
	 * @attributes  The attributes for the new related entity.
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function create( struct attributes = {} ) {
		var newInstance = variables.related.newEntity().fill( arguments.attributes );
		setForeignAttributesForCreate( newInstance );
		return newInstance.save();
	}

	/**
	 * Sets the parent key value as the foreign key for the entity.
	 *
	 * @entity   The entity to associate.
	 *
	 * @return   quick.models.BaseEntity
	 */
	public any function setForeignAttributesForCreate( required any entity ) {
		return tap( arguments.entity, function( e ) {
			arrayZipEach(
				[
					variables.foreignKeys,
					getParentKeys()
				],
				function( foreignKey, parentKey ) {
					e.forceAssignAttribute( foreignKey, parentKey );
				}
			);
		} );
	}


	/**
	 * Returns the fully-qualified local key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedLocalKeys() {
		return variables.localKeys.map( function( localKey ) {
			return variables.parent.qualifyColumn( localKey );
		} );
	}

	/**
	 * Returns the fully-qualified column name of foreign key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedForeignKeyNames() {
		return variables.foreignKeys.map( function( foreignKey ) {
			return variables.related.qualifyColumn( foreignKey );
		} );
	}

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public QuickBuilder function applyThroughExists( any base = variables.related ) {
		// apply compare constraints
		arrayZipEach(
			[
				variables.foreignKeys,
				variables.localKeys
			],
			function( foreignKey, localKey ) {
				base.whereColumn(
					variables.related.qualifyColumn( foreignKey ),
					variables.parent.qualifyColumn( localKey )
				);
			}
		);

		// nest in exists
		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( arguments.base );
	}

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public void function applyThroughJoin( required any base ) {
		arguments.base.join( variables.parent.tableName(), function( j ) {
			arrayZipEach(
				[
					variables.foreignKeys,
					variables.localKeys
				],
				function( foreignKey, localKey ) {
					j.on( variables.related.qualifyColumn( foreignKey ), variables.parent.qualifyColumn( localKey ) );
				}
			);
		} );
	}

	/**
	 * Applies the constraints for the final relationship in a `hasManyThrough` chain.
	 *
	 * @return  void
	 */
	public QueryBuilder function initialThroughConstraints() {
		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.where( function( q ) {
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

}
