/**
 * Represents a belongsTo relationship.
 *
 * This is a relationship where the related entity belongs to
 * exactly one of the parent entity. The inverse of this relationship
 * is a `hasMany` relationship.
 *
 * For instance, a `Post` may belong to a `User` which we can call an author.
 * This would be modeled in Quick by adding a method to the `Post` entity
 * that returns a `BelongsTo` relationship instance.
 *
 * ```
 * function author() {
 *     returns belongsTo( "User" );
 * }
 * ```
 */
component
	extends   ="quick.models.Relationships.BaseRelationship"
	implements="IConcatenatableRelationship"
	accessors ="true"
{

	/**
	 * An alias for the parent entity.
	 */
	property name="child";

	/**
	 * The column names on the `parent` entity that refers to
	 * the `localKeys` on the `related` entity.
	 */
	property name="foreignKeys" type="array";

	/**
	 * The column names on the `realted` entity that is referred
	 * to by the `foreignKeys` of the `parent` entity.
	 */
	property name="localKeys" type="array";

	/**
	 * Used to check for the type of relationship more quickly than using isInstanceOf.
	 */
	this.relationshipClass = "BelongsTo";

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
	 *
	 * @return              quick.models.Relationships.BelongsTo
	 */
	public BelongsTo function init(
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
		variables.child       = arguments.parent;

		return super.init(
			related            = arguments.related,
			relationName       = arguments.relationName,
			relationMethodName = arguments.relationMethodName,
			parent             = arguments.parent,
			withConstraints    = arguments.withConstraints
		);
	}

	/**
	 * Returns the result of the relationship.
	 * If a null is returned, an optional default model can be returned.
	 * The default model can be configured using a `withDefault` method.
	 *
	 * @return  quick.models.BaseEntity | null
	 */
	public any function getResults() {
		var result = (
			fieldsAreNull( entity = variables.child, fields = variables.foreignKeys )
			 ? javacast( "null", "" )
			 : variables.relationshipBuilder.first()
		);

		if ( !isNull( result ) ) {
			return result;
		}

		if ( !variables.returnDefaultEntity ) {
			return javacast( "null", "" );
		}

		return newDefaultEntity();
	}

	/**
	 * Adds the constraints to the related entity.
	 *
	 * @return  void
	 */
	public void function addConstraints() {
		var constraints = variables.relationshipBuilder.getQB().forNestedWhere();
		for ( var i = 1; i <= variables.localKeys.len(); i++ ) {
			constraints.where(
				variables.related.qualifyColumn( variables.localKeys[ i ] ),
				variables.child.retrieveAttribute( variables.foreignKeys[ i ] )
			);
		}
		variables.relationshipBuilder.getQB().addNestedWhereQuery( constraints );
	}

	/**
	 * Adds the constraints for eager loading.
	 *
	 * @entities  The entities being eager loaded.
	 *
	 * @return    quick.models.Relationships.BelongsTo
	 */
	public boolean function addEagerConstraints( required array entities, required any baseEntity ) {
		var allKeys = getEagerEntityKeys( arguments.entities, arguments.baseEntity );
		if ( allKeys.isEmpty() ) {
			return false;
		}
		var eagerConstraints = variables.relationshipBuilder.getQB().forNestedWhere();
		for ( var keys in allKeys ) {
			var keyConstraints = eagerConstraints.forNestedWhere();
			for ( var i = 1; i <= variables.localKeys.len(); i++ ) {
				keyConstraints.where(
					variables.related.qualifyColumn( variables.localKeys[ i ] ),
					variables.related.generateQueryParamStruct( variables.localKeys[ i ], keys[ i ] )
				);
			}
			eagerConstraints.addNestedWhereQuery( keyConstraints, "or" );
		}
		variables.relationshipBuilder.getQB().addNestedWhereQuery( eagerConstraints );
		return true;
	}

	/**
	 * Returns an array of entity keys for the entities being eager loaded.
	 *
	 * @entities     The entities being eager loaded.
	 *
	 * @doc_generic  any
	 * @return       [any]
	 */
	public array function getEagerEntityKeys( required array entities, required any baseEntity ) {
		var seenKeys        = createObject( "java", "java.util.LinkedHashSet" ).init();
		var eagerEntityKeys = [];
		for ( var entity in arguments.entities ) {
			var values = [];
			for ( var foreignKey in variables.foreignKeys ) {
				if (
					!entityHasAttribute(
						entity,
						foreignKey,
						arguments.baseEntity
					)
				) {
					break;
				}
				var value = entityRetrieveAttribute(
					entity,
					foreignKey,
					arguments.baseEntity
				);
				if ( isNull( value ) || arguments.baseEntity.isNullValue( foreignKey, value ) ) {
					break;
				}
				values.append( value );
			}
			if ( values.len() == variables.foreignKeys.len() ) {
				var serializedKey = serializeJSON( values );
				if ( !seenKeys.contains( serializedKey ) ) {
					seenKeys.add( serializedKey );
					eagerEntityKeys.append( values );
				}
			}
		}
		return eagerEntityKeys;
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
		arguments.entities.each( function( entity ) {
			var defaultEntity = newDefaultEntity();
			if ( structKeyExists( arguments.entity, "isQuickEntity" ) ) {
				arguments.entity.assignRelationship(
					relation,
					isNull( defaultEntity ) ? javacast( "null", "" ) : defaultEntity
				);
			} else {
				arguments.entity[ relation ] = isNull( defaultEntity ) ? {} : defaultEntity.getMemento();
			}
		} );
		return arguments.entities;
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
		var dictionary = {};
		for ( var result in arguments.results ) {
			var keyValues = [];
			for ( var localKey in variables.localKeys ) {
				keyValues.append(
					structKeyExists( result, "isQuickEntity" ) ? result.retrieveAttribute( localKey ) : result[ localKey ]
				);
			}
			dictionary[ keyValues.toList() ] = result;
		}

		for ( var entity in arguments.entities ) {
			var foreignKeyValues = [];
			for ( var foreignKey in variables.foreignKeys ) {
				foreignKeyValues.append( entityRetrieveAttribute( entity, foreignKey, variables.parent ) );
			}
			var foreignKeyValue = foreignKeyValues.toList();
			if ( structKeyExists( dictionary, foreignKeyValue ) ) {
				if ( structKeyExists( entity, "isQuickEntity" ) ) {
					entity.assignRelationship( arguments.relation, dictionary[ foreignKeyValue ] );
				} else {
					entity[ arguments.relation ] = dictionary[ foreignKeyValue ];
				}
			}
		}

		return arguments.entities;
	}

	/**
	 * Associates the given entity when the relationship is used as a setter.
	 *
	 * Relationships on entities can be called with `set` in front of it.
	 * If it is, a `BelongsTo` relationship forwards the call to `associate`.
	 *
	 * @entity  The entity or entity id to associate as the new owner.
	 *          If an entity is passed, it is also cached in the child entity
	 *          as the value for the relationship.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function applySetter() {
		return associate( argumentCollection = arguments );
	}

	/**
	 * Sets a new entity as the parent of the relationship.
	 * For example, if a Post belongs to a User, associate will set
	 * the foreign key on the Post table to the User's id.
	 *
	 * @entity  The entity or entity id to associate as the new owner.
	 *          If an entity is passed, it is also cached in the child entity
	 *          as the value for the relationship.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function associate( required any entity ) {
		var localKeyValues = [];
		if ( isObject( arguments.entity ) ) {
			for ( var localKey in variables.localKeys ) {
				localKeyValues.append( arguments.entity.retrieveAttribute( localKey ) );
			}
		} else {
			localKeyValues = arrayWrap( arguments.entity );
		}

		guardAgainstKeyLengthMismatch( localKeyValues, variables.foreignKeys );

		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			variables.child.forceAssignAttribute( variables.foreignKeys[ i ], localKeyValues[ i ] );
		}

		if ( isObject( arguments.entity ) ) {
			variables.child.assignRelationship( variables.relationMethodName, arguments.entity );
		}

		return variables.child;
	}

	/**
	 * Creates the related parent entity, associates it to the child, and caches
	 * it as the loaded relationship value.  The child entity is not saved.
	 *
	 * @attributes  The attributes for the new related entity.
	 *
	 * @return      quick.models.BaseEntity
	 */
	public any function create( struct attributes = {} ) {
		var createdEntity = variables.related
			.newEntity()
			.fill( arguments.attributes )
			.save();
		associate( createdEntity );
		return createdEntity;
	}

	/**
	 * Removes an entity as the parent of the relationship.
	 * For example, if a Post belongs to a User, dissociate will set the
	 * foreign key column on the Post entity to null.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function dissociate() {
		var entity = variables.child.clearRelationship( variables.relationMethodName );
		for ( var foreignKey in variables.foreignKeys ) {
			entity.forceClearAttribute( name = foreignKey, setToNull = true );
		}
		return entity;
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
			qualifiedLocalKeys.append( variables.related.qualifyColumn( localKey ) );
		}
		return qualifiedLocalKeys;
	}

	/**
	 * Get the key to compare in the existence query.
	 *
	 * @doc_generic  String
	 * @return       [String]
	 */
	public array function getExistenceCompareKeys( any builder = variables.relationshipBuilder ) {
		var compareKeys = [];
		for ( var foreignKey in variables.foreignKeys ) {
			compareKeys.append( variables.child.qualifyColumn( foreignKey ) );
		}
		return compareKeys;
	}

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public QuickBuilder function applyThroughExists( required QuickBuilder base ) {
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			arguments.base.whereColumn(
				variables.child.qualifyColumn( variables.foreignKeys[ i ] ),
				variables.related.qualifyColumn( variables.localKeys[ i ] )
			);
		}
		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( structKeyExists( arguments.base, "isBuilder" ) ? arguments.base : arguments.base.getQB() );
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

	/**
	 * Applies the join for relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the join to.
	 *
	 * @return  void
	 */
	public void function applyThroughJoin( required any base ) {
		var join = newJoinClause( arguments.base, variables.child.tableName() );
		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			join.on(
				variables.child.qualifyColumn( variables.foreignKeys[ i ] ),
				variables.related.qualifyColumn( variables.localKeys[ i ] )
			);
		}
		attachJoinClause( arguments.base, join );
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
				variables.related.qualifyColumn( variables.localKeys[ i ] ),
				variables.child.retrieveAttribute( variables.foreignKeys[ i ] )
			);
		}
		query.addNestedWhereQuery( constraints );
	}

	public struct function appendToDeepRelationship(
		required array through,
		required array foreignKeys,
		required array localKeys,
		required numeric position
	) {
		if ( variables.localKeys.len() == 1 ) {
			arguments.foreignKeys.append( variables.localKeys, true );
		} else {
			arguments.foreignKeys.append( variables.localKeys );
		}

		if ( variables.foreignKeys.len() == 1 ) {
			arguments.localKeys.append( variables.foreignKeys, true );
		} else {
			arguments.localKeys.append( variables.foreignKeys );
		}

		return {
			"through"     : arguments.through,
			"foreignKeys" : arguments.foreignKeys,
			"localKeys"   : arguments.localKeys
		};
	}

}
