component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Get Spec", function() {
            it( "finds an entity by the primary key", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.isLoaded() ).toBeTrue(
                    "The user instance should be found and loaded, but was not."
                );
            } );

            it( "returns null if the record cannot be found", function() {
                expect( getInstance( "User" ).find( 999 ) ).toBeNull(
                    "The user instance should be null because it could not be found, but was not."
                );
            } );

            it( "returns null if the first record cannot be found", function() {
                expect( getInstance( "Empty" ).first() ).toBeNull(
                    "The instance should be null because there are none in the database."
                );
            } );

            it( "can refresh itself from the database", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
                queryExecute(
                    "UPDATE `users` SET `username` = ? WHERE `id` = ?",
                    [ "new_username", 1 ]
                );
                expect( user.getUsername() ).toBe( "elpete" );
                user.refresh();
                expect( user.getUsername() ).toBe( "new_username" );
            } );

            it( "can get a fresh instance from the database", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
                queryExecute(
                    "UPDATE `users` SET `username` = ? WHERE `id` = ?",
                    [ "new_username", 1 ]
                );
                expect( user.getUsername() ).toBe( "elpete" );
                var freshUser = user.fresh();
                expect( user.getUsername() ).toBe( "elpete" );
                expect( freshUser.getUsername() ).toBe( "new_username" );
            } );

            describe( "loaded", function() {
                it( "a new entity returns false when asked if it loaded", function() {
                    expect( getInstance( "User" ).isLoaded() ).toBeFalse();
                } );

                it( "an entity loaded from the database returns true when asked if it loaded", function() {
                    expect( getInstance( "User" ).find( 1 ).isLoaded() ).toBeTrue();
                } );
            } );

            it( "throws an exception if no entity is found using find or fail", function() {
                expect( function() {
                    getInstance( "User" ).findOrFail( 1 );
                } ).notToThrow();

                expect( function() {
                    getInstance( "User" ).findOrFail( 999 );
                } ).toThrow( type = "EntityNotFound" );
            } );

            it( "throws an exception if no entity is found using first or fail", function() {
                expect( function() {
                    getInstance( "User" ).whereUsername( "johndoe" ).firstOrFail();
                } ).notToThrow();

                expect( function() {
                    getInstance( "User" ).whereUsername( "doesnt-exist" ).firstOrFail();
                } ).toThrow( type = "EntityNotFound" );
            } );

            it( "can return if an entity exists", function() {
                expect(
                    getInstance( "User" ).whereUsername( "johndoe" ).exists()
                ).toBeTrue();
                expect(
                    getInstance( "User" ).whereUsername( "doesnt-exist" ).exists()
                ).toBeFalse();
            } );

            it( "throws an exception if an entity does not exist when calling existsOrFail", function() {
                expect( function() {
                    getInstance( "User" ).whereUsername( "johndoe" ).existsOrFail();
                } ).notToThrow();

                expect( function() {
                    getInstance( "User" ).whereUsername( "doesnt-exist" ).existsOrFail();
                } ).toThrow( type = "EntityNotFound" );
            } );

            it( "can paginate a Quick query", function() {
                for ( var i = 1; i <= 45; i++ ) {
                    // create A
                    var a = getInstance( "A" ).create( { "name": "Instance #i#" } );
                }

                var p = getInstance( "A" ).paginate();
                expect( p.pagination.page ).toBe( 1 );
                expect( p.results ).toHaveLength( 25 );
                expect( p.results[ 1 ].getId() ).toBe( 1 );
                expect( p.results[ p.results.len() ].getId() ).toBe( 25 );

                p = getInstance( "A" ).paginate( 2 );
                expect( p.pagination.page ).toBe( 2 );
                expect( p.results ).toHaveLength( 20 );
                expect( p.results[ 1 ].getId() ).toBe( 26 );
                expect( p.results[ p.results.len() ].getId() ).toBe( 45 );
            } );

            it( "can eager load and paginate a Quick query", function() {
                var as = [];
                var bs = [];
                for ( var i = 1; i < 10; i++ ) {
                    as.append( { "name": "Instance #i#" } );
                    for ( var j = 1; j < 5; j++ ) {
                        bs.append( { "name": "Instance #j#", "a_id": i } );
                    }
                }

                getInstance( "A" ).insert( as );
                getInstance( "B" ).insert( bs );

                var p = getInstance( "B" ).with( "a" ).paginate();
                expect( p.pagination.page ).toBe( 1 );
                expect( p.results ).toHaveLength( 25 );
                var firstB = p.results[ 1 ];
                expect( firstB.getId() ).toBe( 1 );
                expect( firstB.isRelationshipLoaded( "a" ) ).toBeTrue();
            } );
        } );
    }

}
