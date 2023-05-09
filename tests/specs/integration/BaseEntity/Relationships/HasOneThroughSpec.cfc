component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Has One Through Spec", function() {
			it( "can get the related entity through another entity", function() {
				var country = getInstance( "Country@something" ).find( "02B84D66-0AA0-F7FB-1F71AFC954843861" );
				expect( country.getLatestPost() ).notToBeNull();
				expect( country.getLatestPost() ).notToBeArray();
				expect( country.getLatestPost().getPost_Pk() ).toBe( 523526 );
				expect( country.getLatestPost().getBody() ).toBe( "My second awesome post body" );
			} );
		} );
	}

}
