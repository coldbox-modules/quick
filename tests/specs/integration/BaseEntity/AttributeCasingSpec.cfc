component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Attributes Casing Spec", function() {
            it( "defaults to no transformation", function() {
                var post = getInstance( "Post" ).find( 1 );

                expect( post.retrieveAttributesData() ).toHaveKey( "post_pk" );
                expect( post.retrieveAttributesData() ).notToHaveKey( "PostPk" );

                expect( post.getPost_Pk() ).notToBeNull();

                post.setCreatedDate( now() );

                expect( post.retrieveAttributesData() ).toHaveKey( "created_date" );
            } );

            it( "converts stores all attributes internally as snake case when the `attributecasing` metadata property is set to `snake`", function() {
                var user = getInstance( "User" ).find( 1 );

                expect( user.retrieveAttributesData() ).toHaveKey( "first_name" );
                expect( user.retrieveAttributesData() ).notToHaveKey( "firstName" );

                expect( function() {
                    user.getFirstName();
                }).notToThrow();

                expect( function() {
                    user.getFirstName();
                }).notToThrow();

                user.setCreatedDate( now() );

                expect( user.retrieveAttributesData() ).notToHaveKey( "createdDate" );
                expect( user.retrieveAttributesData() ).toHaveKey( "created_date" );
            } );
        } );
    }

}
