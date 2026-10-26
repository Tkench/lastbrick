# Last Brick email templates

Paste each into **Supabase → Authentication → Emails → Templates** (choose the matching template, switch the editor to HTML/source, replace everything, save).

| Supabase template | File | Subject |
|---|---|---|
| Confirm signup | confirm-signup.html | Confirm your Last Brick account |
| Reset password | reset-password.html | Reset your Last Brick password |
| Change email address | change-email.html | Confirm your new email for Last Brick |

Emails are sent through Brevo (custom SMTP: smtp-relay.brevo.com, port 587) from "Last Brick <hello@lastbrick.co.uk>".
