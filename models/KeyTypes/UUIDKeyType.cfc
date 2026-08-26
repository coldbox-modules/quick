/**
 * Sets the primary key to a random UUID before inserting it into the database.
 */
component implements="KeyType" {

	/**
	 * Sets the primary keys to random UUIDs.
	 *
	 * @entity   The entity that is being inserted.
	 * @builder  The builder that is doing the inserting.
	 *
	 * @return   void
	 */
	public void function preInsert( required any entity, required any builder ) {
		for ( var keyName in arguments.entity.keyNames() ) {
			if ( arguments.entity.isNullAttribute( keyName ) ) {
				var uuid      = createUUID();
				var uuidParts = listToArray( uuid, "-" );
				if ( uuidParts.len() == 5 ) {
					uuid = "#uuidParts[ 1 ]#-#uuidParts[ 2 ]#-#uuidParts[ 3 ]#-#uuidParts[ 4 ]##uuidParts[ 5 ]#";
				}
				arguments.entity.assignAttribute( keyName, uuid );
			}
		}
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
