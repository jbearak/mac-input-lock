# Security

Report suspected vulnerabilities privately through this fork's GitHub security
advisory feature.

Mac Input Lock uses Accessibility access to suppress global input. It does not
log or transmit input, make network requests, install a privileged helper, or
run a background service. Its in-memory buffer retains only enough characters
to recognize the unlock sequence.

There is no updater. Pull and review source changes, rebuild, and replace the
installed app to receive fixes. Do not close the lid or use the physical power
button as part of an input-lock test; those remain under macOS control.
