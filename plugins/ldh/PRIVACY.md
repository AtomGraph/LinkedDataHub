# LinkedDataHub plugin: privacy

The plugin collects, stores and transmits no data of its own. Its skills instruct the agent to run
the `ldh` CLI against the LinkedDataHub instance the user configures (`LDH_BASE`), authenticating
with the user's own client certificate. Data goes only to that instance, under the operator's
control. AtomGraph receives nothing.
