/**
 * Represents a polymorphicHasMany relationship.
 *
 * A polymorphic relationship is one where the related entity can belong to
 * more than one type of entity.  As such, the type of entity it is related
 * to is stored alongside the foreign key values.
 *
 * This is a relationship where the parent entity has zero or more of the related
 * entity. The inverse of this relationship is a `polymorphicBelongsTo` relationship.
 *
 * For instance, a `Post` or a `Video` may have one or more `Comment` entities
 * associated to them. This would be modeled in Quick by adding a method to the
 * `Post` or `Video` entity that returns a `PolymorphicHasMany` relationship instance.
 *
 * ```
 * function comments() {
 *     returns polymorphicHasMany( "Comment", "commentable" );
 * }
 * ```
 */
component extends="quick.models.Relationships.PolymorphicHasOneOrMany" accessors="true" {

	/**
	 * Returns the result of the relationship.
	 *
	 * @doc_generic  quick.models.BaseEntity
	 * @return       [quick.models.BaseEntity]
	 */
	public array function getResults() {
		return variables.relationshipBuilder.get();
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
	function match( entities, results, relation ) {
		return matchMany( argumentCollection = arguments );
	}

	public QuickBuilder function initialThroughConstraints() {
		var base = variables.parent
			.newQuery()
			.reselectRaw( 1 )
			.where( variables.related.qualifyColumn( variables.morphType ), variables.morphMapping );

		for ( var localKey in variables.localKeys ) {
			base.where( variables.parent.qualifyColumn( localKey ), variables.parent.retrieveAttribute( localKey ) );
		}

		for ( var i = 1; i <= variables.foreignKeys.len(); i++ ) {
			base.whereColumn(
				variables.related.qualifyColumn( variables.foreignKeys[ i ] ),
				variables.parent.qualifyColumn( variables.localKeys[ i ] )
			);
		}

		return variables.related
			.newQuery()
			.reselectRaw( 1 )
			.whereExists( structKeyExists( base, "isBuilder" ) ? base : base.getQB() );
	}

	/**
	 * Applies the constraints for the final relationship in a `hasManyThrough` chain.
	 *
	 * @base    The query to apply the constraints to.
	 *
	 * @return  void
	 */
	public void function applyThroughConstraints( required any base ) {
		arguments.base.where( variables.related.qualifyColumn( variables.morphType ), variables.morphMapping );
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

}
