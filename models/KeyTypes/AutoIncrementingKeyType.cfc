/**
 * Handles the key being set and returned by the database under the
 * `generated_key` key in the query result.
 */
component implements="KeyType" {

    /**
     * Does nothing as the key will be set by the database.
     *
     * @entity   The entity that is being inserted.
     *
     * @returns  void
     */
    public void function preInsert( required any entity ) {
        return;
    }

    /**
     * Sets the returned `generated_key` as the key value in the database.
     *
     * @entity   The entity that was inserted.
     * @result   The result of the queryExecute call.
     *
     * @returns  void
     */
    public void function postInsert( required any entity, required struct result ) {
        var generatedKey = arguments.result.result.keyExists( arguments.entity.keyName() ) ?
            arguments.result.result[ arguments.entity.keyName() ] :
            arguments.result.result.keyExists( "generated_key" ) ?
            arguments.result.result[ "generated_key" ] :
            arguments.result.result[ "generatedKey" ];
        arguments.entity.assignAttribute( arguments.entity.keyName(), generatedKey );
    }

}
