component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Columns", function() {
            it( "can access the attributes by their alias", function() {
                var link = getInstance( "Link" ).findOrFail( 1 );

                var configuredAttributes = link.get_Attributes();
                expect( configuredAttributes ).toBeStruct();

                var attributeNames = link.retrieveAttributeNames( columnNames = true );
                arraySort( attributeNames, "textnocase" );
                expect( attributeNames ).toBeArray();
                expect( attributeNames ).toHaveLength( 3 );
                expect( attributeNames ).toBe( [ "created_date", "link_id", "link_url" ] );

                expect( link.getLink_Id() ).toBe( 1 );
                expect( link.getLink_Id() ).toBe( link.retrieveAttributesData()[ "link_id" ] );
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

            it( "translates attributes to their column names when applying query restrictions", function() {
                var john = getInstance( "User" ).where( "firstName", "John" ).first();
                expect( john ).notToBeNull();
                expect( john.getId() ).toBe( 2 );
                expect( john.getUsername() ).toBe( "johndoe" );

                var bindings = getInstance( "User" ).where( "firstName", "firstName" ).retrieveQuery().getBindings();
                expect( bindings ).toBeArray();
                expect( bindings ).toHaveLength( 1 );
                expect( bindings[ 1 ] ).toBeStruct();
                expect( bindings[ 1 ].value ).toBe( "firstName" );
            } );
        } );
    }

}
