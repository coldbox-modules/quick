/**
 * Handles the key being set and returned by the database using the
 * `RETURNING` functionality of select databases.
 */
component implements="KeyType" {

	/**
	 * Adds a RETURNING clause for the primary key to the query.
	 *
	 * @entity   The entity that is being inserted.
	 *
	 * @return   void
	 */
	public void function preInsert( required any entity ) {
		arguments.entity.retrieveQuery().returning( arguments.entity.keyColumns() );
	}

	/**
	 * Sets the primary key equal to the returned value.
	 *
	 * @entity   The entity that was inserted.
	 * @result   The result of the queryExecute call.
	 *
	 * @return   void
	 */
	public void function postInsert( required any entity, required struct result ) {
		arguments.entity
			.keyColumns()
			.each( function( keyColumn ) {
				entity.assignAttribute( keyColumn, result.query[ keyColumn ] );
			} );
	}

}
