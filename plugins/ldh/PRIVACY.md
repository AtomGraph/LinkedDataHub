# LinkedDataHub plugin: privacy

The plugin collects, stores and transmits no data of its own. Its skills instruct the agent to run
the `ldh` CLI against the LinkedDataHub instance the user configures, authenticating
with the user's own client certificate. The base and the certificate's path are the plugin's settings;
the certificate's password is read by `ldh` from the user's own environment. Data goes only to that
instance, under the operator's control. AtomGraph receives nothing.
