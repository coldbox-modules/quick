component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Aggregate Spec", function() {
			it( "can retrieve aggregates with no issues", function() {
				expect( getInstance( "User" ).count() ).toBe( 5 );
				expect( getInstance( "User" ).whereUsername( "elpete" ).count() ).toBe( 1 );
			} );
		} );
	}

}
