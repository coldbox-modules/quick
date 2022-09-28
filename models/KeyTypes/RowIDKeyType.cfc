/**
 * Handles the key being set by the database but not returned in the response.
 * It queries the database based on the ROWID returned to get the actual primary key.
 */
component implements="KeyType" {

	/**
	 * Does nothing as the key will be set by the database.
	 *
	 * @entity   The entity that is being inserted.
	 * @builder  The builder that is doing the inserting.
	 *
	 * @return   void
	 */
	public void function preInsert( required any entity, required any builder ) {
		if ( arguments.entity.keyNames().len() > 1 ) {
			throw( type = "InvalidKeyLength", message = "RowIDKeyType cannot be used with composite primary keys." );
		}
		return;
	}

	/**
	 * Sets the primary key after fetching the record by the ROWID
	 *
	 * @entity   The entity that was inserted.
	 * @result   The result of the queryExecute call.
	 *
	 * @return   void
	 */
	public void function postInsert( required any entity, required struct result ) {
		var keyName = arguments.entity.keyNames()[ 1 ];
		var rowID   = arguments.result.result.keyExists( keyName ) ? arguments.result.result[ keyName ] : arguments.result.result.keyExists(
			"generated_key"
		) ? arguments.result.result[ "generated_key" ] : arguments.result.result[ "generatedKey" ];
		var generatedKey = arguments.entity
			.newQuery()
			.retrieveQuery()
			.where( "ROWID", rowID )
			.value( keyName );
		arguments.entity.assignAttribute( keyName, generatedKey );
	}

}
