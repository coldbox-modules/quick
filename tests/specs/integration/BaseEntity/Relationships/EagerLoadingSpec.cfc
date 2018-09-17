component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        controller.getInterceptorService().registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "Eager Loading Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can eager load a belongs to relationship", function() {
                var posts = getInstance( "Post" ).with( "author" ).get();
                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 2 );
                var authors = posts.map( function( post ) {
                    return post.getAuthor();
                } );
                expect( authors ).toBeArray();
                expect( authors ).toHaveLength( 2 );
                expect( authors[ 1 ] ).notToBeArray();
                expect( authors[ 1 ] ).toBeInstanceOf( "app.models.User" );
                expect( authors[ 2 ] ).notToBeArray();
                expect( authors[ 2 ] ).toBeInstanceOf( "app.models.User" );
                if ( arrayLen( variables.queries ) != 2 ) {
                    expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
                }
            } );

            it( "can eager load a has many relationship", function() {
                var users = getInstance( "User" ).with( "posts" ).latest().get();
                expect( users ).toBeArray();
                expect( users ).toHaveLength( 3, "Three users should be returned" );

                var janedoe = users[ 1 ];
                expect( janedoe.getUsername() ).toBe( "janedoe" );
                expect( janedoe.getPosts() ).toBeArray();
                expect( janedoe.getPosts() ).toHaveLength( 0, "No posts should belong to janedoe" );

                var johndoe = users[ 2 ];
                expect( johndoe.getUsername() ).toBe( "johndoe" );
                expect( johndoe.getPosts() ).toBeArray();
                expect( johndoe.getPosts() ).toHaveLength( 0, "No posts should belong to johndoe" );

                var elpete = users[ 3 ];
                expect( elpete.getUsername() ).toBe( "elpete" );
                expect( elpete.getPosts() ).toBeArray();
                expect( elpete.getPosts() ).toHaveLength( 2, "Two posts should belong to elpete" );

                expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
            } );

            it( "can eager load a hasOne relationship", function() {
                var users = getInstance( "User" ).with( "latestPost" ).latest().get();
                expect( users ).toBeArray();
                expect( users ).toHaveLength( 3, "Three users should be returned" );

                var janedoe = users[ 1 ];
                expect( janedoe.getUsername() ).toBe( "janedoe" );
                expect( janedoe.getLatestPost() ).toBeStruct();
                expect( janedoe.getLatestPost() ).toBeEmpty();

                var johndoe = users[ 2 ];
                expect( johndoe.getUsername() ).toBe( "johndoe" );
                expect( johndoe.getLatestPost() ).toBeStruct();
                expect( johndoe.getLatestPost() ).toBeEmpty();

                var elpete = users[ 3 ];
                expect( elpete.getUsername() ).toBe( "elpete" );
                expect( elpete.getLatestPost() ).toBeStruct();
                expect( elpete.getLatestPost() ).notToBeEmpty();

                expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
            } );

            it( "can eager load a belongs to many relationship", function() {
                var posts = getInstance( "Post" ).with( "tags" ).get();
                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 2 );

                expect( posts[ 1 ].getTags() ).toBeArray();
                expect( posts[ 1 ].getTags() ).toHaveLength( 2 );

                expect( posts[ 2 ].getTags() ).toBeArray();
                expect( posts[ 2 ].getTags() ).toHaveLength( 2 );

                expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
            } );

            it( "can eager load a has many through relationship", function() {
                var countries = getInstance( "Country" ).with( "posts" ).get();
                expect( countries ).toBeArray();
                expect( countries ).toHaveLength( 2 );

                expect( countries[ 1 ].getPosts() ).toBeArray();
                expect( countries[ 1 ].getPosts() ).toHaveLength( 2 );
                expect( countries[ 1 ].getPosts()[ 1 ].getBody() ).toBe( "My awesome post body" );
                expect( countries[ 1 ].getPosts()[ 2 ].getBody() ).toBe( "My second awesome post body" );

                expect( countries[ 2 ].getPosts() ).toBeArray();
                expect( countries[ 2 ].getPosts() ).toBeEmpty();

                expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
            } );

            it( "can eager load polymorphic belongs to relationships", function() {
                var comments = getInstance( "Comment" ).with( "commentable" ).get();

                expect( comments ).toBeArray();
                expect( comments ).toHaveLength( 3 );

                expect( comments[ 1 ].getId() ).toBe( 1 );
                expect( comments[ 1 ].getCommentable().get_entityName() ).toBe( "Post" );
                expect( comments[ 1 ].getCommentable().getPost_Pk() ).toBe( 1245 );

                expect( comments[ 2 ].getId() ).toBe( 2 );
                expect( comments[ 2 ].getCommentable().get_entityName() ).toBe( "Post" );
                expect( comments[ 2 ].getCommentable().getPost_Pk() ).toBe( 1245 );

                expect( comments[ 3 ].getId() ).toBe( 3 );
                expect( comments[ 3 ].getCommentable().get_entityName() ).toBe( "Video" );
                expect( comments[ 3 ].getCommentable().getId() ).toBe( 2 );

                expect( variables.queries ).toHaveLength( 3, "Only three queries should have been executed." );
            } );

            it( "can eager load polymorphic has many relationships", function() {
                var posts = getInstance( "Post" ).with( "comments" ).get();

                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 2 );

                expect( posts[ 1 ].getComments() ).toBeArray();
                expect( posts[ 1 ].getComments() ).toHaveLength( 2 );

                expect( posts[ 2 ].getComments() ).toBeArray();
                expect( posts[ 2 ].getComments() ).toBeEmpty();

                expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
            } );

            it( "can eager load a large relationship quickly", function() {
                queryExecute( "
                    CREATE TABLE `a` (
                        `id` int(11) NOT NULL AUTO_INCREMENT,
                        `name` varchar(50) NOT NULL,
                        PRIMARY KEY (`id`)
                    )
                " );
                queryExecute( "
                    CREATE TABLE `b` (
                        `id` int(11) NOT NULL AUTO_INCREMENT,
                        `a_id` int(11),
                        `name` varchar(50) NOT NULL,
                        PRIMARY KEY (`id`)
                    )
                " );
                for ( var i = 1; i < 20; i++ ) {
                    // create A
                    var a = getInstance( "A" ).create( {
                        "name" = "Instance #i#"
                    } );
                    for ( var j = 1; j < 5; j++ ) {
                        getInstance( "B" ).create( {
                            "name" = "Instance #j#",
                            "a_id" = a.getId()
                        } );
                    }
                }

                var startTick = getTickCount();
                var a = getInstance( "B" ).with( "a" ).get();
                expect( getTickCount() - startTick ).toBeLT( 5000, "Query is taking too long" );
            } );
        } );
    }

    function preQBExecute( event, interceptData, buffer, rc, prc ) {
        arrayAppend( variables.queries, interceptData );
    }

}
