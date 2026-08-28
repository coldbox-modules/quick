component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Soft Deletes", function() {
			it( "can soft delete, query, restore, and force delete entities", function() {
				var user = getInstance( "SoftDeleteUser" ).findOrFail( 1 );
				expect( user.retrieveSoftDeleteColumn() ).toBe( "deletedDate" );

				user.delete();

				expect( user.isLoaded() ).toBeTrue();
				expect( user.isTrashed() ).toBeTrue();
				expect( getInstance( "SoftDeleteUser" ).find( 1 ) ).toBeNull();
				expect( getInstance( "SoftDeleteUser" ).all() ).toHaveLength( 4 );
				expect( getInstance( "SoftDeleteUser" ).withTrashed().all() ).toHaveLength( 5 );
				expect( getInstance( "SoftDeleteUser" ).onlyTrashed().count() ).toBe( 1 );

				var trashedUser = getInstance( "SoftDeleteUser" ).withTrashed().findOrFail( 1 );
				expect( trashedUser.isTrashed() ).toBeTrue();
				structDelete( request, "softDeleteUserPostUpdateCalled" );
				trashedUser.restore();

				expect( trashedUser.isTrashed() ).toBeFalse();
				expect( request ).toHaveKey( "softDeleteUserPostUpdateCalled" );
				expect( getInstance( "SoftDeleteUser" ).findOrFail( 1 ).getUsername() ).toBe( "elpete" );

				getInstance( "SoftDeleteUser" ).where( "id", 2 ).deleteAll();
				expect( getInstance( "SoftDeleteUser" ).find( 2 ) ).toBeNull();
				getInstance( "SoftDeleteUser" ).onlyTrashed().restoreAll();
				expect( getInstance( "SoftDeleteUser" ).findOrFail( 2 ).getUsername() ).toBe( "johndoe" );
				getInstance( "SoftDeleteUser" ).where( "id", 2 ).forceDeleteAll();
				expect( getInstance( "SoftDeleteUser" ).withTrashed().find( 2 ) ).toBeNull();

				trashedUser.forceDelete();
				expect( getInstance( "SoftDeleteUser" ).withTrashed().find( 1 ) ).toBeNull();
			} );
		} );
	}

}
