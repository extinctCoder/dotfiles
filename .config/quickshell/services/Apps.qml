pragma Singleton
import Quickshell
import QtQuick
import qs.theme

// Installed apps: fuzzy search, ranking and launch.
Singleton {
    // subsequence match: "gh" matches "Ghostty"
    function fuzzy(query, str) {
        query = query.toLowerCase();
        str = str.toLowerCase();
        let i = 0;
        for (const ch of str) if (ch === query[i]) i++;
        return i >= query.length;
    }
    // lower is better: 0 starts with, 1 a word starts with, 2 contains, 3 loose match
    function score(query, name) {
        const q = query.toLowerCase(), n = name.toLowerCase();
        if (q === "" || n.startsWith(q)) return 0;
        if (n.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 1;
        if (n.includes(q)) return 2;
        return 3;
    }

    function search(query) {
        return Array.from(DesktopEntries.applications.values)
            .filter(a => !a.noDisplay && fuzzy(query, a.name))
            .sort((a, b) => score(query, a.name) - score(query, b.name) || a.name.localeCompare(b.name))
            .slice(0, 50);
    }

    // launcher rows, with the app's own icon (Papirus)
    function rows(query) {
        return search(query).map(a => ({
            kind: "app", title: a.name, sub: a.genericName || a.comment || "app",
            icon: Quickshell.iconPath(a.icon, "application-x-executable"),
            score: score(query, a.name),
            run: () => launch(a)
        }));
    }

    // execute() ignores Terminal=true, so terminal apps open inside Ghostty
    function launch(entry) {
        if (entry.runInTerminal) Term.run(Array.from(entry.command));
        else entry.execute();
    }
}
