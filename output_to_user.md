I have updated the error handling to make the messages more accurate. I have removed the generic "Failed to connect to the server" prefix.

Now, please run the application again using the same command as before:

**`flutter run -d chrome --web-browser-flag "--disable-web-security"`**

When you attempt to get user details, you will see a new, more precise error message. It will no longer say "Failed to connect", but will instead directly report the `403` status code and the "bad response" from the server.

This confirms that your session is active, but the server is denying permission.

To fix this, you must follow the instructions I provided earlier: **whitelist the `get_user_details` method in your Frappe app's Python code and restart your Frappe bench.** This is the only solution.