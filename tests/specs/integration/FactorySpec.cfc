component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Quick model factories", function() {
			it( "makes unsaved entities from defaults and explicit overrides", function() {
				var user = newFactoryManager( { suffix : "make" } )
					.factory( "User" )
					.make( { firstName : "Overridden" } );

				expect( user ).toBeInstanceOf( "User" );
				expect( user.isLoaded() ).toBeFalse();
				expect( user.getUsername() ).toInclude( "factory-make-" );
				expect( user.getFirstName() ).toBe( "Overridden" );
				expect( user.getLastName() ).toBe( "User 0" );
				expect( getInstance( "User" ).where( "username", user.getUsername() ).count() ).toBe( 0 );
			} );

			it( "combines counts, named states, sequences, and persisted Quick entities", function() {
				var users = newFactoryManager( { suffix : "sequence" } )
					.factory( "User" )
					.count( 3 )
					.administrator()
					.state( function( attributes, context ) {
						return { firstName : "State #context.index#" };
					} )
					.sequence( [
						{ lastName : "Sequence A" },
						function( attributes, context ) {
							return { lastName : "Sequence #context.index#" };
						}
					] )
					.create();

				expect( users ).toHaveLength( 3 );
				expect( users[ 1 ].getLastName() ).toBe( "Sequence A" );
				expect( users[ 2 ].getLastName() ).toBe( "Sequence 1" );
				expect( users[ 3 ].getLastName() ).toBe( "Sequence A" );
				expect( users[ 2 ].getFirstName() ).toBe( "State 1" );
				expect( users[ 1 ].getType() ).toBe( "admin" );
				expect( users[ 1 ].isLoaded() ).toBeTrue();
				expect( getInstance( "User" ).whereLike( "username", "factory-sequence-%" ).count() ).toBe( 3 );
			} );

			it( "creates factories through WireBox so application dependencies are injected", function() {
				var user = newFactoryManager()
					.factory( "User" )
					.wired()
					.make();

				expect( user.getFirstName() ).toBe( "Injected" );
			} );

			it( "runs one-use after-making and after-creating callbacks", function() {
				var made    = [];
				var created = [];
				var user    = newFactoryManager()
					.factory( "User" )
					.state( { username : "factory-callback" } )
					.afterMaking( function( entity, attributes ) {
						arrayAppend( made, attributes.username );
					} )
					.afterCreating( function( entity, attributes ) {
						arrayAppend( created, attributes.id );
					} )
					.create();

				expect( made ).toBe( [ "factory-callback" ] );
				expect( created ).toHaveLength( 1 );
				expect( created[ 1 ] ).toBe( user.getId() );
			} );

			it( "returns arrays whenever count is explicit", function() {
				var one = newFactoryManager()
					.factory( "User" )
					.count( 1 )
					.make();
				var none = newFactoryManager()
					.factory( "User" )
					.count( 0 )
					.make();

				expect( one ).toBeArray();
				expect( one ).toHaveLength( 1 );
				expect( none ).toBeArray();
				expect( none ).toBeEmpty();
			} );

			it( "rejects invalid counts, states, sequences, callbacks, and factory names", function() {
				var factory = newFactoryManager().factory( "User" );

				expect( function() {
					factory.count( -1 );
				} ).toThrow( type = "QuickFactory.InvalidCount" );
				expect( function() {
					factory.state( "invalid" );
				} ).toThrow( type = "QuickFactory.InvalidState" );
				expect( function() {
					factory.sequence( [] );
				} ).toThrow( type = "QuickFactory.EmptySequence" );
				expect( function() {
					factory.afterCreating( "invalid" );
				} ).toThrow( type = "QuickFactory.InvalidCallback" );
				expect( function() {
					newFactoryManager().factory( "User;drop" );
				} ).toThrow( type = "QuickFactory.InvalidFactoryName" );
			} );
		} );
	}

	private any function newFactoryManager( struct context = {} ) {
		return new quick.resources.testing.FactoryManager(
			wirebox     = getWireBox(),
			factoryPath = "tests.resources.factories",
			context     = arguments.context
		);
	}

}
