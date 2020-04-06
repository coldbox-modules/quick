interface displayname="CastsAttribute" {

	/**
	 * Casts the given value from the database to the target cast type.
	 *
	 * @entity      The entity with the attribute being casted.
	 * @key         The attribute alias name.
	 * @value       The value of the attribute.
	 *
	 * @return      The casted attribute.
	 */
	public any function get(
		required any entity,
		required string key,
		any value
	);

	/**
	 * Returns the value to assign to the key before saving to the database.
	 *
	 * @entity      The entity with the attribute being casted.
	 * @key         The attribute alias name.
	 * @value       The value of the attribute.
	 *
	 * @return      The value to save to the database. A struct of values
	 *              can be returned if the cast value affects multiple attributes.
	 */
	public any function set(
		required any entity,
		required string key,
		any value
	);

}
