import { CustomFieldDescription } from "../../../parseFields";
const h = require('snabbdom/h')


export function customField(field: CustomFieldDescription) : ReturnType<typeof h> {
  return  h('input', {
    props: {
      name: `customFields[${field.name}]`
    , placeholder: field.label
    }
  });
}