pragma Singleton
import Quickshell
import QtQuick
import qs.theme

// Launcher calculator. Only digits, spaces and + - * / % ^ ( ) . are accepted,
// so nothing but arithmetic can ever be evaluated.
Singleton {
    function evaluate(expr) {
        const e = expr.trim();
        if (!/^[\d\s+\-*/%^().]+$/.test(e) || !/\d/.test(e)) return null;
        try {
            const r = Function('"use strict"; return (' + e.replace(/\^/g, "**") + ");")();
            return (typeof r === "number" && isFinite(r)) ? Number(r.toPrecision(12)) : null;
        } catch (err) {
            return null;
        }
    }
    // a row only when the text is a real calculation (has an operator), or forced with "="
    function rows(expr, forced) {
        if (!forced && !/[+\-*/%^]/.test(expr.trim().slice(1))) return [];
        const r = evaluate(expr);
        if (r === null) return [];
        return [{
            kind: "calc", title: "= " + r, sub: "enter copies the result", glyph: Icons.calc,
            run: () => Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", String(r)])
        }];
    }
}
