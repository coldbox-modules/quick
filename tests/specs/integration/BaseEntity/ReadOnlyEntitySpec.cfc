component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Read Only models", function() {
			it( "prevents saves from being performed on new instances", function() {
				var referral = getInstance( "Referral" );
				referral.setType( "internal" );
				expect( function() {
					referral.save();
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents create from being performed on new instances", function() {
				expect( function() {
					getInstance( "Referral" ).create( { type : "internal" } );
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents save from being performed on existing instances", function() {
				var referral = getInstance( "Referral" ).findOrFail( 1 );
				referral.setType( "external" );
				expect( function() {
					referral.save();
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents updates from being performed on existing instances", function() {
				var referral = getInstance( "Referral" ).findOrFail( 1 );
				expect( function() {
					referral.update( { type : "external" } );
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents mass updates from being performed on existing instances", function() {
				expect( function() {
					getInstance( "Referral" ).updateAll( { type : "external" } );
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents deletes from being performed on existing instances", function() {
				var referral = getInstance( "Referral" ).findOrFail( 1 );
				expect( function() {
					referral.delete();
				} ).toThrow( type = "QuickReadOnlyException" );
			} );

			it( "prevents mass deletes from being performed on existing instances", function() {
				expect( function() {
					getInstance( "Referral" ).deleteAll();
				} ).toThrow( type = "QuickReadOnlyException" );
			} );
		} );
	}

}
