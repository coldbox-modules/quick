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
