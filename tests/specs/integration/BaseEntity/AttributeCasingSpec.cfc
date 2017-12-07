component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Attributes Casing Spec", function() {
            it( "defaults to no transformation", function() {
                var post = getInstance( "Post" ).find( 1 );

                expect( post.getAttributesData() ).toHaveKey( "post_pk" );
                expect( post.getAttributesData() ).notToHaveKey( "PostPk" );

                expect( function() {
                    post.getPostPk();
                }).toThrow();

                expect( function() {
                    post.getPost_Pk();
                }).notToThrow();

                post.setCreatedDate( now() );

                expect( post.getAttributesData() ).toHaveKey( "createdDate" );
                expect( post.getAttributesData() ).toHaveKey( "created_date" );
            } );

            it( "converts stores all attributes internally as snake case when the `attributecasing` metadata property is set to `snake`", function() {
                var user = getInstance( "User" ).find( 1 );

                expect( user.getAttributesData() ).toHaveKey( "first_name" );
                expect( user.getAttributesData() ).notToHaveKey( "firstName" );

                expect( function() {
                    user.getFirstName();
                }).notToThrow();

                expect( function() {
                    user.getFirstName();
                }).notToThrow();

                user.setCreatedDate( now() );

                expect( user.getAttributesData() ).notToHaveKey( "createdDate" );
                expect( user.getAttributesData() ).toHaveKey( "created_date" );
            } );
        } );
    }

}
