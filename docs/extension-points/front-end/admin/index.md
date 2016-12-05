# Admin Plugin

Allows plugins to add items to the admin pane in existing or new sections.

To register an admin item:

```js
require(['configuration/plugins/registry'], function(registry) {
    registry.registerExtension('org.visallo.admin', {
        section: 'My New Section',
        name: 'My Admin Tool',
        subtitle: 'Some custom tools for administration',
        componentPath: 'com/example/admin/tool',
        requiredPrivilege: 'ADMIN'
    });
});
```

# Properties

* `section`: _(required)_ `[String]` Existing or new section to place this item.
* `name`: _(required)_ `[String]` Name of the admin tool, to be displayed under the section.
* `subtitle`: _(optional)_ `[String]` Text to describe admin tool.
* `requiredPrivilege`: _(optional)_ `[String|function]` A string containing the privilege required to view
   this extension. Or, a function which will be executed, if function returns true the extension will be
   visible. The default for this property is `'ADMIN'`.
* `options`: _(optional)_ `[Object]`
  * `sortHint`: `[Number]` A number indicating the admin tool's position within the section. If not
    included, admin items will be sorted within a section by name.
* Exactly one of: `componentPath` or `Component`, or `url` _(required)_

    * `componentPath`: `[String]` requirejs or react component path
    * `Component`: `[Object]` FlightJS or react component
    * `url`: `[String]` Open new window to this url

