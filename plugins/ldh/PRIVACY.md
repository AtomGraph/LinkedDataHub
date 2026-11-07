# LinkedDataHub plugin: privacy

The plugin collects, stores and transmits no data of its own. Its skills instruct the agent to run
the `ldh` CLI against the LinkedDataHub instance the user configures, authenticating
with the user's own client certificate. The base, certificate and password are the plugin's settings;
the password is kept in the system credential store and handed only to `ldh`. Data goes only to that
instance, under the operator's control. AtomGraph receives nothing.
