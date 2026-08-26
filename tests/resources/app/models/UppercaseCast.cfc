component singleton {

	public any function get(
		required any entity,
		required string key,
		any value
	) {
		return isNull( arguments.value ) ? javacast( "null", "" ) : uCase( arguments.value );
	}

	public any function set(
		required any entity,
		required string key,
		any value
	) {
		return isNull( arguments.value ) ? javacast( "null", "" ) : lCase( arguments.value );
	}

}
