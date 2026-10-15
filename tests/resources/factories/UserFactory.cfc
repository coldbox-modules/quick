component extends="quick.resources.testing.Factory" {

	property name="wirebox" inject="wirebox";

	struct function definition() {
		var suffix = structKeyExists( getFactoryContext(), "suffix" ) ? getFactoryContext().suffix : "default";
		return {
			username  : "factory-#suffix#-#lCase( createUUID() )#",
			firstName : "Factory",
			lastName  : function( attributes, context ) {
				return "User #context.index#";
			},
			email    : "factory-#lCase( createUUID() )#@example.test",
			password : hash( "password" ),
			type     : "limited"
		};
	}

	any function administrator() {
		return state( { type : "admin" } );
	}

	any function wired() {
		return state( { firstName : isObject( variables.wirebox ) ? "Injected" : "Missing" } );
	}

}
