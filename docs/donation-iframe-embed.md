# Donation Embed Parameters (Engineering Reference)

This is the engineering source-of-truth for the parameters supported by the
donation form when it is embedded on an external site — either as a **donate
button** (`<a class="commitchange-donate">`) or as a **custom iframe**.

The customer-facing version of the redirect/thank-you-page workflow lives in
Help Scout (see `docs/help-center/redirecting-donors-to-a-custom-thank-you-page.md`
for the source content).

## Two embed methods

### 1. Donate button (recommended)

The widget loader script (`client/js/widget/donate-button.v2.js`) finds every
`.commitchange-donate` element, reads its `data-*` attributes, and assembles the
donation URL for you. The base it builds is:

```
{host}/nonprofits/{npo_id}/donate?offsite=t&<params from data-attrs and page UTMs>
```

Note it **always appends `offsite=t`** (line ~121). If the element also has
`data-embedded`, the loader appends `&mode=embedded` and renders an inline
iframe; otherwise it renders a modal popup.

Because the loader does the URL assembly and encoding, this method avoids the
encoding pitfalls of the hand-written iframe below.

### 2. Custom iframe

A hand-written iframe pointing directly at the donate URL. You are responsible
for assembling the query string correctly (single `?`, `&`-joined params,
encoding). Example:

```html
<iframe frameborder="0" class="commitchange-iframe-embedded" width="100%" height="600"
  src="https://us.commitchange.com/nonprofits/3728/donate?campaign_id=6090&amp;mode=embedded&amp;custom_amounts=25%2C50%2C100%2C250%2C700%2C1000%2C1500&amp;redirect=https://www.example.org/thank-you&amp;skipFinish=t"></iframe>
```

## Parameter reference

Params are parsed on the donate page via `url.parse(href, true).query`
(`client/js/nonprofits/donate/wizard/utils/parseDonateParams.ts`). The
`data-*` column shows the equivalent attribute on a donate button, where one
exists.

| Query param | Button `data-*` | Type | Purpose |
|---|---|---|---|
| `campaign_id` | `data-campaign-id` | id | Attribute the gift to a campaign |
| `gift_option_id` | `data-gift-option-id` | id | Pre-select a gift option (with `campaign_id`) |
| `amount` | `data-amount` | number | Pre-fill a donation amount |
| `type` | `data-type` | `one-time`/`recurring` | Default donation type |
| `custom_amounts` | `data-custom-amounts` / `data-amounts` | string | Amount buttons. Comma/semicolon/underscore-separated numbers (`25,50,100`) or JSON5 with `{amount, highlight}`. Default `[25,50,100,250,500,1000,1500]`. |
| `custom_fields` | `data-custom-fields` | string | Extra form fields |
| `designation` | `data-designation` | string | Pre-select a designation |
| `multiple_designations` | `data-multiple-designations` | string | Allow multiple designations |
| `designations_prompt` | `data-designations-prompt` | string | Prompt text for designations |
| `designation_desc` | `data-designation-desc` / `data-description` | string | Designation description |
| `single_amount` | `data-single-amount` | number | Lock to a single amount |
| `hide_dedication` | `data-hide-dedication` | bool | Hide dedication fields |
| `manual_cover_fees` | `data-manual-cover-fees` | bool | Manual fee-coverage handling |
| `hide_cover_fees_option` | `data-hide-cover-fees-option` | bool | Hide the "cover fees" UI |
| `hide_anonymous` | `data-hide-anonymous` | bool | Hide the anonymous option |
| `minimal` | `data-minimal` | bool | Minimal UI |
| `weekly` | `data-weekly` | bool | Offer weekly recurring |
| `default` | `data-default` | string | Default recurring interval |
| `locale` | `data-locale` | string | Locale |
| `tags` | `data-tags` | string | Tag the donation |
| `utm_source` `utm_campaign` `utm_medium` `utm_content` | `data-utm_source` etc. | string | Analytics tags (also auto-read from the host page URL by the loader) |
| `first_name` `last_name` `country` `postal_code` `address` `city` | `data-first_name` etc. | string | Donor prefill |
| `redirect` | `data-redirect` | url | Where to send the donor after the gift completes |
| `skipFinish` | — (iframe/query only) | truthy | Auto-complete without the Finish button (see below) |
| `mode=embedded` | `data-embedded` (presence) | flag | Inline embed vs modal: hides close button, no auto-close |
| `offsite` | added automatically by loader | flag | Marks an external embed; gates the Finish button (see below) |
| `modal` | — | flag | Modal context |
| `fixed` | `data-fixed` | flag | Fixed/floating button variant |

## redirect / skipFinish / offsite interaction

This is the part most likely to cause confusion, so it is spelled out here.

- **`redirect`** (`client/js/nonprofits/donate/wizard/utils/handleWizardFinished.ts`):
  when the wizard finishes, if a `redirect` value is set and we're inside an
  iframe, the form posts `commitchange:redirect:{url}` to the parent; otherwise
  it sets `window.location` directly.

- **`skipFinish`** (`client/js/nonprofits/donate/wizard.js`): when the charge
  completes, if `skipFinish` is truthy the form calls `handleWizardFinished`
  immediately — skipping the Finish button. Truthy check, so any non-empty
  value (e.g. `t`) works. **There is no `data-skip-finish` attribute — this is
  reachable only via the iframe/query-string method.**

