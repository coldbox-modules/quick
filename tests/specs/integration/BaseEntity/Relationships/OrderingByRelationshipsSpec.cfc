component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Ordering By Relationships Spec", function() {
            it( "can order by a belongs to relationship", function() {
                var posts = getInstance( "Post" )
                    .has( "author" )
                    .orderBy( "author.firstName" )
                    .orderBy( "post_pk" )
                    .get();

                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 3 );
                expect( posts[ 1 ].keyValue() ).toBe( 321 );
                expect( posts[ 2 ].keyValue() ).toBe( 1245 );
                expect( posts[ 3 ].keyValue() ).toBe( 523526 );
            } );

            it( "can order by a belongs to relationship descending", function() {
                var posts = getInstance( "Post" )
                    .has( "author" )
                    .orderBy( "author.firstName", "desc" )
                    .orderBy( "post_pk" )
                    .get();

                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 3 );
                expect( posts[ 1 ].keyValue() ).toBe( 1245 );
                expect( posts[ 2 ].keyValue() ).toBe( 523526 );
                expect( posts[ 3 ].keyValue() ).toBe( 321 );
            } );

            it( "can order by a nested belongs to relationship descending", function() {
                var postsQuery = getInstance( "Post" )
                    .has( "author.country" )
                    .orderBy( "author.country.name" )
                    .orderBy( "post_pk" );

                var posts = postsQuery.get();

                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 3 );
                expect( posts[ 1 ].keyValue() ).toBe( 321 );
                expect( posts[ 2 ].keyValue() ).toBe( 1245 );
                expect( posts[ 3 ].keyValue() ).toBe( 523526 );
            } );
        } );
    }

}
