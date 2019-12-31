component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "good error messages", function() {
            it( "throws about unloaded entities when trying to retrieve the `keyValue`", function() {
                expect( function() {
                    getInstance( "User" ).keyValue();
                } ).toThrow(
                    type = "QuickEntityNotLoaded",
                    regex = "This instance is not loaded so the \`keyValue\` cannot be retrieved\."
                );
            } );

            it( "throws about unloaded entities when calling `delete`", function() {
                expect( function() {
                    getInstance( "User" ).delete();
                } ).toThrow(
                    type = "QuickEntityNotLoaded",
                    regex = "This instance is not loaded so it cannot be deleted\.  Did you maybe mean to use `deleteAll`\?"
                );
            } );

            it( "throws about unloaded entities when calling `update`", function() {
                expect( function() {
                    getInstance( "User" ).update( { "username": "johndoe" } );
                } ).toThrow(
                    type = "QuickEntityNotLoaded",
                    regex = "This instance is not loaded so it cannot be updated\.  Did you maybe mean to use `updateAll`, `insert`, or `save`\?"
                );
            } );

            it( "throws a helpful error message when the key value is defaulted", function() {
                expect( function() {
                    getInstance( "DefaultedKeyEntity" );
                } ).toThrow(
                    type = "QuickEntityDefaultedKey",
                    regex = "The key value \[id\] has a default value\.  Default values on keys prevents Quick from working as expected\.  Remove the default value to continue\."
                );
            } );
        } );
    }

}
