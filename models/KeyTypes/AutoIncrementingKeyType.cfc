component implements="KeyType" {

    /**
     * Called to handle any tasks before inserting into the database.
     * Receives the entity as the only argument.
     */
    public void function preInsert( required entity ) {
        return;
    }

    /**
     * Called to handle any tasks after inserting into the database.
     * Receives the entity and the queryExecute result as arguments.
     */
    public void function postInsert( required entity, required struct result ) {
        var generatedKey = result.result.keyExists( entity.keyName() ) ?
            result.result[ entity.keyName() ] :
            result.result.keyExists( "generated_key" ) ?
            result.result[ "generated_key" ] :
            result.result[ "generatedKey" ];
        entity.assignAttribute( entity.keyName(), generatedKey );
    }

}
