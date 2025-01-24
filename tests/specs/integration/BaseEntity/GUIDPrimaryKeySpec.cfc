component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "GUID Primary Key Spec", function() {
			it( "sets the primary key with a guid before saving", function() {
				var country = getInstance( "Actor" ).create( { "name" : "Tina Fey" } );

				expect( country.getId() ).notToBeNumeric();
			} );
		} );
	}

}
