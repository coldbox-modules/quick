/**
 * Represents a hasOne relationship.
 *
 * This is a relationship where the parent entity has exactly zero or one of
 * the related entity. The inverse of this relationship is also a `hasOne`
 * relationship.
 *
 * For instance, a `User` may have zero or one `UserProfile` associated to them.
 * This would be modeled in Quick by adding a method to the `User` entity
 * that returns a `HasOne` relationship instance.
 *
 * ```
 * function profile() {
 *     returns hasOne( "UserProfile" );
 * }
 * ```
 */
component extends="quick.models.Relationships.HasOneOrMany" {

	/**
	 * Returns the result of the relationship.
	 *
	 * @return  quick.models.BaseEntity
	 */
	public any function getResults() {
		var result = (
			fieldsAreNull( entity = variables.parent, fields = variables.localKeys )
			 ? javacast( "null", "" )
			 : variables.related.first()
		);

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

}
