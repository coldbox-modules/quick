component singleton {

	function get( entity, key, value ) {
		if ( isNull( arguments.value ) ) {
			return javacast( "null", "" );
		}
		return isStruct( arguments.value ) ? arguments.value : deserializeJSON( arguments.value );
	}
	function set( entity, key, value ) {
		return isNull( arguments.value ) ? javacast( "null", "" ) : serializeJSON( arguments.value );
	}

}
