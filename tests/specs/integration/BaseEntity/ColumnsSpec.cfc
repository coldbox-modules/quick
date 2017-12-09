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

            it( "always retrieves the primary key", function() {
                var link = getInstance( "Link" ).findOrFail( 1 );

                var configuredAttributes = link.getAttributes();
                expect( configuredAttributes ).toBeStruct();
                expect( configuredAttributes ).notToHaveKey( "link_id" );

                var attributeNames = link.getAttributeNames();
                arraySort( attributeNames, "textnocase" );
                expect( attributeNames ).toBeArray();
                expect( attributeNames ).toHaveLength( 2 );
                expect( attributeNames ).toBe( [ "link_id", "link_url" ] );
            } );

            it( "can access the attributes by their alias", function() {
                var link = getInstance( "Link" ).findOrFail( 1 );

                var configuredAttributes = link.getAttributes();
                expect( configuredAttributes ).toBeStruct();
                expect( configuredAttributes ).notToHaveKey( "link_id" );

                var attributeNames = link.getAttributeNames();
                arraySort( attributeNames, "textnocase" );
                expect( attributeNames ).toBeArray();
                expect( attributeNames ).toHaveLength( 2 );
                expect( attributeNames ).toBe( [ "link_id", "link_url" ] );

                expect( link.getId() ).toBe( 1 );
                expect( link.getId() ).toBe( link.getAttributesData()[ "link_id" ] );
                expect( link.getUrl() ).toBe( "http://example.com/some-link" );
                expect( link.getUrl() ).toBe( link.getAttributesData()[ "link_url" ] );
            } );

            it( "ignores non-persistent attributes", function() {
                expect( function() {
                     var link = getInstance( "Link" ).findOrFail( 1 );
                } ).notToThrow();
            } );
        } );
    }

}
