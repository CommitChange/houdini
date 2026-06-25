# Redirecting donors to a custom thank-you page

After a donation completes, you can send donors to your own custom thank-you page (for example, a page with a special video, a survey, or conversion tracking). This is done with two settings: **redirect** and **skipFinish**.

**Which method should I use?**

- If it's okay for donors to click a **"Finish" button** before being sent to your page, use the **donate button** (Option 1) — it's the easiest and there's nothing to encode.
- If you want donors sent to your page **automatically and immediately** when their gift completes (skipping the Finish screen), you must use the **custom iframe embed** (Option 2). This is the only method that supports the automatic skip.

---

## Option 1 — Donate button (redirect after "Finish")

If you're using a CommitChange donate button, just add the `data-redirect` attribute. CommitChange handles all the URL formatting for you, so there's nothing to encode.

```html
<a class='commitchange-donate'
   data-campaign-id='786'
   data-redirect='https://www.example.org/thank-you'></a>
```

- **data-redirect** — the full URL of your thank-you page

With this method, the donor completes their gift, clicks **Finish**, and is then sent to your thank-you page. (The donate button does not support skipping the Finish screen — for that, use Option 2.)

---

## Option 2 — Custom iframe embed

If you embed the donation form with an iframe, add `redirect` and `skipFinish` as query parameters in the iframe's `src`.

```html
<iframe frameborder="0" class="commitchange-iframe-embedded" width="100%" height="600"
  src="https://us.commitchange.com/nonprofits/3728/donate?campaign_id=6090&amp;mode=embedded&amp;redirect=https://www.example.org/thank-you&amp;skipFinish=t"></iframe>
```

### The rules (this is where most mistakes happen)

1. **Use only ONE `?` in the whole URL.** It goes right after `/donate`. Everything after it is joined with `&` (written as `&amp;` inside HTML). A second `?` will break the redirect silently.

   ❌ Wrong: `...custom_amounts=25,50,100?redirect=https://...`
   ✅ Right: `...custom_amounts=25,50,100&amp;redirect=https://...`

2. **Keep `&amp;` as-is.** Inside an iframe, `&amp;` is the correct way to write `&` — your browser converts it automatically. Don't change it to a plain `&` or anything else, and never type `&amp;` directly into a browser address bar (security firewalls will block it).

3. **`skipFinish` is a CommitChange setting, not part of your thank-you page address.** It stays in the iframe URL; it is not added onto your thank-you page.

---

## Adding tracking (UTM tags) to your thank-you page

If your thank-you page uses Google Analytics, you can tag the redirect so you can see which campaign drove the donation. Use the standard `utm_campaign` tag (plus `utm_source` and `utm_medium` if you like).

**Important:** Once your thank-you page address has its *own* `?` (like a UTM tag), the entire redirect address must be URL-encoded so it doesn't conflict with the donation form's settings.

Your desired thank-you page:
```
https://www.example.org/thank-you?utm_source=commitchange&utm_medium=donation&utm_campaign=spring-appeal
```

URL-encoded for the redirect (this is what goes in the iframe):
```
https%3A%2F%2Fwww.example.org%2Fthank-you%3Futm_source%3Dcommitchange%26utm_medium%3Ddonation%26utm_campaign%3Dspring-appeal
```

You can use any free "URL encoder" tool online to do this conversion. Keep UTM values lowercase with no spaces (Google Analytics treats `Spring` and `spring` as different campaigns).

---

## Troubleshooting

- **The redirect doesn't happen.** Check that there's only one `?` in your URL and that everything else uses `&` (or `&amp;` in an iframe).
- **You land on a blank or error page.** Open your thank-you page address directly in a browser first to confirm it loads. If the page itself is broken or blocked, fix that on your website before adding it to the redirect.
- **Tracking isn't showing up.** Confirm Google Analytics is installed on the thank-you page, and that you URL-encoded the redirect once you added UTM tags.

---

### Related articles

- Creating a campaign-specific donate button
- Basic donate button implementation
- Floating donate button
- Why isn't my donate button working?
