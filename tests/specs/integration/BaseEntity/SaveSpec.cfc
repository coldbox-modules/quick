component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Save Spec", function() {
            aroundEach( function( spec ) {
                transaction action="begin" {
                    try { arguments.spec.body(); }
                    catch ( any e ) { rethrow; }
                    finally { transaction action="rollback"; }
                }
            } );

            describe( "normal saving", function() {
                it( "inserts the attributes as a new row if it has not been loaded", function() {
                    var newUser = getInstance( "User" );
                    newUser.setUsername( "new_user" );
                    newUser.setFirstName( "New" );
                    newUser.setLastName( "User" );
                    newUser.setPassword( hash( "password" ) );
                    var userRowsPreSave = queryExecute( "SELECT * FROM users" );
                    expect( userRowsPreSave ).toHaveLength( 2 );
                    newUser.save();
                    var userRowsPostSave = queryExecute( "SELECT * FROM users" );
                    expect( userRowsPostSave ).toHaveLength( 3 );
                } );

                it( "retrieves the generated key when saving a new record", function() {
                    var newUser = getInstance( "User" );
                    newUser.setUsername( "new_user" );
                    newUser.setFirstName( "New" );
                    newUser.setLastName( "User" );
                    newUser.setPassword( hash( "password" ) );
                    newUser.save();
                    expect( newUser.getAttributesData() ).toHaveKey( "id" );
                } );

                it( "a saved entity is not dirty", function() {
                    var newUser = getInstance( "User" );
                    newUser.setUsername( "new_user" );
                    newUser.setFirstName( "New" );
                    newUser.setLastName( "User" );
                    newUser.setPassword( hash( "password" ) );
                    newUser.save();
                    expect( newUser.isDirty() ).toBeFalse();
                } );

                it( "updates the attributes of an existing row if it has been loaded", function() {
                    var existingUser = getInstance( "User" ).find( 1 );
                    existingUser.setUsername( "new_elpete_username" );
                    var userRowsPreSave = queryExecute( "SELECT * FROM users" );
                    expect( userRowsPreSave ).toHaveLength( 2 );
                    existingUser.save();
                    var userRowsPostSave = queryExecute( "SELECT * FROM users" );
                    expect( userRowsPostSave ).toHaveLength( 2 );
                } );
            } );

            describe( "many-to-many relationship saving", function() {
                describe( "attach", function() {
                    it( "can attach an id to a relationship", function() {
                        var tag = getInstance( "Tag" );
                        tag.setName( "miscellaneous" );
                        tag.save();

                        var post = getInstance( "Post" ).find( 1 );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 2 );

                        post.tags().attach( tag.getId() );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 3 );
                    } );

                    it( "attaches using the id if the entity is passed", function() {
                        var tag = getInstance( "Tag" );
                        tag.setName( "miscellaneous" );
                        tag.save();

                        var post = getInstance( "Post" ).find( 1 );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 2 );

                        post.tags().attach( tag );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 3 );
                    } );

                    it( "can attach multiple ids or entities at once", function() {
                        var tagA = getInstance( "Tag" );
                        tagA.setName( "miscellaneous" );
                        tagA.save();

                        var tagB = getInstance( "Tag" );
                        tagB.setName( "other" );
                        tagB.save();

                        var post = getInstance( "Post" ).find( 1 );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 2 );

                        post.tags().attach( [ tagA.getId(), tagB ] );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 4 );
                    } );
                } );

                describe( "detach", function() {
                    it( "can detatch an id from a relationship", function() {
                        var post = getInstance( "Post" ).find( 1 );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 2 );

                        var tag = post.getTags().toArray()[ 1 ];

                        post.tags().detatch( tag.getId() );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 1 );
                    } );

                    it( "detaches using the id if the entity is passed", function() {
                        var post = getInstance( "Post" ).find( 1 );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 2 );

                        var tag = post.getTags().toArray()[ 1 ];

                        post.tags().detatch( tag );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 1 );
                    } );

                    it( "can detach multiple ids or entities at once", function() {
                        var post = getInstance( "Post" ).find( 1 );

                        var tags = post.getTags().toArray();
                        expect( tags ).toBeArray();
                        expect( tags ).toHaveLength( 2 );

                        post.tags().detatch( [ tags[ 1 ].getId(), tags[ 2 ] ] );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toBeEmpty();
                    } );
                } );

                describe( "sync", function() {
                    it( "sets the related ids equal to the list passed in", function() {
                        var newTagA = getInstance( "Tag" );
                        newTagA.setName( "miscellaneous" );
                        newTagA.save();

                        var newTagB = getInstance( "Tag" );
                        newTagB.setName( "other" );
                        newTagB.save();

                        var post = getInstance( "Post" ).find( 1 );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 2 );
                        var existingTags = post.getTags().toArray();

                        var tagsToSync = [ existingTags[ 1 ], newTagA.getId(), newTagB ];
                        var tagIds = [
                            existingTags[ 1 ].getKeyValue(),
                            newTagA.getKeyValue(),
                            newTagB.getKeyValue()
                        ];

                        post.tags().sync( [ existingTags[ 1 ], newTagA.getId(), newTagB ] );

                        expect( post.getTags().toArray() ).toBeArray();
                        expect( post.getTags().toArray() ).toHaveLength( 3 );
                        expect( post.getTags().pluck( "keyValue" ).toArray() ).toBe( tagIds );
                    } );
                } );
            } );
        } );
    }

}
