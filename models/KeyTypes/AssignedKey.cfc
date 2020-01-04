component implements="KeyType" {

    /**
     * Called to handle any tasks before inserting into the database.
     * Recieves the entity as the only argument.
     */
    public void function preInsert( required entity ) {
        return;
    }

    /**
     * Called to handle any tasks after inserting into the database.
     * Recieves the entity and the queryExecute result as arguments.
     */
    public void function postInsert( required entity, required struct result ) {
        return;
    }

}
