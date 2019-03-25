component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Columns", function() {
            it( "retrieves all columns by default", function() {
                var user = getInstance( "User" ).findOrFail( 1 );
                var attributeNames = user.retrieveAttributeNames( columnNames = true );
                arraySort( attributeNames, "textnocase" );

                expect( attributeNames ).toBeArray();
                expect( attributeNames ).toHaveLength( 10 );
                expect( attributeNames ).toBe( [
                    "COUNTRY_ID",
                    "CREATED_DATE",
                    "EMAIL",
                    "FIRST_NAME",
                    "ID",
                    "LAST_NAME",
                    "MODIFIED_DATE",
                    "PASSWORD",
                    "TYPE",
                    "USERNAME"
                ] );
            } );

            it( "always retrieves the primary key", function() {
                var link = getInstance( "Link" ).findOrFail( 1 );

                var configuredAttributes = link.get_Attributes();
                expect( configuredAttributes ).toBeStruct();
                expect( configuredAttributes ).notToHaveKey( "link_id" );

                var attributeNames = link.retrieveAttributeNames( columnNames = true );
                arraySort( attributeNames, "textnocase" );
                expect( attributeNames ).toBeArray();
                expect( attributeNames ).toHaveLength( 3 );
                expect( attributeNames ).toBe( [ "created_date", "link_id", "link_url" ] );
            } );

            it( "can access the attributes by their alias", function() {
                var link = getInstance( "Link" ).findOrFail( 1 );

                var configuredAttributes = link.get_Attributes();
                expect( configuredAttributes ).toBeStruct();
                expect( configuredAttributes ).notToHaveKey( "link_id" );

                var attributeNames = link.retrieveAttributeNames( columnNames = true );
                arraySort( attributeNames, "textnocase" );
                expect( attributeNames ).toBeArray();
                expect( attributeNames ).toHaveLength( 3 );
                expect( attributeNames ).toBe( [ "created_date", "link_id", "link_url" ] );

                expect( link.getId() ).toBe( 1 );
                expect( link.getId() ).toBe( link.retrieveAttributesData()[ "link_id" ] );
                expect( link.getUrl() ).toBe( "http://example.com/some-link" );
                expect( link.getUrl() ).toBe( link.retrieveAttributesData()[ "link_url" ] );
            } );

            it( "ignores non-persistent attributes", function() {
                expect( function() {
                     var link = getInstance( "Link" ).findOrFail( 1 );
                } ).notToThrow();
            } );

            it( "translates attributes to their column names", function() {
                expect( function() {
                    getInstance( "Link" ).create( {
                        url = "https://example.com"
                    } );
                } ).notToThrow();
            } );
        } );
    }

}
