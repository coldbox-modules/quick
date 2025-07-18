# v12.0.4
## 15 Jul 2025 — 18:27:26 UTC

### fix

+ __QuickBuilder:__ Allow passing `options` for retrieval methods
 ([0e0fc11](https://github.com/coldbox-modules/quick/commit/0e0fc11dab7ee470cd917314dce98c986520cb82))


# v12.0.3
## 11 Jul 2025 — 23:07:07 UTC

### fix

+ __BaseEntity:__ More ACF compatibility fixes for parallel eager loading ([3557e84](https://github.com/coldbox-modules/quick/commit/3557e845ee1744b9cb476a4259852286616d76b2))
+ __BaseEntity:__ potential workaround for ACF ([a46298e](https://github.com/coldbox-modules/quick/commit/a46298e8e083e9c4f759371044722574e4a8fabf))
+ __BaseEntity:__ use BIF for ACF compat ([6f56f52](https://github.com/coldbox-modules/quick/commit/6f56f520d01c26da8efd33b73381273c116a0604))
+ __BaseEntity:__ Fix async relationship loading ([60b9ba8](https://github.com/coldbox-modules/quick/commit/60b9ba8e92df5afc83046ecad8421ef94710a1ed))


# v12.0.2
## 19 Jun 2025 — 19:37:19 UTC

### fix

+ __ModuleConfig:__ Ensure cache exists before clearing it when unloading Quick
 ([baaa763](https://github.com/coldbox-modules/quick/commit/baaa763799d8c06ccfbaa56d3b564c39af4a82e7))


# v12.0.1
## 18 Jun 2025 — 19:52:37 UTC

### fix

+ __QuickQB:__ Fix for casts in where statements
 ([c605721](https://github.com/coldbox-modules/quick/commit/c6057214f7132d3beab13b4406252420619fdf67))


# v12.0.0
## 12 Jun 2025 — 22:59:56 UTC

### BREAKING

+ __HasManyDeep:__ Fix for deep entities with compound keys ([21c3e03](https://github.com/coldbox-modules/quick/commit/21c3e03db26588a32bdad5cd9ba1352cb94af1d4))
+ __HasManyThrough:__ Use qb 13 to fix missing alias rewriting ([95ce7e6](https://github.com/coldbox-modules/quick/commit/95ce7e6132185aa60ed4db9d32ed971d4c04382f))
+ __box.json:__ Upgrade to latest dependencies ([0b3a4c8](https://github.com/coldbox-modules/quick/commit/0b3a4c82dec7bdf5ee9e39d8bd7f914d0b2c4594))

### chore

+ __tests:__ Modify test to work with BoxLang
 ([102406a](https://github.com/coldbox-modules/quick/commit/102406a3a8f0514d8391f42591aa42eddd8a4e39))
+ __CI:__ Stick to mysql:5.7 for now
 ([028c2ad](https://github.com/coldbox-modules/quick/commit/028c2adc54d53210dc6d07e8cb1e10fb8cf81bf3))
+ __CI:__ Use explicity ports for MySQL 8 service
 ([53e4edc](https://github.com/coldbox-modules/quick/commit/53e4edc42a7a9aec82671279633d3aecafac85a8))
+ __CI:__ Update testing matrix and java versions
 ([1d7c0c8](https://github.com/coldbox-modules/quick/commit/1d7c0c8abe5b9d74f0ec20a3e7c3741082e50bc2))
+ __CI:__ Use separate server.json files for different engines
 ([ceb4484](https://github.com/coldbox-modules/quick/commit/ceb44842fb58e394ca77ac7801f0a5ff1a1be5cc))

### fix

+ __QuickBuilder:__ Fix for qb 13's new column syntax
 ([e7fb76a](https://github.com/coldbox-modules/quick/commit/e7fb76a200cf4b9c01a502f78d5126e4641a73e5))
+ __ChildEntity:__ Fix for bringing back columns correct when multiple child entities share the same column
 ([9c5d69e](https://github.com/coldbox-modules/quick/commit/9c5d69e5b4c476bf44cbd3df723bd7d986922209))
+ __QuickBuilder:__ Preserve case for `withCount` and `withSum` ([1262c8d](https://github.com/coldbox-modules/quick/commit/1262c8d8ffd255ba3190b0802b73fbd75a3cf794))
+ __QuickQB:__ Casts values when using them in where clauses ([6035327](https://github.com/coldbox-modules/quick/commit/60353271b190dc37d11f2c06e597578e3a2c13e2))
+ __CI:__ Fix for Lucee 6 and custom DSNs in CI
 ([1e2ddaf](https://github.com/coldbox-modules/quick/commit/1e2ddaf345be1cbedb185bc5cc413c571027237a))

### other

+ __\*:__ Failing test
 ([25bca38](https://github.com/coldbox-modules/quick/commit/25bca381fcbf160b61284e351ad6f15aec8fbdab))


# v11.3.0
## 29 Apr 2025 — 20:55:57 UTC

### chore

+ __CI:__ Lucee 6 is not ready for prime time
 ([88473a0](https://github.com/coldbox-modules/quick/commit/88473a0c5d111a39f216bd4c3ec7e4ac6d094db0))
+ __CI:__ More test engine matrix pruning
 ([935fd04](https://github.com/coldbox-modules/quick/commit/935fd047d3072ec6d87f95cc52b878800fffe174))
+ __CI:__ Upgrade ACF testing matrix
 ([3173e92](https://github.com/coldbox-modules/quick/commit/3173e923b8785f83de323f3c91b1662482334796))

### feat

+ __Relationship:__ Allow parallel loading for loadRelationship
 ([4e2b199](https://github.com/coldbox-modules/quick/commit/4e2b1996ea902c1ec523d41b39ffd1f93c5b0c4e))

### other

+ __\*:__ fix: Use ColdBox Async manager over built in async loops
 ([5920e2c](https://github.com/coldbox-modules/quick/commit/5920e2c105201113234d248085f15eea48a22b78))


# v11.2.1
## 04 Apr 2025 — 20:26:28 UTC

### fix

+ __EagerLoading:__ Use `box` namespace for CommandBox compatibility
 ([a05076f](https://github.com/coldbox-modules/quick/commit/a05076f8ea55a32ec061cfcbb345f7ed37f6eaaa))


# v11.2.0
## 03 Apr 2025 — 18:33:20 UTC

### feat

+ __EagerLoading:__ Give entities a way to automatically eager load certain relationships ([399bb93](https://github.com/coldbox-modules/quick/commit/399bb939f9c1e2f4d8b96416c1892ac16478df1b))
+ __EagerLoading:__ Allow preventing all lazy loading of relationships ([5939192](https://github.com/coldbox-modules/quick/commit/5939192e6f595dfd8f58d09a5c287083566d19f6))

### fix

+ __BoxLang:__ Compatibility updates
 ([4426aee](https://github.com/coldbox-modules/quick/commit/4426aeef420740359b39169902dcf9f0d73f73b1))


# v11.1.0
## 05 Feb 2025 — 17:05:10 UTC

### feat

+ __KeyTypes:__ Add GUID keyType introduced in QB v9
 ([38b2479](https://github.com/coldbox-modules/quick/commit/38b247906c398690303eb9e3ba41f0de23ab9e49))

### fix

+ __HasManyDeep:__ Account for compound keys in hasManyDeep relationships
 ([71d9c5a](https://github.com/coldbox-modules/quick/commit/71d9c5a3ee8067954995aed8513368533022b003))


# v11.0.1
## 04 Feb 2025 — 02:48:38 UTC

### fix

+ __QuickBuilder:__ Fix for aliases with fully server qualified identifiers
 ([5b61ebe](https://github.com/coldbox-modules/quick/commit/5b61ebedd6b4906e7235eb156682ce2f961e9cdb))


# v11.0.0
## 03 Feb 2025 — 22:21:28 UTC

### BREAKING

+ __\*:__ feat: BoxLang compatibility ([68dbfd4](https://github.com/coldbox-modules/quick/commit/68dbfd4ebdef4cc2f80d28f00c92a2f087600275))

### fix

+ __QuickBuilder:__ Pass grammar to `inferSqlType`
 ([54ca2aa](https://github.com/coldbox-modules/quick/commit/54ca2aaff7e2242df5ab4d7f1a7ee53d5d85a390))


# v10.0.1
## 15 Jan 2025 — 18:16:59 UTC

### fix

+ __BaseEntity:__ Better matching of only "as" in relationship strings ([263461d](https://github.com/coldbox-modules/quick/commit/263461de025ad8ef340d618d4fcf622b6a275e40))


# v10.0.0
## 08 Oct 2024 — 06:05:50 UTC

### BREAKING

+ __qb:__ Upgrade to qb v10 ([8a9be8f](https://github.com/coldbox-modules/quick/commit/8a9be8f9fc1d47fbd3b0ea06443f30c1f2dd796d))


# v9.0.3
## 04 Oct 2024 — 17:13:58 UTC

### fix

+ __ChildEntity:__ Ensure single table inheritance columns are not duplicated ([2a37ead](https://github.com/coldbox-modules/quick/commit/2a37ead9962e98e79eabda042a43a7969ce407f4))


# v9.0.2
## 24 Sep 2024 — 18:55:51 UTC

### fix

+ __HasOneThrough:__ Add missing matchOne method
 ([a09196e](https://github.com/coldbox-modules/quick/commit/a09196ec8f248ade92202e140c3a10d1d5a4a20a))
+ __ChildEntities:__ Fix qualifying column on discriminated joined entities
 ([d3559bc](https://github.com/coldbox-modules/quick/commit/d3559bc206a74d3ac27602e999fd4758b13a2d21))


# v9.0.1
## 12 Jun 2024 — 21:45:58 UTC

### fix

+ __BaseEntity:__ Fixed issue with NULL values being inserted into identity columns for MSSQL ([4ae80fa](https://github.com/coldbox-modules/quick/commit/4ae80fae95d2b40461ad7b23306b4111f785ea40))


# v9.0.0
## 31 May 2024 — 22:18:55 UTC

### BREAKING

+ __Relationships:__ Return default entities for non-matched eager loaded entites ([b1212de](https://github.com/coldbox-modules/quick/commit/b1212deb04a68339db7a3f128a9e549e041907a9))
+ __Child Entities:__ Fix casting for discriminated entities ([288b81b](https://github.com/coldbox-modules/quick/commit/288b81baa17a45181d559a6d8bd26fbdeeb9da16))

### chore

+ __tests:__ Only test against Lucee 6 in cron tests ([940ed80](https://github.com/coldbox-modules/quick/commit/940ed80dd48c6919c1cc1176880b12172c54aadd))
+ __tests:__ Add in Adobe 2023 and ColdBox 7 to the testing matrix
 ([cd3c8da](https://github.com/coldbox-modules/quick/commit/cd3c8da4d584e6924f37a1add7565658fa809562))

### feat

+ __Relationships:__ Get a new filled instance of a relationship by calling the `fill` method on the relationship object
 ([a2da133](https://github.com/coldbox-modules/quick/commit/a2da13357eae26c68eab6454588217ba3a307568))
+ __Events:__ Add `newAttributes` and `originalAttributes` to the `preUpdate` event
 ([4dd8496](https://github.com/coldbox-modules/quick/commit/4dd8496638fe7e689428e36ff2066223f930ba22))
+ __Relationships:__ Add additional fetch methods to all relationships ([9709b2f](https://github.com/coldbox-modules/quick/commit/9709b2f72c8c4182d63440cd5f88cd39526114bb))
+ __Casts:__ Allow specifying virtual attributes with a cast ([a57d092](https://github.com/coldbox-modules/quick/commit/a57d092047b320a34d18ff2775a7f55176ee5e91))

### fix

+ __Relationships:__ Clear the relationship cache for a relationship when using the relationship setter
 ([f49b099](https://github.com/coldbox-modules/quick/commit/f49b09909fd5482f46bb2637f2790523ed295a6b))
+ __BaseEntity:__ Only computed attributes hash from persistent attributes
 ([164b047](https://github.com/coldbox-modules/quick/commit/164b0479451bff48e731fbb5e1c9200ebc390d7f))
+ __Relationships:__ Fix naming collision with `newEntity` function and variable name.
 ([81aedbb](https://github.com/coldbox-modules/quick/commit/81aedbb48504a14ac87b1be8cae5f587bbfd3556))
+ __BaseEntity:__ Handle null values when assigning to attributes
 ([ba3a2f4](https://github.com/coldbox-modules/quick/commit/ba3a2f437d2d8f880088f6e7b2fa8033e682c554))
+ __HasOneOrMany:__ Allow returning a new non-persisted entity ([084a089](https://github.com/coldbox-modules/quick/commit/084a089508f6ba935b5a527564a727c3c452560f))

### other

+ __\*:__ Fixed issue null check would never pass
 ([38005c9](https://github.com/coldbox-modules/quick/commit/38005c9a9ee54b71f0b6eed1837b534181b90e39))
+ __\*:__ Update JsonCast.cfc
 ([b92fc0a](https://github.com/coldbox-modules/quick/commit/b92fc0a418a7d5f991d4e9f181eacbb53808ec94))
+ __\*:__ -fixed regression for issue #203
 ([45095ad](https://github.com/coldbox-modules/quick/commit/45095ad616e1b27fee219a3f6411941ca1f90e8e))
+ __\*:__ remove hydrate in favor of manually assigning attributes ([c87cb9c](https://github.com/coldbox-modules/quick/commit/c87cb9c10d6b8e3e64f00cccd78b00024cacbefa))
+ __\*:__ Fixed issue where virtualAttributes were not being applied to discriminated child entities when loading through the parent
 ([149aa9e](https://github.com/coldbox-modules/quick/commit/149aa9eb40d1d382fc195cb6c36682a592ae1768))


# v8.0.3
## 19 Apr 2024 — 21:16:01 UTC

### fix

+ __ModuleConfig:__ Support qb's SqlCommenter
 ([66799c6](https://github.com/coldbox-modules/quick/commit/66799c63aa96ca13197fb5d585193ffd4c233108))


# v8.0.2
## 26 Mar 2024 — 22:12:23 UTC

### fix

+ __Relationships:__ Handle skipping constraints when a relationship is defined with other relationships
 ([62fa4a4](https://github.com/coldbox-modules/quick/commit/62fa4a41d15b64747f27569489d7a2ac51f3ecc5))


# v8.0.1
## 26 Mar 2024 — 20:03:50 UTC

### fix

+ __BaseEntity:__ Make the withoutRelationshipConstraints check more resilient ([4aedbac](https://github.com/coldbox-modules/quick/commit/4aedbac0d06355105d299bf0d240a73c2236f886))


# v8.0.0
## 26 Mar 2024 — 19:33:41 UTC

### BREAKING

+ __Relationship:__ Required the relationship name when disabling constraints to match on ([dff52d6](https://github.com/coldbox-modules/quick/commit/dff52d681e4b47e674dfec979de6f0853cea093c))


# v7.4.4
## 26 Mar 2024 — 18:11:18 UTC

### fix

+ __HasManyThrough:__ Fix for thread safety when loading multiple relationships off of a single entity
 ([9e49f55](https://github.com/coldbox-modules/quick/commit/9e49f558b80cc87e25eecc40791c965a470e283c))


# v7.4.3
## 22 Mar 2024 — 03:08:47 UTC

### fix

+ __HasManyDeep:__ Fix qualifying column issue ([72723b1](https://github.com/coldbox-modules/quick/commit/72723b19f51cd8e873133e04c7c711965784830d))


# v7.4.2
## 20 Mar 2024 — 22:55:50 UTC

### fix

+ __HasManyDeep:__ Remove duplicate join from addCompareConstraints
 ([a9fa07e](https://github.com/coldbox-modules/quick/commit/a9fa07e2973e62122d6a28b4f24c09a0fe02b2e2))


# v7.4.1
## 19 Mar 2024 — 17:54:52 UTC

### fix

+ __box.json:__ Upgrade to latest str dependency
 ([582e4cc](https://github.com/coldbox-modules/quick/commit/582e4cc38ed3fe8317ddc5553bb143fb7ba976a2))


# v7.4.0
## 18 Mar 2024 — 16:41:44 UTC

### chore

+ __tests:__ Remove extra debug logs from tests
 ([1ba3ca0](https://github.com/coldbox-modules/quick/commit/1ba3ca0a49f3cdc35c122151aab9f7af7b18fe8a))

### feat

+ __HasManyThrough:__ The `hasManyThrough` function now returns `HasManyDeep` relationships 
 ([1af491a](https://github.com/coldbox-modules/quick/commit/1af491ab0f1c21f8c15d67603c4e413f24af1320))
+ __Relationships:__ New `hasManyDeep` and `hasManyDeepBuilder` relationships. ([5331b36](https://github.com/coldbox-modules/quick/commit/5331b36b67d9f35996ae47579d780cc97fa0371d))

### fix

+ __HasManyThrough:__ Keep constraints of through entities for `hasManyThrough` relationships
 ([3f3de36](https://github.com/coldbox-modules/quick/commit/3f3de36125997717ecc56a208384ba5c307eb500))
+ __HasManyThrough:__ Keep constraints on final related entities in hasManyThrough
 ([95a53d3](https://github.com/coldbox-modules/quick/commit/95a53d304205bac9f6815d9053f99147788620ce))
+ __IRelationship:__ Update type hints to satisfy `IRelationship` interface
 ([026d7e0](https://github.com/coldbox-modules/quick/commit/026d7e0a8bd365a0c2efc1559737f3c325b4a971))

### other

+ __\*:__ v7.4.0-beta.2
 ([530502c](https://github.com/coldbox-modules/quick/commit/530502c92aadc7c291a98ae5406d38b0c00fba8c))
+ __\*:__ v7.4.0-beta.1
 ([49e11bb](https://github.com/coldbox-modules/quick/commit/49e11bb8956ea93bf2c547e7faa215879283489f))


# v7.3.2
## 05 Feb 2024 — 20:23:02 UTC

### fix

+ __BaseEntity:__ Use the interceptor approach instead of `wirebox:targetId` to support CommandBox ([164247d](https://github.com/coldbox-modules/quick/commit/164247d2858c9d5f6b3f3e27548d4296fe1ea07a))


# v7.3.1
## 03 Jan 2024 — 17:58:04 UTC

### fix

+ __Discriminators:__ Fix where discriminated entities could use the wrong qualified column name in the join with the parent entity.
 ([682aa03](https://github.com/coldbox-modules/quick/commit/682aa03874ae16af927b1b6b6c400a1791687544))


# v7.3.0
## 21 Dec 2023 — 19:13:38 UTC

### chore

+ __tests:__ add test case for checking null attributes on newly created entities ([638754a](https://github.com/coldbox-modules/quick/commit/638754a701fda2a4500dae9b5bdcd744ce68bbc7))
+ __tests:__ add test case for deleteAll off of a hasMany relationship
 ([1626bc5](https://github.com/coldbox-modules/quick/commit/1626bc5cfd7d8e40e6b1033c872934d579e2271c))
+ __tests:__ add test case for belongsToMany withCount
 ([8bfad62](https://github.com/coldbox-modules/quick/commit/8bfad624eaa91a0a9ce506afcc92750968159f26))
+ __tests:__ add test case for firstOrNew with aliases and columns ([5dc81bf](https://github.com/coldbox-modules/quick/commit/5dc81bf9b6c2f0d29e49ed80b45d6c4c6797844f))

### feat

+ __QuickBuilder:__ Return optional QuickBuilder instances for `withCount` and `withSum` ([e1b17cf](https://github.com/coldbox-modules/quick/commit/e1b17cfeccb5e9693fa4b9dcaa7e65c100814a1a))

### fix

+ __BaseEntity:__ Fix clearAttribute when not setting to null ([4018d54](https://github.com/coldbox-modules/quick/commit/4018d541fdd3635924a9eddd4986a6704df1c187))
+ __QuickBuilder:__ Fix using a query builder instance to define a subselect ([8ac6ba7](https://github.com/coldbox-modules/quick/commit/8ac6ba727fb8e290a0fe620a5702fc8398d0383c))

### other

+ __\*:__ fix: revert server.json change
 ([4182c55](https://github.com/coldbox-modules/quick/commit/4182c55b22fa39e0e273b736daa4df635f280127))


# v7.2.0
## 15 Sep 2023 — 20:07:44 UTC

### feat

+ __QuickQB:__ Allow defaultOptions for underlying QuickQB
 ([a1e282f](https://github.com/coldbox-modules/quick/commit/a1e282fb60d0c625ea08e46d578af3950868c0ca))


# v4.1.5
## 02 Nov 2020 — 12:24:13 UTC

### fix

+ __HasOne:__ Provide initialThroughConstraints for hasOne relationships
 ([7b3b8d0](https://github.com/coldbox-modules/quick/commit/7b3b8d0bb9a6f4f7993d227dea6c1908ec930f64))


# v4.1.4
## 30 Oct 2020 — 18:35:59 UTC

### chore

+ __Tests:__ Add test for dynamic subselect relationships
 ([fdf97eb](https://github.com/coldbox-modules/quick/commit/fdf97ebf857f3a21c68653a83cca85e1c7d7ba14))

### fix

+ __Relationship:__ Don't include orders when doing a count on a relationship (#126) ([313c594](https://github.com/coldbox-modules/quick/commit/313c594b7cc39aaaadd8e8136852727f35686cc4))


# v4.1.3
## 10 Sep 2020 — 16:11:22 UTC

### chore

+ __Testing:__ Migrate to new database fixtures setup ([e65add5](https://github.com/coldbox-modules/quick/commit/e65add59c858f532fc6102318b9514ce6e783144))


# v4.1.2
## 04 Sep 2020 — 15:33:44 UTC

### fix

+ __Casts:__ Fix for retaining cast cache when creating entities
 ([835beee](https://github.com/coldbox-modules/quick/commit/835beeea6439f74e0116f8693ef2f2712379a2f3))


# v4.1.1
## 03 Sep 2020 — 03:48:53 UTC

### chore

+ __Format:__ Format with CFFormat
 ([621ce6c](https://github.com/coldbox-modules/quick/commit/621ce6c4dff3fe01746c64cef1256c007b1534c5))

### fix

+ __Cast:__ Preserve casted value after saving
 ([8680b1d](https://github.com/coldbox-modules/quick/commit/8680b1de20b95f8bb5d3c76ef731c7b3575647bc))


# v4.1.0
## 28 Aug 2020 — 20:59:11 UTC

### feat

+ __BaseEntity:__ Allow for child entities included discriminated entities ([28bf5e2](https://github.com/coldbox-modules/quick/commit/28bf5e25bcf9182091190a3fe542bec1d3aa4247))

### fix

+ __KeyType:__ Look up returning values by column name not by alias
 ([f1a0832](https://github.com/coldbox-modules/quick/commit/f1a0832fc1bedf1b5ce42a174e59bfb1070064ca))


# v4.0.2
## 13 Aug 2020 — 05:45:22 UTC

### fix

+ __EagerLoading:__ Skip eager loading when no keys are found ([8b83529](https://github.com/coldbox-modules/quick/commit/8b835296de59c1b4fdd93981d6dd724591296305))
+ __Relationships:__ Only apply CONCAT when needed ([db220e2](https://github.com/coldbox-modules/quick/commit/db220e290db06b8604e15b631ac8301efea0bdaa))


# v4.0.1
## 04 Aug 2020 — 21:26:55 UTC

### fix

+ __Relationships:__ Remove DISTINCT in favor of WHERE EXISTS ([a051c98](https://github.com/coldbox-modules/quick/commit/a051c98772b58a397e622538c8cd0747502744a1))


# v4.0.0
## 24 Jul 2020 — 15:14:31 UTC

### BREAKING

+ __Scopes:__ Scopes with an OR combinator are automatically grouped ([3183f6d](https://github.com/coldbox-modules/quick/commit/3183f6d45bfbd1755002d585fb578564f0728195))

### chore

+ __docs:__ Fix broken link from README to official docs ([6881634](https://github.com/coldbox-modules/quick/commit/6881634e256c01837b5b02706a3a000b3b38f1ab))

### feat

+ __Relationships:__ Add a `withCount` method to easily add relationship counts to entities ([8524ef8](https://github.com/coldbox-modules/quick/commit/8524ef8473276e6d21589f9c54544b624113d1f2))
+ __QuickBuilder:__ Automatically scope whereHas and whereDoesntHave callbacks
 ([38b8a46](https://github.com/coldbox-modules/quick/commit/38b8a466cf9863d73d6b24ab204790705be63e3a))

### fix

+ __ErrorMessages:__ Improve error message when attempting to set relationships on unloaded entities
 ([fe4ad26](https://github.com/coldbox-modules/quick/commit/fe4ad26b72c34e707daf52fd3eecf11055c221f5))
+ __Relationships:__ Fix addSubselect and *manyThrough overflows and bugs
 ([ab8e121](https://github.com/coldbox-modules/quick/commit/ab8e1218b785e78d0cc5b323bde61e29b9a34dd0))
+ __BelongsTo:__ If all the foreign keys are null, skip the database and return the default entity or null ([287e990](https://github.com/coldbox-modules/quick/commit/287e990a14947db06e723878b596078610dad240))
+ __BelongsTo:__  Reference provided localKeys instead of pulling them from the related entity ([43f47aa](https://github.com/coldbox-modules/quick/commit/43f47aa73ff0568d256ec018b37952329ba792aa))
+ __HasManyThrough:__ Swap final compare constraints in nested query
 ([22d1728](https://github.com/coldbox-modules/quick/commit/22d17280ec3e99dce66b34f3114f8611a22e4081))


# v3.1.7
## 10 Jul 2020 — 16:04:10 UTC

### fix

+ __tests:__ Correct jQuery link in test runner (#95) ([7bb1b3d](https://github.com/coldbox-modules/quick/commit/7bb1b3d755f4642421926a93ef5bf623f5578e14))


# v3.1.6
## 29 Jun 2020 — 19:19:44 UTC

### fix

+ __QuickBuilder:__ Allow expressions in basic where clauses
 ([f267c2f](https://github.com/coldbox-modules/quick/commit/f267c2f7fff469d113e4d52f1a52c1c1a4ae7d40))
+ __BaseEntity:__ Fix delete naming collision
 ([c7dca98](https://github.com/coldbox-modules/quick/commit/c7dca9870e37b4ba7600e7d7ef6c4443b8930791))


# v3.1.5
## 24 Jun 2020 — 00:24:50 UTC

### fix

+ __QuickBuilder:__ Add an alias to `with` ([5491ba7](https://github.com/coldbox-modules/quick/commit/5491ba70333e3f7a308d8c1ed0f2eb3e177e6b59))


# v3.1.4
## 19 Jun 2020 — 05:58:34 UTC

### fix

+ __QuickBuilder:__ Fix stack overflow on nested relationship checks ([16bae19](https://github.com/coldbox-modules/quick/commit/16bae1992b5d2f690f33569520ebd49f567e5e29))


# v3.1.3
## 19 Jun 2020 — 05:44:30 UTC

### fix

+ __QuickBuilder:__ Configured tables are now used for qualifying columns ([76bb1f7](https://github.com/coldbox-modules/quick/commit/76bb1f7b8eb089a18c5da4a1c69473dffd203d04))


# v3.1.2
## 29 May 2020 — 18:03:15 UTC

### fix

+ __BelongsToMany:__ Remove unnecessary nesting in compare queries
 ([97e3a88](https://github.com/coldbox-modules/quick/commit/97e3a88cb1171855cc12c59353ed00e8a6595707))


# v3.1.1
## 28 May 2020 — 22:05:51 UTC

### fix

+ __Relationships:__ Fix orWhereHas methods when querying nested relationships
 ([8262bb3](https://github.com/coldbox-modules/quick/commit/8262bb30efba7c28da753b395b4826a1969de5be))


# v3.1.0
## 28 May 2020 — 21:25:33 UTC

### feat

+ __JSONCast:__ Add support for JSON casting ([137701a](https://github.com/coldbox-modules/quick/commit/137701a5383abf25d53d218fa5f90537fea53554))


# v3.0.4
## 27 May 2020 — 05:41:15 UTC

### fix

+ __CBORMCompatEntity:__ Updates for coldbox@6
 ([1f10fde](https://github.com/coldbox-modules/quick/commit/1f10fde47a78b18b94112198c89911620a5c69db))


# v3.0.3
## 13 May 2020 — 17:24:08 UTC

### chore

+ __CI:__ Fix module id
 ([9d9c4ab](https://github.com/coldbox-modules/quick/commit/9d9c4abe00ba3bce9051d815408f0c94f7c8ab90))

### fix

+ __Casts:__ Optimize cast caching
 ([2f9b510](https://github.com/coldbox-modules/quick/commit/2f9b510ccf8a3e60402eadd85c4386fd75f1a885))


# v3.0.2
## 11 May 2020 — 20:02:26 UTC

### fix

+ __EagerLoading:__ Apply custom sqltypes during eager loading
 ([c9633d3](https://github.com/coldbox-modules/quick/commit/c9633d3fc42a1e14fe48051a735dd1eeee956318))


# v3.0.1
## 08 May 2020 — 22:04:29 UTC

### fix

+ __BaseEntity:__ Account for null values in fill
 ([3f8bc2c](https://github.com/coldbox-modules/quick/commit/3f8bc2cabb1503d6617ccea9ad0c870b3816461c))
+ __Memento:__ Swap structAppend order for a Lucee bug
 ([1e0d217](https://github.com/coldbox-modules/quick/commit/1e0d2173ad8fe2eefce96ac509cd8d127ab34a0c))


# v3.0.0
## 06 May 2020 — 19:01:56 UTC

### BREAKING

+ __QuickBuilder:__ Prevent duplicate joins by default ([a8ac022](https://github.com/coldbox-modules/quick/commit/a8ac02207b2b7125a11fd4b9ba60ed44ebcfbdbc))
+ __BaseEntity:__ Enforce accessors for entities ([ad16248](https://github.com/coldbox-modules/quick/commit/ad162481322ea8c6a56cc59fa1cc80904e4b666c))
+ __BaseEntity:__ Remove virtual inheritance ([3b026b1](https://github.com/coldbox-modules/quick/commit/3b026b156684332648fbeb093086618c50f5d272))
+ __BaseEntity:__ Improve virtual column support ([5ebc42c](https://github.com/coldbox-modules/quick/commit/5ebc42c9d09d625285594c94311d38b41fd9dc1f))

### chore

+ __CI:__ CI debugging
 ([1111603](https://github.com/coldbox-modules/quick/commit/1111603eaaa1a981822f1c5441af883516dc8922))
+ __CI:__ CI debugging
 ([19b3053](https://github.com/coldbox-modules/quick/commit/19b30532b77fb1cbbed28ac30f22f7d95ddb8f67))
+ __CI:__ CI debugging
 ([6280040](https://github.com/coldbox-modules/quick/commit/6280040c7fc61bbf9573c4e944b6ea7cbfea7612))
+ __CI:__ CI debugging
 ([75bcb64](https://github.com/coldbox-modules/quick/commit/75bcb64d8757778c7a44e4e8efdde77104185aab))
+ __CI:__ CI debugging
 ([fda269a](https://github.com/coldbox-modules/quick/commit/fda269ab259bfa36aaa38174c465d51a8daa2ce4))
+ __CI:__ CI debugging
 ([5662bdc](https://github.com/coldbox-modules/quick/commit/5662bdc450218cddc4da0df6772079b9d05d6fcb))
+ __CI:__ CI debugging
 ([7716222](https://github.com/coldbox-modules/quick/commit/771622240e8e051d5dedd6031a0ba1f11b59fdb5))
+ __CI:__ CI debugging. :-(
 ([1912c2a](https://github.com/coldbox-modules/quick/commit/1912c2a8b80895abc81e446f2754c6df177efae7))
+ __CI:__ Add qb mapping for tests
 ([45c5238](https://github.com/coldbox-modules/quick/commit/45c5238767b57a356dc1a52bc30fee3003ac1348))
+ __CI:__ Fix overriding coldbox@be installation
 ([c4f9ae0](https://github.com/coldbox-modules/quick/commit/c4f9ae02e575855bd5e5d5b14fd01059039a6484))
+ __CI:__ Publish API docs after publishing a new version
 ([690b95d](https://github.com/coldbox-modules/quick/commit/690b95d077c3a179fccdb6d210d932326b6e5f9d))
+ __CI:__ Adjust CI builds to test bleeding edge on cron jobs
 ([0ffdafc](https://github.com/coldbox-modules/quick/commit/0ffdafc1049a4aac1ffd92fb9281200fa1b34b31))
+ __CI:__ Clean up .travis.yml
 ([d5753b5](https://github.com/coldbox-modules/quick/commit/d5753b51736ff2fb37b4c69ac390e1df567e87f6))

### feat

+ __Interceptors:__ Fire the postLoad event for all entities
 ([a480ef2](https://github.com/coldbox-modules/quick/commit/a480ef230ac73975b53995cbd8cb7c9f9177ee3f))
+ __ErrorMessages:__ Improve error message when accessing relationships on unloaded entities ([d43f699](https://github.com/coldbox-modules/quick/commit/d43f6994e8e7c9cf16bf44a79c1bde0170ef43fe))

### fix

+ __BaseEntity:__ Rename is and isNot to isSameAs and isNotSameAs for better ACF compatibility
 ([fff27a1](https://github.com/coldbox-modules/quick/commit/fff27a1f0c17579bb9b229711f7d1937bb18f353))
+ __BaseEntity:__ Improved hasRelationship check ([4064619](https://github.com/coldbox-modules/quick/commit/406461960915aea8d24dd9d448214d0df864f762))
+ __QuickBuilder:__ Fix nested whereHas with belongsToMany Relationships ([99f957e](https://github.com/coldbox-modules/quick/commit/99f957ed4c909860afd73b5b6ea7c0fb1e744b44))
+ __BaseEntity:__ Fix for virtual columns trying to be updated
 ([5f13e4f](https://github.com/coldbox-modules/quick/commit/5f13e4f9f210acf1f9d97b6a740acce9e03cb531))
+ __BaseEntity:__ Qualify all column names and correctly return eager loaded belongsToMany Relationships ([09f9c64](https://github.com/coldbox-modules/quick/commit/09f9c643c095f8b0d936d6fb4234341b0aa04b3c))
+ __BaseEntity:__ Forward updateOrInsert calls to updateOrCreate ([888fa22](https://github.com/coldbox-modules/quick/commit/888fa22c2586bc86fe2ecd6c3a855ca3ac8a1164))
+ __Memento:__ Ensure virtual columns are included in mementos by default
 ([6c72a46](https://github.com/coldbox-modules/quick/commit/6c72a4658be04ddfff6b25148e58ec832bbea064))
+ __BaseEntity:__ qualify columns when using fresh and refresh
 ([1cce0a2](https://github.com/coldbox-modules/quick/commit/1cce0a252b751879c5f74628d8aa24147152cdac))
+ __QuickBuilder:__ Clear orders when querying releationships ([d77c781](https://github.com/coldbox-modules/quick/commit/d77c781b1d204f00bf9514bb3292aaf73da61021))
+ __GlobalScopes:__ Ensure global scopes are only applied once per query
 ([664b288](https://github.com/coldbox-modules/quick/commit/664b288feb25f74f70ed28dd22b7f2b9068b6108))
+ __BaseEntity:__ Duplicate metadata struct when creating new entities ([5c06fa4](https://github.com/coldbox-modules/quick/commit/5c06fa4ea6dfdd508a932302c69cf28581fe8756))
+ __BaseEntity:__ Fix double applying of global scopes
 ([b374caa](https://github.com/coldbox-modules/quick/commit/b374caa9f65d4534c381945eb6af0a2d0e2bdf5c))
+ __BaseEntity:__ Default polymorphicBelongsTo name to the relation method name
 ([72352d6](https://github.com/coldbox-modules/quick/commit/72352d6a7325e95258fbef952375903858a381e0))

### other

+ __\*:__ v3.0.0-beta.13
 ([27ada30](https://github.com/coldbox-modules/quick/commit/27ada3048023a90e615a0f161a3b792eda07fcc7))
+ __\*:__ v3.0.0-beta.12
 ([57c1098](https://github.com/coldbox-modules/quick/commit/57c1098cd419fdffe8963da27b9653cb87c68728))
+ __\*:__ v3.0.0-beta.11
 ([defadc4](https://github.com/coldbox-modules/quick/commit/defadc4707919bfe492d95963ba189c096e2c75f))
+ __\*:__ v3.0.0-beta.10
 ([3ed41b4](https://github.com/coldbox-modules/quick/commit/3ed41b473f976fc1bf92d1f9c94bcda0eddaa651))
+ __\*:__ v3.0.0-beta.9
 ([0e761bf](https://github.com/coldbox-modules/quick/commit/0e761bf82c7cb21eb831a522b51655305a5ee2d9))
+ __\*:__ v3.0.0-beta.8
 ([5f33efa](https://github.com/coldbox-modules/quick/commit/5f33efad60a2701daf4d167e494c248ccada4c00))
+ __\*:__ chore: format with cfformat
 ([ad9d544](https://github.com/coldbox-modules/quick/commit/ad9d5441ee1f04b37eaffabc462c1846c8f0c492))
+ __\*:__ v3.0.0-beta.7
 ([da7eb88](https://github.com/coldbox-modules/quick/commit/da7eb880a8ab8897855de1a74d1ba6af9dbf428c))
+ __\*:__ Update docblocks
 ([b48e1d8](https://github.com/coldbox-modules/quick/commit/b48e1d8f0f8f8156be0e4ce6e5de94277fd73e56))
+ __\*:__ v3.0.0-beta.6
 ([24ad429](https://github.com/coldbox-modules/quick/commit/24ad42992b5f658254c6ef8c03a6acbe1f6bdc42))
+ __\*:__ v3.0.0-beta.5
 ([27e0258](https://github.com/coldbox-modules/quick/commit/27e02585f86be3cb87cae30371e7923031e6e313))
+ __\*:__ v3.0.0-beta.4
 ([d41d071](https://github.com/coldbox-modules/quick/commit/d41d071663db2405ac6647612b7ea5ddd90acbf2))
+ __\*:__ v3.0.0-beta.3
 ([59bb622](https://github.com/coldbox-modules/quick/commit/59bb622f19117263a0b188046a14f06f78355a1e))
+ __\*:__ v3.0.0-beta.2
 ([6e2ceab](https://github.com/coldbox-modules/quick/commit/6e2ceab6f2f8626998e711cc36cc334f2eba7af5))
+ __\*:__ v3.0.0-beta.1
 ([092ce93](https://github.com/coldbox-modules/quick/commit/092ce93beec9577f99136e73f24998ef8ed1e399))
+ __\*:__ chore: Update docblocks
 ([ecd3e27](https://github.com/coldbox-modules/quick/commit/ecd3e277ca1d0a1995362afedf1985f01f6fedb0))
+ __\*:__ v3.0.0-alpha.2
 ([4f01505](https://github.com/coldbox-modules/quick/commit/4f01505258721ce132dca0d947fdd71e47ae72a7))

### refactor

+ __BaseEntity:__ Clean up virtual column naming
 ([88d8237](https://github.com/coldbox-modules/quick/commit/88d823709a50b5c20363011bae3713311285ea89))


# v2.5.7
## 26 Feb 2020 — 00:16:25 UTC

### other

+ __\*:__ docs: Fix link to Gitbook from README ([5a8cf6a](https://github.com/coldbox-modules/quick/commit/5a8cf6aa945b4e5dc21b17823a475feaa0ab8e06))


# v2.5.6
## 19 Feb 2020 — 22:22:10 UTC

### fix

+ __BaseEntity:__ Correctly use the grammar annotation
 ([2312e9e](https://github.com/coldbox-modules/quick/commit/2312e9e3bcfdd441b4d80207d0636402aa612b1a))


# v2.5.5
## 13 Feb 2020 — 17:30:08 UTC

### other

+ __\*:__ chore: Use forgeboxStorage ([ad6c413](https://github.com/coldbox-modules/quick/commit/ad6c41392be2cff5b1d738a15209ed5b01beef1d))


# v2.5.4
## 20 Dec 2019 — 06:20:30 UTC

### fix

+ __CBORMCompat:__ Pass along query options in compat methods
 ([9a2739e](https://github.com/coldbox-modules/quick/commit/9a2739e0030fc1197e0255a1390fb061f07823e2))


# v2.5.3
## 11 Dec 2019 — 21:40:12 UTC

### fix

+ __BaseEntity:__ Revert calling setters when hydrating entities ([670fadb](https://github.com/coldbox-modules/quick/commit/670fadbbc5887952c7040025da16c497229a138e))


# v2.5.2
## 09 Dec 2019 — 17:57:41 UTC

### fix

+ __BaseEntity:__ Pass the entity to `when` closures ([96a8f3a](https://github.com/coldbox-modules/quick/commit/96a8f3af6bec3383e7acc4a9703fe1de3a9bd0cc))


# v2.5.1
## 05 Dec 2019 — 04:55:20 UTC

### fix

+ __BaseEntity:__ Account for null values with custom setters ([685e175](https://github.com/coldbox-modules/quick/commit/685e17572978b6d9f34a883843e765d3910e4870))
+ __BaseEntity:__ Reset underlying query when resetting entity ([83a6fdb](https://github.com/coldbox-modules/quick/commit/83a6fdb43736170671e9d4ad919c4e5b0b51c788))


# v2.5.0
## 04 Dec 2019 — 21:53:02 UTC

### feat

+ __BaseEntity:__ Allow entities to define a custom collection type. ([9135eee](https://github.com/coldbox-modules/quick/commit/9135eeeeddc86e97160cf473fcbbe79a5e336f42))


# v2.4.3
## 19 Nov 2019 — 07:59:46 UTC

### fix

+ __BaseEntity:__ Avoid stack overflow with getMemento and custom getters ([7c9e073](https://github.com/coldbox-modules/quick/commit/7c9e073c089f62047faac1e3e8fcc87eacbc8e0f))


# v2.4.2
## 08 Nov 2019 — 00:45:47 UTC

### fix

+ __memento:__ Use available getters for the memento
 ([ba562c3](https://github.com/coldbox-modules/quick/commit/ba562c3062d1170ff8e50e2a45357358aaf0c444))


# v2.4.1
## 07 Nov 2019 — 16:58:47 UTC

### fix

+ __memento:__ Correctly serialize array relationships by default
 ([479dabc](https://github.com/coldbox-modules/quick/commit/479dabce8f71459a7c3e1f3c084b2290a8b802f1))


# v2.4.0
## 06 Nov 2019 — 22:25:58 UTC

### chore

+ __dependencies:__ Update TestBox to version 3
 ([a0dd6ab](https://github.com/coldbox-modules/quick/commit/a0dd6abb904646f3c0a6eded06186bafa1afd704))

### feat

+ __setters:__ Apply setters when hydrating the entity from the database
 ([e4a0158](https://github.com/coldbox-modules/quick/commit/e4a0158ecb74b189428166c67677147b9ff19d00))
+ __ErrorMessages:__ Improve error messages for not loaded entities ([f3f2e2d](https://github.com/coldbox-modules/quick/commit/f3f2e2d95d2fb47e17765d11d581c1b3283d5dc0))
+ __Scopes:__ Query scopes can return any value ([358e977](https://github.com/coldbox-modules/quick/commit/358e977635b2f6b9f6d30c2c1b3dfdbe26054d73))


# v2.3.1
## 06 Nov 2019 — 21:45:40 UTC

### chore

+ __build:__ Adjust travis testbox run
 ([790df84](https://github.com/coldbox-modules/quick/commit/790df84685a411013128d00dd519602930007b2a))

### fix

+ __tests:__ Fix strange test error on Lucee 5 with nested describe blocks
 ([305e0a2](https://github.com/coldbox-modules/quick/commit/305e0a224282bf12df222116ce4a4dd110ca17c6))
+ __BaseEntity:__ Return the correct memento with accessors on ([59614a0](https://github.com/coldbox-modules/quick/commit/59614a00bea3a73346985be1e9487d599d65d178))


# v2.3.0
## 08 Jul 2019 — 15:46:12 UTC

### feat

+ __BaseEntity:__ Add flag to ignore non-existing attributes to fill ([428b31a](https://github.com/coldbox-modules/quick/commit/428b31ac0ab5de22440ff92341f079735de2db3a))


# v2.2.3
## 17 Jun 2019 — 15:06:40 UTC

### fix

+ __BaseEntity:__ Temporary fix for extra values in data ([821a054](https://github.com/coldbox-modules/quick/commit/821a05492a7184cb7a97361bfb6a1134991e1536))


# v2.2.2
## 14 Jun 2019 — 05:10:05 UTC

### perf

+ __BaseEntity:__ Better caching of metadata ([27b6ec3](https://github.com/coldbox-modules/quick/commit/27b6ec38a4ff3fc513807bad69f4461e7f3b8655))


# v2.2.1
## 14 Jun 2019 — 04:37:21 UTC

### chore

+ __build:__ Use openjdk8 in Travis builds
 ([d8f7d41](https://github.com/coldbox-modules/quick/commit/d8f7d41e00d53b740ee5d824087db90f47129177))

### other

+ __\*:__ docs: Fix Getting Started 404 ([5c9eddd](https://github.com/coldbox-modules/quick/commit/5c9eddd1d3f32daf87d80a2aa47e9c0d845da0c8))


# v2.2.0
## 29 May 2019 — 03:27:23 UTC

### feat

+ __Relationships:__ Add fetch methods to all Relationships ([61a6035](https://github.com/coldbox-modules/quick/commit/61a6035beba2f6d3fbcbcfd5a36941f32d38ae20))


# v2.1.3
## 14 May 2019 — 01:57:33 UTC

### tests

+ __Relationships:__ Prove relationship setters use the cache ([953d653](https://github.com/coldbox-modules/quick/commit/953d65310159a51e8388cf653283c201bd6bc680))


# v2.1.2
## 07 May 2019 — 07:07:20 UTC

### fix

+ __VirtualInheritance:__ Certify virtual inheritance support ([e105f18](https://github.com/coldbox-modules/quick/commit/e105f1899d26a072fd241e2337f060d32525898d))


# v2.1.1
## 03 May 2019 — 22:58:37 UTC

### fix

+ __Subselect:__ Return the entity after executing a subselect
 ([87e5a7a](https://github.com/coldbox-modules/quick/commit/87e5a7a7b2738500a7f1a84a09ca6e263d1df9f5))


# v2.1.0
## 03 May 2019 — 22:25:30 UTC

### feat

+ __Relationships:__ Relationships can be set using relationship setters ([e1e21a8](https://github.com/coldbox-modules/quick/commit/e1e21a83fc72232f8edc370665ed739eb6f33370))
+ __Relationships:__ Allow saving of ids as well as entities
 ([3f30131](https://github.com/coldbox-modules/quick/commit/3f301314629f5f07d474b661dae8db90f1b19815))
+ __HasMany:__ Many entities can be saved to a hasMany relationship at once ([c9f8f47](https://github.com/coldbox-modules/quick/commit/c9f8f4773bea5c7bd7e1ae142c5aad0550614aa5))
+ __Scopes:__ Register global scopes for entities ([995706b](https://github.com/coldbox-modules/quick/commit/995706b1266bf57456cf5f8406d188d6b978e26c))
+ __Subselects:__ Add subselect helper ([cf13ddd](https://github.com/coldbox-modules/quick/commit/cf13dddd8a8e674e6ee98730912220d5eeb010bf))

### fix

+ __Relationships:__ Make mapping foreign keys optional ([708506d](https://github.com/coldbox-modules/quick/commit/708506d8d4eee9fde0307d1fd6ed9bac57d94752))


# v1.3.2
## 30 Apr 2019 — 19:52:39 UTC

### chore

+ __box.json:__ Add author
 ([b38a7ed](https://github.com/coldbox-modules/quick/commit/b38a7edde6e810c71ff139cd295418a86779bb51))


# v1.3.1
## 30 Apr 2019 — 19:43:23 UTC

### chore

+ __Release:__ v2.0.0 ([425d474](https://github.com/coldbox-modules/quick/commit/425d474898058000c4f0b4defa270a75f3e73b64))

### docs

+ __README:__ Document that all fields need to be mapped ([ecece5c](https://github.com/coldbox-modules/quick/commit/ecece5c6a19d21eb0aa5718ad607995375467bef))


# v1.3.0
## 22 Aug 2018 — 19:58:30 UTC

### chore

+ __ci:__ Test on adobe@2018
 ([d42cf61](https://github.com/coldbox-modules/quick/commit/d42cf61e63d4bdeacfb04ab04e4a1c0b3c4f6a4a))

### feat

+ __BaseEntity:__ Enable per entity datasources and grammars ([561f368](https://github.com/coldbox-modules/quick/commit/561f36841bdba0eb238d07167d35754faf32976c))
+ __KeyType:__ Add AssignedKey Type ([897277d](https://github.com/coldbox-modules/quick/commit/897277d0ffeffafb515341ed3f9ed4e71fc50bda))


# v1.2.0
## 19 Jul 2018 — 22:43:54 UTC

### chore

+ __build:__ Fix spotty gpg key ([c3c5a18](https://github.com/coldbox-modules/quick/commit/c3c5a18b132ee73bc3f5dabb2dee6014f0855b59))
+ __build:__ Test adobe@2018 on CI ([299d5b0](https://github.com/coldbox-modules/quick/commit/299d5b0be6972bc7dc966e1b19acb5c24fac6723))

### feat

+ __Scopes:__ Allow scopes to call other scopes ([07bbde1](https://github.com/coldbox-modules/quick/commit/07bbde1f447b85a3ee4f0d80e4c24ca233102a65))


# v1.1.2
## 02 Jul 2018 — 17:22:46 UTC

### chore

+ __build:__ Set location automatically on version update ([183b05a](https://github.com/coldbox-modules/quick/commit/183b05a839e71105ffd1aae2a271dce85c808bbc))

### fix

+ __BaseEntity:__ Only set loaded for attributes successfully retrieved from the database ([665a78a](https://github.com/coldbox-modules/quick/commit/665a78a4cb44e61282f5017d895a41ae0768bcf9))


# v1.1.1
## 02 Jul 2018 — 16:54:21 UTC

### fix

+ __Relationships:__ correct detach function name ([5dceb17](https://github.com/coldbox-modules/quick/commit/5dceb17af5bcccee1b2eb6428a2c1a083b2432e9))

### other

+ __\*:__ Use logo in README ([3125e6b](https://github.com/coldbox-modules/quick/commit/3125e6b589e205718dd1cc19c1f52aa256a7e858))
+ __\*:__ Add quick logo ([9e26b09](https://github.com/coldbox-modules/quick/commit/9e26b0927041218d608b81000df8259fe42d83dc))
+ __\*:__ Copied Readme from docs (#1) ([137c688](https://github.com/coldbox-modules/quick/commit/137c68841facdddb245083e8076b7bbd17861422))


# v1.1.0
## 06 Jun 2018 — 20:50:16 UTC

### chore

+ __box.json:__ remove package scripts in favor of commandbox-semantic-release ([aafe02a](https://github.com/coldbox-modules/quick/commit/aafe02afe8d25683a3d85874f9193aca1b1c7412))

### feat

+ __attributes:__ better guarding against non-existent attributes ([0566e35](https://github.com/coldbox-modules/quick/commit/0566e35b7dca2123d1d115b4a70e9118c3800f5e))
+ __Columns:__ Allow attributes to set a sqltype ([8c3db73](https://github.com/coldbox-modules/quick/commit/8c3db73a49f2d599ddd7179226f9c2fd11437a6e))
+ __Relationships:__ pass arguments through to relationships ([5962a19](https://github.com/coldbox-modules/quick/commit/5962a19082dd9579ce021e139a80674efbf4d9a6))

### fix

+ __Update:__ don't include the key in the SET clause ([846ff78](https://github.com/coldbox-modules/quick/commit/846ff78ef3490b9320e112d3ad6f90635d10dbda))

### other

+ __\*:__ Enable commandbox-semantic-release ([e34f966](https://github.com/coldbox-modules/quick/commit/e34f9660d6c9f840dff25f2e34fbf17416cface8))
