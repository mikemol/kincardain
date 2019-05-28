# Kincardain

Kincardain is the name of a campaign setting I'm building. It's also the name of
a collection of tools I'm writing to maintain and build that settings.

## import.rb

To start with, there's `import.rb`, whose function is to read in the JSON export
from Scabard and import it into a SQLite database. (I use SQL to query the
campaign and find and prioritize gaps.)