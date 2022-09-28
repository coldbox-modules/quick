/**
 * The NullKeyType expects the key to be handled completely by the developer.
 * It does nothing pre- or post- insert.
 */
component implements="KeyType" {

	/**
	 * Does nothing as the key should already be set at this point.
	 *
	 * @entity   The entity that is being inserted.
	 * @builder  The builder that is doing the inserting.
	 *
	 * @return   void
	 */
	public void function preInsert( required any entity, required any builder ) {
		return;
	}

	/**
	 * Does nothing as the key should not have been altered by the database.
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
