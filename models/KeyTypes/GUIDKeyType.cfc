/**
 * Sets the primary key to a random GUID before inserting it into the database. 
 */
component implements="KeyType" {

	/**
	 * Sets the primary keys to random GUIDs.
	 *
	 * @entity   The entity that is being inserted.
	 * @builder  The builder that is doing the inserting.
	 *
	 * @return   void
	 */
	public void function preInsert( required any entity, required any builder ) {
		arguments.entity
			.keyNames()
			.each( function( keyName ) {
				if ( entity.isNullAttribute( keyName ) ) {
					entity.assignAttribute( keyName, createGUID() );
				}
			} );
	}

	/**
	 * Does nothing as the key was set before inserting into the database
	 * and the database should not have modified it.
	 *
	 * @entity   The entity that was inserted.
	 * @result   The result of the queryExecute call.
	 *
	 * @return   void
	 */
	public void function postInsert( required any entity, required struct result ) {
		return;
	}

}
