component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Belongs To Through Spec", function() {
			it( "can get the owning entity through other relationships", function() {
				var post = getInstance( "Post" ).findOrFail( 523526 );
				expect( post.getCountry() ).notToBeNull();
				expect( post.getCountry() ).notToBeArray();
				expect( post.getCountry().getId() ).toBe( "02B84D66-0AA0-F7FB-1F71AFC954843861" );
			} );
		} );
	}

}
