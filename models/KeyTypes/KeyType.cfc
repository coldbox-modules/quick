/**
 * Defines the logic to interact with primary keys when creating entities.
 */
interface displayname="KeyType" {

	/**
	 * Called to handle any tasks before inserting into the database.
	 * Receives the entity as the only argument.
	 *
	 * @entity   The entity that is being inserted.
	 *
	 * @return   void
	 */
	public void function preInsert( required any entity );

	/**
	 * Called to handle any tasks after inserting into the database.
	 * Receives the entity and the queryExecute result as arguments.
	 *
	 * @entity   The entity that was inserted.
	 * @result   The result of the queryExecute call.
	 *
	 * @return   void
	 */
	public void function postInsert( required any entity, required struct result );

}
