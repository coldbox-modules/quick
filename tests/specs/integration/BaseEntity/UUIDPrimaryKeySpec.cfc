component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "UUID Primary Key Spec", function() {
			it( "sets the primary key with a uuid before saving", function() {
				var country = getInstance( "Country" ).create( { "name" : "Wakanda" } );

				expect( country.getId() ).notToBeNumeric();
			} );
		} );
	}

}
