component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Columns", function() {
            it( "retrieves all columns by default", function() {
                var user = getInstance( "User" ).findOrFail( 1 );
                var attributeNames = user.getAttributeNames();
                arraySort( attributeNames, "textnocase" );

                expect( attributeNames ).toBeArray();
                expect( attributeNames ).toHaveLength( 8 );
                expect( attributeNames ).toBe( [
                    "COUNTRY_ID",
                    "CREATED_DATE",
                    "FIRST_NAME",
                    "ID",
                    "LAST_NAME",
                    "MODIFIED_DATE",
                    "PASSWORD",
                    "USERNAME"
                ] );
            } );
        } );
    }

}
