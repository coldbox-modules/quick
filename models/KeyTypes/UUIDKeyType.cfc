/**
 * Sets the primary key to a random UUID before inserting it into the database.
 */
component implements="KeyType" {

    /**
     * Sets the primary key to a random UUID.
     *
     * @entity   The entity that is being inserted.
     *
     * @return   void
     */
    public void function preInsert( required any entity ) {
        arguments.entity.assignAttribute(
            arguments.entity.get_Key(),
            createUUID()
        );
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
    public void function postInsert(
        required any entity,
        required struct result
    ) {
        return;
    }

}
