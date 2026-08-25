/**
 * Abstract HasOneOrMany used to provide shared methods across
 * `hasOne` and `hasMany` relationships.
 *
 * @doc_abstract true
 */
component
	extends   ="quick.models.Relationships.BaseRelationship"
	implements="IConcatenatableRelationship"
	accessors ="true"
{

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
		boolean withConstraints        = true,
		boolean collectionRelationship = false
	) {
		variables.localKeys   = arguments.localKeys;
		variables.foreignKeys = arguments.foreignKeys;

		return super.init(
			related                = arguments.related,
			relationName           = arguments.relationName,
			relationMethodName     = arguments.relationMethodName,
			parent                 = arguments.parent,
			withConstraints        = arguments.withConstraints,
			collectionRelationship = arguments.collectionRelationship
		);
	}

	/**
	 * Adds the constraints to the related entity.
	 *
	 * @return  quick.models.Relationships.HasOneOrMany
	 */
	public HasOneOrMany function addConstraints() {
		var foreignKeyNames = getQualifiedForeignKeyNames();
		var parentKeys      = getParentKeys();
		var constraints     = variables.relationshipBuilder.getQB().forNestedWhere();
		for ( var i = 1; i <= foreignKeyNames.len(); i++ ) {
			constraints.where( foreignKeyNames[ i ], parentKeys[ i ] ).whereNotNull( foreignKeyNames[ i ] );
		}
		variables.relationshipBuilder.getQB().addNestedWhereQuery( constraints );
		return this;
	}

	/**
	 * Adds the constraints for eager loading.
	 *
	 * @entities  The entities being eager loaded.
	 *
	 * @return    quick.models.Relationships.HasOneOrMany
	 */
	public boolean function addEagerConstraints( required array entities, required any baseEntity ) {
		var allKeys = getKeys(
			entities,
			variables.localKeys,
			arguments.baseEntity
		);
		if ( allKeys.isEmpty() ) {
			return false;
		}

		var eagerConstraints = variables.relationshipBuilder.getQB().forNestedWhere();
		for ( var keys in allKeys ) {
			var keyConstraints = eagerConstraints.forNestedWhere();
			for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
				keyConstraints.where(
					variables.related.qualifyColumn( variables.foreignKeys[ i ] ),
					variables.relationshipBuilder.generateQueryParamStruct( variables.foreignKeys[ i ], keys[ i ] )
				);
			}
			eagerConstraints.addNestedWhereQuery( keyConstraints, "or" );
		}
		variables.relationshipBuilder.getQB().addNestedWhereQuery( eagerConstraints );

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
		for ( var entity in arguments.entities ) {
			var keyValues = [];
			for ( var localKey in variables.localKeys ) {
				keyValues.append(
					structKeyExists( entity, "isQuickEntity" ) ? entity.retrieveAttribute( localKey ) : entity[ localKey ]
				);
			}
			var key = keyValues.toList();
			if ( structKeyExists( dictionary, key ) ) {
				if ( structKeyExists( entity, "isQuickEntity" ) ) {
					entity.assignRelationship( arguments.relation, getRelationValue( dictionary, key, arguments.type ) );
				} else {
					entity[ arguments.relation ] = getRelationValue( dictionary, key, arguments.type );
				}
			}
		}
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
		var dictionary = {};
		for ( var result in arguments.results ) {
			var keyValues = [];
			for ( var foreignKey in variables.foreignKeys ) {
				keyValues.append(
					entityRetrieveAttribute(
						result,
						foreignKey,
						variables.related
					)
				);
			}
			var key = keyValues.toList();
			if ( !structKeyExists( dictionary, key ) ) {
				dictionary[ key ] = [];
			}
			arrayAppend( dictionary[ key ], result );
		}
		return dictionary;
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
		var parentKeys = [];
		for ( var localKey in variables.localKeys ) {
			parentKeys.append( variables.parent.retrieveAttribute( localKey ) );
		}
		return parentKeys;
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
		var nullAttributes = {};
		for ( var foreignKey in variables.foreignKeys ) {
			nullAttributes[ foreignKey ] = {
				"value"     : "",
				"cfsqltype" : "varchar",
				"null"      : true,
				"nulls"     : true
			};
		}
		variables.relationshipBuilder.updateAll( attributes = nullAttributes, force = true );
		var savedEntities = saveMany( argumentCollection = arguments );
		variables.parent.assignRelationship( variables.relationMethodName, savedEntities );
		return savedEntities;
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
		arguments.entities        = isArray( arguments.entities ) ? arguments.entities : [ arguments.entities ];
		var relationshipWasLoaded = variables.parent.isRelationshipLoaded( variables.relationMethodName );
		var loadedEntities        = relationshipWasLoaded ? variables.parent.retrieveRelationship(
			variables.relationMethodName
		) : [];

		var savedEntities = [];
		for ( var entity in arguments.entities ) {
			savedEntities.append( save( entity ) );
		}
		if ( relationshipWasLoaded ) {
			loadedEntities.append( savedEntities, true );
			variables.parent.assignRelationship( variables.relationMethodName, loadedEntities );
		}
		return savedEntities;
	}

	/**
	 * Deletes entities matching the relationship query and synchronizes a loaded parent cache.
	 *
	 * @ids  An optional array of related entity ids to delete.
	 *
	 * @return  { "query": QueryBuilder Return Format, "result": struct }
	 */
	public struct function deleteAll( array ids = [] ) {
		var result = variables.relationshipBuilder.deleteAll( arguments.ids );

		if ( variables.parent.isRelationshipLoaded( variables.relationMethodName ) ) {
			if ( arguments.ids.isEmpty() ) {
				var loadedValue = variables.parent.retrieveRelationship( variables.relationMethodName );
				variables.parent.assignRelationship(
					variables.relationMethodName,
					isArray( loadedValue ) ? [] : javacast( "null", "" )
				);
			} else {
				variables.parent.clearRelationship( variables.relationMethodName );
			}
		}

		return result;
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
			var keyValues       = arguments.entity;
			arguments.entity    = variables.related.newEntity();
			var relatedKeyNames = variables.related.keyNames();
			arguments.entity.set_loaded( true );
			for ( var i = 1; i <= relatedKeyNames.len(); i++ ) {
				arguments.entity.forceAssignAttribute( relatedKeyNames[ i ], keyValues[ i ] );
			}
		}
		setForeignAttributesForCreate( arguments.entity );
		return arguments.entity.save();
	}

	/**
	 * Creates a new entity, associates it to the parent entity, and returns it.
	 *
	 * @attributes           The attributes for the new related entity.
	 * @inverseRelationship  An optional relationship name on the new entity to
	 *                       seed with the parent before saving.
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function create( struct attributes = {}, string inverseRelationship ) {
		var createdEntity = newEntity().fill( arguments.attributes );
		if ( !isNull( arguments.inverseRelationship ) ) {
			if ( !createdEntity.hasRelationship( arguments.inverseRelationship ) ) {
				throw(
					type    = "RelationshipNotFound",
					message = "The [#arguments.inverseRelationship#] relationship was not found on the [#createdEntity.entityName()#] entity."
				);
			}
			createdEntity.assignRelationship( arguments.inverseRelationship, variables.parent );
		}
		createdEntity.save();

		if ( variables.parent.isRelationshipLoaded( variables.relationMethodName ) ) {
			var loadedValue = variables.parent.retrieveRelationship( variables.relationMethodName );
			if ( isArray( loadedValue ) ) {
				loadedValue.append( createdEntity );
				variables.parent.assignRelationship( variables.relationMethodName, loadedValue );
			} else {
				variables.parent.assignRelationship( variables.relationMethodName, createdEntity );
			}
		}

		return createdEntity;
	}

	/**
	 * Sets the parent key value as the foreign key for the entity.
	 *
	 * @entity   The entity to associate.
	 *
	 * @return   quick.models.BaseEntity
	 */
	public any function setForeignAttributesForCreate( required any entity ) {
		var parentKeys = getParentKeys();
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			arguments.entity.forceAssignAttribute( variables.foreignKeys[ i ], parentKeys[ i ] );
		}
		return arguments.entity;
	}


	/**
	 * Returns the fully-qualified local key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedLocalKeys( any builder = variables.relationshipBuilder ) {
		var qualifiedLocalKeys = [];
		for ( var localKey in variables.localKeys ) {
			qualifiedLocalKeys.append( variables.parent.qualifyColumn( localKey ) );
		}
		return qualifiedLocalKeys;
	}

	/**
	 * Returns the fully-qualified column name of foreign key.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getQualifiedForeignKeyNames( any builder = variables.relationshipBuilder ) {
		var qualifiedForeignKeys = [];
		for ( var foreignKey in variables.foreignKeys ) {
			qualifiedForeignKeys.append( arguments.builder.qualifyColumn( foreignKey ) );
		}
		return qualifiedForeignKeys;
	}

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public QuickBuilder function applyThroughExists( any base = variables.relationshipBuilder ) {
		// apply compare constraints
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			arguments.base.whereColumn(
				variables.related.qualifyColumn( variables.foreignKeys[ i ] ),
				variables.parent.qualifyColumn( variables.localKeys[ i ] )
			);
		}

		// nest in exists
		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( structKeyExists( arguments.base, "isBuilder" ) ? arguments.base : arguments.base.getQB() );
	}

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public void function applyThroughJoin( required any base ) {
		var join = newJoinClause( arguments.base, variables.parent.tableName() );
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			join.on(
				variables.related.qualifyColumn( variables.foreignKeys[ i ] ),
				variables.parent.qualifyColumn( variables.localKeys[ i ] )
			);
		}
		attachJoinClause( arguments.base, join );
	}

	/**
	 * Applies the constraints for the final relationship in a `hasManyThrough` chain.
	 *
	 * @return  void
	 */
	public QuickBuilder function initialThroughConstraints() {
		var query       = variables.related.newQuery().reselectRaw( 1 );
		var constraints = query.getQB().forNestedWhere();
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			constraints.where(
				variables.related.qualifyColumn( variables.foreignKeys[ i ] ),
				variables.parent.retrieveAttribute( variables.localKeys[ i ] )
			);
		}
		query.getQB().addNestedWhereQuery( constraints );
		return query;
	}

	public struct function appendToDeepRelationship(
		required array through,
		required array foreignKeys,
		required array localKeys,
		required numeric position
	) {
		if ( variables.foreignKeys.len() == 1 ) {
			arguments.foreignKeys.append( variables.foreignKeys, true );
		} else {
			arguments.foreignKeys.append( variables.foreignKeys );
		}

		if ( variables.localKeys.len() == 1 ) {
			arguments.localKeys.append( variables.localKeys, true );
		} else {
			arguments.localKeys.append( variables.localKeys );
		}

		return {
			"through"     : arguments.through,
			"foreignKeys" : arguments.foreignKeys,
			"localKeys"   : arguments.localKeys
		};
	}

}
