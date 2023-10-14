// License: LGPL-3.0-or-later
import { CustomFieldDescription, nudgeToCustomFieldDescription } from ".";

export function newParseCustomField(input:string) : CustomFieldDescription {
  const [name, ...rest] = input.split(":").map((s) => s.trim())
  let label:string|null = null;
  if (rest.length > 0) {
    label = rest[0]
  }

  return nudgeToCustomFieldDescription({ name, label: label || name });;
};
