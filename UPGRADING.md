# Upgrading

## Upgrading to 0.7.0

Starting from version 0.7.0, rodauth-rails now correctly detects Rails
application's `secret_key_base` when setting default `hmac_secret`, including
when it's set via credentials or `$SECRET_KEY_BASE` environment variable. This
means that your authentication will now be more secure by default, and Rodauth
features that require `hmac_secret` should now work automatically as well.

However, if you've already been using rodauth-rails in production, where the
`secret_key_base` is set via credentials or environment variable and `hmac_secret`
was not explicitly set, the fact that your authentication will now start using
HMACs has backwards compatibility considerations. See the [Rodauth
documentation][hmac] for instructions on how to safely transition, or just set
`hmac_secret nil` in your Rodauth configuration.
