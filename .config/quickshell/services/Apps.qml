pragma Singleton
import Quickshell
import QtQuick

// Installed apps: fuzzy search and launch.
Singleton {
    // subsequence match: "gh" matches "Ghostty"
    function fuzzy(query, str) {
        query = query.toLowerCase();
        str = str.toLowerCase();
        let i = 0;
        for (const ch of str) if (ch === query[i]) i++;
        return i >= query.length;
    }

    function search(query) {
        return Array.from(DesktopEntries.applications.values)
            .filter(a => !a.noDisplay && fuzzy(query, a.name))
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 50);
    }

    // execute() ignores Terminal=true, so terminal apps open inside Ghostty
    function launch(entry) {
        if (entry.runInTerminal) Term.run(Array.from(entry.command));
        else entry.execute();
    }
}
