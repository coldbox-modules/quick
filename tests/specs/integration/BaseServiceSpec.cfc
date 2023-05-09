component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "BaseService Spec", function() {
			describe( "instantiation", function() {
				it( "can be instantiated with an entity", function() {
					var user    = getInstance( "User" );
					var service = getInstance( name = "BaseService@quick", initArguments = { entity : user } );
					expect( service.entityName() ).toBe( "User" );
				} );

				it( "can be instantiated with a wirebox mapping", function() {
					var service = getInstance( name = "BaseService@quick", initArguments = { entity : "User" } );
					expect( service.entityName() ).toBe( "User" );
				} );

				it( "can inject a service using the wirebox dsl", function() {
					var service = getInstance( dsl = "quickService:User" );
					expect( service.entityName() ).toBe( "User" );
				} );
			} );

			describe( "retriving records", function() {
				beforeEach( function() {
					variables.service = getInstance( dsl = "quickService:User" );
				} );

				afterEach( function() {
					structDelete( variables, "service" );
				} );

				it( "can find a specific record", function() {
					var user = variables.service.find( 1 );
					expect( user.keyValues() ).toBe( [ 1 ] );
				} );

				it( "can find or fail a specific record", function() {
					var user = variables.service.findOrFail( 1 );
					expect( user.keyValues() ).toBe( [ 1 ] );
				} );

				it( "can handle any qb methods", function() {
					var users = variables.service.where( "last_name", "Doe" ).get();
					expect( users ).toBeArray();
					expect( users ).toHaveLength( 2 );
				} );
			} );
		} );
	}

}
