component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "UUID Primary Key Spec", function() {
			it( "sets the primary key with a uuid before saving", function() {
				var country = getInstance( "Country" ).create( { "name" : "Wakanda" } );

				expect( country.getId() ).notToBeNumeric();
				expect( country.getId() ).toHaveLength( 35 );
				expect( reFindNoCase( "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{16}$", country.getId() ) ).toBe(
					1
				);
				expect( getInstance( "Country" ).find( country.getId() ) ).notToBeNull();
			} );
		} );
	}

}