- **`offsite`** (`client/js/nonprofits/donate/followup-step.js` lines 37-38):
  the Finish button only renders when `offsite` is true **and** (`redirect` or
  `modal`) is set. The donate-button loader always sets `offsite=t`.

Resulting behavior:

| Method | offsite | skipFinish | Result |
|---|---|---|---|
| Donate button (`data-redirect`) | `t` (auto) | n/a | Finish button shows → donor clicks → redirect |
| Iframe + `redirect` + `skipFinish=t` | not required | yes | Auto-redirect on completion (no Finish button) |
| Iframe + `redirect`, no `skipFinish` | **required** | no | Needs `offsite=t` or there's no Finish button and no redirect ever fires |

**Practical rule:** if you want an automatic/immediate redirect (skip the Finish
screen), use the iframe method with `skipFinish=t`. If a Finish-button step is
acceptable, the donate button (`data-redirect`) is simpler and adds `offsite=t`
for you.

## ⚠️ A hand-written iframe cannot redirect on its own — the host page needs the loader script

This is the single most common reason a redirect "doesn't work."

When the form runs inside an iframe, it **cannot navigate the parent page
directly** (the iframe is on `*.commitchange.com`, the host page is the
nonprofit's own domain — cross-origin navigation is blocked by the browser).
So instead, on completion the form **posts a message** to the parent window:

```
commitchange:redirect:{url}
```

(`handleWizardFinished.ts` → `WidgetWindowWrapper.notifyParentOfRedirect`.)

Something on the host page has to **listen** for that message and perform the
navigation. The only thing that does this is the **CommitChange loader script**
(`donate-button.v2.js`), which installs:

```js
window.addEventListener('message', (e) => {
  if (typeof e.data === 'string' && e.data.startsWith('commitchange:redirect')) {
    const m = e.data.match(/^commitchange:redirect:(.+)$/)
    if (m.length === 2) window.location.href = m[1]
  }
})
```

If the host page has only a bare `<iframe>` and **not** the loader script, the
redirect message is posted into the void and nothing happens. The donate button
method doesn't hit this because the loader script is required for it anyway.

**Fix for a hand-written iframe:** add the loader script to the host page (it
installs the listener; with no `.commitchange-donate` element it builds no
buttons):

```html
<script id='commitchange-donation-script' data-npo-id='{NPO_ID}'
        src='https://commitchange.com/js/donate-button.v2.js'></script>
```

### Side effect: the loader injects a stylesheet that resizes the embed

On load, the loader also appends
`<link href="https://us.commitchange.com/css/donate-button.v2.css">` to the
host page `<head>`. All of its rules are scoped to `.commitchange-*` classes
(no global/element selectors), so it won't affect the rest of the page — **but**
it includes:

```css
.commitchange-iframe-embedded { width: 390px; height: 450px; max-width: 100%; border: 0; }
```

Because CSS overrides HTML `width`/`height` attributes, a hand-written
`<iframe class="commitchange-iframe-embedded" width="100%" height="600">` will
be resized to 390×450 once the script loads. To keep a custom size, override it
after the script:

```html
<style>.commitchange-iframe-embedded { width: 100% !important; height: 600px !important; }</style>
```

## URL construction rules (hand-written iframe)

1. **One `?` only.** It goes after `/donate`. Everything after is joined with
   `&` (`&amp;` in HTML). A second `?` becomes a literal character and silently
   swallows the following params into the previous value — the classic cause of
   a redirect that "doesn't work."

2. **`&amp;` is HTML encoding, not URL encoding.** Inside an iframe `src` it's
   the correct way to write `&`; the browser decodes it. Don't convert it to a
   plain `&` or to `%26`, and never paste `&amp;` into a browser address bar
   (WAFs such as GoDaddy's flag it as an evasion attempt).

3. **Encode the `redirect` value only when the destination has its own query
   string.** A clean path like `https://example.org/thank-you` needs no
   encoding. But the moment you add the destination's own params (UTMs, etc.),
   URL-encode the entire `redirect` value so its `?`/`&`/`=` don't collide with
   the donate form's params. The form URL-decodes the value automatically.

   Destination: `https://example.org/thank-you?utm_campaign=spring-appeal`
   Encoded for `redirect=`: `https%3A%2F%2Fexample.org%2Fthank-you%3Futm_campaign%3Dspring-appeal`

## Key source files

- `client/js/widget/donate-button.v2.js` — button loader; reads `data-*`, builds the URL, renders modal/inline iframe, injects the widget stylesheet, **and installs the parent-window `message` listener that performs iframe redirects** (lines ~190-201).
- `client/js/nonprofits/donate/wizard/utils/parseDonateParams.ts` — query-string parsing.
- `client/js/nonprofits/donate/wizard/utils/handleWizardFinished.ts` — redirect + close behavior, `mode=embedded` handling.
- `client/js/nonprofits/donate/wizard.js` — `skipFinish` trigger, close-button visibility.
- `client/js/nonprofits/donate/followup-step.js` — Finish-button gating on `offsite`.
- `client/js/nonprofits/donate/parseFields/customAmounts/index.ts` — `custom_amounts` parsing.
