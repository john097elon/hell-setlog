# Workout record mobile UI

`/workout` is the mobile-first structured record hub. The existing workout lifecycle remains available at `/workout/session` and `/workout/:id`; a structured record is saved only when the signed-in user has an active workout.

The input flow loads the W1 exercise catalog, supports search, set duplication, and the contract-specific fields for repetitions/weight, time, and distance. Every submission carries an `X-Idempotency-Key`, keeps entered values after a failed request, and never reports a local preview as a server save.

The history view uses the W1 monthly calendar aggregate plus a date-bounded record query. Calendar dates expose record counts to assistive technology as well as visually.

Mobile layout rules:

- 44 CSS px minimum controls with at least 8 px spacing for adjacent actions.
- Numeric and decimal `inputmode` values for the matching fields.
- A sticky save action clears the mobile bottom navigation and safe-area inset.
- The 360×800, 375×812, 430×932, and 844×390 viewport matrix must remain free of horizontal scrolling and obscured content in E2E verification.