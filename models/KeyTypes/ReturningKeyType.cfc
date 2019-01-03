component implements="KeyType" {

    /**
     * Called to handle any tasks before inserting into the database.
     * Receives the entity as the only argument.
     */
    public void function preInsert( required entity ) {
        entity.retrieveQuery().returning( entity.get_Key() );
    }

    /**
     * Called to handle any tasks after inserting into the database.
     * Receives the entity and the queryExecute result as arguments.
     */
    public void function postInsert( required entity, required struct result ) {
        entity.assignAttribute( entity.get_Key(), result.query.id );
    }

}
