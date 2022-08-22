# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
MAX_EMAIL_JOB_ATTEMPTS = Rails.env == 'production' ? 50 : 2